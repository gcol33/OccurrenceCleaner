// Kernels for the grouped tests: distances among the records of one species
// or taxon, a string hash for bucketing and per-group seeds, and the row-key
// hashes and seen-set of the duplicate test.

#include <Rcpp.h>

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstring>
#include <limits>
#include <string>
#include <unordered_set>
#include <vector>

#include "threads.h"

using namespace Rcpp;

namespace {

const double kDeg = 3.14159265358979323846 / 180.0;
// Earth radius of the haversine distance, as in geosphere::distHaversine().
const double kRadiusKm = 6378.137;

// Haversine distance in km between points given in degrees.
inline double haversine_km(double lon1, double lat1, double lon2, double lat2) {
  const double p1 = lat1 * kDeg, p2 = lat2 * kDeg;
  const double dlat = p2 - p1, dlon = (lon2 - lon1) * kDeg;
  const double s1 = std::sin(dlat / 2), s2 = std::sin(dlon / 2);
  double a = s1 * s1 + std::cos(p1) * std::cos(p2) * s2 * s2;
  if (a > 1) a = 1;
  return 2 * std::atan2(std::sqrt(a), std::sqrt(1 - a)) * kRadiusKm;
}

}  // namespace

// FNV-1a hash of each string's bytes, as a non-negative integer; NA stays NA.
// [[Rcpp::export]]
IntegerVector cpp_hash_strings(CharacterVector x) {
  const R_xlen_t n = x.size();
  IntegerVector out(n);
  for (R_xlen_t i = 0; i < n; ++i) {
    if (CharacterVector::is_na(x[i])) {
      out[i] = NA_INTEGER;
      continue;
    }
    const char* s = CHAR(STRING_ELT(x, i));
    std::uint32_t h = 2166136261u;
    for (; *s; ++s) {
      h ^= static_cast<unsigned char>(*s);
      h *= 16777619u;
    }
    out[i] = static_cast<int>(h & 0x7fffffffu);
  }
  return out;
}

namespace {

// MurmurHash64A of a byte buffer.
std::uint64_t murmur64(const std::string& buf, std::uint64_t seed) {
  const std::uint64_t m = 0xc6a4a7935bd1e995ULL;
  const int r = 47;
  const std::size_t len = buf.size();
  std::uint64_t h = seed ^ (len * m);
  const unsigned char* p = reinterpret_cast<const unsigned char*>(buf.data());
  const std::size_t nblocks = len / 8;
  for (std::size_t i = 0; i < nblocks; ++i) {
    std::uint64_t k;
    std::memcpy(&k, p + 8 * i, 8);
    k *= m; k ^= k >> r; k *= m;
    h ^= k; h *= m;
  }
  const unsigned char* tail = p + 8 * nblocks;
  switch (len & 7) {
    case 7: h ^= std::uint64_t(tail[6]) << 48; [[fallthrough]];
    case 6: h ^= std::uint64_t(tail[5]) << 40; [[fallthrough]];
    case 5: h ^= std::uint64_t(tail[4]) << 32; [[fallthrough]];
    case 4: h ^= std::uint64_t(tail[3]) << 24; [[fallthrough]];
    case 3: h ^= std::uint64_t(tail[2]) << 16; [[fallthrough]];
    case 2: h ^= std::uint64_t(tail[1]) << 8; [[fallthrough]];
    case 1: h ^= std::uint64_t(tail[0]); h *= m;
  }
  h ^= h >> r; h *= m; h ^= h >> r;
  return h;
}

// Append one field of row i to a key buffer: a type tag, then the value.
// Doubles compare as R's duplicated() does: -0 equals 0, NA and NaN are each
// one value. Strings are compared in UTF-8; NA is distinct from "NA".
void append_field(std::string& buf, SEXP col, R_xlen_t i) {
  switch (TYPEOF(col)) {
    case REALSXP: {
      double v = REAL(col)[i];
      if (v == 0) v = 0;
      if (R_IsNA(v)) { buf.push_back('A'); return; }
      if (std::isnan(v)) { buf.push_back('N'); return; }
      buf.push_back('d');
      buf.append(reinterpret_cast<const char*>(&v), sizeof v);
      return;
    }
    case INTSXP:
    case LGLSXP: {
      const int v = TYPEOF(col) == INTSXP ? INTEGER(col)[i] : LOGICAL(col)[i];
      buf.push_back('i');
      buf.append(reinterpret_cast<const char*>(&v), sizeof v);
      return;
    }
    case STRSXP: {
      SEXP s = STRING_ELT(col, i);
      if (s == NA_STRING) { buf.push_back('S'); return; }
      const char* c = Rf_translateCharUTF8(s);
      const std::uint32_t len = static_cast<std::uint32_t>(std::strlen(c));
      buf.push_back('s');
      buf.append(reinterpret_cast<const char*>(&len), sizeof len);
      buf.append(c, len);
      return;
    }
    default:
      stop("key columns must be numeric, integer, logical or character");
  }
}

struct Key128 {
  std::uint64_t a, b;
  bool operator==(const Key128& o) const { return a == o.a && b == o.b; }
};
struct Key128Hash {
  std::size_t operator()(const Key128& k) const { return static_cast<std::size_t>(k.a ^ (k.b * 0x9e3779b97f4a7c15ULL)); }
};
using SeenSet = std::unordered_set<Key128, Key128Hash>;

inline Key128 key_of(int w1, int w2, int w3, int w4) {
  return Key128{(std::uint64_t(std::uint32_t(w1)) << 31) | std::uint32_t(w2),
                (std::uint64_t(std::uint32_t(w3)) << 31) | std::uint32_t(w4)};
}

}  // namespace

// Hash of each row of a list of equal-length key columns, as four
// non-negative 31-bit integers (124 bits): two MurmurHash64A values with
// different seeds, each cut to 62 bits. Rows with equal values in every
// column get equal words.
// [[Rcpp::export]]
List cpp_key_hash(List cols) {
  const int k = cols.size();
  if (k == 0) stop("no key columns");
  const R_xlen_t n = Rf_xlength(cols[0]);
  for (int j = 1; j < k; ++j)
    if (Rf_xlength(cols[j]) != n) stop("key columns differ in length");
  IntegerVector w1(n), w2(n), w3(n), w4(n);
  std::string buf;
  for (R_xlen_t i = 0; i < n; ++i) {
    buf.clear();
    for (int j = 0; j < k; ++j) append_field(buf, cols[j], i);
    const std::uint64_t h1 = murmur64(buf, 0x8445d61a4e774912ULL);
    const std::uint64_t h2 = murmur64(buf, 0x3c6ef372fe94f82bULL);
    w1[i] = static_cast<int>((h1 >> 31) & 0x7fffffffu);
    w2[i] = static_cast<int>(h1 & 0x7fffffffu);
    w3[i] = static_cast<int>((h2 >> 31) & 0x7fffffffu);
    w4[i] = static_cast<int>(h2 & 0x7fffffffu);
  }
  return List::create(_["h1"] = w1, _["h2"] = w2, _["h3"] = w3, _["h4"] = w4);
}

// A set of key hashes kept between calls.
// [[Rcpp::export]]
SEXP cpp_seen_new() {
  XPtr<SeenSet> p(new SeenSet(), true);
  return p;
}

// For each key in order: TRUE when it is already in the set (an earlier row
// or an earlier call had it), then add it.
// [[Rcpp::export]]
LogicalVector cpp_seen_mark(SEXP set, IntegerVector h1, IntegerVector h2, IntegerVector h3,
                            IntegerVector h4) {
  XPtr<SeenSet> s(set);
  const R_xlen_t n = h1.size();
  LogicalVector out(n);
  for (R_xlen_t i = 0; i < n; ++i)
    out[i] = !s->insert(key_of(h1[i], h2[i], h3[i], h4[i])).second;
  return out;
}

// Distances are summed as integers of 2^-32 km (0.23 micrometres), so a sum
// is exact and the same in any order of addition; a mean is within half a
// unit of the mean of the unrounded distances. A distance is at most half the
// circumference, below 2^46.3 units, so a sum over fewer than kMaxSumPoints
// points fits in 63 bits.
const double kUnitsPerKm = 4294967296.0;
const R_xlen_t kMaxSumPoints = 100000;

// Haversine distance (km) between points a and b, from latitudes in radians
// p, their cosines cp and longitudes in degrees.
static inline double hav_km(const double* lon, const double* p, const double* cp, R_xlen_t a,
                            R_xlen_t b) {
  const double s1 = std::sin((p[b] - p[a]) / 2), s2 = std::sin((lon[b] - lon[a]) * kDeg / 2);
  double h = s1 * s1 + cp[a] * cp[b] * s2 * s2;
  if (h > 1) h = 1;
  return 2 * std::atan2(std::sqrt(h), std::sqrt(1 - h)) * kRadiusKm;
}

// Per-point accumulators of the distances to the other points: the sum in
// integer units, the number of points summed and the minimum.
struct DistAcc {
  std::vector<std::int64_t> s, k;
  std::vector<double> m;
  explicit DistAcc(R_xlen_t n)
      : s(n, 0), k(n, 0), m(n, std::numeric_limits<double>::infinity()) {}
};

// Add the pairs (i, j), j > i, of the u distinct points; point j stands for
// w[j] records.
static inline void add_row(const double* lon, const double* p, const double* cp, const int* w, R_xlen_t u,
                           R_xlen_t i, DistAcc& a) {
  for (R_xlen_t j = i + 1; j < u; ++j) {
    const double d = hav_km(lon, p, cp, i, j);
    if (!(d > 0)) continue;
    const std::int64_t q = std::llround(d * kUnitsPerKm);
    a.s[i] += q * w[j]; a.k[i] += w[j]; if (d < a.m[i]) a.m[i] = d;
    a.s[j] += q * w[i]; a.k[j] += w[i]; if (d < a.m[j]) a.m[j] = d;
  }
}

// For each of the n points of a group: the mean and the minimum of its
// haversine distances (km) to the other points, leaving out zero distances
// (itself and points at the same coordinates). A point with no non-zero
// distance gets NaN and Inf. Points at the same coordinates share their
// distances, so each pair of distinct coordinates is computed once and
// weighted by the records at both. With threads > 1 the rows are spread over
// the threads, each adding into its own accumulators, which are summed at the
// end; integer sums make the result the same for any number of threads.
static inline void outlier_dist_group(const double* lon, const double* lat, R_xlen_t n, double* mean,
                                      double* mn, int threads) {
  if (n == 0) return;
  std::vector<R_xlen_t> ord(n);
  for (R_xlen_t i = 0; i < n; ++i) ord[i] = i;
  std::sort(ord.begin(), ord.end(), [&](R_xlen_t a, R_xlen_t b) {
    return lon[a] < lon[b] || (lon[a] == lon[b] && (lat[a] < lat[b] || (lat[a] == lat[b] && a < b)));
  });
  std::vector<R_xlen_t> of(n);
  std::vector<double> ux, p, cp;
  std::vector<int> w;
  for (R_xlen_t r = 0; r < n; ++r) {
    const R_xlen_t i = ord[r];
    if (r == 0 || lon[i] != ux.back() || lat[i] != lat[ord[r - 1]]) {
      ux.push_back(lon[i]);
      p.push_back(lat[i] * kDeg);
      cp.push_back(std::cos(lat[i] * kDeg));
      w.push_back(0);
    }
    ++w.back();
    of[i] = static_cast<R_xlen_t>(ux.size()) - 1;
  }
  const R_xlen_t u = static_cast<R_xlen_t>(ux.size());
  DistAcc acc(u);
  if (threads > 1 && u > 1) {
    std::vector<DistAcc> part(threads, DistAcc(u));
    OCC_OMP(omp parallel for num_threads(threads) schedule(dynamic, 8))
    for (R_xlen_t i = 0; i < u; ++i)
      add_row(ux.data(), p.data(), cp.data(), w.data(), u, i, part[occ::thread_id()]);
    for (const DistAcc& t : part)
      for (R_xlen_t i = 0; i < u; ++i) {
        acc.s[i] += t.s[i]; acc.k[i] += t.k[i]; if (t.m[i] < acc.m[i]) acc.m[i] = t.m[i];
      }
  } else {
    for (R_xlen_t i = 0; i < u; ++i) add_row(ux.data(), p.data(), cp.data(), w.data(), u, i, acc);
  }
  for (R_xlen_t i = 0; i < n; ++i) {
    const R_xlen_t c = of[i];
    mean[i] = acc.k[c] ? static_cast<double>(acc.s[c]) / kUnitsPerKm / static_cast<double>(acc.k[c]) : R_NaN;
    mn[i] = acc.m[c];
  }
}

// The distances of outlier_dist_group() within each group of points: group g
// is rows start[g] to start[g + 1] - 1 (0-based; the last entry of start is
// the number of points). Groups of fewer than split_n points are spread over
// the threads, one group per thread at a time; larger groups follow one after
// the other, each spread over the threads by rows. The result does not
// depend on the number of threads.
// [[Rcpp::export]]
List cpp_outlier_dist(NumericVector lon, NumericVector lat, IntegerVector start, int n_threads = 1,
                      int split_n = 1000) {
  const R_xlen_t n = lon.size();
  if (lat.size() != n) stop("lon and lat differ in length");
  const R_xlen_t ng = start.size() - 1;
  if (ng < 0 || start[0] != 0 || start[ng] != n) stop("start must run from 0 to the number of points");
  for (R_xlen_t g = 0; g < ng; ++g) {
    if (start[g + 1] < start[g]) stop("start must be non-decreasing");
    if (start[g + 1] - start[g] >= kMaxSumPoints) stop("a group of the exact outlier test has 100,000 points or more");
  }
  NumericVector mean(n), mn(n);
  const double* px = REAL(lon);
  const double* py = REAL(lat);
  const int* st = INTEGER(start);
  double* pm = REAL(mean);
  double* pn = REAL(mn);
  const int nt = occ::threads(n_threads);
  std::vector<R_xlen_t> small, large;
  for (R_xlen_t g = 0; g < ng; ++g)
    (nt > 1 && st[g + 1] - st[g] >= split_n ? large : small).push_back(g);
  const R_xlen_t ns = static_cast<R_xlen_t>(small.size());
  OCC_OMP(omp parallel for num_threads(nt) schedule(dynamic, 1))
  for (R_xlen_t q = 0; q < ns; ++q) {
    const R_xlen_t g = small[q];
    outlier_dist_group(px + st[g], py + st[g], st[g + 1] - st[g], pm + st[g], pn + st[g], 1);
  }
  for (R_xlen_t g : large)
    outlier_dist_group(px + st[g], py + st[g], st[g + 1] - st[g], pm + st[g], pn + st[g], nt);
  return List::create(_["mean"] = mean, _["min"] = mn);
}

// Cell statistics of the raster approximation: cells with centre (cx, cy)
// holding count records. Weighted: the distance between two cells is
// multiplied by the product of their counts and rounded to whole km, a cell's
// distance to itself counts as same_km, and the statistic is the weighted
// mean; min is the smallest weighted, rounded value. Unweighted: the plain
// mean and minimum over the other cells.
// [[Rcpp::export]]
List cpp_cell_dist(NumericVector cx, NumericVector cy, NumericVector count, bool weighted,
                   double same_km) {
  const R_xlen_t n = cx.size();
  NumericVector mean(n), mn(n);
  for (R_xlen_t a = 0; a < n; ++a) {
    double s = 0, w = 0, m = std::numeric_limits<double>::infinity();
    for (R_xlen_t b = 0; b < n; ++b) {
      double d = (a == b) ? 0.0 : haversine_km(cx[a], cy[a], cx[b], cy[b]);
      if (weighted) {
        if (d == 0) d = same_km;
        const double wab = count[a] * count[b];
        const double v = std::nearbyint(d * wab);
        s += v;
        w += wab;
        if (v < m) m = v;
      } else {
        if (!(d > 0)) continue;
        s += d;
        w += 1;
        if (d < m) m = d;
      }
    }
    mean[a] = w > 0 ? s / w : R_NaN;
    mn[a] = m;
  }
  return List::create(_["mean"] = mean, _["min"] = mn);
}

// Mean of x[0..n-1] as stats::cov() takes it: a long double sum, one
// correction pass, stored as a double.
static double cov_mean(const double* x, R_xlen_t n) {
  long double s = 0;
  for (R_xlen_t i = 0; i < n; ++i) s += x[i];
  long double m = s / n;
  if (R_FINITE(static_cast<double>(m))) {
    long double t = 0;
    for (R_xlen_t i = 0; i < n; ++i) t += x[i] - m;
    m += t / n;
  }
  return static_cast<double>(m);
}

// Lagged covariances of the dataset rounding test: for k = 1..max_lag, the
// covariance of f without its first k values and f without its last k
// values, as stats::cov() computes it.
// [[Rcpp::export]]
NumericVector cpp_lag_cov(NumericVector f, int max_lag) {
  const R_xlen_t n = f.size();
  NumericVector out(max_lag);
  const double* x = f.begin();
  for (int k = 1; k <= max_lag; ++k) {
    const R_xlen_t m = n - k;
    const double* a = x + k;
    const double* b = x;
    const long double ma = cov_mean(a, m), mb = cov_mean(b, m);  // promoted as in cov.c
    long double s = 0;
    for (R_xlen_t i = 0; i < m; ++i) s += (a[i] - ma) * (b[i] - mb);
    out[k - 1] = m > 1 ? static_cast<double>(s / (m - 1)) : NA_REAL;
  }
  return out;
}

// Type-7 quantile of sorted values, in the arithmetic of stats::quantile().
static double quantile7(const std::vector<double>& x, double p) {
  const double index = 1 + (static_cast<double>(x.size()) - 1) * p;
  const std::size_t lo = static_cast<std::size_t>(std::floor(index));
  const std::size_t hi = static_cast<std::size_t>(std::ceil(index));
  const double qs = x[lo - 1];
  if (!(index > lo && x[hi - 1] != qs)) return qs;
  const double h = index - lo;
  return (1 - h) * qs + h * x[hi - 1];
}

// Outlier counts of the dataset rounding test. Every window of win + 1
// consecutive values of gam marks the values above its 75% quantile plus t1
// times its interquartile range (NA left out); the result counts, for each
// position, the windows that marked it.
// [[Rcpp::export]]
IntegerVector cpp_window_outlier_counts(NumericVector gam, int win, double t1) {
  const R_xlen_t n = gam.size();
  IntegerVector tot(n);
  std::vector<double> v;
  v.reserve(win + 1);
  for (R_xlen_t k = 0; k < n - win; ++k) {
    v.clear();
    for (R_xlen_t j = k; j <= k + win; ++j)
      if (!ISNAN(gam[j])) v.push_back(gam[j]);
    if (v.empty()) continue;
    std::sort(v.begin(), v.end());
    const double q75 = quantile7(v, 0.75);
    const double fence = q75 + (q75 - quantile7(v, 0.25)) * t1;
    for (R_xlen_t j = k; j <= k + win; ++j)
      if (gam[j] > fence) ++tot[j];
  }
  return tot;
}

// Spatio-temporal distance of the fossil outlier test. For each pair: the
// geographic distance (haversine km, or Euclidean degrees when euclid) plus
// the absolute difference of the sampled ages rescaled so that the largest
// age difference equals the largest geographic distance, rounded to whole
// units. Each point gets the mean over all points, itself included; pairs
// with a missing coordinate are left out, missing ages count as zero.
// [[Rcpp::export]]
NumericVector cpp_spatiotemporal_mean(NumericVector lon, NumericVector lat, NumericVector age,
                                      bool euclid) {
  const R_xlen_t n = lon.size();
  if (lat.size() != n || age.size() != n) stop("inputs differ in length");
  auto geo = [&](R_xlen_t i, R_xlen_t j) -> double {
    if (ISNAN(lon[i]) || ISNAN(lat[i]) || ISNAN(lon[j]) || ISNAN(lat[j])) return NA_REAL;
    if (euclid) {
      const double dx = lon[i] - lon[j], dy = lat[i] - lat[j];
      return std::sqrt(dx * dx + dy * dy);
    }
    return haversine_km(lon[i], lat[i], lon[j], lat[j]);
  };
  double max_geo = R_NegInf, max_age = R_NegInf;
  for (R_xlen_t i = 0; i < n; ++i) {
    for (R_xlen_t j = 0; j < n; ++j) {
      const double g = geo(i, j);
      if (!ISNAN(g) && g > max_geo) max_geo = g;
      if (!ISNAN(age[i]) && !ISNAN(age[j])) {
        const double t = std::fabs(age[i] - age[j]);
        if (t > max_age) max_age = t;
      }
    }
  }
  const double scale = max_geo / max_age;
  NumericVector out(n);
  for (R_xlen_t i = 0; i < n; ++i) {
    double s = 0;
    R_xlen_t k = 0;
    for (R_xlen_t j = 0; j < n; ++j) {
      const double g = geo(i, j);
      if (ISNAN(g)) continue;
      double t = (ISNAN(age[i]) || ISNAN(age[j])) ? 0.0 : std::fabs(age[i] - age[j]) * scale;
      if (ISNAN(t)) t = 0;
      s += std::nearbyint(t + g);
      ++k;
    }
    out[i] = k ? s / static_cast<double>(k) : R_NaN;
  }
  return out;
}

// Counts of (group, key) pairs kept between calls, for the accumulators of
// the group stage: the records of each raster cell of a large species, and
// the ddmm cells a dataset has filled. A group is named by a string and a key
// is a non-negative integer. Each group also keeps up to `cap` distinct
// points in the order they arrive, which is all the tests ask of them (does a
// species or dataset reach a number of distinct coordinates). Adding a chunk
// costs the chunk only, whatever has been added before.

#include <Rcpp.h>

#include <algorithm>
#include <cstdint>
#include <cstdio>
#include <string>
#include <unordered_map>
#include <utility>
#include <vector>

using namespace Rcpp;

namespace {

struct GroupCounts {
  int cap = 0;
  std::unordered_map<std::string, int> id;
  std::vector<std::string> names;
  std::vector<std::vector<std::pair<double, double>>> pts;
  std::unordered_map<std::uint64_t, double> n;

  int group(const std::string& name) {
    auto it = id.find(name);
    if (it != id.end()) return it->second;
    const int g = static_cast<int>(names.size());
    id.emplace(name, g);
    names.push_back(name);
    pts.emplace_back();
    return g;
  }
};

inline std::uint64_t pair_key(int g, int key) {
  return (static_cast<std::uint64_t>(static_cast<std::uint32_t>(g)) << 32) |
         static_cast<std::uint32_t>(key);
}

const char kMagic[8] = {'O', 'C', 'C', 'N', 'T', '0', '0', '1'};

}  // namespace

// [[Rcpp::export]]
SEXP cpp_counts_new(int cap) {
  if (cap < 0) stop("cap must be non-negative");
  XPtr<GroupCounts> p(new GroupCounts(), true);
  p->cap = cap;
  return p;
}

// Add one record per element: group[i], key[i], and its point (lon[i],
// lat[i]) when lon and lat are given (length 0 skips the points). Returns TRUE
// where the (group, key) pair is new: not in an earlier call, nor earlier in
// this one.
// [[Rcpp::export]]
LogicalVector cpp_counts_add(SEXP counts, CharacterVector group, IntegerVector key, NumericVector lon,
                             NumericVector lat) {
  XPtr<GroupCounts> p(counts);
  const R_xlen_t m = group.size();
  if (key.size() != m) stop("group and key differ in length");
  const bool points = lon.size() > 0;
  if (points && (lon.size() != m || lat.size() != m)) stop("lon and lat must match group in length");
  LogicalVector fresh(m);
  // Records of one group usually arrive together, so the last name is kept.
  int g = -1;
  SEXP last = R_NilValue;
  for (R_xlen_t i = 0; i < m; ++i) {
    SEXP s = group[i];
    if (s == NA_STRING || key[i] == NA_INTEGER || key[i] < 0) stop("groups and keys must not be missing");
    if (s != last) {
      g = p->group(std::string(CHAR(s)));
      last = s;
    }
    auto ins = p->n.emplace(pair_key(g, key[i]), 0.0);
    ins.first->second += 1.0;
    fresh[i] = ins.second;
    if (points) {
      auto& v = p->pts[g];
      if (static_cast<int>(v.size()) < p->cap) {
        const std::pair<double, double> xy(lon[i], lat[i]);
        bool seen = false;
        for (const auto& q : v) if (q == xy) { seen = true; break; }
        if (!seen) v.push_back(xy);
      }
    }
  }
  return fresh;
}

// The groups in the order they were first seen, with their number of
// distinct points (at most cap).
// [[Rcpp::export]]
List cpp_counts_groups(SEXP counts) {
  XPtr<GroupCounts> p(counts);
  const int ng = static_cast<int>(p->names.size());
  CharacterVector name(ng);
  IntegerVector points(ng);
  for (int g = 0; g < ng; ++g) {
    name[g] = p->names[g];
    points[g] = static_cast<int>(p->pts[g].size());
  }
  return List::create(_["name"] = name, _["points"] = points);
}

// Every (group, key) pair with its count, ordered by group (1-based, in the
// order of cpp_counts_groups()) and then by key.
// [[Rcpp::export]]
List cpp_counts_table(SEXP counts) {
  XPtr<GroupCounts> p(counts);
  std::vector<std::pair<std::uint64_t, double>> rows(p->n.begin(), p->n.end());
  std::sort(rows.begin(), rows.end());
  const R_xlen_t m = static_cast<R_xlen_t>(rows.size());
  IntegerVector group(m), key(m);
  NumericVector count(m);
  for (R_xlen_t i = 0; i < m; ++i) {
    group[i] = static_cast<int>(rows[i].first >> 32) + 1;
    key[i] = static_cast<int>(rows[i].first & 0xffffffffu);
    count[i] = rows[i].second;
  }
  return List::create(_["group"] = group, _["key"] = key, _["count"] = count);
}

// Write the counts to a binary file, and read them back. The file holds the
// cap, the group names in order with their points, and the (pair, count)
// entries.
// [[Rcpp::export]]
void cpp_counts_save(SEXP counts, std::string path) {
  XPtr<GroupCounts> p(counts);
  std::FILE* f = std::fopen(path.c_str(), "wb");
  if (!f) stop("cannot write " + path);
  bool ok = std::fwrite(kMagic, 1, 8, f) == 8;
  auto put = [&](const void* x, size_t size) { ok = ok && std::fwrite(x, 1, size, f) == size; };
  const std::int64_t cap = p->cap, ng = static_cast<std::int64_t>(p->names.size()),
                     ne = static_cast<std::int64_t>(p->n.size());
  put(&cap, 8);
  put(&ng, 8);
  for (std::int64_t g = 0; g < ng; ++g) {
    const std::int64_t len = static_cast<std::int64_t>(p->names[g].size());
    put(&len, 8);
    put(p->names[g].data(), static_cast<size_t>(len));
    const std::int64_t np = static_cast<std::int64_t>(p->pts[g].size());
    put(&np, 8);
    for (const auto& q : p->pts[g]) {
      put(&q.first, 8);
      put(&q.second, 8);
    }
  }
  put(&ne, 8);
  for (const auto& e : p->n) {
    put(&e.first, 8);
    put(&e.second, 8);
  }
  if (std::fclose(f) != 0) ok = false;
  if (!ok) stop("could not write " + path);
}

// [[Rcpp::export]]
SEXP cpp_counts_load(std::string path) {
  std::FILE* f = std::fopen(path.c_str(), "rb");
  if (!f) stop("cannot read " + path);
  XPtr<GroupCounts> p(new GroupCounts(), true);
  char magic[8];
  bool ok = std::fread(magic, 1, 8, f) == 8 && std::equal(magic, magic + 8, kMagic);
  auto get = [&](void* x, size_t size) { ok = ok && std::fread(x, 1, size, f) == size; };
  std::int64_t cap = 0, ng = 0, ne = 0;
  get(&cap, 8);
  get(&ng, 8);
  for (std::int64_t g = 0; ok && g < ng; ++g) {
    std::int64_t len = 0, np = 0;
    get(&len, 8);
    std::string name(ok ? static_cast<size_t>(len) : 0, '\0');
    get(&name[0], static_cast<size_t>(len));
    const int gi = p->group(name);
    get(&np, 8);
    for (std::int64_t k = 0; ok && k < np; ++k) {
      double x = 0, y = 0;
      get(&x, 8);
      get(&y, 8);
      p->pts[gi].emplace_back(x, y);
    }
  }
  get(&ne, 8);
  if (ok) p->n.reserve(static_cast<size_t>(ne));
  for (std::int64_t i = 0; ok && i < ne; ++i) {
    std::uint64_t k = 0;
    double c = 0;
    get(&k, 8);
    get(&c, 8);
    p->n.emplace(k, c);
  }
  std::fclose(f);
  if (!ok) stop("could not read " + path);
  p->cap = static_cast<int>(cap);
  return p;
}

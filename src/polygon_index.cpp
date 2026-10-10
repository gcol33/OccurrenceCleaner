#include "polygon_index.h"

#include <algorithm>
#include <cmath>
#include <utility>

#include "geodesic.h"

namespace occ {

namespace {
// Offsets, as fractions of a cell, that place the reference point away from
// the exact centre so it does not coincide with vertices placed on round
// coordinates. Irrational-looking so that no gazetteer vertex lands on it.
const double kJitterX = 0.0137391128;
const double kJitterY = 0.0092718453;
const double kDeg = 3.14159265358979323846 / 180.0;

inline double orient(double ax, double ay, double bx, double by, double cx, double cy) {
  return (bx - ax) * (cy - ay) - (by - ay) * (cx - ax);
}

inline bool positive(double v) { return v >= 0.0; }

inline std::size_t clamp_index(double v, double origin, double cell, std::size_t n) {
  double f = std::floor((v - origin) / cell);
  if (f < 0) f = 0;
  if (f > static_cast<double>(n - 1)) f = static_cast<double>(n - 1);
  return static_cast<std::size_t>(f);
}
}  // namespace

PolygonIndex::PolygonIndex(const std::vector<double>& x, const std::vector<double>& y,
                           const std::vector<std::size_t>& ring_start,
                           const std::vector<int>& ring_feature, double cell,
                           double xmin, double xmax, double ymin, double ymax)
    : cell_(cell), x0_(xmin), x1_(xmax), y0_(ymin), y1_(ymax), n_features_(0) {
  nx_ = std::max<std::size_t>(1, static_cast<std::size_t>(std::ceil((x1_ - x0_) / cell_)));
  ny_ = std::max<std::size_t>(1, static_cast<std::size_t>(std::ceil((y1_ - y0_) / cell_)));
  for (std::size_t r = 0; r + 1 < ring_start.size(); ++r) {
    const std::size_t lo = ring_start[r], hi = ring_start[r + 1];
    if (hi - lo < 2) continue;
    n_features_ = std::max(n_features_, ring_feature[r] + 1);
    for (std::size_t k = lo; k < hi; ++k) {
      const std::size_t k2 = (k + 1 < hi) ? k + 1 : lo;  // closes the ring
      if (x[k] == x[k2] && y[k] == y[k2]) continue;
      ex0_.push_back(x[k]);
      ey0_.push_back(y[k]);
      ex1_.push_back(x[k2]);
      ey1_.push_back(y[k2]);
      efeat_.push_back(ring_feature[r]);
    }
  }
  build_cells();
  build_parity();
}

void PolygonIndex::centre(std::size_t i, std::size_t j, double& cx, double& cy) const {
  cx = x0_ + (static_cast<double>(i) + 0.5 + kJitterX) * cell_;
  cy = y0_ + (static_cast<double>(j) + 0.5 + kJitterY) * cell_;
}

std::size_t PolygonIndex::col(double lon) const { return clamp_index(lon, x0_, cell_, nx_); }
std::size_t PolygonIndex::row(double lat) const { return clamp_index(lat, y0_, cell_, ny_); }

void PolygonIndex::build_cells() {
  const std::size_t ncell = nx_ * ny_;
  std::vector<std::size_t> count(ncell, 0);
  const std::size_t ne = ex0_.size();
  std::vector<std::size_t> i0(ne), i1(ne), j0(ne), j1(ne);
  for (std::size_t e = 0; e < ne; ++e) {
    i0[e] = col(std::min(ex0_[e], ex1_[e]));
    i1[e] = col(std::max(ex0_[e], ex1_[e]));
    j0[e] = row(std::min(ey0_[e], ey1_[e]));
    j1[e] = row(std::max(ey0_[e], ey1_[e]));
    for (std::size_t j = j0[e]; j <= j1[e]; ++j)
      for (std::size_t i = i0[e]; i <= i1[e]; ++i) ++count[cell_index(i, j)];
  }
  cell_offset_.assign(ncell + 1, 0);
  for (std::size_t c = 0; c < ncell; ++c) cell_offset_[c + 1] = cell_offset_[c] + count[c];
  cell_edges_.assign(cell_offset_[ncell], 0);
  std::vector<std::size_t> fill(cell_offset_.begin(), cell_offset_.end() - 1);
  for (std::size_t e = 0; e < ne; ++e)
    for (std::size_t j = j0[e]; j <= j1[e]; ++j)
      for (std::size_t i = i0[e]; i <= i1[e]; ++i) cell_edges_[fill[cell_index(i, j)]++] = e;
}

void PolygonIndex::build_parity() {
  cell_feature_.assign(nx_ * ny_, -1);
  // Edges bucketed by the grid rows their y-range touches.
  std::vector<std::vector<std::size_t> > rows(ny_);
  for (std::size_t e = 0; e < ex0_.size(); ++e) {
    const std::size_t j0 = row(std::min(ey0_[e], ey1_[e]));
    const std::size_t j1 = row(std::max(ey0_[e], ey1_[e]));
    for (std::size_t j = j0; j <= j1; ++j) rows[j].push_back(e);
  }
  std::vector<std::pair<double, int> > crossings;
  std::vector<int> parity(static_cast<std::size_t>(n_features_), 0);
  for (std::size_t j = 0; j < ny_; ++j) {
    double cx, cy;
    centre(0, j, cx, cy);
    crossings.clear();
    for (std::size_t k = 0; k < rows[j].size(); ++k) {
      const std::size_t e = rows[j][k];
      const double y0 = ey0_[e], y1 = ey1_[e];
      if ((y0 > cy) == (y1 > cy)) continue;
      const double xi = ex0_[e] + (cy - y0) * (ex1_[e] - ex0_[e]) / (y1 - y0);
      crossings.push_back(std::make_pair(xi, efeat_[e]));
    }
    if (crossings.empty()) continue;
    // Walk cells from the right; a ray to +infinity from a cell centre
    // crosses every edge intersection to its right.
    std::sort(crossings.begin(), crossings.end());
    std::fill(parity.begin(), parity.end(), 0);
    std::vector<int> odd;
    std::size_t k = crossings.size();
    for (std::size_t ii = nx_; ii-- > 0;) {
      centre(ii, j, cx, cy);
      while (k > 0 && crossings[k - 1].first > cx) {
        const int f = crossings[k - 1].second;
        parity[f] ^= 1;
        --k;
      }
      int feat = -1;
      for (int f = 0; f < n_features_; ++f)
        if (parity[f]) {
          feat = f;
          break;
        }
      cell_feature_[cell_index(ii, j)] = feat;
    }
  }
}

std::size_t PolygonIndex::n_boundary_cells() const {
  std::size_t n = 0;
  for (std::size_t c = 0; c + 1 < cell_offset_.size(); ++c)
    if (cell_offset_[c + 1] > cell_offset_[c]) ++n;
  return n;
}

int PolygonIndex::locate(double lon, double lat) const {
  if (!(lon >= x0_ && lon <= x1_ && lat >= y0_ && lat <= y1_)) return -1;
  const std::size_t i = col(lon);
  const std::size_t j = row(lat);
  const std::size_t c = cell_index(i, j);
  const std::size_t lo = cell_offset_[c], hi = cell_offset_[c + 1];
  int feat = cell_feature_[c];
  if (lo == hi) return feat;

  double qx, qy;
  centre(i, j, qx, qy);
  // Toggle list: features whose parity flips between the centre and the point.
  int toggled[8];
  int ntog = 0;
  for (std::size_t k = lo; k < hi; ++k) {
    const std::size_t e = cell_edges_[k];
    const double ax = ex0_[e], ay = ey0_[e], bx = ex1_[e], by = ey1_[e];
    const double d4 = orient(ax, ay, bx, by, lon, lat);
    if (d4 == 0.0) {
      // On the edge's line and between the endpoints' projections: on edge.
      const double dot = (lon - ax) * (bx - ax) + (lat - ay) * (by - ay);
      const double len2 = (bx - ax) * (bx - ax) + (by - ay) * (by - ay);
      if (dot >= 0.0 && dot <= len2) return efeat_[e];
    }
    const double d1 = orient(qx, qy, lon, lat, ax, ay);
    const double d2 = orient(qx, qy, lon, lat, bx, by);
    if (positive(d1) == positive(d2)) continue;
    const double d3 = orient(ax, ay, bx, by, qx, qy);
    if (positive(d3) == positive(d4)) continue;
    const int f = efeat_[e];
    int pos = -1;
    for (int t = 0; t < ntog; ++t)
      if (toggled[t] == f) pos = t;
    if (pos >= 0) {
      toggled[pos] = toggled[--ntog];
    } else if (ntog < 8) {
      toggled[ntog++] = f;
    } else {
      // More than eight distinct features in one cell: fall back to a full
      // per-feature count.
      std::vector<int> counts(static_cast<std::size_t>(n_features_), 0);
      for (int t = 0; t < ntog; ++t) counts[toggled[t]] = 1;
      counts[f] = 1;
      for (std::size_t k2 = k + 1; k2 < hi; ++k2) {
        const std::size_t e2 = cell_edges_[k2];
        const double a2x = ex0_[e2], a2y = ey0_[e2], b2x = ex1_[e2], b2y = ey1_[e2];
        const double s4 = orient(a2x, a2y, b2x, b2y, lon, lat);
        if (s4 == 0.0) {
          const double dot = (lon - a2x) * (b2x - a2x) + (lat - a2y) * (b2y - a2y);
          const double len2 = (b2x - a2x) * (b2x - a2x) + (b2y - a2y) * (b2y - a2y);
          if (dot >= 0.0 && dot <= len2) return efeat_[e2];
        }
        const double s1 = orient(qx, qy, lon, lat, a2x, a2y);
        const double s2 = orient(qx, qy, lon, lat, b2x, b2y);
        if (positive(s1) == positive(s2)) continue;
        const double s3 = orient(a2x, a2y, b2x, b2y, qx, qy);
        if (positive(s3) == positive(s4)) continue;
        counts[efeat_[e2]] ^= 1;
      }
      int inside = -1;
      for (int g = 0; g < n_features_; ++g) {
        const bool centre_in = (g == feat);
        if (centre_in != (counts[g] == 1)) {
          inside = g;
          break;
        }
      }
      return inside;
    }
  }
  // Resolve: the centre's feature leaves if toggled; another enters if toggled.
  bool centre_out = false;
  int entered = -1;
  for (int t = 0; t < ntog; ++t) {
    if (toggled[t] == feat)
      centre_out = true;
    else if (entered < 0 || toggled[t] < entered)
      entered = toggled[t];
  }
  if (entered >= 0) return entered;
  if (feat >= 0 && !centre_out) return feat;
  return -1;
}

bool PolygonIndex::near_edge(double lon, double lat, double buffer_m) const {
  if (!(buffer_m > 0) || ex0_.empty()) return false;
  // One degree of latitude is at least 110.5 km; widen the window by 1 %.
  const double dlat = buffer_m / 110500.0 * 1.01;
  const double coslat = std::cos(std::min(89.9, std::fabs(lat) + dlat) * kDeg);
  const double dlon = std::min(360.0, dlat / std::max(coslat, 1e-6));
  if (lon + dlon < x0_ || lon - dlon > x1_ || lat + dlat < y0_ || lat - dlat > y1_) return false;
  const std::size_t i0 = col(lon - dlon), i1 = col(lon + dlon);
  const std::size_t j0 = row(lat - dlat), j1 = row(lat + dlat);
  const double kx = std::cos(lat * kDeg);
  for (std::size_t j = j0; j <= j1; ++j) {
    for (std::size_t i = i0; i <= i1; ++i) {
      const std::size_t c = cell_index(i, j);
      for (std::size_t k = cell_offset_[c]; k < cell_offset_[c + 1]; ++k) {
        const std::size_t e = cell_edges_[k];
        const double ax = (ex0_[e] - lon) * kx, ay = ey0_[e] - lat;
        const double bx = (ex1_[e] - lon) * kx, by = ey1_[e] - lat;
        const double vx = bx - ax, vy = by - ay;
        const double len2 = vx * vx + vy * vy;
        double t = len2 > 0 ? -(ax * vx + ay * vy) / len2 : 0.0;
        t = std::max(0.0, std::min(1.0, t));
        const double px = ex0_[e] + t * (ex1_[e] - ex0_[e]);
        const double py = ey0_[e] + t * (ey1_[e] - ey0_[e]);
        const double d = geodesic_m(lon, lat, px, py);
        if (d <= buffer_m) return true;
      }
    }
  }
  return false;
}

}  // namespace occ

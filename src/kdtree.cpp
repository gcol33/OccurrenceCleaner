#include "kdtree.h"

#include <algorithm>
#include <cmath>
#include <limits>

#include "geodesic.h"

namespace occ {

namespace {
const std::size_t kLeafSize = 8;
const std::size_t kNone = static_cast<std::size_t>(-1);

inline double dist2(const double* a, const double* b) {
  const double dx = a[0] - b[0], dy = a[1] - b[1], dz = a[2] - b[2];
  return dx * dx + dy * dy + dz * dz;
}
}  // namespace

KdTree3::KdTree3(const std::vector<double>& lon, const std::vector<double>& lat)
    : lon_(lon), lat_(lat), xyz_(3 * lon.size()), idx_(lon.size()), root_(kNone) {
  for (std::size_t i = 0; i < lon.size(); ++i) {
    to_unit(lon[i], lat[i], &xyz_[3 * i]);
    idx_[i] = i;
  }
  nodes_.reserve(2 * (lon.size() / kLeafSize + 1));
  if (!lon.empty()) root_ = build(0, lon.size());
}

std::size_t KdTree3::build(std::size_t lo, std::size_t hi) {
  Node n;
  n.lo = lo;
  n.hi = hi;
  n.left = n.right = kNone;
  if (hi - lo <= kLeafSize) {
    n.dim = -1;
    n.split = 0.0;
    nodes_.push_back(n);
    return nodes_.size() - 1;
  }
  double mn[3], mx[3];
  for (int d = 0; d < 3; ++d) {
    mn[d] = std::numeric_limits<double>::infinity();
    mx[d] = -mn[d];
  }
  for (std::size_t k = lo; k < hi; ++k) {
    const double* p = &xyz_[3 * idx_[k]];
    for (int d = 0; d < 3; ++d) {
      mn[d] = std::min(mn[d], p[d]);
      mx[d] = std::max(mx[d], p[d]);
    }
  }
  int dim = 0;
  for (int d = 1; d < 3; ++d)
    if (mx[d] - mn[d] > mx[dim] - mn[dim]) dim = d;
  const std::size_t mid = lo + (hi - lo) / 2;
  const std::vector<double>& xyz = xyz_;
  std::nth_element(idx_.begin() + lo, idx_.begin() + mid, idx_.begin() + hi,
                   [&xyz, dim](std::size_t a, std::size_t b) {
                     return xyz[3 * a + dim] < xyz[3 * b + dim];
                   });
  n.dim = dim;
  n.split = xyz_[3 * idx_[mid] + dim];
  nodes_.push_back(n);
  const std::size_t self = nodes_.size() - 1;
  const std::size_t left = build(lo, mid);
  const std::size_t right = build(mid, hi);
  nodes_[self].left = left;
  nodes_[self].right = right;
  return self;
}

void KdTree3::within(double lon, double lat, double chord,
                     std::vector<std::size_t>& out) const {
  out.clear();
  if (root_ == kNone) return;
  double q[3];
  to_unit(lon, lat, q);
  within_rec(root_, q, chord * chord, out);
}

void KdTree3::within_rec(std::size_t node, const double q[3], double r2,
                         std::vector<std::size_t>& out) const {
  const Node& n = nodes_[node];
  if (n.dim < 0) {
    for (std::size_t k = n.lo; k < n.hi; ++k)
      if (dist2(q, &xyz_[3 * idx_[k]]) <= r2) out.push_back(idx_[k]);
    return;
  }
  const double diff = q[n.dim] - n.split;
  const std::size_t near = diff < 0 ? n.left : n.right;
  const std::size_t far = diff < 0 ? n.right : n.left;
  within_rec(near, q, r2, out);
  if (diff * diff <= r2) within_rec(far, q, r2, out);
}

std::size_t KdTree3::nearest(double lon, double lat, double& chord2) const {
  chord2 = std::numeric_limits<double>::infinity();
  if (root_ == kNone) return size();
  double q[3];
  to_unit(lon, lat, q);
  std::size_t best = size();
  nearest_rec(root_, q, best, chord2);
  return best;
}

void KdTree3::nearest_rec(std::size_t node, const double q[3], std::size_t& best,
                          double& best2) const {
  const Node& n = nodes_[node];
  if (n.dim < 0) {
    for (std::size_t k = n.lo; k < n.hi; ++k) {
      const double d2 = dist2(q, &xyz_[3 * idx_[k]]);
      if (d2 < best2) {
        best2 = d2;
        best = idx_[k];
      }
    }
    return;
  }
  const double diff = q[n.dim] - n.split;
  const std::size_t near = diff < 0 ? n.left : n.right;
  const std::size_t far = diff < 0 ? n.right : n.left;
  nearest_rec(near, q, best, best2);
  if (diff * diff < best2) nearest_rec(far, q, best, best2);
}

}  // namespace occ

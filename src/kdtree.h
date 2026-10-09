#ifndef OCCURRENCECLEANER_KDTREE_H
#define OCCURRENCECLEANER_KDTREE_H

#include <vector>

namespace occ {

// Static kd-tree over points on the unit sphere, stored as 3-D unit vectors.
// Queries are by chord length, which is monotone in great-circle distance.
class KdTree3 {
 public:
  KdTree3(const std::vector<double>& lon, const std::vector<double>& lat);

  std::size_t size() const { return lon_.size(); }
  double lon(std::size_t i) const { return lon_[i]; }
  double lat(std::size_t i) const { return lat_[i]; }

  // Indices of every stored point whose chord distance to (lon, lat) is at
  // most `chord`, in no particular order.
  void within(double lon, double lat, double chord, std::vector<std::size_t>& out) const;

  // Index of the stored point nearest to (lon, lat) by chord, or size() if
  // the tree is empty. `chord2` receives the squared chord distance.
  std::size_t nearest(double lon, double lat, double& chord2) const;

 private:
  struct Node {
    int dim;         // split dimension, or -1 for a leaf
    double split;    // split coordinate
    std::size_t lo;  // first index into idx_ (leaves)
    std::size_t hi;  // one past the last index into idx_ (leaves)
    std::size_t left, right;
  };

  std::size_t build(std::size_t lo, std::size_t hi);
  void within_rec(std::size_t node, const double q[3], double r2,
                  std::vector<std::size_t>& out) const;
  void nearest_rec(std::size_t node, const double q[3], std::size_t& best,
                   double& best2) const;

  std::vector<double> lon_, lat_;
  std::vector<double> xyz_;  // 3 doubles per point
  std::vector<std::size_t> idx_;
  std::vector<Node> nodes_;
  std::size_t root_;
};

}  // namespace occ

#endif

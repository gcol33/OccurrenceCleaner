#ifndef OCCURRENCECLEANER_POLYGON_INDEX_H
#define OCCURRENCECLEANER_POLYGON_INDEX_H

#include <cstddef>
#include <vector>

namespace occ {

// Point-in-polygon index over a set of rings in planar longitude/latitude,
// each ring belonging to a feature. A regular grid stores, per cell, the
// feature containing the cell centre and the edges that pass through the
// cell. A point in a cell without edges takes the cell's feature; a point in
// a cell with edges is resolved exactly by counting the edges crossed on the
// straight segment from the cell centre to the point. Even-odd parity, so
// holes are rings of the same feature.
class PolygonIndex {
 public:
  // x, y: ring vertices, concatenated. ring_start: offset of each ring's
  // first vertex plus a final entry equal to x.size(). ring_feature: feature
  // id (>= 0) of each ring. cell: grid cell size in degrees.
  PolygonIndex(const std::vector<double>& x, const std::vector<double>& y,
               const std::vector<std::size_t>& ring_start,
               const std::vector<int>& ring_feature, double cell);

  // Feature containing (lon, lat), or -1 if none. A point on an edge belongs
  // to that edge's feature.
  int locate(double lon, double lat) const;

  double cell() const { return cell_; }
  std::size_t n_edges() const { return ex0_.size(); }
  std::size_t n_boundary_cells() const;

 private:
  std::size_t cell_index(std::size_t i, std::size_t j) const { return j * nx_ + i; }
  void centre(std::size_t i, std::size_t j, double& cx, double& cy) const;
  void build_cells();
  void build_parity();

  double cell_;
  std::size_t nx_, ny_;
  int n_features_;
  // Edges.
  std::vector<double> ex0_, ey0_, ex1_, ey1_;
  std::vector<int> efeat_;
  // Per cell: feature at the centre (-1 none) and CSR edge lists.
  std::vector<int> cell_feature_;
  std::vector<std::size_t> cell_offset_;
  std::vector<std::size_t> cell_edges_;
};

}  // namespace occ

#endif

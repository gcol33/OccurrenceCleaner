#include <Rcpp.h>

#include <cmath>
#include <vector>

#include "geodesic.h"
#include "kdtree.h"
#include "polygon_index.h"
#include "threads.h"

using namespace Rcpp;

// Build a nearest-neighbour index over reference points (degrees).
// [[Rcpp::export]]
SEXP cpp_point_index(NumericVector lon, NumericVector lat) {
  if (lon.size() != lat.size()) stop("lon and lat differ in length");
  std::vector<double> lo(lon.begin(), lon.end()), la(lat.begin(), lat.end());
  XPtr<occ::KdTree3> p(new occ::KdTree3(lo, la), true);
  return p;
}

// TRUE where some reference point lies within buffer_m (WGS84 geodesic
// metres) of the record. Records with non-finite coordinates are FALSE.
// [[Rcpp::export]]
LogicalVector cpp_point_within(SEXP index, NumericVector lon, NumericVector lat,
                               double buffer_m, int n_threads = 1) {
  XPtr<occ::KdTree3> tree(index);
  const occ::KdTree3* t = tree.get();
  const R_xlen_t n = lon.size();
  if (lat.size() != n) stop("lon and lat differ in length");
  LogicalVector out(n, FALSE);
  int* o = LOGICAL(out);
  const double* px = REAL(lon);
  const double* py = REAL(lat);
  const double chord = occ::chord_bound(buffer_m);
  const int nt = occ::threads(n_threads);
  OCC_OMP(omp parallel num_threads(nt))
  {
    std::vector<std::size_t> cand;
    OCC_OMP(omp for schedule(dynamic, 1024))
    for (R_xlen_t i = 0; i < n; ++i) {
      const double x = px[i], y = py[i];
      if (!std::isfinite(x) || !std::isfinite(y)) continue;
      t->within(x, y, chord, cand);
      for (std::size_t k = 0; k < cand.size(); ++k) {
        const double d = occ::geodesic_m(x, y, t->lon(cand[k]), t->lat(cand[k]));
        if (d <= buffer_m) {
          o[i] = TRUE;
          break;
        }
      }
    }
  }
  return out;
}

// Nearest reference point (1-based index) and the geodesic distance to it in
// metres, nearest measured by chord on the sphere.
// [[Rcpp::export]]
List cpp_point_nearest(SEXP index, NumericVector lon, NumericVector lat) {
  XPtr<occ::KdTree3> tree(index);
  const R_xlen_t n = lon.size();
  if (lat.size() != n) stop("lon and lat differ in length");
  IntegerVector idx(n, NA_INTEGER);
  NumericVector dist(n, NA_REAL);
  for (R_xlen_t i = 0; i < n; ++i) {
    const double x = lon[i], y = lat[i];
    if (!std::isfinite(x) || !std::isfinite(y)) continue;
    double c2;
    const std::size_t j = tree->nearest(x, y, c2);
    if (j >= tree->size()) continue;
    idx[i] = static_cast<int>(j) + 1;
    dist[i] = occ::geodesic_m(x, y, tree->lon(j), tree->lat(j));
  }
  return List::create(_["index"] = idx, _["distance_m"] = dist);
}

// WGS84 geodesic distance in metres between paired points.
// [[Rcpp::export]]
NumericVector cpp_geodesic_m(NumericVector lon1, NumericVector lat1, NumericVector lon2,
                             NumericVector lat2) {
  const R_xlen_t n = lon1.size();
  if (lat1.size() != n || lon2.size() != n || lat2.size() != n)
    stop("coordinate vectors differ in length");
  NumericVector out(n, NA_REAL);
  for (R_xlen_t i = 0; i < n; ++i) {
    if (!std::isfinite(lon1[i]) || !std::isfinite(lat1[i]) || !std::isfinite(lon2[i]) ||
        !std::isfinite(lat2[i]))
      continue;
    out[i] = occ::geodesic_m(lon1[i], lat1[i], lon2[i], lat2[i]);
  }
  return out;
}

// Build a point-in-polygon index. ring_start holds 0-based offsets of each
// ring plus a final entry equal to length(x); ring_feature is 1-based.
// [[Rcpp::export]]
SEXP cpp_polygon_index(NumericVector x, NumericVector y, IntegerVector ring_start,
                       IntegerVector ring_feature, double cell,
                       NumericVector extent = NumericVector::create(-180, 180, -90, 90)) {
  if (extent.size() != 4) stop("extent must be c(xmin, xmax, ymin, ymax)");
  if (x.size() != y.size()) stop("x and y differ in length");
  if (ring_start.size() != ring_feature.size() + 1)
    stop("ring_start must have one more entry than ring_feature");
  if (!(cell > 0)) stop("cell must be positive");
  std::vector<double> vx(x.begin(), x.end()), vy(y.begin(), y.end());
  std::vector<std::size_t> rs(ring_start.size());
  for (R_xlen_t i = 0; i < ring_start.size(); ++i) {
    if (ring_start[i] < 0 || ring_start[i] > x.size()) stop("ring_start out of range");
    rs[i] = static_cast<std::size_t>(ring_start[i]);
  }
  std::vector<int> rf(ring_feature.size());
  for (R_xlen_t i = 0; i < ring_feature.size(); ++i) {
    if (ring_feature[i] < 1) stop("ring_feature must be >= 1");
    rf[i] = ring_feature[i] - 1;
  }
  XPtr<occ::PolygonIndex> p(
      new occ::PolygonIndex(vx, vy, rs, rf, cell, extent[0], extent[1], extent[2], extent[3]), true);
  return p;
}

// Feature (1-based) containing each point, 0 where none; NA coordinates give 0.
// [[Rcpp::export]]
IntegerVector cpp_polygon_locate(SEXP index, NumericVector lon, NumericVector lat, int n_threads = 1) {
  XPtr<occ::PolygonIndex> poly(index);
  const occ::PolygonIndex* pi = poly.get();
  const R_xlen_t n = lon.size();
  if (lat.size() != n) stop("lon and lat differ in length");
  IntegerVector out(n, 0);
  int* o = INTEGER(out);
  const double* px = REAL(lon);
  const double* py = REAL(lat);
  const int nt = occ::threads(n_threads);
  OCC_OMP(omp parallel for num_threads(nt) schedule(dynamic, 4096))
  for (R_xlen_t i = 0; i < n; ++i) {
    const double x = px[i], y = py[i];
    if (!std::isfinite(x) || !std::isfinite(y)) continue;
    o[i] = pi->locate(x, y) + 1;
  }
  return out;
}

// TRUE where some polygon edge lies within buffer_m metres of the point.
// [[Rcpp::export]]
LogicalVector cpp_polygon_near(SEXP index, NumericVector lon, NumericVector lat, double buffer_m,
                               int n_threads = 1) {
  XPtr<occ::PolygonIndex> poly(index);
  const occ::PolygonIndex* pi = poly.get();
  const R_xlen_t n = lon.size();
  if (lat.size() != n) stop("lon and lat differ in length");
  LogicalVector out(n, FALSE);
  int* o = LOGICAL(out);
  const double* px = REAL(lon);
  const double* py = REAL(lat);
  const int nt = occ::threads(n_threads);
  OCC_OMP(omp parallel for num_threads(nt) schedule(dynamic, 256))
  for (R_xlen_t i = 0; i < n; ++i) {
    const double x = px[i], y = py[i];
    if (!std::isfinite(x) || !std::isfinite(y)) continue;
    o[i] = pi->near_edge(x, y, buffer_m);
  }
  return out;
}

// Threads the OpenMP runtime hands out; 1 without OpenMP.
// [[Rcpp::export]]
int cpp_max_threads() { return occ::threads(1 << 20); }

// Diagnostics for a polygon index.
// [[Rcpp::export]]
List cpp_polygon_info(SEXP index) {
  XPtr<occ::PolygonIndex> poly(index);
  return List::create(_["cell"] = poly->cell(),
                      _["n_edges"] = static_cast<double>(poly->n_edges()),
                      _["n_boundary_cells"] = static_cast<double>(poly->n_boundary_cells()));
}

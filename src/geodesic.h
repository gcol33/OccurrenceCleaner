#ifndef OCCURRENCECLEANER_GEODESIC_H
#define OCCURRENCECLEANER_GEODESIC_H

namespace occ {

// Longitude and latitude in degrees to a unit vector on the sphere.
void to_unit(double lon_deg, double lat_deg, double out[3]);

// Chord length on the unit sphere that is guaranteed to contain every pair
// of points whose WGS84 geodesic distance is at most dist_m. Used to bound
// candidate searches before the exact geodesic test.
double chord_bound(double dist_m);

// WGS84 geodesic distance in metres (Vincenty inverse formula). Returns NaN
// if the iteration does not converge, which only happens for nearly
// antipodal points.
double geodesic_m(double lon1, double lat1, double lon2, double lat2);

}  // namespace occ

#endif

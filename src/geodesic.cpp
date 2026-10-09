#include "geodesic.h"

#include <cmath>
#include <limits>

namespace occ {

namespace {
const double kPi = 3.14159265358979323846;
const double kDegToRad = kPi / 180.0;
// WGS84.
const double kA = 6378137.0;
const double kF = 1.0 / 298.257223563;
const double kB = (1.0 - kF) * kA;
// Smaller than the smallest radius of curvature of the WGS84 ellipsoid
// (6,335,439 m, meridional at the equator), so dist_m / kRadiusBound is an
// upper bound on the angular separation of two points dist_m apart.
const double kRadiusBound = 6300000.0;
}  // namespace

void to_unit(double lon_deg, double lat_deg, double out[3]) {
  const double lon = lon_deg * kDegToRad;
  const double lat = lat_deg * kDegToRad;
  const double cl = std::cos(lat);
  out[0] = cl * std::cos(lon);
  out[1] = cl * std::sin(lon);
  out[2] = std::sin(lat);
}

double chord_bound(double dist_m) {
  const double theta = dist_m / kRadiusBound;
  if (theta >= kPi) return 2.0;
  return 2.0 * std::sin(theta / 2.0);
}

double geodesic_m(double lon1, double lat1, double lon2, double lat2) {
  const double L = (lon2 - lon1) * kDegToRad;
  const double U1 = std::atan((1.0 - kF) * std::tan(lat1 * kDegToRad));
  const double U2 = std::atan((1.0 - kF) * std::tan(lat2 * kDegToRad));
  const double sinU1 = std::sin(U1), cosU1 = std::cos(U1);
  const double sinU2 = std::sin(U2), cosU2 = std::cos(U2);

  double lambda = L;
  double sinSigma = 0, cosSigma = 0, sigma = 0, sinAlpha = 0;
  double cosSqAlpha = 0, cos2SigmaM = 0;
  for (int iter = 0; iter < 200; ++iter) {
    const double sinLambda = std::sin(lambda), cosLambda = std::cos(lambda);
    const double t1 = cosU2 * sinLambda;
    const double t2 = cosU1 * sinU2 - sinU1 * cosU2 * cosLambda;
    sinSigma = std::sqrt(t1 * t1 + t2 * t2);
    if (sinSigma == 0.0) return 0.0;
    cosSigma = sinU1 * sinU2 + cosU1 * cosU2 * cosLambda;
    sigma = std::atan2(sinSigma, cosSigma);
    sinAlpha = cosU1 * cosU2 * sinLambda / sinSigma;
    cosSqAlpha = 1.0 - sinAlpha * sinAlpha;
    cos2SigmaM = cosSqAlpha != 0.0
                     ? cosSigma - 2.0 * sinU1 * sinU2 / cosSqAlpha
                     : 0.0;
    const double C = kF / 16.0 * cosSqAlpha * (4.0 + kF * (4.0 - 3.0 * cosSqAlpha));
    const double lambdaPrev = lambda;
    lambda = L + (1.0 - C) * kF * sinAlpha *
                     (sigma + C * sinSigma *
                                  (cos2SigmaM + C * cosSigma *
                                                    (-1.0 + 2.0 * cos2SigmaM * cos2SigmaM)));
    if (std::fabs(lambda - lambdaPrev) <= 1e-12) {
      const double uSq = cosSqAlpha * (kA * kA - kB * kB) / (kB * kB);
      const double A = 1.0 + uSq / 16384.0 *
                                 (4096.0 + uSq * (-768.0 + uSq * (320.0 - 175.0 * uSq)));
      const double B = uSq / 1024.0 * (256.0 + uSq * (-128.0 + uSq * (74.0 - 47.0 * uSq)));
      const double deltaSigma =
          B * sinSigma *
          (cos2SigmaM + B / 4.0 *
                            (cosSigma * (-1.0 + 2.0 * cos2SigmaM * cos2SigmaM) -
                             B / 6.0 * cos2SigmaM * (-3.0 + 4.0 * sinSigma * sinSigma) *
                                 (-3.0 + 4.0 * cos2SigmaM * cos2SigmaM)));
      return kB * A * (sigma - deltaSigma);
    }
  }
  return std::numeric_limits<double>::quiet_NaN();
}

}  // namespace occ

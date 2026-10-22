#ifndef OCCURRENCECLEANER_THREADS_H
#define OCCURRENCECLEANER_THREADS_H

// OpenMP where the compiler provides it; without it the pragmas vanish and
// every loop runs on one thread.
#ifdef _OPENMP
#include <omp.h>
#define OCC_OMP(x) _Pragma(#x)
#else
#define OCC_OMP(x)
#endif

namespace occ {

// Threads a loop may use: the request, at least 1, at most what the OpenMP
// runtime hands out; 1 without OpenMP.
inline int threads(int requested) {
#ifdef _OPENMP
  const int cap = omp_get_max_threads();
  if (requested < 1) return 1;
  return requested < cap ? requested : cap;
#else
  (void)requested;
  return 1;
#endif
}

// The number of the calling thread within its parallel region; 0 outside one
// and without OpenMP.
inline int thread_id() {
#ifdef _OPENMP
  return omp_get_thread_num();
#else
  return 0;
#endif
}

}  // namespace occ

#endif

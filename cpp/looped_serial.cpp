#include <TMB.hpp>

using namespace Eigen;

template<class Type>
Type objective_function<Type>::operator() ()
{
  DATA_INTEGER(N);
  DATA_MATRIX(X);
  DATA_VECTOR(y);
  DATA_INTEGER(cores);

  PARAMETER_VECTOR(B);
  PARAMETER(log_sigma);
  // omp_set_num_threads(cfores);

  Type sigma = exp(log_sigma);
  Type nll = 0;
  for(size_t i = 0; i < N; i++) {
    nll -= dnorm(y[i], (X.row(i).transpose().array() * B).sum(), sigma, true);
  }
  return nll;
}

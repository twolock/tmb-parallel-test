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
  omp_set_num_threads(cores);

  Type sigma = exp(log_sigma);
  parallel_accumulator<Type> nll(this);
  nll -= sum(dnorm(y, X*B, sigma, true));
  return nll;
}

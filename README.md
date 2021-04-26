# Testing parallel TMB templates

 A small repository to test compare serial and parallel templates in TMB. The R script `fit_models.R` fits a statistical model using four mathematically identical TMB templates. The model is typical Bayesian linear regression.
By default, $X$ has 100 columns and a number of rows ranging from 1,000 to 20,000.

The four templates (in `cpp/`) vary in how the negative log-posterior density is calculated and in parallelism. In the two parallel templates, `nll` is a `parallel_accumulator`:

```c++
parallel_accumulator<Type> nll(this);
```

whereas in the serial templates, it is declared in the conventional way:

```c++
Type nll = 0;
```

In the "vectorized" templates, `nll` is calculated all at once:

```c++
nll = -sum(dnorm(y, X*B, sigma, true));
```

and in the looped templates, it is incremented in a loop over observations. The fastest template should be the "looped parallel" template.
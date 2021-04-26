library(TMB)
library(data.table)
library(ggplot2)

test.eval.time <- F

## No. of covariates
k <- 100

## Need each of these .cpp
all.templates <- c(
   'vectorized_serial',
   'vectorized_parallel',
   'looped_serial',
   'looped_parallel'
)
## Compile and load all at once
for(template in all.templates) {
   try(dyn.unload(dynlib(template)), silent = T)
   compile(sprintf('cpp/%s.cpp', template), flags = '-w')
   dyn.load(dynlib(sprintf('cpp/%s', template)))
}

all.dt <- data.table()

N_seq <- seq(1000, 20000, 1000)
## Iterate over sample sizes
for (N in N_seq) {
   ## Generate covariates plus intercept
   X <- cbind(1, matrix(rnorm(N * k), ncol = k))
   ## Simulate coefficients
   B <- rnorm(k+1)
   
   ## Find means
   mu <- X %*% B
   ## Fix SD
   sigma <- 1
   ## Sample y
   y <- rnorm(N, mu, sigma)
   
   ## Input to TMB
   in.dat <- list(
      N = N,
      X = X,
      y = y,
      cores = 8
   )
   in.par <- list(
      B = rep(0, ncol(in.dat$X)),
      log_sigma = 0
   )
   
   for (template in all.templates) {
      print(sprintf('%i %s', N, template))
      
      ## Make AD function object
      start.time <- Sys.time()
      obj <- MakeADFun(data = in.dat, parameters = in.par, DLL = template)
      obj$method <- 'L-BFGS-B'
      end.time <- Sys.time()
      make.time <- difftime(end.time, start.time, units = 'sec')
      
      ## Optimize
      start.time <- Sys.time()
      opt <- do.call(optim, obj)
      end.time <- Sys.time()
      opt.time <- difftime(end.time, start.time, units = 'sec')
      
      ## Calculate uncertainty
      start.time <- Sys.time()
      sd.obj <- sdreport(obj)
      end.time <- Sys.time()
      sd.time <- difftime(end.time, start.time, units = 'sec')
      
      fn.time <- NA
      gr.time <- NA
      if (test.eval.time) {
         fn.time <- system.time(for (i in 1:100) {
            obj$fn()
         })
         gr.time <- system.time(for (i in 1:100) {
            obj$gr()
         })
      }
      
      ## Add to total
      all.dt <- rbind(all.dt, data.table(template, N = N,
                                         make.time, opt.time,
                                         sd.time, fn.time = fn.time['elapsed'],
                                         gr.time = gr.time['elapsed']))
   }
}

## Find total time
all.dt[, total.time := make.time + opt.time + sd.time]

all.dt[, c('design', 'execution') := tstrsplit(template, '_')]
all.dt[, Model := paste(design, execution)]

ggplot(all.dt, aes(x=N, y=total.time, color=Model)) + 
   geom_point() + geom_line() +
   theme_bw() +
   coord_cartesian(expand = 0) +
   scale_x_continuous(labels = scales::comma)

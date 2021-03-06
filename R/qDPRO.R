qDPRO <-
function(dat, q, B, datatype=c("abundance", "incidence")){ # dat=(n, y1, y2, ...,ys); q can be a vector
  dat <- as.numeric(dat)
  # function 
  qDpro <- function(y, q, n, datatype){
    if (datatype=="abundance"){
      f <- function(q, y){length(y[which(y == q)])}  
      f1 <- f(1, y); f2 <- f(2, y)
      delta <- function(y, k, t){
        y <- y[which(y != 0)]
        y <- subset(y, y <= t - k)
        sum(y/t*choose(t - y, k)/choose(t - 1, k))
      }
      # p_1: average probability of the species which appear only once.
      if (f2 > 0){      
        p_1 <- 2*f2/((n - 1)*f1 + 2*f2)
      } else if (f2 == 0 & f1 > 0){
        p_1 <- 2/((n - 1)*(f1 - 1) + 2)
      } else {
        p_1 <- 1
      }
      
      y <- y[which(y != 0)]
      if (q == 1){
        k <- 1 : (n - 1)
        #temp1 <- sum(sapply(k, function(k)1/k*delta(y, k, n)))
        temp1 <- sum(y/n*(digamma(n)-digamma(y)))
        if (p_1 != 1){
          temp2 <- f1/n*(1 - p_1)^(-n + 1)*(-log(p_1) - sum((1 - p_1)^k/k))
        } else {
          temp2 <- 0
        }
        D_p <- exp(temp1 + temp2)
        #      } else if (q == 2){
        #        D_p <- 1/sum(y*(y - 1)/n/(n - 1))/(U/n)^2 # take mean first, transform later.
      } else {
        k <- c(0:(n - 1))
        r <- c(0:(n - 1))
        temp1 <- sum(choose(q - 1, k)*(-1)^k*sapply(k, function(k)delta(y, k, n)))
        if (p_1 != 1){
          temp2 <- f1/n*(1 - p_1)^(-n + 1)*(p_1^(q - 1) - sum(choose(q - 1, r)*(p_1 - 1)^r))
        } else {
          temp2 <- 0
        }
        D_p <- (temp1 + temp2)^(1/(1 - q))
      }
    }else{
      U <- sum(y)
      Q <- function(q, y){length(y[which(y == q)])}  
      delta <- function(y, k, t){
        y <- y[which(y != 0)]
        y <- subset(y, y <= t - k)
        sum(y/t*choose(t - y, k)/choose(t - 1, k))
      }
      
      # p_1: average probability of the species which appear only once.
      if (Q(2, y) > 0){      
        p_1 <- 2*Q(2, y)/((n - 1)*Q(1, y) + 2*Q(2, y))
      } else if (Q(2, y) == 0 & Q(1, y) > 0){
        p_1 <- 2/((n - 1)*(Q(1, y) - 1) + 2)
      } else {
        p_1 <- 1
      }
      
      if (q == 1){
        k <- 1 : (n - 1)
        temp1 <- sum(sapply(k, function(k)1/k*delta(y, k, n)))
        if (p_1 != 1){
          temp2 <- Q(1, y)/n*(1 - p_1)^(-n + 1)*(-log(p_1) - sum((1 - p_1)^k/k))
        } else {
          temp2 <- 0
        }
        D_p <- exp(n/U*(temp1 + temp2) + log(U/n))
        #      } else if (q == 2){
        #        D_p <- 1/sum(y*(y - 1)/n/(n - 1))/(U/n)^2 # take mean first, transform later.
      } else {
        k <- c(0:(n - 1))
        r <- c(0:(n - 1))
        temp1 <- sum(choose(q - 1, k)*(-1)^k*sapply(k, function(k)delta(y, k, n)))
        if (p_1 != 1){
          temp2 <- Q(1, y)/n*(1 - p_1)^(-n + 1)*(p_1^(q - 1) - sum(choose(q - 1, r)*(p_1 - 1)^r))
        } else {
          temp2 <- 0
        }
        D_p <- ((n/U)^q*(temp1 + temp2))^(1/(1 - q))
      }
    }
    return(D_p)
  } # Estimation
  ibootstrap <- function(y, fun, B, q, n, datatype){      # improved bootstrap
   if (datatype == "abundance"){
     f <- function(r, data){sum(data == r)}
     y <- y[which(y != 0)]
     f1 <- f(1, y); f2 <- f(2, y)
     
     if (f2 > 0){
       alfa1 <- 2*f2/((n - 1)*f1 + 2*f2)
     } else if (f2 == 0 & f1 != 0){
       alfa1 <- 2/((n - 1)*(f1 - 1) + 1)
     } else {
       alfa1 <- 1  
     }
     Chat <- 1 - f1/n*(1 - alfa1)
     
     W <- (1 - Chat)/sum(y/n*(1 - y/n)^n)
     pi.hat <- y/n*(1 - W*(1 - y/n)^n)
     
     if (f2 > 0){
       f0_hat <- (n - 1)/n*f1^2/(2*f2)
     }else{
       f0_hat <- (n - 1)/n*f1*(f1 - 1)/(2*(f2 + 1))
     }
     f0_hat <- ceiling(f0_hat)
     pi.hat.r <- rep((1 - Chat)/f0_hat, f0_hat)         
     pi.star <- c(pi.hat, pi.hat.r)     
     
     set.seed(456)
     Y <- matrix(rmultinom(B, n, pi.star), ncol=B)
     
     b <- 1:B
     sd(sapply(b, function(b){fun(Y[, b], q, n, datatype)}))
     
   }else{
     Q <- function(r, data){sum(data == r)} 
     y <- y[which(y != 0)]
     q1 <- Q(1, y); q2 <- Q(2, y)
     U <- sum(y)
     
     if (q2 > 0){
       alfa1 <- 2*q2/((n - 1)*q1 + 2*q2)
     } else if (q2 == 0 & q1 != 0){
       alfa1 <- 2/((n - 1)*(q1 - 1) + 1)
     } else {
       alfa1 <- 1  
     }
     Chat <- 1 - q1/U*(1 - alfa1)
     
     W <- U/n*(1 - Chat)/sum(y/n*(1 - y/n)^n)
     pi.hat <- y/n*(1 - W*(1 - y/n)^n)
     
     if (q2 > 0){
       Q0_hat <- (n - 1)/n*q1^2/(2*q2)
     }else{
       Q0_hat <- (n - 1)/n*q1*(q1 - 1)/(2*(q2 + 1))
     }
     Q0_hat <- ceiling(Q0_hat)
     pi.hat.r <- rep(U/n*(1 - Chat)/Q0_hat, Q0_hat)         
     pi.star <- c(pi.hat, pi.hat.r)     
     
     set.seed(456)
     Y <- matrix(rbinom(length(pi.star) * B, n, pi.star), ncol = B)
     
     b <- 1:B
     sd(sapply(b, function(b){fun(Y[, b], q, n, datatype)}))
     
   }
  }
  if (datatype == "abundance"){
    y <- dat; n <- sum(dat)
  }else{
    y <- dat[-1]; n <- dat[1]
  }
  # estimate
  i <- 1:length(q)
  est.value <- sapply(i, function(i) qDpro(y, q[i], n, datatype))
  est.sd <- sapply(i, function(i) ibootstrap(y, qDpro, B, q[i], n, datatype))
  return(matrix(c(est.value, est.sd), nrow=2, byrow=T))
}

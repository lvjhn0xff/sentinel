import project/solvers/adam as adam 

proc objective(solution: seq[float]) : float = 
    let x = solution[0]
    return x * x

proc derivative(solution: seq[float]) : seq[float] = 
    let x = solution[0]
    return @[2 * x]

let solver = adam.createAdamSolver(
  objective = objective,
  bounds = @[(lo: -1.0, hi: 1.0)],
  derivative = derivative,
  n_iter = 500,
  alpha = 0.01, 
  beta1 = 0.9, 
  beta2 = 0.99,
  eps = 1e-12,
  verbose = 1
)

for i in 1 .. 100:
    solver.iterate()
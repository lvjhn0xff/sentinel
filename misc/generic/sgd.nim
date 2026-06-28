import project/solvers/sgd as sgd 
import project.utils.vector

proc objective(solution: Vector[float]) : float = 
    let x = solution[0]
    return x * x

proc derivative(solution: Vector[float]) : Vector[float] = 
    let x = solution[0]
    return createVector(@[2 * x])

let solver = sgd.createSGDSolver(
  objective = objective,
  bounds = createVector(@[(lo: -1.0, hi: 1.0)]),
  derivative = derivative,
  n_iter = 500,
  step_size = 0.1,
  verbose = 1
)

for i in 1 .. 100:
    solver.iterate()
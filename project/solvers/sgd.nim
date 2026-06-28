{.experimental: "codeReordering".}

import std/random as random
import std/times
import std/options
import utils.nim.vector

type    
    SGDSolver* = ref object 
        # Parameters #
        objective*          : proc (solution: Vector[float]) : float
        bounds*             : Vector[tuple[lo: float, hi: float]] 
        derivative*         : proc (solution: Vector[float]) : Vector[float]
        n_iter*             : int 
        step_size*          : float
        random_state*       : int
        initial_solution*   : Option[Vector[float]]

        # State Variables # 
        iter_count          : int 
        indent              : string 
        verbose             : int
        best_solution       : Vector[float]
        best_score          : float
        rng                 : Rand
        current_solution    : Vector[float]

proc createSGDSolver* (
    objective           : proc (solution: Vector[float]) : float,
    bounds              : Vector[tuple[lo: float, hi: float]],
    derivative          : proc (solution: Vector[float]) : Vector[float],
    n_iter              : int = 1000, 
    step_size           : float = 0.01, 
    verbose             : int = 10000,
    random_state        : int = 42,
    initial_solution    : Option[Vector[float]] = none(Vector[float])
) : SGDSolver =  
    # Prepare Parameters and Variables
    var best_solution : Vector[float] 
    var best_score : float = Inf

    var initial_solution_x : Option[Vector[float]] = none(Vector[float])
        
    if initial_solution_x.isSome: 
        initial_solution_x = initial_solution
    else: 
        initial_solution_x = none(Vector[float])

    var rng = initRand(random_state)

    var current_solution : Vector[float]

    # Solver
    let self = SGDSolver(
        # Parameters #
        objective: objective, 
        bounds: bounds, 
        derivative: derivative, 
        n_iter: n_iter, 
        step_size: step_size, 
        verbose: verbose,
        random_state: random_state,
        initial_solution: initial_solution_x,

        # State #
        iter_count: 0,
        indent: "",
        best_solution: best_solution, 
        best_score: best_score,
        rng: rng,
        current_solution: current_solution
    )   

    # Create Initial Solution 
    var initial_solution = self.initial_solution
    if not initial_solution.isSome: 
        initial_solution = some(self.createInitialSolution())
    self.initial_solution = initial_solution    
    self.current_solution = initial_solution.get()
    
    result = self

proc iterate* (self: SGDSolver) = 
    #
    #  Run a single iteration of gradient descent.
    #

    # Log iteration
    self.print("> SGD: Iteration [" & $self.iter_count & "]")

    # Solutions and Scores
    var best_score = self.best_score 
    var best_solution = self.best_solution
    var current_solution = self.current_solution
    var derivative = self.derivative
    var step_size = self.step_size 
    var objective = self.objective

    # Get gradients. 
    var gradients = derivative(current_solution) 

    # Compute new solution.
    var new_solution : Vector[float] = current_solution - gradients * step_size
    
    # Update current solution.
    self.current_solution = new_solution

    # Compute score. 
    var score = objective(new_solution)

    # Display information about iteration.
    self.print("\tScore     = " & $score)

    # Increase iteration count 
    self.iter_count += 1

proc print*(self: SGDSolver, message: string) =
    if self.verbose != 0 and self.iter_count mod self.verbose == 0: 
        echo message

proc createInitialSolution(self: SGDSolver) : Vector[float] = 
    #
    #   Create initial solution.
    # 
    var bounds = self.bounds 
    var initial_solution = newVector[float](bounds.len)
    for i in 0 .. bounds.len - 1: 
        let bounds_i = bounds[i]
        let a = bounds_i.lo 
        let b = bounds_i.hi
        let init_value = self.rng.rand(a .. b)
        initial_solution[i] = init_value
    result = initial_solution
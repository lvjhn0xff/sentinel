{.experimental: "codeReordering".}

import std/random as random
import std/times
import std/options
import utils.nim.vector

type
    AdamSolver* = ref object 
        # Parameters #
        objective*          : proc (solution: Vector[float]) : float
        bounds*             : Vector[tuple[lo: float, hi: float]] 
        derivative*         : proc (solution: Vector[float]) : Vector[float]
        n_iter*             : int 
        alpha*              : float 
        beta1*              : float 
        beta2*              : float
        eps*                : float
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
        m                   : Vector[float] 
        v                   : Vector[float]
        

proc createAdamSolver* (
    objective           : proc (solution: Vector[float]) : float,
    bounds              : Vector[tuple[lo: float, hi: float]],
    derivative          : proc (solution: Vector[float]) : Vector[float],
    n_iter              : int = 1000, 
    alpha               : float = 0.01, 
    beta1               : float = 0.9, 
    beta2               : float = 0.99,
    eps                 : float = 1e-8,
    verbose             : int = 10000,
    random_state        : int = 42,
    initial_solution    : Option[Vector[float]] = none(Vector[float])
) : AdamSolver =  
    # Prepare Parameters and Variables
    let best_solution : Vector[float] = @[] 
    let best_score : float = Inf

    var initial_solution_x : Option[Vector[float]] = none(Vector[float])
        
    if initial_solution_x.isSome: 
        initial_solution_x = initial_solution
    else: 
        initial_solution_x = none(Vector[float])

    var rng = initRand(random_state)
    var current_solution : Vector[float]
    var no_of_params = len(bounds)
    var m : Vector[float] = newVector[float](no_of_params)
    var v : Vector[float] = newVector[float](no_of_params)

    # Solver
    let self = AdamSolver(
        # Parameters #
        objective: objective, 
        bounds: bounds, 
        derivative: derivative, 
        n_iter: n_iter, 
        alpha: alpha, 
        beta1: beta1, 
        beta2: beta2,
        eps: eps,
        verbose: verbose,
        random_state: random_state,
        initial_solution: initial_solution_x,

        # State #
        iter_count: 0,
        indent: "",
        best_solution: best_solution, 
        best_score: best_score,
        rng: rng,
        current_solution: current_solution,
        m: m, 
        v: v 
    )   

    # Create Initial Solution 
    var initial_solution = self.initial_solution
    if not initial_solution.isSome: 
        initial_solution = some(self.createInitialSolution())
    self.initial_solution = initial_solution    
    self.current_solution = initial_solution.get()
    
    
    result = self

proc iterate* (self: AdamSolver) = 
    #
    #  Run a single iteration of gradient descent.
    #

    # Log iteration
    self.print("> ADAM: Iteration [" & $self.iter_count & "]")

    # Solutions and Scores
    var best_score = self.best_score 
    var best_solution = self.best_solution
    var current_solution = self.current_solution
    var derivative = self.derivative
    var alpha = self.alpha 
    var beta1 = self.beta1 
    var beta2 = self.beta2
    var eps = self.eps
    var objective = self.objective
    var _m = self.m 
    var _v = self.v

    # Get gradients. 
    var gradients = derivative(current_solution) 

    # Compute new solution.
    var m_ = beta1 * _m + (1 - beta) * g
    var v_ = beta2 * _v + (1 - beta2) * (g ** 2)

    var new_solution : Vector[float] = (
        
    )

    # Update current solution.
    self.current_solution = new_solution

    # Compute score. 
    var score = objective(new_solution)

    # Display information about iteration.
    self.print("\tScore     = " & $score)

    # Increase iteration count 
    self.iter_count += 1

proc print*(self: AdamSolver, message: string) =
    if self.verbose != 0 and self.iter_count mod self.verbose == 0: 
        echo message

proc createInitialSolution(self: AdamSolver) : Vector[float] = 
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
import math, strutils

# ==========================================
# 1. Core Data Structures & Context Definition
# ==========================================

type
  Context* = ref object
    tape: seq[Node]

  NodeKind = enum
    nkLeaf, nkBinary, nkUnary

  OpType = enum
    opAdd, opSub, opMul, opDiv,
    opLn, opLog, opSin, opCos, opTan,
    opSigmoid, opRelu, opTanh, opPower

  Node* = ref object
    ctx: Context        
    val: float64
    grad: float64
    case kind: NodeKind
    of nkLeaf: discard
    of nkUnary:
      sub: Node
      uOp: OpType
    of nkBinary:
      lhs, rhs: Node
      bOp: OpType

proc newContext*(): Context =
  Context(tape: @[])

# ==========================================
# 2. Graph Construction Factory Functions
# ==========================================

proc newNode(ctx: Context, val: float64, isConstant: bool = false): Node =
  result = Node(ctx: ctx, val: val, grad: 0.0, kind: nkLeaf)
  # Fix: Constants do not get recorded on the tracking tape
  if not isConstant:
    ctx.tape.add(result)

proc newUnaryNode(ctx: Context, val: float64, sub: Node, op: OpType): Node =
  result = Node(ctx: ctx, val: val, grad: 0.0, kind: nkUnary, sub: sub, uOp: op)
  ctx.tape.add(result)

proc newBinaryNode(ctx: Context, val: float64, lhs: Node, rhs: Node, op: OpType): Node =
  assert lhs.ctx == rhs.ctx, "Graph error: Cannot perform cross-operations on nodes from different Contexts"
  result = Node(ctx: lhs.ctx, val: val, grad: 0.0, kind: nkBinary, lhs: lhs, rhs: rhs, bOp: op)
  lhs.ctx.tape.add(result)

proc variable*(ctx: Context, val: float64): Node =
  ctx.newNode(val, isConstant = false)

proc constant*(ctx: Context, val: float64): Node =
  ctx.newNode(val, isConstant = true)

# ==========================================
# 3. Contextual Operators & Scalars
# ==========================================

proc `+`*(lhs, rhs: Node): Node = newBinaryNode(lhs.ctx, lhs.val + rhs.val, lhs, rhs, opAdd)
proc `+`*(lhs: Node, rhs: float64): Node = lhs + lhs.ctx.constant(rhs)
proc `+`*(lhs: float64, rhs: Node): Node = rhs.ctx.constant(lhs) + rhs

proc `-`*(lhs, rhs: Node): Node = newBinaryNode(lhs.ctx, lhs.val - rhs.val, lhs, rhs, opSub)
proc `-`*(lhs: Node, rhs: float64): Node = lhs - lhs.ctx.constant(rhs)
proc `-`*(lhs: float64, rhs: Node): Node = rhs.ctx.constant(lhs) - rhs

proc `*`*(lhs, rhs: Node): Node = newBinaryNode(lhs.ctx, lhs.val * rhs.val, lhs, rhs, opMul)
proc `*`*(lhs: Node, rhs: float64): Node = lhs * lhs.ctx.constant(rhs)
proc `*`*(lhs: float64, rhs: Node): Node = rhs.ctx.constant(lhs) * rhs

proc `/`*(lhs, rhs: Node): Node = newBinaryNode(lhs.ctx, lhs.val / rhs.val, lhs, rhs, opDiv)
proc `/`*(lhs: Node, rhs: float64): Node = lhs / lhs.ctx.constant(rhs)
proc `/`*(lhs: float64, rhs: Node): Node = rhs.ctx.constant(lhs) / rhs

# ==========================================
# 4. Mathematical Functions & Activations
# ==========================================

proc ln*(n: Node): Node = newUnaryNode(n.ctx, math.ln(n.val), n, opLn)
proc log*(n: Node, base: float64 = 10.0): Node = newBinaryNode(n.ctx, math.log(n.val, base), n, n.ctx.constant(base), opLog)
proc sin*(n: Node): Node = newUnaryNode(n.ctx, math.sin(n.val), n, opSin)
proc cos*(n: Node): Node = newUnaryNode(n.ctx, math.cos(n.val), n, opCos)
proc tan*(n: Node): Node = newUnaryNode(n.ctx, math.tan(n.val), n, opTan)
proc sigmoid*(n: Node): Node = newUnaryNode(n.ctx, 1.0 / (1.0 + math.exp(-n.val)), n, opSigmoid)
proc relu*(n: Node): Node = newUnaryNode(n.ctx, (if n.val > 0.0: n.val else: 0.0), n, opRelu)
proc tanh*(n: Node): Node = newUnaryNode(n.ctx, math.tanh(n.val), n, opTanh)

proc pow*(base: Node, exponent: float64): Node =
  let val = if base.val < 0.0 and exponent == (1.0 / 3.0):
              -math.pow(-base.val, exponent)
            else:
              math.pow(base.val, exponent)
  newBinaryNode(base.ctx, val, base, base.ctx.constant(exponent), opPower)

# ==========================================
# 5. Advanced Vector Aggregations
# ==========================================

proc arithmeticMean*(nodes: openArray[Node]): Node =
  var sumNode = nodes[0]
  for i in 1..<nodes.len: sumNode = sumNode + nodes[i]
  result = sumNode / nodes.len.float64

proc cubicMean*(nodes: openArray[Node]): Node =
  var sumCube = pow(nodes[0], 3.0)
  for i in 1..<nodes.len: sumCube = sumCube + pow(nodes[i], 3.0)
  result = pow(sumCube / nodes.len.float64, 1.0 / 3.0)

# ==========================================
# 6. Reverse Engine Execution Pass
# ==========================================

proc backward*(output: Node) =
  let ctx = output.ctx
  for node in ctx.tape: node.grad = 0.0
  output.grad = 1.0
  
  for i in countdown(ctx.tape.len - 1, 0):
    let node = ctx.tape[i]
    if node.grad == 0.0: continue
    
    case node.kind:
    of nkLeaf: discard
    of nkUnary:
      let sub = node.sub
      case node.uOp:
      of opLn:      sub.grad += node.grad * (1.0 / sub.val)
      of opSin:     sub.grad += node.grad * math.cos(sub.val)
      of opCos:     sub.grad += node.grad * (-math.sin(sub.val))
      of opTan:     sub.grad += node.grad * (1.0 / math.pow(math.cos(sub.val), 2.0))
      of opSigmoid: sub.grad += node.grad * (node.val * (1.0 - node.val))
      of opRelu:    sub.grad += node.grad * (if sub.val > 0.0: 1.0 else: 0.0)
      of opTanh:    sub.grad += node.grad * (1.0 - math.pow(node.val, 2.0))
      else: discard
    of nkBinary:
      let lhs = node.lhs
      let rhs = node.rhs
      case node.bOp:
      of opAdd:
        lhs.grad += node.grad
        rhs.grad += node.grad
      of opSub:
        lhs.grad += node.grad
        rhs.grad -= node.grad
      of opMul:
        lhs.grad += node.grad * rhs.val
        rhs.grad += node.grad * lhs.val
      of opDiv:
        lhs.grad += node.grad / rhs.val
        rhs.grad -= node.grad * lhs.val / (rhs.val * rhs.val)
      of opLog:
        lhs.grad += node.grad * (1.0 / (lhs.val * math.ln(rhs.val)))
        rhs.grad -= node.grad * (math.ln(lhs.val) / (rhs.val * math.pow(math.ln(rhs.val), 2.0)))
      of opPower:
        if lhs.val < 0.0 and rhs.val == (1.0 / 3.0):
          let deriv = rhs.val * math.pow(abs(lhs.val), rhs.val - 1.0)
          lhs.grad += node.grad * deriv
        else:
          lhs.grad += node.grad * (rhs.val * math.pow(lhs.val, rhs.val - 1.0))
        if lhs.val > 0.0:
          rhs.grad += node.grad * (node.val * math.ln(lhs.val))
      else: discard

proc grad*(n: Node): float64 = n.grad
proc val*(n: Node): float64 = n.val

# ==========================================
# 7. Verification Loop with Expected Values
# ==========================================

type
  DenseNeuron = object
    w1, w2, b: Node

proc newDenseNeuron(ctx: Context, initialW1, initialW2, initialB: float64): DenseNeuron =
  DenseNeuron(w1: ctx.variable(initialW1), w2: ctx.variable(initialW2), b: ctx.variable(initialB))

proc forward(n: DenseNeuron, x1, x2: Node): Node =
  result = sigmoid(n.w1 * x1 + n.w2 * x2 + n.b)

proc verify(name: string, actual, expected: float64, tolerance: float64 = 1e-6) =
  let diff = abs(actual - expected)
  let verdict = if diff <= tolerance and not math.isNaN(actual): "CORRECT" else: "WRONG"
  echo "$1 -> Actual: $2 | Expected: $3 | Verdict: [$4]" % [name.alignLeft(18), ($actual).alignLeft(18), ($expected).alignLeft(18), verdict]

proc main() =
  let graphA = newContext()
  let graphB = newContext()

  # Graph A Setup
  let neuronA = newDenseNeuron(graphA, 0.5, -0.2, 0.1)
  let x1_A = graphA.variable(1.0)
  let x2_A = graphA.variable(2.0)
  let outputA = neuronA.forward(x1_A, x2_A)

  # Graph B Setup
  let neuronB = newDenseNeuron(graphB, 0.8, 0.4, -0.5)
  let x1_B = graphB.variable(0.5)
  let x2_B = graphB.variable(-1.5)
  let outputB = cubicMean([neuronB.w1 * x1_B, neuronB.w2 * x2_B])

  # Execution & Checks
  backward(outputA)
  echo "=== Verification Graph Context A ==="
  verify("Output A Value", outputA.val, 0.549833997312478)
  verify("Neuron A w1 Grad", neuronA.w1.grad, 0.24751657271186)
  verify("Neuron B w1 Grad", neuronB.w1.grad, 0.0)

  backward(outputB)
  echo "\n=== Verification Graph Context B ==="
  verify("Output B Value", outputB.val, -0.4235823584)
  verify("Neuron B w1 Grad", neuronB.w1.grad, 0.2229380834)
  
main()
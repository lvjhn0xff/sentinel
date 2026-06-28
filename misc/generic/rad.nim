import utils.nim.rad as rad 

let graphA = rad.newContext()
let graphB = rad.newContext()

# Graph A Setup
let neuronA = rad.newDenseNeuron(graphA, 0.5, -0.2, 0.1)
let x1_A = graphA.variable(1.0)
let x2_A = graphA.variable(2.0)
let outputA = neuronA.forward(x1_A, x2_A)

# Graph B Setup
let neuronB = rad.newDenseNeuron(graphB, 0.8, 0.4, -0.5)
let x1_B = graphB.variable(0.5)
let x2_B = graphB.variable(-1.5)
let outputB = rad.cubicMean([neuronB.w1 * x1_B, neuronB.w2 * x2_B])

# Execution & Checks
rad.backward(outputA)
echo "=== Verification Graph Context A ==="
rad.verify("Output A Value", outputA.val, 0.549833997312478)
rad.verify("Neuron A w1 Grad", neuronA.w1.grad, 0.24751657271186)
rad.verify("Neuron B w1 Grad", neuronB.w1.grad, 0.0)

rad.backward(outputB)
echo "\n=== Verification Graph Context B ==="
rad.verify("Output B Value", outputB.val, -0.4235823584)
rad.verify("Neuron B w1 Grad", neuronB.w1.grad, 0.2229380834)


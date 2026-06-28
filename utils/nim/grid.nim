import std/sequtils
import std/strutils
import std/math

type
  Grid*[T] = ref object
    rows*, cols*: int
    data*: seq[T]

  # Updated View to hold arbitrary, non-contiguous index maps
  GridView*[T] = object
    source*: Grid[T]
    rowIndices*: seq[int]
    colIndices*: seq[int]

# --- Core Grid Set up ---
proc newGrid*[T](rows, cols: int): Grid[T] =
  Grid[T](rows: rows, cols: cols, data: newSeq[T](rows * cols))

proc toGrid*[T](rows, cols: int, data: seq[T]): Grid[T] =
  Grid[T](rows: rows, cols: cols, data: data)

proc `[]`*[T](m: Grid[T], r, c: int): T {.inline.} = m.data[r * m.cols + c]
proc `[]=`*[T](m: Grid[T], r, c: int, val: T) {.inline.} = m.data[r * m.cols + c] = val

# --- View Dimensions ---
template rows*[T](v: GridView[T]): int = v.rowIndices.len
template cols*[T](v: GridView[T]): int = v.colIndices.len

# --- Non-Contiguous Accessors & Setters ---
proc `[]`*[T](v: GridView[T], r, c: int): T {.inline.} =
  ## Maps virtual view coordinates to arbitrary underlying Grid positions
  v.source[v.rowIndices[r], v.colIndices[c]]

proc `[]=`*[T](v: var GridView[T], r, c: int, val: T) {.inline.} =
  ## Directly mutates the non-contiguous element in the source Grid
  v.source[v.rowIndices[r], v.colIndices[c]] = val

# --- Non-Contiguous Slicing (Zero-Copy) ---
proc `[]`*[T](m: Grid[T], rows: seq[int], cols: seq[int]): GridView[T] {.inline.} =
  ## Accepts arbitrary sequences of indices (e.g., @[0, 2])
  GridView[T](source: m, rowIndices: rows, colIndices: cols)

# --- Slice Getters and Setters ---

# Get a row as a seq[T] (since we don't have Vector here)
proc row*[T](m: Grid[T], r: int): seq[T] =
  assert r >= 0 and r < m.rows, "Row index out of bounds"
  result = newSeq[T](m.cols)
  for c in 0 ..< m.cols:
    result[c] = m[r, c]

# Set a row from a seq[T]
proc setRow*[T](m: var Grid[T], r: int, values: seq[T]) =
  assert r >= 0 and r < m.rows, "Row index out of bounds"
  assert values.len == m.cols, "Sequence length must match grid columns"
  for c in 0 ..< m.cols:
    m[r, c] = values[c]

# Get a column as a seq[T]
proc col*[T](m: Grid[T], c: int): seq[T] =
  assert c >= 0 and c < m.cols, "Column index out of bounds"
  result = newSeq[T](m.rows)
  for r in 0 ..< m.rows:
    result[r] = m[r, c]

# Set a column from a seq[T]
proc setCol*[T](m: var Grid[T], c: int, values: seq[T]) =
  assert c >= 0 and c < m.cols, "Column index out of bounds"
  assert values.len == m.rows, "Sequence length must match grid rows"
  for r in 0 ..< m.rows:
    m[r, c] = values[r]

# Get a slice of rows as a Grid
proc getRows*[T](m: Grid[T], rowStart, rowEnd: int): Grid[T] =
  assert rowStart >= 0 and rowEnd < m.rows and rowStart <= rowEnd, "Invalid row range"
  result = newGrid[T](rowEnd - rowStart + 1, m.cols)
  var destR = 0
  for r in rowStart .. rowEnd:
    for c in 0 ..< m.cols:
      result[destR, c] = m[r, c]
    destR.inc

# Get a slice of columns as a Grid
proc getCols*[T](m: Grid[T], colStart, colEnd: int): Grid[T] =
  assert colStart >= 0 and colEnd < m.cols and colStart <= colEnd, "Invalid column range"
  result = newGrid[T](m.rows, colEnd - colStart + 1)
  for r in 0 ..< m.rows:
    var destC = 0
    for c in colStart .. colEnd:
      result[r, destC] = m[r, c]
      destC.inc

# Get a subgrid (rows and cols ranges)
proc subgrid*[T](m: Grid[T], rowStart, rowEnd, colStart, colEnd: int): Grid[T] =
  assert rowStart >= 0 and rowEnd < m.rows and rowStart <= rowEnd, "Invalid row range"
  assert colStart >= 0 and colEnd < m.cols and colStart <= colEnd, "Invalid column range"
  result = newGrid[T](rowEnd - rowStart + 1, colEnd - colStart + 1)
  var destR = 0
  for r in rowStart .. rowEnd:
    var destC = 0
    for c in colStart .. colEnd:
      result[destR, destC] = m[r, c]
      destC.inc
    destR.inc

# Set a subgrid from another Grid
proc setSubgrid*[T](m: var Grid[T], rowStart, colStart: int, src: Grid[T]) =
  assert rowStart >= 0 and rowStart + src.rows <= m.rows, "Subgrid rows out of bounds"
  assert colStart >= 0 and colStart + src.cols <= m.cols, "Subgrid cols out of bounds"
  for r in 0 ..< src.rows:
    for c in 0 ..< src.cols:
      m[rowStart + r, colStart + c] = src[r, c]

# --- Axis-based operations ---

# Sum along axis
proc sum*[T](m: Grid[T], axis: int = -1): seq[T] =
  case axis:
  of 0:  # Sum each column
    result = newSeq[T](m.cols)
    for c in 0 ..< m.cols:
      var s = default(T)
      for r in 0 ..< m.rows:
        s += m[r, c]
      result[c] = s
  of 1:  # Sum each row
    result = newSeq[T](m.rows)
    for r in 0 ..< m.rows:
      var s = default(T)
      for c in 0 ..< m.cols:
        s += m[r, c]
      result[r] = s
  else:  # Sum all (flatten)
    var s = default(T)
    for i in 0 ..< m.data.len:
      s += m.data[i]
    result = @[s]

# Mean along axis
proc mean*[T](m: Grid[T], axis: int = -1): seq[float] =
  case axis:
  of 0:
    result = newSeq[float](m.cols)
    for c in 0 ..< m.cols:
      var s = 0.0
      for r in 0 ..< m.rows:
        s += float(m[r, c])
      result[c] = s / float(m.rows)
  of 1:
    result = newSeq[float](m.rows)
    for r in 0 ..< m.rows:
      var s = 0.0
      for c in 0 ..< m.cols:
        s += float(m[r, c])
      result[r] = s / float(m.cols)
  else:
    var s = 0.0
    for i in 0 ..< m.data.len:
      s += float(m.data[i])
    result = @[s / float(m.data.len)]

# Max along axis
proc max*[T](m: Grid[T], axis: int = -1): seq[T] =
  assert m.rows > 0 and m.cols > 0, "Cannot get max of empty Grid"
  case axis:
  of 0:
    result = newSeq[T](m.cols)
    for c in 0 ..< m.cols:
      var maxVal = m[0, c]
      for r in 1 ..< m.rows:
        if m[r, c] > maxVal: maxVal = m[r, c]
      result[c] = maxVal
  of 1:
    result = newSeq[T](m.rows)
    for r in 0 ..< m.rows:
      var maxVal = m[r, 0]
      for c in 1 ..< m.cols:
        if m[r, c] > maxVal: maxVal = m[r, c]
      result[r] = maxVal
  else:
    var maxVal = m.data[0]
    for i in 1 ..< m.data.len:
      if m.data[i] > maxVal: maxVal = m.data[i]
    result = @[maxVal]

# Min along axis
proc min*[T](m: Grid[T], axis: int = -1): seq[T] =
  assert m.rows > 0 and m.cols > 0, "Cannot get min of empty Grid"
  case axis:
  of 0:
    result = newSeq[T](m.cols)
    for c in 0 ..< m.cols:
      var minVal = m[0, c]
      for r in 1 ..< m.rows:
        if m[r, c] < minVal: minVal = m[r, c]
      result[c] = minVal
  of 1:
    result = newSeq[T](m.rows)
    for r in 0 ..< m.rows:
      var minVal = m[r, 0]
      for c in 1 ..< m.cols:
        if m[r, c] < minVal: minVal = m[r, c]
      result[r] = minVal
  else:
    var minVal = m.data[0]
    for i in 1 ..< m.data.len:
      if m.data[i] < minVal: minVal = m.data[i]
    result = @[minVal]

# --- Element-wise operations (apply to all elements) ---

# Apply a function to every element
proc map*[T, R](m: Grid[T], f: proc(x: T): R): Grid[R] =
  result = newGrid[R](m.rows, m.cols)
  for r in 0 ..< m.rows:
    for c in 0 ..< m.cols:
      result[r, c] = f(m[r, c])

# Apply a function to every element with index
proc mapIdx*[T, R](m: Grid[T], f: proc(r, c: int, x: T): R): Grid[R] =
  result = newGrid[R](m.rows, m.cols)
  for r in 0 ..< m.rows:
    for c in 0 ..< m.cols:
      result[r, c] = f(r, c, m[r, c])

# --- Math operations on entire grid ---

proc sqrt*[T](m: Grid[T]): Grid[float] =
  result = m.map(proc(x: T): float = 
    let val = float(x)
    assert val >= 0, "sqrt requires non-negative values"
    math.sqrt(val)
  )

proc square*[T](m: Grid[T]): Grid[T] =
  result = m.map(proc(x: T): T = x * x)

proc abs*[T](m: Grid[T]): Grid[T] =
  result = m.map(proc(x: T): T = if x < 0: -x else: x)

proc exp*[T](m: Grid[T]): Grid[float] =
  result = m.map(proc(x: T): float = math.exp(float(x)))

proc log*[T](m: Grid[T]): Grid[float] =
  result = m.map(proc(x: T): float = 
    let val = float(x)
    assert val > 0, "Logarithm requires positive values"
    math.log(val)
  )

proc log10*[T](m: Grid[T]): Grid[float] =
  result = m.map(proc(x: T): float = 
    let val = float(x)
    assert val > 0, "Logarithm requires positive values"
    math.log10(val)
  )

proc pow*[T](m: Grid[T], exponent: float): Grid[float] =
  result = m.map(proc(x: T): float = math.pow(float(x), exponent))

proc tanh*[T](m: Grid[T]): Grid[float] =
  result = m.map(proc(x: T): float = math.tanh(float(x)))

proc softmax*[T](m: Grid[T]): Grid[float] =
  # Softmax over entire grid (flattened)
  # First compute exp(x - max) for all elements
  var maxVal = float(m.data[0])
  for i in 1 ..< m.data.len:
    if float(m.data[i]) > maxVal: maxVal = float(m.data[i])
  
  var expSum = 0.0
  var expData = newSeq[float](m.data.len)
  for i in 0 ..< m.data.len:
    let expVal = exp(float(m.data[i]) - maxVal)
    expData[i] = expVal
    expSum += expVal
  
  result = newGrid[float](m.rows, m.cols)
  for i in 0 ..< m.data.len:
    result.data[i] = expData[i] / expSum

# --- In-place element-wise operations ---

proc apply*[T](m: var Grid[T], f: proc(x: T): T) =
  for r in 0 ..< m.rows:
    for c in 0 ..< m.cols:
      m[r, c] = f(m[r, c])

proc apply*[T](v: var GridView[T], f: proc(x: T): T) =
  for r in 0 ..< v.rows:
    for c in 0 ..< v.cols:
      var val = v[r, c]
      val = f(val)
      v[r, c] = val

# --- Explicit Copying ---
proc copy*[T](v: GridView[T]): Grid[T] =
  ## Materializes the non-contiguous view into a packed, sequential Grid
  result = newGrid[T](v.rows, v.cols)
  for r in 0 ..< v.rows:
    for c in 0 ..< v.cols:
      result[r, c] = v[r, c]

# --- 2D Sequence Conversion Utilities ---

proc toSeq2D*[T](m: Grid[T]): seq[seq[T]] =
  ## Converts a packed Grid into a native Nim 2D nested sequence
  result = newSeq[seq[T]](m.rows)
  for r in 0 ..< m.rows:
    result[r] = newSeq[T](m.cols)
    for c in 0 ..< m.cols:
      result[r][c] = m[r, c]

proc fromSeq2D*[T](s2d: seq[seq[T]]): Grid[T] =
  ## Creates a packed Grid from a native Nim 2D nested sequence
  let rLen = s2d.len
  if rLen == 0: return newGrid[T](0, 0)
  let cLen = s2d[0].len
  
  result = newGrid[T](rLen, cLen)
  for r in 0 ..< rLen:
    assert s2d[r].len == cLen, "All rows in the 2D sequence must be uniform in length"
    for c in 0 ..< cLen:
      result[r, c] = s2d[r][c]

# --- Mass Assignment & Fill Broadcasting ---
proc fill*[T](v: var GridView[T], val: T) {.inline.} =
  for r in 0 ..< v.rows:
    for c in 0 ..< v.cols:
      v[r, c] = val

proc fill*[T](v: var GridView[T], m: Grid[T]) {.inline.} =
  assert v.rows == m.rows and v.cols == m.cols, "Shape mismatch"
  for r in 0 ..< v.rows:
    for c in 0 ..< v.cols:
      v[r, c] = m[r, c]

proc fill*[T](v1: var GridView[T], v2: GridView[T]) {.inline.} =
  assert v1.rows == v2.rows and v1.cols == v2.cols, "Shape mismatch"
  for r in 0 ..< v1.rows:
    for c in 0 ..< v1.cols:
      v1[r, c] = v2[r, c]

# --- NumPy-like Math Operations & In-place Operators ---

template makeScalarOp(opName: untyped, baseOp: untyped) =
  proc opName*[T](m: var Grid[T], val: T) {.inline.} =
    for i in 0 ..< m.data.len:
      baseOp(m.data[i], val)

  proc opName*[T](v: var GridView[T], val: T) {.inline.} =
    for r in 0 ..< v.rows:
      for c in 0 ..< v.cols:
        var element = v[r, c]
        baseOp(element, val)
        v[r, c] = element

template makeVectorOp(opName: untyped, baseOp: untyped) =
  proc opName*[T](m1: var Grid[T], m2: Grid[T]) {.inline.} =
    assert m1.rows == m2.rows and m1.cols == m2.cols, "Shape mismatch"
    for i in 0 ..< m1.data.len:
      baseOp(m1.data[i], m2.data[i])

  proc opName*[T](v1: var GridView[T], v2: GridView[T]) {.inline.} =
    assert v1.rows == v2.rows and v1.cols == v2.cols, "Shape mismatch"
    for r in 0 ..< v1.rows:
      for c in 0 ..< v1.cols:
        var element = v1[r, c]
        baseOp(element, v2[r, c])
        v1[r, c] = element

  proc opName*[T](v: var GridView[T], m: Grid[T]) {.inline.} =
    assert v.rows == m.rows and v.cols == m.cols, "Shape mismatch"
    for r in 0 ..< v.rows:
      for c in 0 ..< v.cols:
        var element = v[r, c]
        baseOp(element, m[r, c])
        v[r, c] = element

  proc opName*[T](m: var Grid[T], v: GridView[T]) {.inline.} =
    assert m.rows == v.rows and m.cols == v.cols, "Shape mismatch"
    for r in 0 ..< m.rows:
      for c in 0 ..< m.cols:
        baseOp(m[r, c], v[r, c])

makeScalarOp(`+=`, `+=`)
makeScalarOp(`-=`, `-=`)
makeScalarOp(`*=`, `*=`)
makeScalarOp(`/=`, `/=`)

makeVectorOp(`+=`, `+=`)
makeVectorOp(`-=`, `-=`)
makeVectorOp(`*=`, `*=`)
makeVectorOp(`/=`, `/=`)

# --- Pretty Printing ---
proc `$`*[T](m: Grid[T]): string =
  var lines = newSeq[string]()
  for r in 0 ..< m.rows:
    var rowVals = newSeq[string]()
    for c in 0 ..< m.cols: rowVals.add($m[r, c])
    lines.add("[" & rowVals.join(", ") & "]")
  result = "Grid:\n " & lines.join("\n ")

# --- Main/Sanity Check ---
when isMainModule:
  # 1. Create from a native nested 2D sequence
  let nestedSeq = @[
    @[1.0, 4.0, 9.0],
    @[16.0, 25.0, 36.0],
    @[49.0, 64.0, 81.0]
  ]
  
  var grid = fromSeq2D(nestedSeq)
  echo "--- Grid created from 2D sequence ---"
  echo grid

  # 2. Row and column operations
  echo "\n--- Row and Column Operations ---"
  let row1 = grid.row(1)
  echo "Row 1: ", row1
  
  var newRow = @[10.0, 11.0, 12.0]
  grid.setRow(1, newRow)
  echo "Grid after setting row 1:"
  echo grid
  
  let col0 = grid.col(0)
  echo "Column 0: ", col0
  
  # 3. Subgrid operations
  echo "\n--- Subgrid Operations ---"
  let sub = grid.subgrid(0, 1, 0, 1)
  echo "Subgrid (rows 0-1, cols 0-1):"
  echo sub
  
  var newSub = fromSeq2D(@[@[99.0, 98.0], @[97.0, 96.0]])
  grid.setSubgrid(0, 0, newSub)
  echo "Grid after setting subgrid:"
  echo grid

  # 4. Axis operations
  echo "\n--- Axis Operations ---"
  echo "Sum each column (axis 0): ", grid.sum(0)
  echo "Sum each row (axis 1): ", grid.sum(1)
  echo "Sum all (axis -1): ", grid.sum(-1)
  echo "Mean each column (axis 0): ", grid.mean(0)
  echo "Mean each row (axis 1): ", grid.mean(1)
  echo "Mean all (axis -1): ", grid.mean(-1)
  
  # 5. Element-wise operations
  echo "\n--- Element-wise Operations ---"
  let squared = grid.map(proc(x: float): float = x * x)
  echo "Squared grid:"
  echo squared
  
  # 6. Math functions
  echo "\n--- Math Functions ---"
  let mathGrid = fromSeq2D(@[
    @[1.0, 4.0, 9.0],
    @[16.0, 25.0, 36.0],
    @[49.0, 64.0, 81.0]
  ])
  echo "Original grid:"
  echo mathGrid
  echo "sqrt:"
  echo mathGrid.sqrt()
  echo "square:"
  echo mathGrid.square()
  echo "abs (of negative values):"
  let negGrid = fromSeq2D(@[
    @[-1.0, -4.0, 9.0],
    @[16.0, -25.0, 36.0],
    @[-49.0, 64.0, -81.0]
  ])
  echo negGrid.abs()
  echo "exp:"
  echo mathGrid.exp()
  echo "log:"
  echo mathGrid.log()
  echo "pow(0.5):"
  echo mathGrid.pow(0.5)
  echo "tanh:"
  echo mathGrid.tanh()
  
  # 7. Perform a NumPy style slice mutation
  var corners = grid[@[0, 2], @[0, 2]]
  corners *= 100.0
  echo "\nGrid after corners *= 100:"
  echo grid

  # 8. Convert back to native nested 2D sequence
  let outputSeq2D = grid.toSeq2D()
  echo "\n--- Converted back to 2D standard sequences (Raw Data) ---"
  echo outputSeq2D
import std/sequtils
import std/strutils
import std/math
import std/algorithm

type
  Vector*[T] = ref object
    items*: seq[T]

# ==========================================
# Constructors & Helpers
# ==========================================

proc newVector*[T](size: int): Vector[T] =
  Vector[T](items: newSeq[T](size))

proc toVector*[T](s: seq[T]): Vector[T] =
  Vector[T](items: s)

proc createVector*[T](elements: openArray[T]): Vector[T] =
  var s = newSeq[T](elements.len)
  for i in 0 ..< elements.len: s[i] = elements[i]
  return Vector[T](items: s)

template len*[T](l: Vector[T]): int = l.items.len

proc `$`*[T](l: Vector[T]): string = $l.items

# ==========================================
# Copy Operations
# ==========================================

# Shallow copy (copies the reference)
proc shallowCopy*[T](v: Vector[T]): Vector[T] =
  v  # Returns the same object reference

# Deep copy (creates a new independent vector)
proc copy*[T](v: Vector[T]): Vector[T] =
  result = newVector[T](v.len)
  for i in 0 ..< v.len:
    result[i] = v[i]

# Alternative deep copy using seq copy
proc deepCopy*[T](v: Vector[T]): Vector[T] =
  toVector(v.items)  # seq copy is automatic

# Clone (alias for copy)
proc clone*[T](v: Vector[T]): Vector[T] =
  v.copy()

# ==========================================
# Accessors (Single, Slice, Multi-Index)
# ==========================================

proc `[]`*[T](l: Vector[T], idx: int): T {.inline.} = l.items[idx]
proc `[]=`*[T](l: Vector[T], idx: int, val: T) {.inline.} = l.items[idx] = val

proc `[]`*[T](l: Vector[T], slice: HSlice[int, int]): Vector[T] =
  let b = l.items.toBounds(slice)
  result = newVector[T](b.len)
  var idx = 0
  for i in b:
    result[idx] = l.items[i]
    inc idx

proc `[]=`*[T](l: Vector[T], slice: HSlice[int, int], values: openArray[T]) =
  let b = l.items.toBounds(slice)
  assert b.len == values.len, "Slice size mismatch"
  var idx = 0
  for i in b:
    l.items[i] = values[idx]
    inc idx

proc `[]`*[T](l: Vector[T], indices: openArray[int]): Vector[T] =
  result = newVector[T](indices.len)
  for i in 0 ..< indices.len: result[i] = l.items[indices[i]]

proc `[]=`*[T](l: Vector[T], indices: openArray[int], values: openArray[T]) =
  assert indices.len == values.len, "Indices and values size mismatch"
  for i in 0 ..< indices.len: l.items[indices[i]] = values[i]

# ==========================================
# Out-of-place Math (Vector & Scalar)
# ==========================================

# Vector-Vector
proc `+`*[T](a, b: Vector[T]): Vector[T] =
  assert a.len == b.len; result = newVector[T](a.len)
  for i in 0 ..< a.len: result[i] = a[i] + b[i]
proc `-`*[T](a, b: Vector[T]): Vector[T] =
  assert a.len == b.len; result = newVector[T](a.len)
  for i in 0 ..< a.len: result[i] = a[i] - b[i]
proc `*`*[T](a, b: Vector[T]): Vector[T] =
  assert a.len == b.len; result = newVector[T](a.len)
  for i in 0 ..< a.len: result[i] = a[i] * b[i]
proc `/`*[T](a, b: Vector[T]): Vector[T] =
  assert a.len == b.len; result = newVector[T](a.len)
  for i in 0 ..< a.len: result[i] = a[i] / b[i]

# Vector-Scalar & Scalar-Vector
proc `+`*[T](a: Vector[T], val: T): Vector[T] =
  result = newVector[T](a.len)
  for i in 0 ..< a.len: result[i] = a[i] + val
proc `+`*[T](val: T, a: Vector[T]): Vector[T] = a + val

proc `-`*[T](a: Vector[T], val: T): Vector[T] =
  result = newVector[T](a.len)
  for i in 0 ..< a.len: result[i] = a[i] - val
proc `-`*[T](val: T, a: Vector[T]): Vector[T] =
  result = newVector[T](a.len)
  for i in 0 ..< a.len: result[i] = val - a[i]

proc `*`*[T](a: Vector[T], val: T): Vector[T] =
  result = newVector[T](a.len)
  for i in 0 ..< a.len: result[i] = a[i] * val
proc `*`*[T](val: T, a: Vector[T]): Vector[T] = a * val

proc `/`*[T](a: Vector[T], val: T): Vector[T] =
  result = newVector[T](a.len)
  for i in 0 ..< a.len: result[i] = a[i] / val
proc `/`*[T](val: T, a: Vector[T]): Vector[T] =
  result = newVector[T](a.len)
  for i in 0 ..< a.len: result[i] = val / a[i]

# ==========================================
# NumPy Style: In-place Operators (+=, -=, *=, /=)
# ==========================================

proc `+=`*[T](a: var Vector[T], b: Vector[T]) =
  assert a.len == b.len
  for i in 0 ..< a.len: a.items[i] += b[i]

proc `+=`*[T](a: var Vector[T], val: T) =
  for i in 0 ..< a.len: a.items[i] += val

proc `-=`*[T](a: var Vector[T], b: Vector[T]) =
  assert a.len == b.len
  for i in 0 ..< a.len: a.items[i] -= b[i]

proc `-=`*[T](a: var Vector[T], val: T) =
  for i in 0 ..< a.len: a.items[i] -= val

proc `*=`*[T](a: var Vector[T], b: Vector[T]) =
  assert a.len == b.len
  for i in 0 ..< a.len: a.items[i] *= b[i]

proc `*=`*[T](a: var Vector[T], val: T) =
  for i in 0 ..< a.len: a.items[i] *= val

proc `/=`*[T](a: var Vector[T], b: Vector[T]) =
  assert a.len == b.len
  for i in 0 ..< a.len: a.items[i] /= b[i]

proc `/=`*[T](a: var Vector[T], val: T) =
  for i in 0 ..< a.len: a.items[i] /= val

# ==========================================
# NumPy Style: Vector Comparison Masks
# ==========================================

proc `==`*[T](a: Vector[T], val: T): Vector[bool] =
  result = newVector[bool](a.len)
  for i in 0 ..< a.len: result[i] = a[i] == val

proc `<`*[T](a: Vector[T], val: T): Vector[bool] =
  result = newVector[bool](a.len)
  for i in 0 ..< a.len: result[i] = a[i] < val

proc `>`*[T](a: Vector[T], val: T): Vector[bool] =
  result = newVector[bool](a.len)
  for i in 0 ..< a.len: result[i] = a[i] > val

proc `<=`*[T](a: Vector[T], val: T): Vector[bool] =
  result = newVector[bool](a.len)
  for i in 0 ..< a.len: result[i] = a[i] <= val

proc `>=`*[T](a: Vector[T], val: T): Vector[bool] =
  result = newVector[bool](a.len)
  for i in 0 ..< a.len: result[i] = a[i] >= val

# NumPy-style boolean masking (e.g., v[v > 3])
proc `[]`*[T](l: Vector[T], mask: Vector[bool]): Vector[T] =
  assert l.len == mask.len, "Mask length must match vector length"
  var temp: seq[T]
  for i in 0 ..< l.len:
    if mask[i]: temp.add(l[i])
  return toVector(temp)

# ==========================================
# NumPy Style: Reductions
# ==========================================

proc sum*[T](v: Vector[T]): T =
  result = default(T)
  for i in 0 ..< v.len: result += v[i]

proc mean*[T](v: Vector[T]): float =
  float(v.sum()) / float(v.len)

proc max*[T](v: Vector[T]): T =
  assert v.len > 0, "Cannot get max of empty Vector"
  result = v[0]
  for i in 1 ..< v.len:
    if v[i] > result: result = v[i]

proc min*[T](v: Vector[T]): T =
  assert v.len > 0, "Cannot get min of empty Vector"
  result = v[0]
  for i in 1 ..< v.len:
    if v[i] < result: result = v[i]

proc dot*[T](a, b: Vector[T]): T =
  assert a.len == b.len; result = default(T)
  for i in 0 ..< a.len: result += a[i] * b[i]

# ==========================================
# Advanced Mathematical Functions
# ==========================================

# Hyperbolic tangent (tanh) - element-wise
proc tanh*[T](v: Vector[T]): Vector[float] =
  result = newVector[float](v.len)
  for i in 0 ..< v.len:
    result[i] = math.tanh(float(v[i]))

# Cubic Mean (Root Mean Cube)
proc cubicMean*[T](v: Vector[T]): float =
  assert v.len > 0, "Cannot compute cubic mean of empty Vector"
  var sumCubes = 0.0
  for i in 0 ..< v.len:
    sumCubes += float(v[i]) ^ 3
  return pow(sumCubes / float(v.len), 1.0 / 3.0)

# Harmonic Mean
proc harmonicMean*[T](v: Vector[T]): float =
  assert v.len > 0, "Cannot compute harmonic mean of empty Vector"
  var sumReciprocals = 0.0
  for i in 0 ..< v.len:
    let val = float(v[i])
    assert val != 0.0, "Cannot compute harmonic mean with zero values"
    sumReciprocals += 1.0 / val
  return float(v.len) / sumReciprocals

# Geometric Mean
proc geometricMean*[T](v: Vector[T]): float =
  assert v.len > 0, "Cannot compute geometric mean of empty Vector"
  var product = 1.0
  for i in 0 ..< v.len:
    let val = float(v[i])
    assert val > 0.0, "Cannot compute geometric mean with non-positive values"
    product *= val
  return pow(product, 1.0 / float(v.len))

# Softmax (returns probability distribution)
proc softmax*[T](v: Vector[T]): Vector[float] =
  assert v.len > 0, "Cannot compute softmax of empty Vector"
  
  var maxVal = float(v[0])
  for i in 1 ..< v.len:
    if float(v[i]) > maxVal: maxVal = float(v[i])
  
  var expSum = 0.0
  result = newVector[float](v.len)
  for i in 0 ..< v.len:
    let expVal = exp(float(v[i]) - maxVal)
    result[i] = expVal
    expSum += expVal
  
  for i in 0 ..< v.len:
    result[i] = result[i] / expSum

# ==========================================
# Additional Mathematical Functions
# ==========================================

# Square root (element-wise)
proc sqrt*[T](v: Vector[T]): Vector[float] =
  result = newVector[float](v.len)
  for i in 0 ..< v.len:
    assert float(v[i]) >= 0, "sqrt requires non-negative values"
    result[i] = math.sqrt(float(v[i]))

# Square (element-wise)
proc square*[T](v: Vector[T]): Vector[T] =
  result = newVector[T](v.len)
  for i in 0 ..< v.len:
    result[i] = v[i] * v[i]

# Absolute value (element-wise)
proc abs*[T](v: Vector[T]): Vector[T] =
  result = newVector[T](v.len)
  for i in 0 ..< v.len:
    result[i] = if v[i] < 0: -v[i] else: v[i]

# Exponential (element-wise)
proc exp*[T](v: Vector[T]): Vector[float] =
  result = newVector[float](v.len)
  for i in 0 ..< v.len:
    result[i] = math.exp(float(v[i]))

# Natural logarithm (element-wise)
proc log*[T](v: Vector[T], e: float = math.E): Vector[float] =
  result = newVector[float](v.len)
  for i in 0 ..< v.len:
    let val = float(v[i])
    assert val > 0, "Logarithm requires positive values"
    result[i] = math.log(val, e)

# Base-10 logarithm (element-wise)
proc log10*[T](v: Vector[T]): Vector[float] =
  result = newVector[float](v.len)
  for i in 0 ..< v.len:
    let val = float(v[i])
    assert val > 0, "Logarithm requires positive values"
    result[i] = math.log10(val)

# Power (element-wise)
proc pow*[T](v: Vector[T], exponent: float): Vector[float] =
  result = newVector[float](v.len)
  for i in 0 ..< v.len:
    result[i] = math.pow(float(v[i]), exponent)

# ==========================================
# Functional Operations
# ==========================================

# Apply a function to every element (in-place)
proc apply*[T](v: var Vector[T], f: proc(x: T): T) =
  for i in 0 ..< v.len:
    v[i] = f(v[i])

# Apply a function to every element (returns new Vector)
proc map*[T, R](v: Vector[T], f: proc(x: T): R): Vector[R] =
  result = newVector[R](v.len)
  for i in 0 ..< v.len:
    result[i] = f(v[i])

# Apply a function to every element with index (returns new Vector)
proc mapIdx*[T, R](v: Vector[T], f: proc(idx: int, x: T): R): Vector[R] =
  result = newVector[R](v.len)
  for i in 0 ..< v.len:
    result[i] = f(i, v[i])

# Apply a function to every element with index (in-place)
proc applyIdx*[T](v: var Vector[T], f: proc(idx: int, x: T): T) =
  for i in 0 ..< v.len:
    v[i] = f(i, v[i])

# ==========================================
# Vector Manipulation
# ==========================================

# Concatenate two vectors
proc concat*[T](a, b: Vector[T]): Vector[T] =
  result = newVector[T](a.len + b.len)
  for i in 0 ..< a.len:
    result[i] = a[i]
  for i in 0 ..< b.len:
    result[a.len + i] = b[i]

# Reverse the vector (returns new Vector)
proc reversed*[T](v: Vector[T]): Vector[T] =
  result = newVector[T](v.len)
  for i in 0 ..< v.len:
    result[i] = v[v.len - 1 - i]

# Reverse the vector (in-place)
proc reverse*[T](v: var Vector[T]) =
  for i in 0 ..< (v.len div 2) - 1:
    let j = v.len - 1 - i
    swap(v[i], v[j])

# Sort the vector (in-place)
proc sort*[T](v: var Vector[T]) =
  v.items.sort()

# Sort the vector (returns new Vector)
proc sorted*[T](v: Vector[T]): Vector[T] =
  result = v.copy()
  result.items.sort()

# ==========================================
# Conversion to seq
# ==========================================

# Convert Vector to seq
proc toSeq*[T](v: Vector[T]): seq[T] =
  result = v.items

# ==========================================
# Demo Main Block
# ==========================================
when isMainModule:
  var v = createVector([1, 2, 3, 4, 5])
  
  # 1. In-place modification
  v += 10 
  echo "In-place += 10: ", v  # Output: [11, 12, 13, 14, 15]
  
  # 2. Vector conditional mask tracking
  let mask = v > 12
  echo "Mask (v > 12):  ", mask # Output: [false, false, true, true, true]
  
  # 3. Filtering using boolean masks (v[v > 12])
  let filtered = v[v > 12]
  echo "Filtered vector: ", filtered # Output: [13, 14, 15]
  
  # 4. Reductions
  echo "Sum:  ", v.sum()   # Output: 65
  echo "Mean: ", v.mean()  # Output: 13.0
  echo "Max:  ", v.max()   # Output: 15
  
  # 5. Advanced Mathematical Functions
  let original = createVector([1.0, 2.0, 3.0, 4.0, 5.0])
  echo "\n--- Advanced Mathematical Functions ---"
  echo "Original: ", original
  
  echo "tanh: ", original.tanh()
  echo "sqrt: ", original.sqrt()
  echo "square: ", original.square()
  echo "exp: ", original.exp()
  echo "log: ", original.log()
  echo "log10: ", original.log10()
  echo "pow(2.0): ", original.pow(2.0)
  echo "abs: ", createVector([-1.0, -2.0, 3.0, -4.0, 5.0]).abs()
  
  echo "Cubic Mean: ", original.cubicMean()
  echo "Harmonic Mean: ", original.harmonicMean()
  echo "Geometric Mean: ", original.geometricMean()
  
  let softmaxResult = original.softmax()
  echo "Softmax: ", softmaxResult
  echo "Softmax sum: ", softmaxResult.sum()
  
  # 6. Apply and Map functions
  echo "\n--- Apply and Map Functions ---"
  var v2 = createVector([1.0, 2.0, 3.0, 4.0, 5.0])
  echo "Original: ", v2
  
  # In-place apply
  v2.apply(proc(x: float): float = x * 2)
  echo "After apply(x * 2): ", v2
  
  # Map to new vector
  let mapped = v2.map(proc(x: float): float = x + 1)
  echo "After map(x + 1): ", mapped
  
  # Map with index
  let mappedIdx = v2.mapIdx(proc(idx: int, x: float): float = x + float(idx))
  echo "After mapIdx(x + idx): ", mappedIdx
  
  # Apply with index
  v2.applyIdx(proc(idx: int, x: float): float = x * float(idx + 1))
  echo "After applyIdx(x * (idx+1)): ", v2
  
  # 7. Vector Manipulation
  echo "\n--- Vector Manipulation ---"
  let v3 = createVector([1, 2, 3])
  let v4 = createVector([4, 5, 6])
  echo "v3: ", v3
  echo "v4: ", v4
  echo "concat: ", v3.concat(v4)
  echo "reversed: ", v3.reversed()
  
  var v5 = createVector([5, 3, 1, 4, 2])
  echo "Unsorted: ", v5
  v5.sort()
  echo "Sorted (in-place): ", v5
  
  let v6 = createVector([9, 7, 5, 3, 1])
  echo "v6: ", v6
  echo "Sorted copy: ", v6.sorted()
  echo "v6 unchanged: ", v6
  
  # 8. Copy demonstrations
  echo "\n--- Copy Demonstrations ---"
  let v7 = createVector([10, 20, 30, 40, 50])
  echo "Original v7: ", v7
  
  # Shallow copy (same reference)
  let v7Shallow = v7.shallowCopy()
  echo "Shallow copy: ", v7Shallow
  v7Shallow[0] = 999
  echo "After modifying shallow copy:"
  echo "  v7: ", v7
  echo "  v7Shallow: ", v7Shallow
  echo "  (Both changed because they reference the same data)"
  
  # Deep copy (independent)
  let v7Deep = v7.copy()
  echo "\nDeep copy: ", v7Deep
  v7Deep[0] = 888
  echo "After modifying deep copy:"
  echo "  v7: ", v7
  echo "  v7Deep: ", v7Deep
  echo "  (Only the deep copy changed because it's independent)"
  
  # Clone (alias for copy)
  let v7Clone = v7.clone()
  echo "\nClone: ", v7Clone
  v7Clone[0] = 777
  echo "After modifying clone:"
  echo "  v7: ", v7
  echo "  v7Clone: ", v7Clone
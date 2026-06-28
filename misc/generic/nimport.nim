# math_utils.nim
import nimpy

# The exportpy pragma tells Nim to make this function visible to Python
proc fast_fibonacci(n: int): int {.exportpy.} =
  if n <= 1:
    return n
  
  var prev = 0
  var curr = 1
  
  for i in 2 .. n:
    let next = prev + curr
    prev = curr
    curr = next
    
  return curr
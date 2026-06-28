# main.py
import nimporter  # This hooks into the import system
import misc.nimport as nimport  # Imports math_utils.nim directly!

def main():
    # Call the compiled Nim function seamlessly
    number = 40
    result = nimport.fast_fibonacci(number)
    
    print(f"The {number}th Fibonacci number is: {result}")

if __name__ == "__main__":
    main()

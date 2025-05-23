print("Hello")
print("2 + 3 =", 2 + 3)
print("10 - 4 =", 10 - 4)
print("5 * 6 =", 5 * 6)
print("20 / 4 =", 20 / 4)

# A simple Python program demonstrating classes, methods, loops, and user input

class Calculator:
    def add(self, a, b):
        return a + b

    def subtract(self, a, b):
        return a - b

    def multiply(self, a, b):
        return a * b

    def divide(self, a, b):
        if b == 0:
            return "Cannot divide by zero"
        return a / b

calc = Calculator()

print("Welcome to the Python Calculator!")
results = []  # List to store results

while True:
    print("\nChoose operation: add, subtract, multiply, divide, or exit")
    op = input("Operation: ").strip().lower()

    if op == "exit":
        break

    try:
        a = float(input("Enter first number: "))
        b = float(input("Enter second number: "))
    except ValueError:
        print("Invalid input. Please enter numbers.")
        continue

    if op == "add":
        result = calc.add(a, b)
    elif op == "subtract":
        result = calc.subtract(a, b)
    elif op == "multiply":
        result = calc.multiply(a, b)
    elif op == "divide":
        result = calc.divide(a, b)
    else:
        result = "Unknown operation"

    results.append(f"Operation: {op}, Numbers: {a}, {b}, Result: {result}")
    print("Result:", result)

print("\nAll Results:")
for r in results:
    print(r)

print("Goodbye!")

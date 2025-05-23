println("Hello")
println("2 + 3 = ", 2 + 3)
println("10 - 4 = ", 10 - 4)
println("5 * 6 = ", 5 * 6)
println("20 / 4 = ", 20 / 4)

# A simple Julia program demonstrating structs, methods, loops, and user input

struct Calculator
end

function add(::Calculator, a, b)
    a + b
end

function subtract(::Calculator, a, b)
    a - b
end

function multiply(::Calculator, a, b)
    a * b
end

function divide(::Calculator, a, b)
    b == 0 && return "Cannot divide by zero"
    a / b
end

calc = Calculator()

println("Welcome to the Julia Calculator!")
results = String[]  # Array to store results

while true
    println("\nChoose operation: add, subtract, multiply, divide, or exit")
    print("Operation: ")
    op = lowercase(strip(readline()))

    if op == "exit"
        break
    end

    try
        print("Enter first number: ")
        a = parse(Float64, readline())
        print("Enter second number: ")
        b = parse(Float64, readline())
    catch
        println("Invalid input. Please enter numbers.")
        continue
    end

    result = if op == "add"
        add(calc, a, b)
    elseif op == "subtract"
        subtract(calc, a, b)
    elseif op == "multiply"
        multiply(calc, a, b)
    elseif op == "divide"
        divide(calc, a, b)
    else
        "Unknown operation"
    end

    push!(results, "Operation: $op, Numbers: $a, $b, Result: $result")
    println("Result: ", result)
end

println("\nAll Results:")
for r in results
    println(r)
end

println("Goodbye!")
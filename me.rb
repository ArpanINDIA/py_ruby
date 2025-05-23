puts "hello"
puts "2 + 3 = #{2 + 3}"
puts "10 - 4 = #{10 - 4}"
puts "5 * 6 = #{5 * 6}"
puts "20 / 4 = #{20 / 4}"

# A simple Ruby program demonstrating classes, methods, loops, and user input

class Calculator
  def add(a, b)
    a + b
  end

  def subtract(a, b)
    a - b
  end

  def multiply(a, b)
    a * b
  end

  def divide(a, b)
    return "Cannot divide by zero" if b == 0
    a.to_f / b
  end
end

calc = Calculator.new

puts "Welcome to the Ruby Calculator!"
# results: Array
# An array used to store the results of computations or operations.
results = []  # Array to store results

loop do
  puts "\nChoose operation: add, subtract, multiply, divide, or exit"
  print "Operation: "
  op = gets.chomp.strip.downcase

  break if op == "exit"

  print "Enter first number: "
  a = gets.chomp.to_f
  print "Enter second number: "
  b = gets.chomp.to_f

  result = case op
           when "add"
             calc.add(a, b)
           when "subtract"
             calc.subtract(a, b)
           when "multiply"
             calc.multiply(a, b)
           when "divide"
             calc.divide(a, b)
           else
             "Unknown operation"
           end

  results << "Operation: #{op}, Numbers: #{a}, #{b}, Result: #{result}"  # Store in array
  puts "Result: #{result}"
end

puts "\nAll Results:"
results.each { |r| puts r }

puts "Goodbye!"
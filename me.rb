puts "hello"
puts "2 + 3 = #{2 + 3}"
puts "10 - 4 = #{10 - 4}"
puts "5 * 6 = #{5 * 6}"
puts "20 / 4 = #{20 / 4}"

class Calculator
  def add(a, b); a + b; end
  def subtract(a, b); a - b; end
  def multiply(a, b); a * b; end
  def divide(a, b); return "Cannot divide by zero" if b == 0; a.to_f / b; end
  def power(a, b); a**b; end
  def modulus(a, b); return "Cannot modulus by zero" if b == 0; a % b; end
  def sqrt(a); return "Cannot take sqrt of negative" if a < 0; Math.sqrt(a); end
  def abs(a); a.abs; end
  def max(a, b); [a, b].max; end
  def min(a, b); [a, b].min; end
end

calc = Calculator.new
results = []

operations = {
  "add" => 2, "subtract" => 2, "multiply" => 2, "divide" => 2,
  "power" => 2, "modulus" => 2, "sqrt" => 1, "abs" => 1, "max" => 2, "min" => 2
}

puts "Welcome to the Ruby Calculator!"

loop do
  puts "\nChoose operation: #{operations.keys.join(', ')}, or exit"
  print "Operation: "
  op = gets.chomp.strip.downcase

  break if op == "exit"

  unless operations.key?(op)
    puts "Unknown operation"
    next
  end

  args = []
  if operations[op] == 2
    print "Enter first number: "
    args << gets.chomp.to_f
    print "Enter second number: "
    args << gets.chomp.to_f
  elsif operations[op] == 1
    print "Enter number: "
    args << gets.chomp.to_f
  end

  result = calc.send(op, *args)
  results << "Operation: #{op}, Numbers: #{args.join(', ')}, Result: #{result}"
  puts "Result: #{result}"
end

puts "\nAll Results:"
results.each { |r| puts r }
puts "Goodbye!"
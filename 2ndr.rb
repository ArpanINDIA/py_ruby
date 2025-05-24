def data_entry
  # Initialize an empty array to store the entries
  entries = []
  
  puts "Welcome to the Data Entry System"
  puts "--------------------------------"
  
  loop do
    # Initialize a hash for the current entry
    entry = {}
    
    puts "\nNew Entry (leave any field blank to finish)"
    
    # Get user input for each field
    print "Name: "
    entry[:name] = gets.chomp.strip
    
    # Exit if name is blank (assuming name is required)
    break if entry[:name].empty?
    
    print "Age: "
    entry[:age] = gets.chomp.strip
    
    print "Email: "
    entry[:email] = gets.chomp.strip
    
    print "Address: "
    entry[:address] = gets.chomp.strip
    
    # Add the entry to the entries array
    entries << entry
    
    puts "\nEntry added successfully!"
    print "Add another entry? (y/n): "
    continue = gets.chomp.downcase
    break unless continue == 'y'
  end
  
  puts "\nData Entry Complete. Here's your data:"
  puts "--------------------------------------"
  
  # Display all entries
  entries.each_with_index do |entry, index|
    puts "\nEntry #{index + 1}:"
    entry.each { |key, value| puts "#{key.capitalize}: #{value}" }
  end
  
  # Return the entries array
  entries
end

# Call the function to start data entry
data_entry
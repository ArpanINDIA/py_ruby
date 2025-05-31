# -----------------------------------------------------------------------------
# DataEntrySystem v2.0
# A simple command-line Ruby application for collecting and summarizing user data.
# Users are prompted to enter their name, age, email, and address for each entry.
# Entries are collected in a loop until the user leaves the name blank.
# The system validates age input, allows multiple entries, and displays a summary.
# -----------------------------------------------------------------------------

class DataEntrySystem
  def initialize
    @entries = []
    @prompts = {
      name: "Full Name",
      age: "Age",
      email: "Email Address",
      address: "Physical Address"
    }
  end

  def run
    display_welcome
    collect_entries
    display_summary
    @entries
  end

  private

  def display_welcome
    puts "\n╔════════════════════════════════════╗"
    puts "║      DATA ENTRY SYSTEM v2.0       ║"
    puts "╚════════════════════════════════════╝"
    puts "\nInstructions:"
    puts "- Complete all fields for each entry"
    puts "- Leave name blank to finish\n\n"
  end

  def collect_entries
    loop do
      entry = collect_single_entry
      break if entry.nil?

      @entries << entry
      puts "\n✓ Entry added successfully!"
      break unless continue?
    end
  end

  def collect_single_entry
    puts "\n#{' NEW ENTRY '.center(40, '─')}"
    
    entry = {}
    @prompts.each do |field, prompt|
      print "#{prompt}: "
      input = gets.chomp.strip
      
      # Exit if name is blank
      return nil if field == :name && input.empty?
      
      # Validate age if provided
      if field == :age && !input.empty?
        unless input =~ /^\d+$/
          puts "⚠️ Age must be a number. Please enter Age."
          redo
        end
      end
      
      entry[field] = input.empty? ? "N/A" : input
    end
    
    entry
  end

  def continue?
    print "\nAdd another entry? (y/n): "
    gets.chomp.downcase == 'y'
  end

  def display_summary
    return if @entries.empty?

    puts "\n#{' DATA SUMMARY '.center(40, '═')}"
    @entries.each_with_index do |entry, index|
      puts "\n#{ "Entry #{index + 1}".center(40, '─') }"
      entry.each do |field, value|
        puts "• #{@prompts[field] || field.to_s.capitalize}: #{value}"
      end
    end
    puts "\nTotal entries: #{@entries.size}".center(40)
  end
end

# Run the program
DataEntrySystem.new.run
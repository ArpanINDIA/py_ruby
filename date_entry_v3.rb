# before run this code install this -- gem install tty-prompt tty-table colorize
# -----------------------------------------------------------------------------
# DataEntrySystem v3.0
# An enhanced command-line Ruby application for collecting and managing user data.
# Features improved validation, better UI, data persistence, and more options.
# -----------------------------------------------------------------------------

require 'tty-prompt'
require 'tty-table'
require 'json'
require 'colorize'

class DataEntrySystem
  def initialize
    @entries = []
    @prompt = TTY::Prompt.new
    @data_file = 'user_data.json'
    load_entries
  end

  def run
    display_welcome
    main_menu
    display_goodbye
  end

  private

  def display_welcome
    system 'clear' || 'cls'
    puts "\n#{' DATA ENTRY SYSTEM v3.0 '.center(50, '═').bold}"
    puts "\nA modern solution for collecting and managing user information".light_black
  end

  def display_goodbye
    puts "\n#{' Thank you for using DataEntrySystem! '.center(50, '═').bold}"
    puts "Your data has been safely stored.".light_black
  end

  def main_menu
    loop do
      choice = @prompt.select("\nMain Menu:".bold, cycle: true) do |menu|
        menu.choice 'Add New Entry', 1
        menu.choice 'View All Entries', 2
        menu.choice 'Search Entries', 3
        menu.choice 'Export Data', 4
        menu.choice 'Exit', 5
      end

      case choice
      when 1 then add_new_entry
      when 2 then display_all_entries
      when 3 then search_entries
      when 4 then export_data
      when 5 then break
      end
    end
  end

  def add_new_entry
    loop do
      system 'clear' || 'cls'
      puts "\n#{' NEW ENTRY FORM '.center(50, '─').bold}"

      entry = {
        name: @prompt.ask('Full Name:'.bold) do |q|
          q.required true
          q.modify :strip
        end,
        
        age: @prompt.ask('Age:'.bold) do |q|
          q.validate(/^\d+$/, "Invalid age! Please enter numbers only")
          q.modify :strip
        end,
        
        email: @prompt.ask('Email Address:'.bold) do |q|
          q.validate(/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i, "Invalid email format!")
          q.modify :strip
        end,
        
        address: @prompt.ask('Physical Address:'.bold, default: 'N/A') do |q|
          q.modify :strip
        end,
        
        timestamp: Time.now.strftime("%Y-%m-%d %H:%M:%S")
      }

      @entries << entry
      save_entries
      
      puts "\n✓ Entry added successfully!".green
      break unless @prompt.yes?('Add another entry?')
    end
  end

  def display_all_entries
    system 'clear' || 'cls'
    if @entries.empty?
      puts "\nNo entries found. Please add some data first.".yellow
      return
    end

    puts "\n#{' ALL ENTRIES '.center(50, '═').bold}"
    
    table = TTY::Table.new(
      header: ['#', 'Name', 'Age', 'Email', 'Address', 'Added On']
    ) do |t|
      @entries.each_with_index do |entry, index|
        t << [
          index + 1,
          entry[:name],
          entry[:age],
          entry[:email],
          entry[:address].split(', ').first,
          entry[:timestamp]
        ]
      end
    end

    puts table.render(:unicode, padding: [0, 1], resize: true)
    @prompt.keypress("Press any key to continue...")
  end

  def search_entries
    system 'clear' || 'cls'
    if @entries.empty?
      puts "\nNo entries found. Please add some data first.".yellow
      return
    end

    search_term = @prompt.ask('Search by name, email, or address:'.bold) do |q|
      q.modify :strip, :down
    end

    results = @entries.select do |entry|
      entry[:name].downcase.include?(search_term) ||
      entry[:email].downcase.include?(search_term) ||
      entry[:address].downcase.include?(search_term)
    end

    display_search_results(results)
  end

  def display_search_results(results)
    system 'clear' || 'cls'
    if results.empty?
      puts "\nNo matching entries found.".yellow
      return
    end

    puts "\n#{' SEARCH RESULTS '.center(50, '═').bold}"
    
    table = TTY::Table.new(
      header: ['#', 'Name', 'Age', 'Email', 'Address']
    ) do |t|
      results.each_with_index do |entry, index|
        t << [
          index + 1,
          entry[:name],
          entry[:age],
          entry[:email],
          entry[:address].split(', ').first
        ]
      end
    end

    puts table.render(:unicode, padding: [0, 1], resize: true)
    @prompt.keypress("Press any key to continue...")
  end

  def export_data
    choices = [
      { name: 'JSON', value: :json },
      { name: 'CSV', value: :csv },
      { name: 'Cancel', value: :cancel }
    ]
    
    format = @prompt.select("Select export format:", choices)
    
    case format
    when :json
      File.write('export.json', JSON.pretty_generate(@entries))
      puts "\n✓ Data exported to export.json".green
    when :csv
      require 'csv'
      CSV.open('export.csv', 'w') do |csv|
        csv << @entries.first.keys
        @entries.each { |entry| csv << entry.values }
      end
      puts "\n✓ Data exported to export.csv".green
    end
    
    @prompt.keypress("Press any key to continue...")
  end

  def save_entries
    File.write(@data_file, JSON.pretty_generate(@entries))
  end

  def load_entries
    @entries = JSON.parse(File.read(@data_file), symbolize_names: true) if File.exist?(@data_file)
  rescue JSON::ParserError, Errno::ENOENT
    @entries = []
  end
end

# Run the program
begin
  DataEntrySystem.new.run
rescue Interrupt
  puts "\n\nOperation cancelled by user. Goodbye!".red
end
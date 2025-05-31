require 'tty-prompt'
require 'tty-table'
require 'json'
require 'colorize'
require 'tty-cursor'

class DataEntrySystem
  def initialize
    @entries = []
    @prompt = TTY::Prompt.new
    @data_file = 'user_data.json'
    @cursor = TTY::Cursor
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
        menu.choice 'Edit Entry', 4
        menu.choice 'Export Data', 5
        menu.choice 'Exit', 6
      end

      case choice
      when 1 then add_new_entry
      when 2 then display_all_entries
      when 3 then search_entries_menu
      when 4 then edit_entry
      when 5 then export_data
      when 6 then break
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

  def search_entries_menu
    loop do
      system 'clear' || 'cls'
      search_choice = @prompt.select("\nSearch by:".bold, cycle: true) do |menu|
        menu.choice 'Name/Email/Address', 1
        menu.choice 'Age Range', 2
        menu.choice 'Return to Main Menu', 3
      end

      case search_choice
      when 1 then search_entries
      when 2 then search_by_age_range
      when 3 then break
      end
    end
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

  def search_by_age_range
    system 'clear' || 'cls'
    if @entries.empty?
      puts "\nNo entries found. Please add some data first.".yellow
      return
    end

    min_age = @prompt.ask('Minimum age:', default: '0') do |q|
      q.validate(/^\d+$/, "Invalid age! Please enter numbers only")
      q.convert :int
    end

    max_age = @prompt.ask('Maximum age:', default: '100') do |q|
      q.validate(/^\d+$/, "Invalid age! Please enter numbers only")
      q.convert :int
      q.validate(->(input) { input >= min_age }, "Maximum age must be >= minimum age")
    end

    results = @entries.select do |entry|
      age = entry[:age].to_i
      age >= min_age && age <= max_age
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

  def edit_entry
    system 'clear' || 'cls'
    if @entries.empty?
      puts "\nNo entries found. Please add some data first.".yellow
      return
    end

    choices = @entries.map.with_index do |entry, index|
      { name: "#{index + 1}. #{entry[:name]} (Age: #{entry[:age]}, Email: #{entry[:email]})", value: index }
    end

    index = @prompt.select("Select entry to edit:", choices, per_page: 10, filter: true)
    entry = @entries[index]

    puts "\n#{' EDIT ENTRY '.center(50, '─').bold}"
    puts "Use arrow keys to navigate, Enter to select, Esc to cancel"

    fields = [
      { name: 'Name', value: :name, current: entry[:name] },
      { name: 'Age', value: :age, current: entry[:age] },
      { name: 'Email', value: :email, current: entry[:email] },
      { name: 'Address', value: :address, current: entry[:address] },
      { name: 'Save Changes', value: :save },
      { name: 'Cancel', value: :cancel }
    ]

    current_selection = 0
    editing = true

    while editing
      system 'clear' || 'cls'
      puts "\n#{' EDIT ENTRY '.center(50, '─').bold}"
      puts "Editing: #{entry[:name]} (ID: #{index + 1})".light_black

      fields.each_with_index do |field, i|
        prefix = i == current_selection ? '→ ' : '  '
        if field[:value] == :save || field[:value] == :cancel
          puts "#{prefix}#{field[:name]}"
        else
          puts "#{prefix}#{field[:name]}: #{field[:current].to_s.yellow}"
        end
      end

      input = STDIN.getch
      case input
      when "\e[A" # Up arrow
        current_selection = (current_selection - 1) % fields.size
      when "\e[B" # Down arrow
        current_selection = (current_selection + 1) % fields.size
      when "\r" # Enter
        selected = fields[current_selection]
        case selected[:value]
        when :save
          @entries[index] = entry.merge(
            name: fields.find { |f| f[:value] == :name }[:current],
            age: fields.find { |f| f[:value] == :age }[:current],
            email: fields.find { |f| f[:value] == :email }[:current],
            address: fields.find { |f| f[:value] == :address }[:current],
            timestamp: Time.now.strftime("%Y-%m-%d %H:%M:%S")
          )
          save_entries
          puts "\n✓ Entry updated successfully!".green
          editing = false
        when :cancel
          editing = false
        else
          new_value = @prompt.ask("New #{selected[:name]}:", default: selected[:current].to_s) do |q|
            q.validate(/^\d+$/, "Invalid age! Please enter numbers only") if selected[:value] == :age
            q.validate(/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i, "Invalid email format!") if selected[:value] == :email
          end
          fields[current_selection][:current] = new_value
        end
      when "\e" # Escape
        editing = false
      end
    end
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
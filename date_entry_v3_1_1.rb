require 'tty-prompt'
require 'tty-table'
require 'json'
require 'colorize'
require 'tty-cursor'

class DataEntrySystem
  def initialize
    @prompt = TTY::Prompt.new
    @data_file = 'user_data.json'
    @cursor = TTY::Cursor
    @entries = load_entries
  end

  def run
    display_welcome
    main_menu
    display_goodbye
  end

  private

  def display_welcome
    clear_screen
    puts "\n#{' DATA ENTRY SYSTEM v3.1 '.center(50, '═').bold}"
    puts "\nFast and efficient data management".light_black
  end

  def display_goodbye
    puts "\n#{' Thank you for using DataEntrySystem! '.center(50, '═').bold}"
  end

  def clear_screen
    system('clear') || system('cls')
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
      clear_screen
      puts "\n#{' NEW ENTRY FORM '.center(50, '─').bold}"

      entry = {
        name: ask_required('Full Name:'.bold),
        age: ask_age,
        email: ask_email,
        address: @prompt.ask('Physical Address:'.bold, default: 'N/A', &method(:strip_input)),
        timestamp: Time.now.strftime("%Y-%m-%d %H:%M:%S")
      }

      @entries << entry
      save_entries
      
      puts "\n✓ Entry added successfully!".green
      break unless @prompt.yes?('Add another entry?')
    end
  end

  def ask_required(question)
    @prompt.ask(question) do |q|
      q.required true
      q.modify :strip
    end
  end

  def ask_age
    @prompt.ask('Age:'.bold) do |q|
      q.validate(/^\d+$/, "Invalid age! Please enter numbers only")
      q.modify :strip
    end
  end

  def ask_email
    @prompt.ask('Email Address:'.bold) do |q|
      q.validate(/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i, "Invalid email format!")
      q.modify :strip
    end
  end

  def strip_input(q)
    q.modify :strip
  end

  def display_all_entries
    clear_screen
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
      clear_screen
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
    clear_screen
    return no_entries_message if @entries.empty?

    search_term = @prompt.ask('Search by name, email, or address:'.bold, &method(:downcase_input))
    results = @entries.select do |entry|
      entry[:name].downcase.include?(search_term) ||
      entry[:email].downcase.include?(search_term) ||
      entry[:address].downcase.include?(search_term)
    end

    display_search_results(results)
  end

  def downcase_input(q)
    q.modify :strip, :down
  end

  def search_by_age_range
    clear_screen
    return no_entries_message if @entries.empty?

    min_age = @prompt.ask('Minimum age:', default: '0', convert: :int) do |q|
      q.validate(/^\d+$/, "Invalid age! Please enter numbers only")
    end

    max_age = @prompt.ask('Maximum age:', default: '100', convert: :int) do |q|
      q.validate(/^\d+$/, "Invalid age! Please enter numbers only")
      q.validate(->(input) { input >= min_age }, "Maximum age must be >= minimum age")
    end

    results = @entries.each_with_object([]) do |entry, arr|
      age = entry[:age].to_i
      arr << entry if age >= min_age && age <= max_age
    end

    display_search_results(results)
  end

  def no_entries_message
    puts "\nNo entries found. Please add some data first.".yellow
    @prompt.keypress("Press any key to continue...")
  end

  def display_search_results(results)
    clear_screen
    if results.empty?
      puts "\nNo matching entries found.".yellow
      return @prompt.keypress("Press any key to continue...")
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
    clear_screen
    return no_entries_message if @entries.empty?

    index = select_entry_to_edit
    return if index.nil?

    entry = @entries[index]
    fields = setup_edit_fields(entry)

    edit_loop(entry, index, fields)
  end

  def select_entry_to_edit
    choices = @entries.map.with_index do |entry, index|
      { name: "#{index + 1}. #{entry[:name]} (Age: #{entry[:age]}, Email: #{entry[:email]})", value: index }
    end

    @prompt.select("Select entry to edit:", choices, per_page: 10, filter: true)
  end

  def setup_edit_fields(entry)
    [
      { name: 'Name', value: :name, current: entry[:name] },
      { name: 'Age', value: :age, current: entry[:age] },
      { name: 'Email', value: :email, current: entry[:email] },
      { name: 'Address', value: :address, current: entry[:address] },
      { name: 'Save Changes', value: :save },
      { name: 'Cancel', value: :cancel }
    ]
  end

  def edit_loop(entry, index, fields)
    current_selection = 0
    editing = true

    while editing
      clear_screen
      render_edit_screen(entry, index, fields, current_selection)

      case STDIN.getch
      when "\e[A" then current_selection = (current_selection - 1) % fields.size # Up
      when "\e[B" then current_selection = (current_selection + 1) % fields.size # Down
      when "\r" then editing = handle_enter(fields, current_selection, entry, index)
      when "\e" then editing = false # Escape
      end
    end
  end

  def render_edit_screen(entry, index, fields, current_selection)
    puts "\n#{' EDIT ENTRY '.center(50, '─').bold}"
    puts "Editing: #{entry[:name]} (ID: #{index + 1})".light_black

    fields.each_with_index do |field, i|
      prefix = i == current_selection ? '→ ' : '  '
      if [:save, :cancel].include?(field[:value])
        puts "#{prefix}#{field[:name]}"
      else
        puts "#{prefix}#{field[:name]}: #{field[:current].to_s.yellow}"
      end
    end
  end

  def handle_enter(fields, current_selection, entry, index)
    selected = fields[current_selection]
    case selected[:value]
    when :save
      save_edited_entry(entry, index, fields)
      false
    when :cancel
      false
    else
      edit_field(selected)
      true
    end
  end

  def save_edited_entry(entry, index, fields)
    @entries[index] = entry.merge(
      name: fields.find { |f| f[:value] == :name }[:current],
      age: fields.find { |f| f[:value] == :age }[:current],
      email: fields.find { |f| f[:value] == :email }[:current],
      address: fields.find { |f| f[:value] == :address }[:current],
      timestamp: Time.now.strftime("%Y-%m-%d %H:%M:%S")
    )
    save_entries
    puts "\n✓ Entry updated successfully!".green
    @prompt.keypress("Press any key to continue...")
  end

  def edit_field(field)
    case field[:value]
    when :age
      field[:current] = ask_age
    when :email
      field[:current] = ask_email
    else
      field[:current] = @prompt.ask("New #{field[:name]}:", default: field[:current].to_s)
    end
  end

  def export_data
    format = @prompt.select("Select export format:", 
      ['JSON', 'CSV', 'Cancel'], 
      symbols: { marker: '>' }
    )

    case format
    when 'JSON'
      File.write('export.json', JSON.pretty_generate(@entries))
      puts "\n✓ Data exported to export.json".green
    when 'CSV'
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
    return [] unless File.exist?(@data_file)
    JSON.parse(File.read(@data_file), symbolize_names: true)
  rescue JSON::ParserError
    puts "\n⚠️ Corrupted data file. Starting with empty dataset.".red
    []
  end
end

begin
  DataEntrySystem.new.run
rescue Interrupt
  puts "\n\nOperation cancelled by user. Goodbye!".red
end
require 'tty-prompt'
require 'tty-table'
require 'json'
require 'colorize'
require 'tty-cursor'
require 'io/console'
require 'securerandom'

class DataEntrySystem
  def initialize
    @prompt = TTY::Prompt.new
    @data_file = 'user_data.json'
    @backup_file = 'user_data_backup.json'
    @cursor = TTY::Cursor
    @entries = load_entries
  end

  def run
    display_welcome
    main_menu
    display_goodbye
  rescue Interrupt
    puts "\n\nOperation cancelled by user. Goodbye!".red
  rescue => e
    puts "\nAn unexpected error occurred: #{e.message}".red
    puts e.backtrace if ENV['DEBUG']
    @prompt.keypress("Press any key to exit...")
  end

  private

  def load_entries
    return [] unless File.exist?(@data_file)
    
    begin
      data = File.read(@data_file)
      JSON.parse(data, symbolize_names: true).map do |entry|
        # Ensure all entries have UUIDs (backward compatibility)
        entry[:id] ||= SecureRandom.uuid
        entry
      end
    rescue JSON::ParserError
      attempt_data_recovery
    end
  end

  def attempt_data_recovery
    if File.exist?(@backup_file)
      puts "Main data file corrupted. Attempting to restore from backup...".yellow
      begin
        backup_data = File.read(@backup_file)
        entries = JSON.parse(backup_data, symbolize_names: true)
        File.write(@data_file, JSON.pretty_generate(entries))
        puts "Restored from backup successfully.".green
        entries
      rescue
        puts "Backup file also corrupted. Starting with empty dataset.".red
        []
      end
    else
      puts "Data file corrupted and no backup available. Starting with empty list.".red
      []
    end
  end

  def display_welcome
    clear_screen
    puts " WELCOME TO DATA ENTRY SYSTEM ".center(80, '=').bold.on_blue
    puts "\nManage your data with this simple console application".center(80)
    puts "\nPress any key to continue..."
    STDIN.getch
  end

  def display_goodbye
    clear_screen
    puts " THANK YOU FOR USING OUR SYSTEM ".center(80, '=').bold.on_green
    puts "\nYour data has been saved successfully".center(80)
    puts "\nGoodbye!".center(80)
  end

  def clear_screen
    print @cursor.clear_screen
    print @cursor.move_to(0, 0)
  end

  def main_menu
    loop do
      clear_screen
      choice = @prompt.select("\nMAIN MENU".bold.blue, cycle: true) do |menu|
        menu.choice 'Add New Entry', 1
        menu.choice 'View/Search Entries', 2
        menu.choice 'Edit Entry', 3
        menu.choice 'Delete Entry', 4
        menu.choice 'Backup/Restore Data', 5
        menu.choice 'Exit', 6
      end

      case choice
      when 1 then add_entry
      when 2 then view_entries_menu
      when 3 then edit_entry
      when 4 then delete_entry
      when 5 then backup_restore_menu
      when 6 then break
      end
    end
  end

  def add_entry
    clear_screen
    puts "\n ADD NEW ENTRY ".center(80, '-').bold

    entry = {
      id: SecureRandom.uuid,
      timestamp: Time.now.strftime("%Y-%m-%d %H:%M:%S")
    }

    entry[:name] = @prompt.ask("Full Name:") do |q|
      q.required true
      q.validate ->(input) { input.match?(/^[a-zA-Z\s\-]+$/) }
      q.messages[:valid?] = "Invalid name. Only letters, spaces and hyphens allowed"
      q.modify :strip, :capitalize
    end

    entry[:age] = @prompt.ask("Age:") do |q|
      q.required true
      q.validate(/^\d+$/, "Invalid age! Must be a positive number")
      q.convert :int
      q.in("1-120")
    end

    entry[:email] = @prompt.ask("Email:") do |q|
      q.required true
      q.validate(/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i, "Invalid email format")
      q.modify :strip, :downcase
    end

    entry[:address] = @prompt.ask("Address:") do |q|
      q.modify :strip
      q.validate(/.{5,}/, "Address too short (minimum 5 characters)")
    end || "Not specified"

    @entries << entry
    save_entries

    puts "\n✓ Entry added successfully!".green
    @prompt.keypress("Press any key to continue...")
  end

  def view_entries_menu
    loop do
      clear_screen
      choice = @prompt.select("\nVIEW ENTRIES".bold.blue, cycle: true) do |menu|
        menu.choice 'View All Entries', 1
        menu.choice 'Search Entries', 2
        menu.choice 'Return to Main Menu', 3
      end

      case choice
      when 1 then display_all_entries
      when 2 then search_entries
      when 3 then break
      end
    end
  end

  def display_all_entries(page = 1)
    clear_screen
    return no_entries_message if @entries.empty?

    per_page = 10
    total_pages = (@entries.size.to_f / per_page).ceil
    paginated_entries = @entries.each_slice(per_page).to_a[page - 1] || []

    table = TTY::Table.new(
      header: ["ID", "Name", "Age", "Email", "Address", "Added On"]
    )

    paginated_entries.each do |entry|
      table << [
        entry[:id][0..7], # Display shortened UUID
        entry[:name],
        entry[:age],
        entry[:email].length > 15 ? "#{entry[:email][0..12]}..." : entry[:email],
        entry[:address].length > 20 ? "#{entry[:address][0..17]}..." : entry[:address],
        entry[:timestamp]
      ]
    end

    puts "\nALL ENTRIES (Page #{page}/#{total_pages})".center(80, '-').bold
    puts table.render(:unicode, alignments: [:center, :left, :center, :left, :left, :center], padding: [0, 1])

    if total_pages > 1
      puts "\nNavigation: (N)ext page, (P)revious page, (Q)uit"
      input = STDIN.getch.downcase
      case input
      when 'n' then display_all_entries(page + 1) if page < total_pages
      when 'p' then display_all_entries(page - 1) if page > 1
      when 'q' then return
      else display_all_entries(page)
      end
    else
      @prompt.keypress("Press any key to continue...")
    end
  end

  def search_entries
    clear_screen
    return no_entries_message if @entries.empty?

    term = @prompt.ask("Enter search term (name, email, etc.):") do |q|
      q.modify :strip, :downcase
    end

    results = @entries.select do |entry|
      entry.values.any? { |v| v.to_s.downcase.include?(term) }
    end

    if results.empty?
      puts "\nNo matching entries found.".yellow
    else
      display_search_results(results)
    end

    @prompt.keypress("Press any key to continue...")
  end

  def display_search_results(results)
    table = TTY::Table.new(
      header: ["ID", "Name", "Age", "Email", "Added On"]
    )

    results.each do |entry|
      table << [
        entry[:id][0..7],
        entry[:name],
        entry[:age],
        entry[:email],
        entry[:timestamp]
      ]
    end

    puts "\nSEARCH RESULTS (#{results.size} found)".center(80, '-').bold
    puts table.render(:unicode, alignments: [:center, :left, :center, :left, :center], padding: [0, 1])
  end

  def select_entry(prompt_message)
    return nil if @entries.empty?

    choices = @entries.map.with_index do |entry, index|
      { name: "#{entry[:name]} (ID: #{entry[:id][0..7]}, Email: #{entry[:email]})", value: entry[:id] }
    end

    choices << { name: "Cancel", value: nil }
    @prompt.select(prompt_message, choices, filter: true)
  end

  def edit_entry
    clear_screen
    entry_id = select_entry("Select entry to edit:")
    return unless entry_id

    entry = @entries.find { |e| e[:id] == entry_id }
    original_entry = entry.dup

    loop do
      clear_screen
      puts "\n EDITING ENTRY: #{entry[:name].upcase} ".center(80, '-').bold

      field = @prompt.select("Select field to edit:") do |menu|
        menu.choice "Name: #{entry[:name]}", :name
        menu.choice "Age: #{entry[:age]}", :age
        menu.choice "Email: #{entry[:email]}", :email
        menu.choice "Address: #{entry[:address]}", :address
        menu.choice "Save Changes", :save
        menu.choice "Cancel Editing", :cancel
      end

      case field
      when :name
        entry[:name] = @prompt.ask("New name:", default: entry[:name]) do |q|
          q.validate(/^[a-zA-Z\s\-]+$/, "Invalid name")
          q.modify :strip, :capitalize
        end
      when :age
        entry[:age] = @prompt.ask("New age:", default: entry[:age].to_s) do |q|
          q.validate(/^\d+$/, "Invalid age")
          q.in("1-120")
          q.convert :int
        end
      when :email
        entry[:email] = @prompt.ask("New email:", default: entry[:email]) do |q|
          q.validate(/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i, "Invalid email")
          q.modify :strip, :downcase
        end
      when :address
        entry[:address] = @prompt.ask("New address:", default: entry[:address]) do |q|
          q.modify :strip
        end
      when :save
        entry[:timestamp] = Time.now.strftime("%Y-%m-%d %H:%M:%S")
        save_entries
        puts "\n✓ Changes saved successfully!".green
        @prompt.keypress("Press any key to continue...")
        break
      when :cancel
        if entry != original_entry
          confirm = @prompt.yes?("Discard changes?")
          if confirm
            @entries[@entries.find_index { |e| e[:id] == entry_id }] = original_entry
            puts "\nChanges discarded.".yellow
            @prompt.keypress("Press any key to continue...")
          else
            next
          end
        end
        break
      end
    end
  end

  def delete_entry
    clear_screen
    entry_id = select_entry("Select entry to delete:")
    return unless entry_id

    entry = @entries.find { |e| e[:id] == entry_id }
    
    confirm = @prompt.yes?("Are you sure you want to delete #{entry[:name]}'s record? This cannot be undone.".red)
    if confirm
      @entries.reject! { |e| e[:id] == entry_id }
      save_entries
      puts "\n✓ Entry deleted successfully!".green
    else
      puts "\nDeletion cancelled.".yellow
    end

    @prompt.keypress("Press any key to continue...")
  end

  def backup_restore_menu
    loop do
      clear_screen
      choice = @prompt.select("\nBACKUP/RESTORE".bold.blue) do |menu|
        menu.choice 'Create Backup', 1
        menu.choice 'Restore from Backup', 2
        menu.choice 'Return to Main Menu', 3
      end

      case choice
      when 1 then create_backup
      when 2 then restore_from_backup
      when 3 then break
      end
    end
  end

  def create_backup
    FileUtils.cp(@data_file, @backup_file)
    puts "\n✓ Backup created successfully at #{@backup_file}".green
    @prompt.keypress("Press any key to continue...")
  rescue => e
    puts "\nFailed to create backup: #{e.message}".red
    @prompt.keypress("Press any key to continue...")
  end

  def restore_from_backup
    unless File.exist?(@backup_file)
      puts "\nNo backup file found.".yellow
      @prompt.keypress("Press any key to continue...")
      return
    end

    confirm = @prompt.yes?("This will overwrite current data. Are you sure?")
    return unless confirm

    FileUtils.cp(@backup_file, @data_file)
    @entries = load_entries
    puts "\n✓ Data restored successfully from backup".green
    @prompt.keypress("Press any key to continue...")
  rescue => e
    puts "\nFailed to restore backup: #{e.message}".red
    @prompt.keypress("Press any key to continue...")
  end

  def save_entries
    # Create backup before saving
    create_backup unless File.exist?(@backup_file)
    
    File.write(@data_file, JSON.pretty_generate(@entries))
  rescue => e
    puts "\nError saving data: #{e.message}".red
    @prompt.keypress("Press any key to continue...")
    false
  end

  def no_entries_message
    puts "\nNo entries found in the database.".yellow
    @prompt.keypress("Press any key to continue...")
  end
end

# Start the application
begin
  DataEntrySystem.new.run
rescue Interrupt
  puts "\n\nOperation cancelled by user. Goodbye!".red
rescue => e
  puts "\nAn unexpected error occurred: #{e.message}".red
  puts e.backtrace if ENV['DEBUG']
end
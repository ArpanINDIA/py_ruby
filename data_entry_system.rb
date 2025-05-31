# DataEntrySystem v4.0
# Enhanced with editing, pagination, additional export formats, address validation, and authentication
#
# Install dependencies: gem install tty-prompt tty-table colorize axlsx roo
# -----------------------------------------------------------------------------
# =============================================================================
# DataEntrySystem v4.0
#
# A command-line data entry and management system with user authentication,
# admin controls, entry editing, pagination, search, and export features.
# Features:
# - User registration and login (admin/user roles)
# - Add, view, edit, and delete entries (with permissions)
# - Paginated entry viewing
# - Search entries by name, email, or address
# - Export data/search results to JSON, CSV, Excel, or XML
# - Admin panel for user management and system settings
#
# Dependencies: tty-prompt, tty-table, colorize, axlsx, roo
# Install with: gem install tty-prompt tty-table colorize axlsx roo
# =============================================================================



# ...existing code...
require 'tty-prompt'
require 'tty-table'
require 'json'
require 'csv'
require 'colorize'
require 'axlsx'
require 'roo'
require 'fileutils'

class DataEntrySystem
  def initialize
    @prompt = TTY::Prompt.new
    @data_file = 'user_data.json'
    @users_file = 'users.json'
    @current_user = nil
    @entries_per_page = 5
    load_data
  end

  def run
    authenticate
    display_welcome
    main_menu
    display_goodbye
  end

  private

  def load_data
    @entries = File.exist?(@data_file) ? JSON.parse(File.read(@data_file), symbolize_names: true) : []
    @users = File.exist?(@users_file) ? JSON.parse(File.read(@users_file), symbolize_names: true) : []
  rescue JSON::ParserError
    @entries = []
    @users = []
  end

  def save_data
    File.write(@data_file, JSON.pretty_generate(@entries))
    File.write(@users_file, JSON.pretty_generate(@users))
  end

  def authenticate
    loop do
      system 'clear' || 'cls'
      puts "\n#{' AUTHENTICATION '.center(50, '═').bold}"

      choice = @prompt.select('Select option:', ['Login', 'Register', 'Exit'])

      case choice
      when 'Login'
        username = @prompt.ask('Username:'.bold) { |q| q.required(true) }
        password = @prompt.mask('Password:'.bold) { |q| q.required(true) }

        user = @users.find { |u| u[:username] == username && u[:password] == password }
        if user
          @current_user = user
          break
        else
          puts "\nInvalid credentials!".red
          sleep 1
        end

      when 'Register'
        username = @prompt.ask('Choose username:'.bold) do |q|
          q.required(true)
          q.validate(/^[a-zA-Z0-9_]{3,20}$/, "Must be 3-20 chars (letters, numbers, _)")
        end

        if @users.any? { |u| u[:username] == username }
          puts "\nUsername already exists!".red
          sleep 1
          next
        end

        password = @prompt.mask('Choose password:'.bold) do |q|
          q.required(true)
          q.validate(/^.{6,}$/, "Must be at least 6 characters")
        end

        @users << { username: username, password: password, role: 'user' }
        save_data
        puts "\nRegistration successful! Please login.".green
        sleep 1

      when 'Exit'
        exit
      end
    end
  end

  def display_welcome
    system 'clear' || 'cls'
    puts "\n#{' DATA ENTRY SYSTEM v4.0 '.center(50, '═').bold}"
    puts "\nWelcome, #{@current_user[:username].capitalize}!".light_blue
  end

  def display_goodbye
    puts "\n#{' Thank you for using DataEntrySystem! '.center(50, '═').bold}"
    puts "Your data has been safely stored.".light_black
  end

  def main_menu
    loop do
      choices = [
        { name: 'Add New Entry', value: 1 },
        { name: 'View/Edit Entries', value: 2 },
        { name: 'Search Entries', value: 3 },
        { name: 'Export Data', value: 4 }
      ]

      choices << { name: 'Admin Panel', value: 5 } if admin?
      choices << { name: 'Exit', value: 6 }

      choice = @prompt.select("\nMain Menu:".bold, choices, cycle: true)

      case choice
      when 1 then add_new_entry
      when 2 then view_entries_menu
      when 3 then search_entries
      when 4 then export_data
      when 5 then admin_panel if admin?
      when 6 then break
      end
    end
  end

  def admin?
    @current_user[:role] == 'admin'
  end

  def admin_panel
    loop do
      choice = @prompt.select("\nAdmin Panel:".bold, cycle: true) do |menu|
        menu.choice 'Manage Users', 1
        menu.choice 'System Settings', 2
        menu.choice 'Back to Main Menu', 3
      end

      case choice
      when 1 then manage_users
      when 2 then system_settings
      when 3 then break
      end
    end
  end

  def manage_users
    system 'clear' || 'cls'
    puts "\n#{' USER MANAGEMENT '.center(50, '═').bold}"

    if @users.empty?
      puts "\nNo users found.".yellow
      return
    end

    table = TTY::Table.new(
      header: ['#', 'Username', 'Role']
    ) do |t|
      @users.each_with_index do |user, index|
        t << [index + 1, user[:username], user[:role]]
      end
    end

    puts table.render(:unicode, padding: [0, 1], resize: true)

    choice = @prompt.select("\nOptions:", ['Edit User', 'Delete User', 'Back'])
    
    case choice
    when 'Edit User'
      user_idx = @prompt.ask("Enter user number to edit:", convert: :int) { |q| q.in("1-#{@users.size}") } - 1
      user = @users[user_idx]
      
      new_role = @prompt.select("Select new role for #{user[:username]}:", ['user', 'admin'])
      user[:role] = new_role
      save_data
      puts "\nUser updated successfully!".green
      sleep 1

    when 'Delete User'
      user_idx = @prompt.ask("Enter user number to delete:", convert: :int) { |q| q.in("1-#{@users.size}") } - 1
      
      if @prompt.yes?("Are you sure you want to delete #{@users[user_idx][:username]}?")
        @users.delete_at(user_idx)
        save_data
        puts "\nUser deleted successfully!".green
        sleep 1
      end
    end
  end

  def system_settings
    system 'clear' || 'cls'
    puts "\n#{' SYSTEM SETTINGS '.center(50, '═').bold}"

    current_settings = {
      'Entries per page' => @entries_per_page
    }

    setting = @prompt.select("Select setting to change:", current_settings.keys + ['Back'])

    if setting == 'Back'
      return
    else
      new_value = @prompt.ask("Enter new value for #{setting}:") do |q|
        q.required(true)
        q.validate(/^\d+$/, "Must be a number") if setting == 'Entries per page'
      end

      case setting
      when 'Entries per page'
        @entries_per_page = new_value.to_i
        puts "\nSetting updated successfully!".green
        sleep 1
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
          q.modify :strip, :capitalize
        end,
        
        age: @prompt.ask('Age:'.bold) do |q|
          q.validate(/^\d+$/, "Invalid age! Please enter numbers only")
          q.modify :strip
          q.convert :int
          q.in?(1..120, "Age must be between 1-120")
        end,
        
        email: @prompt.ask('Email Address:'.bold) do |q|
          q.validate(/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i, "Invalid email format!")
          q.modify :strip, :down
        end,
        
        address: @prompt.ask('Physical Address (Street, City, State, ZIP):'.bold) do |q|
          q.validate(/\A.+\s*,\s*.+\s*,\s*.+\s*,\s*\d{5}(-\d{4})?\z/i, "Format: Street, City, State, ZIP")
          q.modify :strip, :titleize
        end,
        
        added_by: @current_user[:username],
        timestamp: Time.now.strftime("%Y-%m-%d %H:%M:%S")
      }

      @entries << entry
      save_data
      
      puts "\n✓ Entry added successfully!".green
      break unless @prompt.yes?('Add another entry?')
    end
  end

  def view_entries_menu
    system 'clear' || 'cls'
    if @entries.empty?
      puts "\nNo entries found. Please add some data first.".yellow
      return
    end

    total_pages = (@entries.size.to_f / @entries_per_page).ceil
    current_page = 1

    loop do
      display_entries_page(current_page, total_pages)

      choices = []
      choices << { name: 'Next Page', value: :next } if current_page < total_pages
      choices << { name: 'Previous Page', value: :prev } if current_page > 1
      choices << { name: 'Edit Entry', value: :edit }
      choices << { name: 'Delete Entry', value: :delete }
      choices << { name: 'Back to Menu', value: :back }

      action = @prompt.select("\nSelect action:", choices)

      case action
      when :next then current_page += 1
      when :prev then current_page -= 1
      when :edit then edit_entry(current_page)
      when :delete then delete_entry(current_page)
      when :back then break
      end
    end
  end

  def display_entries_page(page, total_pages)
    system 'clear' || 'cls'
    puts "\n#{' ENTRIES '.center(50, '═').bold}"
    puts "Page #{page} of #{total_pages}".light_black

    start_idx = (page - 1) * @entries_per_page
    end_idx = [start_idx + @entries_per_page - 1, @entries.size - 1].min
    page_entries = @entries[start_idx..end_idx]

    table = TTY::Table.new(
      header: ['#', 'Name', 'Age', 'Email', 'Address', 'Added By']
    ) do |t|
      page_entries.each_with_index do |entry, idx|
        t << [
          start_idx + idx + 1,
          entry[:name],
          entry[:age],
          entry[:email],
          entry[:address].split(', ').first,
          entry[:added_by]
        ]
      end
    end

    puts table.render(:unicode, padding: [0, 1], resize: true)
  end

  def edit_entry(current_page)
    entry_num = @prompt.ask("Enter entry number to edit:", convert: :int) do |q|
      start_idx = (current_page - 1) * @entries_per_page
      end_idx = [start_idx + @entries_per_page - 1, @entries.size - 1].min
      q.in((start_idx + 1)..(end_idx + 1))
    end

    entry = @entries[entry_num - 1]

    # Only allow edit if user is admin or the entry creator
    unless admin? || entry[:added_by] == @current_user[:username]
      puts "\n✗ You can only edit your own entries!".red
      sleep 1
      return
    end

    field = @prompt.select("Select field to edit:", ['Name', 'Age', 'Email', 'Address', 'Cancel'])

    case field
    when 'Name'
      entry[:name] = @prompt.ask('New name:', default: entry[:name]) { |q| q.modify :strip, :capitalize }
    when 'Age'
      entry[:age] = @prompt.ask('New age:', default: entry[:age].to_s) do |q|
        q.validate(/^\d+$/, "Invalid age! Please enter numbers only")
        q.convert :int
        q.in?(1..120, "Age must be between 1-120")
      end
    when 'Email'
      entry[:email] = @prompt.ask('New email:', default: entry[:email]) do |q|
        q.validate(/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i, "Invalid email format!")
        q.modify :strip, :down
      end
    when 'Address'
      entry[:address] = @prompt.ask('New address:', default: entry[:address]) do |q|
        q.validate(/\A.+\s*,\s*.+\s*,\s*.+\s*,\s*\d{5}(-\d{4})?\z/i, "Format: Street, City, State, ZIP")
        q.modify :strip, :titleize
      end
    end

    entry[:timestamp] = Time.now.strftime("%Y-%m-%d %H:%M:%S") unless field == 'Cancel'
    save_data
    puts "\n✓ Entry updated successfully!".green if field != 'Cancel'
    sleep 1
  end

  def delete_entry(current_page)
    entry_num = @prompt.ask("Enter entry number to delete:", convert: :int) do |q|
      start_idx = (current_page - 1) * @entries_per_page
      end_idx = [start_idx + @entries_per_page - 1, @entries.size - 1].min
      q.in((start_idx + 1)..(end_idx + 1))
    end

    entry = @entries[entry_num - 1]

    # Only allow delete if user is admin or the entry creator
    unless admin? || entry[:added_by] == @current_user[:username]
      puts "\n✗ You can only delete your own entries!".red
      sleep 1
      return
    end

    if @prompt.yes?("Are you sure you want to delete this entry?")
      @entries.delete_at(entry_num - 1)
      save_data
      puts "\n✓ Entry deleted successfully!".green
      sleep 1
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

  def display_search_results(results)
    system 'clear' || 'cls'
    if results.empty?
      puts "\nNo matching entries found.".yellow
      @prompt.keypress("Press any key to continue...")
      return
    end

    puts "\n#{' SEARCH RESULTS '.center(50, '═').bold}"
    puts "#{results.size} entries found".light_black
    
    table = TTY::Table.new(
      header: ['#', 'Name', 'Age', 'Email', 'Address', 'Added By']
    ) do |t|
      results.each_with_index do |entry, index|
        t << [
          index + 1,
          entry[:name],
          entry[:age],
          entry[:email],
          entry[:address].split(', ').first,
          entry[:added_by]
        ]
      end
    end

    puts table.render(:unicode, padding: [0, 1], resize: true)

    if @prompt.yes?("\nWould you like to export these results?")
      export_search_results(results)
    else
      @prompt.keypress("Press any key to continue...")
    end
  end

  def export_search_results(results)
    format = @prompt.select("Select export format:", ['JSON', 'CSV', 'Excel', 'XML', 'Cancel'])

    filename = "search_results_#{Time.now.strftime('%Y%m%d_%H%M%S')}"

    case format
    when 'JSON'
      File.write("#{filename}.json", JSON.pretty_generate(results))
      puts "\n✓ Results exported to #{filename}.json".green
    when 'CSV'
      CSV.open("#{filename}.csv", 'w') do |csv|
        csv << results.first.keys
        results.each { |entry| csv << entry.values }
      end
      puts "\n✓ Results exported to #{filename}.csv".green
    when 'Excel'
      Axlsx::Package.new do |p|
        p.workbook.add_worksheet(name: "Search Results") do |sheet|
          sheet.add_row results.first.keys.map(&:to_s).map(&:capitalize)
          results.each { |entry| sheet.add_row entry.values }
        end
        p.serialize("#{filename}.xlsx")
      end
      puts "\n✓ Results exported to #{filename}.xlsx".green
    when 'XML'
      xml = '<?xml version="1.0"?><entries>'
      results.each do |entry|
        xml << '<entry>'
        entry.each { |k, v| xml << "<#{k}>#{v}</#{k}>" }
        xml << '</entry>'
      end
      xml << '</entries>'
      File.write("#{filename}.xml", xml)
      puts "\n✓ Results exported to #{filename}.xml".green
    end

    @prompt.keypress("Press any key to continue...") unless format == 'Cancel'
  end

  def export_data
    if @entries.empty?
      puts "\nNo entries to export.".yellow
      @prompt.keypress("Press any key to continue...")
      return
    end

    format = @prompt.select("Select export format:", ['JSON', 'CSV', 'Excel', 'XML', 'Cancel'])

    filename = "data_export_#{Time.now.strftime('%Y%m%d_%H%M%S')}"

    case format
    when 'JSON'
      File.write("#{filename}.json", JSON.pretty_generate(@entries))
      puts "\n✓ Data exported to #{filename}.json".green
    when 'CSV'
      CSV.open("#{filename}.csv", 'w') do |csv|
        csv << @entries.first.keys
        @entries.each { |entry| csv << entry.values }
      end
      puts "\n✓ Data exported to #{filename}.csv".green
    when 'Excel'
      Axlsx::Package.new do |p|
        p.workbook.add_worksheet(name: "Data Export") do |sheet|
          sheet.add_row @entries.first.keys.map(&:to_s).map(&:capitalize)
          @entries.each { |entry| sheet.add_row entry.values }
        end
        p.serialize("#{filename}.xlsx")
      end
      puts "\n✓ Data exported to #{filename}.xlsx".green
    when 'XML'
      xml = '<?xml version="1.0"?><entries>'
      @entries.each do |entry|
        xml << '<entry>'
        entry.each { |k, v| xml << "<#{k}>#{v}</#{k}>" }
        xml << '</entry>'
      end
      xml << '</entries>'
      File.write("#{filename}.xml", xml)
      puts "\n✓ Data exported to #{filename}.xml".green
    end

    @prompt.keypress("Press any key to continue...") unless format == 'Cancel'
  end
end

# Run the program
begin
  # Create initial admin user if none exists
  unless File.exist?('users.json')
    FileUtils.mkdir_p('.')
    File.write('users.json', JSON.pretty_generate([
      { username: 'admin', password: 'admin123', role: 'admin' }
    ]))
  end

  DataEntrySystem.new.run
rescue Interrupt
  puts "\n\nOperation cancelled by user. Goodbye!".red
rescue => e
  puts "\n\nAn error occurred: #{e.message}".red
  puts e.backtrace.join("\n") if ENV['DEBUG']
end
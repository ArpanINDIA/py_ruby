require 'csv'        # For handling CSV files
require 'io/console' # For a cleaner "Press any key to continue"
require 'json'       # For handling JSON configuration file

DATA_FILE = 'contacts.csv'
CONFIG_FILE = 'config.json'

# Default headers if config.json doesn't exist
DEFAULT_HEADERS = [
  { key: :id, display: "ID", type: "string" },
  { key: :name, display: "Name", type: "string" },
  { key: :email, display: "Email", type: "string" },
  { key: :phone, display: "Phone", type: "string" }
].freeze # Freeze to prevent accidental modification if used directly

# Global variable to store current headers and their properties
$current_headers = []

# --- Helper Functions ---

# Loads configuration from config.json
def load_config
  if File.exist?(CONFIG_FILE) && File.size(CONFIG_FILE) > 0
    begin
      config_data = JSON.parse(File.read(CONFIG_FILE), symbolize_names: true)
      if config_data[:headers].is_a?(Array) && !config_data[:headers].empty?
        $current_headers = config_data[:headers].map(&:dup) # Use dup to avoid reference issues
        # Ensure 'id' column is always present and first
        id_header = $current_headers.find { |h| h[:key] == :id }
        unless id_header
          puts "Warning: 'ID' column not found in config. Adding default 'ID' column."
          id_header = { key: :id, display: "ID", type: "string" }
          $current_headers.unshift(id_header)
        end
        $current_headers.sort_by! { |h| h[:key] == :id ? 0 : 1 }
      else
        puts "Warning: 'headers' array missing or empty in config.json. Using default headers."
        $current_headers = DEFAULT_HEADERS.map(&:dup)
      end
    rescue JSON::ParserError => e
      puts "Error parsing config.json: #{e.message}. Using default headers."
      $current_headers = DEFAULT_HEADERS.map(&:dup)
    rescue StandardError => e
      puts "Error loading config: #{e.message}. Using default headers."
      $current_headers = DEFAULT_HEADERS.map(&:dup)
    end
  else
    puts "config.json not found or empty. Initializing with default headers."
    $current_headers = DEFAULT_HEADERS.map(&:dup)
    save_config
  end
end

# Saves configuration to config.json
def save_config
  begin
    File.write(CONFIG_FILE, JSON.pretty_generate({ headers: $current_headers }))
    puts "Configuration saved successfully."
  rescue StandardError => e
    puts "Error saving configuration: #{e.message}"
  end
end

# Generates a unique ID for a new contact by finding the current max ID
def generate_id(records_array)
  max_id = 0
  if records_array && !records_array.empty?
    # Ensure ID is treated as integer for max calculation
    max_id = records_array.map { |r| r[:id].to_s.to_i }.max || 0
  end
  (max_id + 1).to_s
end

# Loads records from the CSV file and builds an ID map for quick lookups
def load_data
  records_array = []
  records_by_id = {} # Hash map for O(1) average time access by ID

  # Get the current header keys for CSV reading
  csv_header_keys = $current_headers.map { |h| h[:display] }

  return [records_array, records_by_id] unless File.exist?(DATA_FILE) && File.size(DATA_FILE) > 0

  begin
    # Read CSV using display names as headers, then map to internal keys
    CSV.foreach(DATA_FILE, headers: true, header_converters: :string) do |row|
      record = {}
      row.each do |header_display, value|
        # Find the internal key for the current display header
        header_def = $current_headers.find { |h| h[:display] == header_display }
        if header_def
          record[header_def[:key]] = value # Store with internal key
        else
          # If a column exists in CSV but not in current config, keep it for now
          # Or, decide to drop it: puts "Warning: Column '#{header_display}' not defined in config. Skipping."
          record[header_display.downcase.to_sym] = value # Fallback to lowercase symbol
        end
      end

      # Ensure 'id' is always present and a string
      if record[:id].nil? || record[:id].empty?
        puts "Warning: Record found with missing or empty ID. Skipping."
        next
      end
      record[:id] = record[:id].to_s

      # Ensure all current headers are present in the record, add nil if missing
      $current_headers.each do |header_def|
        record[header_def[:key]] = nil unless record.key?(header_def[:key])
      end
      
      records_array << record
      records_by_id[record[:id]] = record # Store reference to the record in the map
    end
  rescue CSV::MalformedCSVError => e
    puts "Error: The CSV file seems to be malformed. Please check it. #{e.message}"
    puts "Attempting to proceed with successfully loaded records if any, or an empty list."
  rescue StandardError => e
    puts "Error loading data: #{e.message}"
    # Return empty structures to allow the program to potentially continue or re-initialize
    return [[], {}]
  end
  [records_array, records_by_id]
end

# Saves records to the CSV file
def save_records(records_array)
  # Use display names as headers for the CSV file
  csv_headers = $current_headers.map { |h| h[:display] }

  begin
    CSV.open(DATA_FILE, 'w', write_headers: true, headers: csv_headers) do |csv|
      records_array.each do |record|
        # Ensure all header fields are present in the output row, in the correct order
        # Use internal keys to fetch values, then map to display order
        csv << $current_headers.map { |header_def| record[header_def[:key]] }
      end
    end
    puts "Data saved successfully."
  rescue StandardError => e
    puts "Error saving data: #{e.message}"
  end
end

def press_any_key
  puts "\nPress any key to continue..."
  STDIN.getch
  # system("clear") || system("cls") # Commented out to keep output visible
end

# --- Core Functionalities ---

def add_contact(records_array, records_by_id)
  puts "\n--- Add New Contact ---"
  new_id = generate_id(records_array)

  new_contact = { id: new_id }

  # Dynamically prompt for all columns except ID
  $current_headers.each do |header_def|
    next if header_def[:key] == :id # Skip ID as it's auto-generated

    print "Enter #{header_def[:display]} (#{header_def[:type]}): "
    value = gets.chomp.strip
    
    # Basic validation based on conceptual type (can be expanded)
    case header_def[:type]
    when "integer"
      value = value.to_i if value =~ /^\d+$/
    when "float"
      value = value.to_f if value =~ /^\d+(\.\d+)?$/
    when "boolean"
      value = (value.downcase == "true") if ["true", "false"].include?(value.downcase)
    end

    new_contact[header_def[:key]] = value
  end

  # Basic check for name (or first non-ID column)
  first_data_header = $current_headers.find { |h| h[:key] != :id }
  if first_data_header && new_contact[first_data_header[:key]].to_s.empty?
    puts "#{first_data_header[:display]} cannot be empty. Contact not added."
    return
  end

  records_array << new_contact
  records_by_id[new_id] = new_contact

  puts "Contact added successfully with ID: #{new_id}."
end

def view_contacts(records_array)
  puts "\n--- All Contacts ---"
  if records_array.empty?
    puts "No contacts found."
    return
  end

  # Calculate column widths dynamically
  column_widths = {}
  $current_headers.each do |header_def|
    # Start with header display name length
    max_width = header_def[:display].length
    # Check data length for each record
    records_array.each do |record|
      value = record[header_def[:key]].to_s
      max_width = [max_width, value.length].max
    end
    column_widths[header_def[:key]] = max_width + 2 # Add padding
  end

  # Print headers
  header_line = $current_headers.map do |header_def|
    header_def[:display].ljust(column_widths[header_def[:key]])
  end.join("| ")
  puts header_line
  puts "-" * header_line.length

  # Print records
  records_array.each do |record|
    data_line = $current_headers.map do |header_def|
      record[header_def[:key]].to_s.ljust(column_widths[header_def[:key]])
    end.join("| ")
    puts data_line
  end
end

def search_contacts(records_array)
  puts "\n--- Search Contacts ---"
  print "Enter search term (will search all text fields): "
  search_term = gets.chomp.strip.downcase

  if search_term.empty?
    puts "Search term cannot be empty."
    return
  end

  results = records_array.filter do |record|
    # Search across all string-like fields
    $current_headers.any? do |header_def|
      next if [:id].include?(header_def[:key]) # Don't search ID typically
      record[header_def[:key]].to_s.downcase.include?(search_term)
    end
  end

  if results.empty?
    puts "No contacts found matching '#{search_term}'."
  else
    puts "\n--- Search Results ---"
    view_contacts(results) # Reuse view_contacts for displaying results
  end
end

def update_contact(records_by_id)
  puts "\n--- Update Contact ---"
  print "Enter ID of the contact to update: "
  id_to_update = gets.chomp.strip

  contact = records_by_id[id_to_update]

  if contact.nil?
    puts "Contact with ID '#{id_to_update}' not found."
    return
  end

  puts "Found contact: "
  $current_headers.each do |header_def|
    puts "  #{header_def[:display]} (#{header_def[:type]}): #{contact[header_def[:key]]}" unless header_def[:key] == :id
  end
  puts "Enter new details (leave blank to keep current value):"

  $current_headers.each do |header_def|
    next if header_def[:key] == :id # ID cannot be updated

    print "New #{header_def[:display]} (#{contact[header_def[:key]] || 'N/A'}): "
    new_value = gets.chomp.strip

    unless new_value.empty?
      # Basic type conversion if applicable
      case header_def[:type]
      when "integer"
        contact[header_def[:key]] = new_value.to_i if new_value =~ /^\d+$/
      when "float"
        contact[header_def[:key]] = new_value.to_f if new_value =~ /^\d+(\.\d+)?$/
      when "boolean"
        contact[header_def[:key]] = (new_value.downcase == "true") if ["true", "false"].include?(new_value.downcase)
      else
        contact[header_def[:key]] = new_value
      end
    end
  end

  puts "Contact updated successfully."
end

def delete_contact(records_array, records_by_id)
  puts "\n--- Delete Contact ---"
  print "Enter ID of the contact to delete: "
  id_to_delete = gets.chomp.strip

  contact_to_delete = records_by_id.delete(id_to_delete)

  if contact_to_delete
    records_array.delete(contact_to_delete)
    puts "Contact with ID '#{id_to_delete}' deleted successfully."
  else
    puts "Contact with ID '#{id_to_delete}' not found."
  end
end

# --- Column Management Functions ---

def display_current_columns
  puts "\n--- Current Columns ---"
  if $current_headers.empty?
    puts "No columns defined."
    return
  end
  $current_headers.each_with_index do |header_def, index|
    puts "#{index + 1}. Display: #{header_def[:display]}, Key: #{header_def[:key]}, Type: #{header_def[:type]}"
  end
end

def add_new_column
  puts "\n--- Add New Column ---"
  print "Enter new column display name (e.g., 'Address'): "
  display_name = gets.chomp.strip

  if display_name.empty?
    puts "Display name cannot be empty. Column not added."
    return
  end

  # Generate a key from display name, sanitize
  new_key = display_name.downcase.gsub(/[^a-z0-9_]/, '_').gsub(/__+/, '_').to_sym

  if $current_headers.any? { |h| h[:key] == new_key || h[:display].downcase == display_name.downcase }
    puts "A column with that key or display name already exists. Column not added."
    return
  end

  print "Enter conceptual type (e.g., 'string', 'integer', 'date', 'boolean'): "
  type = gets.chomp.strip.downcase
  type = "string" if type.empty? # Default to string

  $current_headers << { key: new_key, display: display_name, type: type }
  save_config
  puts "Column '#{display_name}' added successfully."
  puts "Note: Existing contacts will have empty values for this new column until updated."
end

def rename_column(records_array)
  puts "\n--- Rename Column ---"
  display_current_columns
  print "Enter the DISPLAY NAME of the column to rename: "
  old_display_name = gets.chomp.strip

  old_header_def = $current_headers.find { |h| h[:display].downcase == old_display_name.downcase }

  if old_header_def.nil?
    puts "Column '#{old_display_name}' not found. No column renamed."
    return
  end

  if old_header_def[:key] == :id
    puts "The 'ID' column cannot be renamed or modified directly."
    return
  end

  print "Enter new display name for '#{old_header_def[:display]}': "
  new_display_name = gets.chomp.strip

  if new_display_name.empty?
    puts "New display name cannot be empty. No column renamed."
    return
  end

  if $current_headers.any? { |h| h[:display].downcase == new_display_name.downcase && h[:key] != old_header_def[:key] }
    puts "A column with the new display name '#{new_display_name}' already exists. No column renamed."
    return
  end

  # Update the display name in the header definition
  old_header_def[:display] = new_display_name
  save_config

  puts "Column '#{old_display_name}' renamed to '#{new_display_name}' successfully."
  puts "Note: The internal key for this column remains '#{old_header_def[:key]}'."
end

def change_column_type
  puts "\n--- Change Column Type ---"
  display_current_columns
  print "Enter the DISPLAY NAME of the column to change type: "
  column_display_name = gets.chomp.strip

  header_def = $current_headers.find { |h| h[:display].downcase == column_display_name.downcase }

  if header_def.nil?
    puts "Column '#{column_display_name}' not found. No type changed."
    return
  end

  if header_def[:key] == :id
    puts "The 'ID' column type cannot be changed."
    return
  end

  print "Enter new conceptual type for '#{header_def[:display]}' (current: #{header_def[:type]}): "
  new_type = gets.chomp.strip.downcase
  new_type = "string" if new_type.empty?

  header_def[:type] = new_type
  save_config
  puts "Type for column '#{header_def[:display]}' changed to '#{new_type}' successfully."
  puts "Note: This is a conceptual type for guidance; CSV stores all data as text."
end

def delete_column(records_array, records_by_id)
  puts "\n--- Delete Column ---"
  display_current_columns
  print "Enter the DISPLAY NAME of the column to delete: "
  column_display_name = gets.chomp.strip

  header_to_delete = $current_headers.find { |h| h[:display].downcase == column_display_name.downcase }

  if header_to_delete.nil?
    puts "Column '#{column_display_name}' not found. No column deleted."
    return
  end

  if header_to_delete[:key] == :id
    puts "The 'ID' column cannot be deleted."
    return
  end

  print "Are you sure you want to delete column '#{header_to_delete[:display]}'? (yes/no): "
  confirm = gets.chomp.strip.downcase
  unless confirm == 'yes'
    puts "Column deletion cancelled."
    return
  end

  # Remove from headers
  $current_headers.delete(header_to_delete)
  save_config

  # Remove data from all records
  records_array.each do |record|
    record.delete(header_to_delete[:key])
  end

  puts "Column '#{column_display_name}' and its data deleted successfully."
  puts "Remember to save to apply changes to the CSV file."
end


def manage_columns_menu(records_array, records_by_id)
  loop do
    puts "\n--- Column Management ---"
    puts "1. View Current Columns"
    puts "2. Add New Column"
    puts "3. Rename Column Display Name"
    puts "4. Change Column Conceptual Type"
    puts "5. Delete Column"
    puts "6. Back to Main Menu"
    print "Choose an option: "
    choice = gets.chomp

    system("clear") || system("cls")

    case choice
    when '1'
      display_current_columns
    when '2'
      add_new_column
      # Reload config and data after column change
      load_config
      records_array.replace(load_data[0])
      records_by_id.replace(load_data[1])
    when '3'
      rename_column(records_array)
      load_config
      records_array.replace(load_data[0])
      records_by_id.replace(load_data[1])
    when '4'
      change_column_type
      load_config
      records_array.replace(load_data[0])
      records_by_id.replace(load_data[1])
    when '5'
      delete_column(records_array, records_by_id)
      load_config
      records_array.replace(load_data[0])
      records_by_id.replace(load_data[1])
    when '6'
      break
    else
      puts "Invalid option. Please try again."
    end
    press_any_key unless choice == '6'
  end
end

# --- Main Application Loop ---
def main_menu
  load_config
  records_array, records_by_id = load_data()
  system("clear") || system("cls")

  loop do
    puts "\n--- Contact Management System (Advanced) ---"
    puts "1. Add Contact"
    puts "2. View Contacts"
    puts "3. Search Contacts"
    puts "4. Update Contact"
    puts "5. Delete Contact"
    puts "6. Manage Columns"
    puts "7. Save and Exit"
    puts "8. Exit Without Saving"
    print "Choose an option: "
    choice = gets.chomp

    system("clear") || system("cls") unless ['7', '8'].include?(choice)

    case choice
    when '1'
      add_contact(records_array, records_by_id)
    when '2'
      view_contacts(records_array)
    when '3'
      search_contacts(records_array)
    when '4'
      update_contact(records_by_id)
    when '5'
      delete_contact(records_array, records_by_id)
    when '6'
      manage_columns_menu(records_array, records_by_id)
      # After managing columns, reload config and data
      load_config
      records_array, records_by_id = load_data()
    when '7'
      save_records(records_array)
      puts "Exiting. Goodbye!"
      break
    when '8'
      puts "Exiting without saving. Goodbye!"
      break
    else
      puts "Invalid option. Please try again."
    end
    press_any_key unless ['7', '8'].include?(choice)
  end
end

# --- Ensure files are initialized ---
def initialize_files
  # Initialize config.json if it doesn't exist
  unless File.exist?(CONFIG_FILE) && File.size(CONFIG_FILE) > 0
    puts "Initializing #{CONFIG_FILE}..."
    load_config # This will create and save default config
  end

  # Initialize contacts.csv if it doesn't exist or is empty
  # This needs current headers to write them
  load_config # Ensure headers are loaded before initializing CSV
  if !File.exist?(DATA_FILE) || File.zero?(DATA_FILE)
    begin
      CSV.open(DATA_FILE, 'w', write_headers: true, headers: $current_headers.map { |h| h[:display] }) do |csv|
        # Just write headers for an empty file
      end
      puts "Initialized empty contacts file with headers: #{DATA_FILE}"
    rescue StandardError => e
      puts "Error initializing data file: #{e.message}"
      puts "Please ensure you have write permissions in the current directory."
      exit # Exit if we can't initialize the data file
    end
  end
end

# --- Run the application ---
initialize_files
main_menu

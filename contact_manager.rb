require 'csv' # For handling CSV files
require 'io/console' # For a cleaner "Press any key to continue"

DATA_FILE = 'contacts.csv'
HEADERS = ['ID', 'Name', 'Email', 'Phone']

# --- Helper Functions ---

# Generates a unique ID for a new contact
def generate_id(records)
  (records.last&.fetch('ID', '0').to_i + 1).to_s
end

# Loads records from the CSV file
def load_records
  return [] unless File.exist?(DATA_FILE)
  CSV.read(DATA_FILE, headers: true, header_converters: :symbol).map(&:to_hash)
rescue StandardError => e
  puts "Error loading data: #{e.message}"
  []
end

# Saves records to the CSV file
def save_records(records)
  CSV.open(DATA_FILE, 'w', write_headers: true, headers: HEADERS) do |csv|
    records.each do |record|
      # Ensure all headers are present, even if value is nil
      csv << HEADERS.map { |header| record[header.downcase.to_sym] || record[header] }
    end
  end
  puts "Data saved successfully."
rescue StandardError => e
  puts "Error saving data: #{e.message}"
end

def press_any_key
  puts "\nPress any key to continue..."
  STDIN.getch
end

# --- Core Functionalities ---

def add_contact(records)
  puts "\n--- Add New Contact ---"
  id = generate_id(records)
  print "Enter Name: "
  name = gets.chomp.strip
  print "Enter Email: "
  email = gets.chomp.strip
  print "Enter Phone: "
  phone = gets.chomp.strip

  if name.empty?
    puts "Name cannot be empty. Contact not added."
    return
  end

  records << { id: id, name: name, email: email, phone: phone }
  puts "Contact added successfully with ID: #{id}."
end

def view_contacts(records)
  puts "\n--- All Contacts ---"
  if records.empty?
    puts "No contacts found."
    return
  end

  puts format("%-5s | %-25s | %-30s | %-15s", "ID", "Name", "Email", "Phone")
  puts "-" * 80
  records.each do |record|
    puts format("%-5s | %-25s | %-30s | %-15s", record[:id], record[:name], record[:email], record[:phone])
  end
end

def search_contacts(records)
  puts "\n--- Search Contacts ---"
  print "Enter name to search (or part of it): "
  search_term = gets.chomp.strip.downcase

  results = records.filter { |record| record[:name]&.downcase&.include?(search_term) }

  if results.empty?
    puts "No contacts found matching '#{search_term}'."
  else
    puts "\n--- Search Results ---"
    puts format("%-5s | %-25s | %-30s | %-15s", "ID", "Name", "Email", "Phone")
    puts "-" * 80
    results.each do |record|
      puts format("%-5s | %-25s | %-30s | %-15s", record[:id], record[:name], record[:email], record[:phone])
    end
  end
end

def update_contact(records)
  puts "\n--- Update Contact ---"
  print "Enter ID of the contact to update: "
  id_to_update = gets.chomp.strip

  contact_index = records.index { |record| record[:id] == id_to_update }

  if contact_index.nil?
    puts "Contact with ID '#{id_to_update}' not found."
    return
  end

  contact = records[contact_index]
  puts "Found contact: #{contact[:name]} | #{contact[:email]} | #{contact[:phone]}"
  puts "Enter new details (leave blank to keep current value):"

  print "New Name (#{contact[:name]}): "
  name = gets.chomp.strip
  print "New Email (#{contact[:email]}): "
  email = gets.chomp.strip
  print "New Phone (#{contact[:phone]}): "
  phone = gets.chomp.strip

  records[contact_index][:name] = name unless name.empty?
  records[contact_index][:email] = email unless email.empty?
  records[contact_index][:phone] = phone unless phone.empty?

  puts "Contact updated successfully."
end

def delete_contact(records)
  puts "\n--- Delete Contact ---"
  print "Enter ID of the contact to delete: "
  id_to_delete = gets.chomp.strip

  original_length = records.length
  records.reject! { |record| record[:id] == id_to_delete }

  if records.length < original_length
    puts "Contact with ID '#{id_to_delete}' deleted successfully."
  else
    puts "Contact with ID '#{id_to_delete}' not found."
  end
end

# --- Main Application Loop ---
def main_menu
  records = load_records

  loop do
    puts "\n--- Contact Management System ---"
    puts "1. Add Contact"
    puts "2. View Contacts"
    puts "3. Search Contacts"
    puts "4. Update Contact"
    puts "5. Delete Contact"
    puts "6. Save and Exit"
    puts "7. Exit Without Saving"
    print "Choose an option: "
    choice = gets.chomp

    case choice
    when '1'
      add_contact(records)
    when '2'
      view_contacts(records)
    when '3'
      search_contacts(records)
    when '4'
      update_contact(records)
    when '5'
      delete_contact(records)
    when '6'
      save_records(records)
      puts "Exiting. Goodbye!"
      break
    when '7'
      puts "Exiting without saving. Goodbye!"
      break
    else
      puts "Invalid option. Please try again."
    end
    press_any_key unless ['6', '7'].include?(choice)
    system "clear" or system "cls" # Clears the console
  end
end

# --- Ensure CSV file has headers if it's new or empty ---
def initialize_data_file
  return if File.exist?(DATA_FILE) && File.size(DATA_FILE) > 0
  CSV.open(DATA_FILE, 'w') do |csv|
    csv << HEADERS
  end
  puts "Initialized empty contacts file: #{DATA_FILE}"
end

# --- Run the application ---
initialize_data_file
main_menu
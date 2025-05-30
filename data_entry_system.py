import json
import csv
import re
from datetime import datetime
from simple_term_menu import TerminalMenu
from tabulate import tabulate
from colorama import Fore, Style, init

# Initialize colorama
init(autoreset=True)

class DataEntrySystem:
    def __init__(self):
        self.entries = []
        self.data_file = "user_data.json"
        self.load_entries()

    def display_welcome(self):
        print(f"\n{Fore.CYAN}{' DATA ENTRY SYSTEM v3.0 (Python) '.center(50, '═')}{Style.RESET_ALL}")
        print(f"\n{Fore.LIGHTBLACK_EX}A modern solution for collecting and managing user information{Style.RESET_ALL}")

    def display_goodbye(self):
        print(f"\n{Fore.CYAN}{' Thank you for using DataEntrySystem! '.center(50, '═')}{Style.RESET_ALL}")
        print(f"{Fore.LIGHTBLACK_EX}Your data has been safely stored.{Style.RESET_ALL}")

    def load_entries(self):
        try:
            with open(self.data_file, "r") as file:
                self.entries = json.load(file)
        except FileNotFoundError:
            self.entries = []
        except json.JSONDecodeError:
            print(f"{Fore.RED}Error: Corrupted data file. Starting with empty database.{Style.RESET_ALL}")
            self.entries = []

    def save_entries(self):
        try:
            with open(self.data_file, "w") as file:
                json.dump(self.entries, file, indent=2)
        except IOError as e:
            print(f"{Fore.RED}Error saving data: {e}{Style.RESET_ALL}")

    def validate_email(self, email):
        pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
        return re.match(pattern, email) is not None

    def email_exists(self, email):
        return any(entry['email'].lower() == email.lower() for entry in self.entries)

    def add_new_entry(self):
        while True:
            print(f"\n{Fore.YELLOW}{' NEW ENTRY FORM '.center(50, '─')}{Style.RESET_ALL}")

            name = input(f"{Fore.BLUE}Full Name:{Style.RESET_ALL} ").strip()
            if not name:
                print(f"{Fore.RED}Name cannot be blank!{Style.RESET_ALL}")
                continue

            while True:
                age = input(f"{Fore.BLUE}Age:{Style.RESET_ALL} ").strip()
                if age.isdigit() and 1 <= int(age) <= 120:
                    break
                print(f"{Fore.RED}Age must be a number between 1 and 120!{Style.RESET_ALL}")

            while True:
                email = input(f"{Fore.BLUE}Email Address:{Style.RESET_ALL} ").strip()
                if not self.validate_email(email):
                    print(f"{Fore.RED}Invalid email format!{Style.RESET_ALL}")
                    continue
                if self.email_exists(email):
                    print(f"{Fore.RED}Email already exists in the system!{Style.RESET_ALL}")
                    continue
                break

            address = input(f"{Fore.BLUE}Physical Address (optional):{Style.RESET_ALL} ").strip() or "N/A"

            self.entries.append({
                "name": name,
                "age": int(age),  # Store as integer
                "email": email.lower(),  # Store in lowercase for consistency
                "address": address,
                "timestamp": datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            })
            self.save_entries()

            print(f"\n{Fore.GREEN}✓ Entry added successfully!{Style.RESET_ALL}")

            if input("\nAdd another entry? (y/n): ").lower() != 'y':
                break

    def display_all_entries(self):
        if not self.entries:
            print(f"\n{Fore.YELLOW}No entries found. Please add some data first.{Style.RESET_ALL}")
            return

        print(f"\n{Fore.CYAN}{' ALL ENTRIES '.center(50, '═')}{Style.RESET_ALL}")
        
        headers = ["#", "Name", "Age", "Email", "Address", "Added On"]
        table_data = []
        
        for idx, entry in enumerate(self.entries, 1):
            table_data.append([
                idx,
                entry["name"],
                entry["age"],
                entry["email"],
                entry["address"].split(",")[0][:20] + "..." if len(entry["address"]) > 20 else entry["address"],
                entry["timestamp"]
            ])
        
        print(tabulate(table_data, headers=headers, tablefmt="grid"))
        input("\nPress Enter to continue...")

    def search_entries(self):
        if not self.entries:
            print(f"\n{Fore.YELLOW}No entries found. Please add some data first.{Style.RESET_ALL}")
            return

        search_term = input("\nSearch by name, email, or address: ").lower()
        results = [
            entry for entry in self.entries
            if (search_term in entry["name"].lower() or
                search_term in entry["email"].lower() or
                search_term in entry["address"].lower())
        ]

        self.display_search_results(results)

    def display_search_results(self, results):
        if not results:
            print(f"\n{Fore.YELLOW}No matching entries found.{Style.RESET_ALL}")
            return

        print(f"\n{Fore.CYAN}{' SEARCH RESULTS '.center(50, '═')}{Style.RESET_ALL}")
        
        headers = ["#", "Name", "Age", "Email", "Address"]
        table_data = []
        
        for idx, entry in enumerate(results, 1):
            table_data.append([
                idx,
                entry["name"],
                entry["age"],
                entry["email"],
                entry["address"].split(",")[0][:20] + "..." if len(entry["address"]) > 20 else entry["address"]
            ])
        
        print(tabulate(table_data, headers=headers, tablefmt="grid"))
        input("\nPress Enter to continue...")

    def export_data(self):
        if not self.entries:
            print(f"\n{Fore.YELLOW}No entries to export.{Style.RESET_ALL}")
            return

        options = ["JSON", "CSV", "Cancel"]
        terminal_menu = TerminalMenu(options, title="Select export format:")
        choice_index = terminal_menu.show()

        if choice_index is None or choice_index == 2:
            print(f"\n{Fore.YELLOW}Export cancelled.{Style.RESET_ALL}")
            return

        try:
            if choice_index == 0:  # JSON
                with open("export.json", "w") as file:
                    json.dump(self.entries, file, indent=2)
                print(f"\n{Fore.GREEN}✓ Data exported to export.json{Style.RESET_ALL}")
            elif choice_index == 1:  # CSV
                with open("export.csv", "w", newline="") as file:
                    writer = csv.DictWriter(file, fieldnames=self.entries[0].keys())
                    writer.writeheader()
                    writer.writerows(self.entries)
                print(f"\n{Fore.GREEN}✓ Data exported to export.csv{Style.RESET_ALL}")
        except Exception as e:
            print(f"\n{Fore.RED}Error during export: {e}{Style.RESET_ALL}")

        input("\nPress Enter to continue...")

    def main_menu(self):
        options = [
            "Add New Entry",
            "View All Entries",
            "Search Entries",
            "Export Data",
            "Exit"
        ]
        
        while True:
            terminal_menu = TerminalMenu(
                options,
                title="Main Menu:",
                cycle_cursor=True,
                clear_screen=True
            )
            choice_index = terminal_menu.show()

            if choice_index == 0:
                self.add_new_entry()
            elif choice_index == 1:
                self.display_all_entries()
            elif choice_index == 2:
                self.search_entries()
            elif choice_index == 3:
                self.export_data()
            elif choice_index == 4:
                break

    def run(self):
        self.display_welcome()
        self.main_menu()
        self.display_goodbye()

if __name__ == "__main__":
    try:
        system = DataEntrySystem()
        system.run()
    except KeyboardInterrupt:
        print(f"\n{Fore.RED}Operation cancelled by user. Goodbye!{Style.RESET_ALL}")
    except Exception as e:
        print(f"\n{Fore.RED}An unexpected error occurred: {e}{Style.RESET_ALL}")
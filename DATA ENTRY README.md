# Data Entry System v4

A robust, interactive Ruby console application for managing user data with backup/restore, editing, and search features.

## Features

- Add, view, search, edit, and delete entries
- Each entry includes: Name, Age, Email, Address, Timestamp, and unique ID
- Data persistence in `user_data.json`
- Backup and restore support (`user_data_backup.json`)
- Paginated viewing of entries
- Input validation for all fields
- Colorized and user-friendly terminal UI (TTY Prompt, TTY Table)
- Handles corrupted data files gracefully

## Requirements

- Ruby 2.5+
- Gems: `tty-prompt`, `tty-table`, `colorize`, `tty-cursor`

Install dependencies:

```sh
gem install tty-prompt tty-table colorize tty-cursor
```

## Usage

Run the application:

```sh
ruby date_entry_v4.rb
```

Follow the on-screen menu to:

- Add new entries
- View/search entries (with pagination)
- Edit or delete existing entries
- Backup or restore your data

## Data Files

- `user_data.json` — main data storage
- `user_data_backup.json` — backup file (auto-created)

## Notes

- All entries are assigned a unique UUID.
- If the main data file is corrupted, the app attempts to restore from backup.
- All actions are performed via interactive menus.

---

## License

MIT License

Copyright (c) 2025 [ARPAN MONADL]

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

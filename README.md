#Log Archive Tool

`Project URL `

`https://roadmap.sh/projects/log-archive-tool`

A simple Bash CLI tool to archive logs by compressing them into a `.tar.gz` file, storing them in a dedicated folder, and optionally scheduling itself to run automatically using `cron`.

## Features

- **Accepts a log directory as argument** – example: `/var/log`
- **Creates timestamped archives** – e.g. `logs_archive_20240920_000000.tar.gz`
- **Stores archives in a separate folder** (`./archived_logs`)
- **Appends log entries to `archive.log`** for history tracking
- **Optional automation** – schedule to run daily, weekly, or monthly at 00:00 using cron
- **Check logs older than a year, and optionally deletes them** - it also creates an audit file

## Usage

Run the tool manually:

```bash
./log-archive.sh /var/log

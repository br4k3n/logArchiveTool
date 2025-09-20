#!/bin/bash

# Log archive tool project from devOpsRoadmaps

# This script takes a log folder as an argument and compresses its content into tar.gz file.

# It saves the file in a new folder, with timestamps about the new compressions.

# You can choose to schedule this every day, every week, or every month.

# You can also select to delete old logs previous than a year.

#--------------------------------------------------------------------------------------------------
# ** Argument logic and tar compression **
#--------------------------------------------------------------------------------------------------

LOG_DIR=${1:-}

# 1) Validate argument
if [ -z "$LOG_DIR" ]; then
  echo "Usage: $0 <log-directory>" >&2
  exit 1
fi

# 2) Validate directory exists
if [ ! -d "$LOG_DIR" ]; then
  echo "Error: directory not found: $LOG_DIR" >&2
  exit 1
fi

# 3) Prepare archive directory
ARCHIVE_DIR="./archived_logs"
mkdir -p "$ARCHIVE_DIR"

# 4) Generate timestamp and archive name
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
ARCHIVE_NAME="logs_archive_${TIMESTAMP}.tar.gz"

# 5) Compress logs (*.log only)
if tar -czf "$ARCHIVE_DIR/$ARCHIVE_NAME" "$LOG_DIR"/*.log 2>/dev/null; then
  echo "$(date '+%Y-%m-%d %H:%M:%S') - Created archive: $ARCHIVE_NAME from $LOG_DIR" >> "$ARCHIVE_DIR/archive.log"
  echo " Archive created: $ARCHIVE_DIR/$ARCHIVE_NAME"

  # 6) Ask user if they want to schedule automation
  read -p "Do you want to schedule this script automatically? (y/n): " answer
  if [[ "$answer" =~ ^[Yy]$ ]]; then
    echo "Choose schedule frequency:"
    echo "1) Every day at 00:00"
    echo "2) Every week (Sunday 00:00)"
    echo "3) Every month (1st day 00:00)"
    read -p "Enter choice (1/2/3): " option

    CRON_EXPR=""
    case $option in
      1) CRON_EXPR="0 0 * * *" ;;   # daily
      2) CRON_EXPR="0 0 * * 0" ;;   # weekly (Sunday)
      3) CRON_EXPR="0 0 1 * *" ;;   # monthly (1st)
      *) echo "Invalid choice. Skipping automation."; exit 0 ;;
    esac

    CRON_LINE="$CRON_EXPR $(realpath "$0") $LOG_DIR"
    (crontab -l 2>/dev/null; echo "$CRON_LINE") | sort -u | crontab -
    echo "Cron job added: $CRON_LINE"
  fi

  # 7) Find logs older than 1 year (*.log only)
  OLD_LOGS=$(find "$LOG_DIR" -type f -name "*.log" -mtime +365)
  if [ -n "$OLD_LOGS" ]; then
    echo "These logs are older than one year:"
    echo "$OLD_LOGS"
    read -p "Do you want to delete these old logs? (y/n): " delete_answer
    if [[ "$delete_answer" =~ ^[Yy]$ ]]; then
      # Save deleted files to audit log with timestamp
      AUDIT_FILE="$ARCHIVE_DIR/deleted_old_logs.log"
      echo "===== $(date '+%Y-%m-%d %H:%M:%S') - Deleted old logs =====" >> "$AUDIT_FILE"
      echo "$OLD_LOGS" >> "$AUDIT_FILE"
      echo "" >> "$AUDIT_FILE"

      echo "$OLD_LOGS" | xargs rm -f
      echo "Old logs deleted. Audit saved in: $AUDIT_FILE"
    else
      echo "ld logs were NOT deleted."
    fi
  else
    echo "No logs older than one year were found."
  fi

else
  echo "Error: tar failed creating $ARCHIVE_DIR/$ARCHIVE_NAME" >&2
  exit 2
fi


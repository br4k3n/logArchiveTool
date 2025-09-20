#!/bin/bash

# Log archive tool project from devOpsRoadmaps

# This script takes a log folder as an argument and compresses its content into tar.gz file.

# It saves the file in a new folder, with timestamps about the new compressions.

# You can choose to schedule this every day, every week, or every month.

# You can also select to delete old logs previous than a year.

#--------------------------------------------------------------------------------------------------
# ** Argument logic and tar compression **
#--------------------------------------------------------------------------------------------------

# 1) Log directory to archive
LOG_DIR=${1:-}
# 2) Make sure user passed an argument
if [ -z "$LOG_DIR" ]; then
  echo "Usage: $0 <log-directory>"
  exit 1
fi
# 3) Error in case no argument exist
if [ ! -d "$LOG_DIR" ]; then
  echo "Error: directory not found: $LOG_DIR" >&2
  exit 1
fi
# 4) Create archive folder
ARCHIVE_DIR="./archived_logs"
mkdir -p "$ARCHIVE_DIR"
# 5) Timestamp for name generation
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
ARCHIVE_NAME="logs_archive_${TIMESTAMP}.tar.gz"

# 6) Run tar
if tar -czf "$ARCHIVE_DIR/$ARCHIVE_NAME" "$LOG_DIR"; then
  # 7) Log the operation into archive.log
  echo "$(date '+%Y-%m-%d %H:%M:%S') - Created archive: $ARCHIVE_NAME from $LOG_DIR" >> "$ARCHIVE_DIR/archive.log"

  # 8) Notify the user 
  echo "Archive created: $ARCHIVE_DIR/$ARCHIVE_NAME"

#--------------------------------------------------------------------------------------------------
# ** Cron automation **
#--------------------------------------------------------------------------------------------------
  # 9) Ask the user if they want to schedule automatic runs with cron
  read -p "Do you want to schedule this script automatically? (y/n): " answer
  if [[ "$answer" =~ ^[Yy]$ ]]; then
    echo "Choose schedule frequency:"
    echo "1) Every day at 00:00"
    echo "2) Every week (Sunday 00:00)"
    echo "3) Every month (1st day 00:00)"
    read -p "Enter choice (1/2/3): " option

    CRON_EXPR=""
    case $option in
      1)
        CRON_EXPR="0 0 * * *"   # daily
        ;;
      2)
        CRON_EXPR="0 0 * * 0"   # weekly (Sunday)
        ;;
      3)
        CRON_EXPR="0 0 1 * *"   # monthly (day 1)
        ;;
      *)
        echo "Invalid choice. Skipping automation."
        exit 0
        ;;
    esac

    # 10) Build the cron line using the expression, realpath and logdirectory
    CRON_LINE="$CRON_EXPR $(realpath "$0") $LOG_DIR"

    # 11) Append to user crontab, dup verification
    (crontab -l 2>/dev/null; echo "$CRON_LINE") | sort -u | crontab -

    echo "Cron job added: $CRON_LINE"

else
  # print error and exit with code 2
  echo "Error: tar failed creating $ARCHIVE_DIR/$ARCHIVE_NAME" >&2
  exit 2
fi


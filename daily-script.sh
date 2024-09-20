#!/bin/bash

# Function to display help content
function display_help {
    echo "Usage: $0 [OPTIONS] <server_folder_name>"
    echo
    echo "Options:"
    echo "  --help      Display this help message and exit"
    echo "  --dryrun    Perform a dry run, outputting log messages to the screen"
    echo
    echo "This script processes backup archives for a specified server folder, extracts them, and performs cleanup on old extracted files."
    echo
    exit 0
}

# Function to check if a command is available
function check_dependency {
    local cmd="$1"
    if ! command -v "$cmd" &> /dev/null; then
        echo "Error: Required dependency '$cmd' is not installed."
        exit 1
    fi
}

# Function to log messages with a specific format
function log_message {
    local message="$1"
    local log_file="$2"
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    local log_format="[$timestamp] $message"

    if $DRYRUN; then
        echo "$log_format"
    else
        echo "$log_format" >> "$log_file"
    fi
}

# Check if the help option is passed
if [[ "$1" == "--help" ]]; then
    display_help
fi

# Dry run mode - If --dryrun is passed or DRYRUN environment variable is set
DRYRUN=false
if [[ "$1" == "--dryrun" ]]; then
    DRYRUN=true
    shift # Remove --dryrun from arguments
fi

# Check if the server folder name is passed as an argument
if [ -z "$1" ]; then
  echo "Error: No server folder name provided."
  echo "Usage: $0 [--dryrun] <server_folder_name>"
  exit 1
fi

# Dependency checks
check_dependency "unzip"
check_dependency "tar"
check_dependency "gunzip"
check_dependency "find"

# Set variables
SERVER_FOLDER="$1"                              # Server folder name passed as an argument
BACKUP_DIR="/files/$SERVER_FOLDER"              # Backup directory with subfolders for each domain
LOGS_DIR="/logs"                                # Path to store logs
EXTRACTED_DIR="/archives/$SERVER_FOLDER"        # Path for extracted files
DATE=$(date +"%Y-%m-%d")

# Log file structure: logs/date:mysql_format/server_name-domain_name.log
mkdir -p "$LOGS_DIR/$DATE"

# Log the start of the script
log_message "Starting extraction script for server: $SERVER_FOLDER..." "$LOGS_DIR/$DATE/${SERVER_FOLDER}.log"

# Loop through each domain subfolder under the server
for domain in "$BACKUP_DIR"/*; do
  if [[ -d "$domain" ]]; then
    DOMAIN_NAME=$(basename "$domain")
    
    # Set the domain-specific log file
    LOG_FILE="$LOGS_DIR/$DATE/${SERVER_FOLDER}-${DOMAIN_NAME}.log"
    
    # Log the start of extraction for the domain
    log_message "Processing domain: $DOMAIN_NAME..." "$LOG_FILE"
    
    # Get the backup files for this domain
    for archive in "$domain"/*; do
      if [[ -f "$archive" ]]; then
        # Get the filename without the extension
        filename=$(basename "$archive")
        foldername="${filename%.*}"
        
        # Create a folder in 'extracted' with the filename of the archive
        extract_path="$EXTRACTED_DIR/$DOMAIN_NAME/$foldername"
        mkdir -p "$extract_path"
        
        # Extract the archive into this folder
        log_message "Extracting $archive to $extract_path..." "$LOG_FILE"
        
        if [[ $archive == *.zip ]]; then
          unzip "$archive" -d "$extract_path" >> "$LOG_FILE" 2>&1
        elif [[ $archive == *.tar.gz || $archive == *.tgz ]]; then
          tar -xzf "$archive" -C "$extract_path" >> "$LOG_FILE" 2>&1
        elif [[ $archive == *.gz ]]; then
          gunzip -c "$archive" > "$extract_path/$(basename "$filename" .gz)" >> "$LOG_FILE" 2>&1
        else
          log_message "Unsupported file format: $archive" "$LOG_FILE"
          continue
        fi
        
        # Check if extraction was successful
        if [ $? -eq 0 ]; then
          log_message "Successfully extracted $archive." "$LOG_FILE"
        else
          log_message "Failed to extract $archive!" "$LOG_FILE"
          continue
        fi
      fi
    done
    
    # If all extractions are successful, delete the previous day's extracted files for this domain
    log_message "Cleaning up old extracted files for domain: $DOMAIN_NAME..." "$LOG_FILE"
    find "$EXTRACTED_DIR/$DOMAIN_NAME" -mindepth 1 -mtime +1 -delete
    if [ $? -eq 0 ]; then
      log_message "Old extracted files cleaned successfully for domain: $DOMAIN_NAME." "$LOG_FILE"
    else
      log_message "Failed to clean old extracted files for domain: $DOMAIN_NAME!" "$LOG_FILE"
    fi
  fi
done

# Log the end of the script
log_message "Extraction script finished for server: $SERVER_FOLDER." "$LOGS_DIR/$DATE/${SERVER_FOLDER}.log"
exit 0

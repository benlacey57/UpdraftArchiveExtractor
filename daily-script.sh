#!/bin/bash

# Check if the server folder name is passed as an argument
if [ -z "$1" ]; then
  echo "Error: No server folder name provided."
  echo "Usage: $0 <server_folder_name>"
  exit 1
fi

# Set variables
SERVER_FOLDER="$1"                              # Server folder name passed as an argument
BACKUP_DIR="/files/$SERVER_FOLDER"              # Backup directory with subfolders for each domain
LOGS_DIR="/logs"                        # Path to store logs
EXTRACTED_DIR="/extracted/$SERVER_FOLDER" # Path for extracted files
DATE=$(date +"%Y-%m-%d")

# Log file structure: logs/date:mysql_format/server_name-domain_name.log
mkdir -p "$LOGS_DIR/$DATE"

# Log the start of the script
echo "[$DATE] Starting extraction script for server: $SERVER_FOLDER..." 

# Loop through each domain subfolder under the server
for domain in "$BACKUP_DIR"/*; do
  if [[ -d "$domain" ]]; then
    DOMAIN_NAME=$(basename "$domain")
    
    # Set the domain-specific log file
    LOG_FILE="$LOGS_DIR/$DATE/${SERVER_FOLDER}-${DOMAIN_NAME}.log"
    
    # Log the start of extraction for the domain
    echo "[$DATE] Processing domain: $DOMAIN_NAME..." >> "$LOG_FILE"
    
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
        echo "[$DATE] Extracting $archive to $extract_path..." >> "$LOG_FILE"
        
        if [[ $archive == *.zip ]]; then
          unzip "$archive" -d "$extract_path" >> "$LOG_FILE" 2>&1
        elif [[ $archive == *.tar.gz || $archive == *.tgz ]]; then
          tar -xzf "$archive" -C "$extract_path" >> "$LOG_FILE" 2>&1
        elif [[ $archive == *.gz ]]; then
          gunzip -c "$archive" > "$extract_path/$(basename "$filename" .gz)" >> "$LOG_FILE" 2>&1
        else
          echo "[$DATE] Unsupported file format: $archive" >> "$LOG_FILE"
          continue
        fi
        
        # Check if extraction was successful
        if [ $? -eq 0 ]; then
          echo "[$DATE] Successfully extracted $archive." >> "$LOG_FILE"
        else
          echo "[$DATE] Failed to extract $archive!" >> "$LOG_FILE"
          # Do not remove the files in case of failure
          continue
        fi
      fi
    done
    
    # If all extractions are successful, delete the previous day's extracted files for this domain
    echo "[$DATE] Cleaning up old extracted files for domain: $DOMAIN_NAME..." >> "$LOG_FILE"
    find "$EXTRACTED_DIR/$DOMAIN_NAME" -mindepth 1 -mtime +1 -delete
    if [ $? -eq 0 ]; then
      echo "[$DATE] Old extracted files cleaned successfully for domain: $DOMAIN_NAME." >> "$LOG_FILE"
    else
      echo "[$DATE] Failed to clean old extracted files for domain: $DOMAIN_NAME!" >> "$LOG_FILE"
    fi
  fi
done

# Log the end of the script
echo "[$DATE] Extraction script finished for server: $SERVER_FOLDER." 
exit 0

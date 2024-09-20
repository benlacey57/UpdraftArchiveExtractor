#!/bin/bash

# Prompt for server name
read -p "Enter the server name: " server_name

# List of domain names and URLs
declare -A domains
domains=(
  ["The_Forge_Kitchen"]="theforgekitchen.co.uk"
  ["Rapid_Move"]="rapidmoveuk.co.uk"
  ["Pyro_Fire"]="pyrofire.co.uk"
)

# Base directory for backups
base_dir="./files/${server_name}"

# Set variables for backup
historic_date="2024-09-01"
current_date=$(date +"%Y-%m-%d")

# Function to generate a random hash
generate_random_hash() {
  echo "$(openssl rand -hex 6)"
}

# Function to generate a random time (HHMM)
generate_random_time() {
  echo "$(date +"%H%M" -d "$((RANDOM % 24)) hours")"
}

# Loop through each domain in the list
for domain_name in "${!domains[@]}"; do
  website_url="${domains[$domain_name]}"
  
  # Create the directory for each website's backup files
  domain_dir="${base_dir}/${website_url}/"
  mkdir -p "$domain_dir"

  # Convert dates to seconds since 1970-01-01 for comparison
  start_date_sec=$(date -d "$historic_date" +%s)
  current_date_sec=$(date -d "$current_date" +%s)
  
  # Loop through each date from historic_date to current_date
  while [ "$start_date_sec" -le "$current_date_sec" ]; do
    # Format the date to MySQL format YYYY-MM-DD and random time
    formatted_date=$(date -d "@$start_date_sec" +"%Y-%m-%d")
    random_time=$(generate_random_time)
    
    # Generate a random hash for each backup set
    random_hash=$(generate_random_hash)
    
    # Create the backup files for this domain with the required format
    touch "${domain_dir}/backup_${formatted_date}-${random_time}_${domain_name}_${random_hash}-db.gz"
    touch "${domain_dir}/backup_${formatted_date}-${random_time}_${domain_name}_${random_hash}-plugins.gz"
    touch "${domain_dir}/backup_${formatted_date}-${random_time}_${domain_name}_${random_hash}-themes.gz"
    
    # Increment date by one day (86400 seconds)
    start_date_sec=$((start_date_sec + 86400))
  done

  echo "Created folders and backup files for ${domain_name} (${website_url})"
done

# Final summary
echo "All folders and backup files have been created under /files/${server_name}/"

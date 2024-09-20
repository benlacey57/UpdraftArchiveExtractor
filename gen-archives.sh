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

# Function to generate random content
generate_random_content() {
  local size=$((RANDOM % 100 + 20))  # Random size between 20 and 120 characters
  tr -dc 'a-zA-Z0-9' < /dev/urandom | fold -w "$size" | head -n 1
}

# Function to generate random plugin files, using the passed backup_hash
generate_plugin_files() {
  local backup_hash="$1"
  local temp_dir="$2"

  # List of potential plugins
  plugins=("woocommerce" "yoast-seo" "elementor" "contact-form-7" "wpforms" "akismet" "wordfence" "updraftplus" "wp-rocket" "wp-super-cache")

  # Select a random number of plugins from the list
  local plugin_count=$((RANDOM % 5 + 1))  # Between 1 and 5 plugins

  for i in $(seq 1 "$plugin_count"); do
    local random_plugin="${plugins[$((RANDOM % ${#plugins[@]}))]}"
    local plugin_dir="${temp_dir}/${backup_hash}-plugin-${random_plugin}"

    # Create the plugin folder and add random files
    mkdir -p "$plugin_dir"
    echo "<?php echo 'Plugin Code'; ?>" > "${plugin_dir}/${random_plugin}.php"
    echo "$(generate_random_content)" > "${plugin_dir}/random_file.txt"
    echo "/* Styles for plugin */" > "${plugin_dir}/style.css"
  done
}

# Function to generate random theme files, using the passed backup_hash
generate_theme_files() {
  local backup_hash="$1"
  local temp_dir="$2"
  local random_theme_name=$(openssl rand -hex 4)
  local theme_dir="${temp_dir}/${backup_hash}-theme-${random_theme_name}"

  mkdir -p "$theme_dir"
  echo "<?php echo 'Random Theme'; ?>" > "${theme_dir}/randomtheme.php"
  echo "<?php echo 'Functions'; ?>" > "${theme_dir}/functions.php"
  echo "/* $(generate_random_content) */" > "${theme_dir}/styles.css"
}

# Function to generate random upload files, using the passed backup_hash
generate_upload_files() {
  local backup_hash="$1"
  local temp_dir="$2"
  local random_month=$(printf "%02d" $((RANDOM % 12 + 1)))
  local uploads_dir="${temp_dir}/2024/${random_month}"

  mkdir -p "$uploads_dir"
  for i in $(seq 1 $((RANDOM % 10 + 1))); do
    echo "$(generate_random_content)" > "${uploads_dir}/${backup_hash}-upload-image-${i}.jpg"
  done
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
    zip_file_plugins="${domain_dir}/backup_${formatted_date}-${random_time}_${domain_name}_${random_hash}-plugins.zip"
    zip_file_themes="${domain_dir}/backup_${formatted_date}-${random_time}_${domain_name}_${random_hash}-themes.zip"
    zip_file_uploads="${domain_dir}/backup_${formatted_date}-${random_time}_${domain_name}_${random_hash}-uploads.zip"
    
    # Create temporary directories to store files
    temp_dir_plugins=$(mktemp -d)
    temp_dir_themes=$(mktemp -d)
    temp_dir_uploads=$(mktemp -d)

    # Generate plugin, theme, and upload files, passing the backup_hash
    generate_plugin_files "$random_hash" "$temp_dir_plugins"
    generate_theme_files "$random_hash" "$temp_dir_themes"
    generate_upload_files "$random_hash" "$temp_dir_uploads"
    
    # Zip the directories
    zip -r "$zip_file_plugins" "$temp_dir_plugins"
    zip -r "$zip_file_themes" "$temp_dir_themes"
    zip -r "$zip_file_uploads" "$temp_dir_uploads"
    
    # Remove the temporary directories
    rm -rf "$temp_dir_plugins" "$temp_dir_themes" "$temp_dir_uploads"
    
    # Increment date by one day (86400 seconds)
    start_date_sec=$((start_date_sec + 86400))
  done

  echo "Created folders and backup files for ${domain_name} (${website_url})"
done

# Final summary
echo "All folders and backup files have been created under /files/${server_name}/"

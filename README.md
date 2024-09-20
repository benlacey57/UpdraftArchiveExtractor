# Daily Backup Extraction Script

## Purpose

This script is designed to extract daily website backup files so they can be scanned for malware by Imunify360 (or other scanning software). The script processes backup archives stored in server folders, extracts them into an `extracted` directory, and prepares the extracted files for malware scanning. 

Each backup archive is extracted into a folder with the same name as the archive file, ensuring that all files are ready for scanning. The script runs daily and removes old extracted files after successful extraction to avoid accumulation.

## Features

- **Server-Specific Backup Processing**: The script accepts a server folder name as an argument and processes backup archives for each website (domain) under that server.
- **Error Handling**: Backup archives are only deleted after successful extraction. If an error occurs during the extraction process, files will not be removed, and logs will provide detailed information for troubleshooting.
- **Automated Cleanup**: Old extracted files (older than one day) are automatically deleted after successful extraction of the new backups.
- **Per-Domain Logging**: Logs are generated for each domain, stored in a structured format (`logs/[date]/[server_name]/[domain_name].log`), making it easy to monitor the extraction status for each domain.

## Usage

### Prerequisites
- Ensure that your server has the necessary archive tools installed (`unzip`, `tar`, `gunzip`).
- The script assumes the following directory structure:
  - Backups are stored in `/files/<server_name>/` where each subfolder represents a domain (e.g., `firstdomain.com`, `seconddomain.co.uk`).
  - The extracted files are stored in `/extracted/<server_name>/`.
  - Logs are stored in `/logs`.

### Running the Script

To run the script, pass the server folder name as an argument. The script will process all website subfolders under that server folder.

#### Example Usage:

```bash
./extract_backups.sh wpx01
```

This command will:
1. Extract backup files from `/files/wpx01/`.
2. Store extracted files in `/extracted/wpx01/`.
3. Log the process in `/logs/`.

### Scheduling the Script

This script is designed to be run daily using cron jobs, typically after your backups have completed. You can set up a cron job for each server, specifying the desired time for the script to run.

#### Example Cron Job:

To schedule the script to run for server `WPX01` at 2 AM daily, add the following line to your crontab:

```bash
0 2 * * * /path/to/extract_backups.sh wpx01
```

For a second server `WPX02`, scheduled for 2:30 AM:

```bash
30 2 * * * /path/to/extract_backups.sh wpx02
```

### Logging

Logs are generated for each domain and stored in the following format:

```
logs/YYYY-MM-DD/[server_name]-[domain_name].log
```

Example:

```
logs/2024-09-19/WPX01-firstdomain.com.log
```

These logs provide detailed information about each extraction, including any errors encountered during the process.

### Error Handling

- If any part of the extraction process fails, the script will log the failure and skip the removal of old extracted files to prevent data loss.
- Supported file formats for extraction include `.zip`, `.tar.gz`, `.tgz`, and `.gz`. Unsupported formats are logged and skipped.

## Future Improvements

- **Integration with Imunify360 CLI**: Once Imunify360 provides a command-line interface, the script can be extended to trigger malware scans on each folder after extraction.
- **Database Scanning**: Imunify360 does not currently support scanning SQL dump files. When a CLI is available, the script can be modified to load the database dump, scan it, and then drop the temporary database.

## License

This script is provided as-is and can be modified to suit your needs. It is designed to automate backup extraction and provide a base for integrating malware scanning into your daily processes.

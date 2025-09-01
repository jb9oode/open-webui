# Open WebUI Backup System

This document describes the backup system for Open WebUI that follows the "Rsync Job With Container Interruption" approach from the documentation.

## Overview

The backup system consists of a shell script (`backup.sh`) that:

1. Stops the development server
2. Creates a timestamped backup of the Open WebUI data
3. Cleans up old backups (keeps last 7 days)

The backup runs daily at 4:00 AM via a crontab entry. Note that the development server
will be stopped during the backup process and will need to be started manually afterward.

## Backup Components

The backup includes the following components from `backend/data/`:

- `webui.db` - SQLite database containing chats, settings, etc.
- `uploads/` - Directory containing user-uploaded files
- `vector_db/` - Directory containing the ChromaDB vector database

The following are excluded from backups:
- `cache/` - Cache directory (can be regenerated)

## Backup Location

Backups are stored in `~/owui-bkup/` with timestamped directory names in the format:
`backup_YYYYMMDD_HHMMSS`

For example: `~/owui-bkup/backup_20250831_123450`

## Manual Backup Execution

To run a backup manually, execute:

```bash
cd /Users/johnb/Projects/open-webui/backend
./backup.sh
```

## Crontab Entry

The backup runs daily at 4:00 AM via the following crontab entry:

```
0 4 * * * /Users/johnb/Projects/open-webui/backend/backup.sh >> /Users/johnb/owui-bkup/backup.log 2>&1
```

To view the crontab entry:
```bash
crontab -l
```

To edit the crontab entry:
```bash
crontab -e
```

## Log Files

Backup logs are stored in `~/owui-bkup/backup.log`. This file contains:
- Backup start/stop timestamps
- Any errors encountered during the backup process
- Information about old backup cleanup

To view the log:
```bash
tail -f ~/owui-bkup/backup.log
```

## Backup Cleanup

The system automatically removes backups older than 7 days to prevent disk space issues.

## Restoring from Backup

To restore from a backup:

1. Stop the development server:
   ```bash
   pkill -f "uvicorn open_webui.main:app"
   ```

2. Copy the backup files to the data directory:
   ```bash
   cp -r ~/owui-bkup/backup_YYYYMMDD_HHMMSS/* /Users/johnb/Projects/open-webui/backend/data/
   ```

3. Start the development server manually:
   ```bash
   cd /Users/johnb/Projects/open-webui/backend
   ./dev.sh
   ```

Note: The backup script will stop the development server but will not start it again.
You must start the server manually after restoring from a backup.

## Troubleshooting

### Backup Script Fails to Stop Server
- Check if the server is running on port 8080:
  ```bash
  lsof -i :8080
  ```
- Manually kill the process if needed:
  ```bash
  kill -9 $(lsof -t -i:8080)
  ```

### No Backups Being Created
- Check the crontab entry:
  ```bash
  crontab -l
  ```
- Check the log file for errors:
  ```bash
  tail -20 ~/owui-bkup/backup.log
  ```

### Disk Space Issues
- Check disk space usage:
  ```bash
  du -sh ~/owui-bkup/
  ```
- Manually clean old backups if needed:
  ```bash
  find ~/owui-bkup/ -name "backup_*" -type d -mtime +7 -exec rm -rf {} +
  ```

## Customization

To modify the backup schedule, edit the crontab entry:
```bash
crontab -e
```

The cron format is: `minute hour day month day_of_week`

For example, to run at 2:30 AM daily:
```
30 2 * * * /Users/johnb/Projects/open-webui/backend/backup.sh >> /Users/johnb/owui-bkup/backup.log 2>&1
```

To change the backup retention period, modify the `clean_old_backups()` function in `backup.sh`.
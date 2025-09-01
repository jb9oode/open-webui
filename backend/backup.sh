#!/bin/bash

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_BASE_DIR="$HOME/owui-bkup"
SOURCE_DATA_DIR="$SCRIPT_DIR/data"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_DIR="$BACKUP_BASE_DIR/backup_$TIMESTAMP"

# Function to check if a process is running on a specific port
is_process_running() {
    local port=$1
    if lsof -i :$port >/dev/null 2>&1; then
        return 0  # Process is running
    else
        return 1  # Process is not running
    fi
}

# Function to stop the development server
stop_dev_server() {
    echo "Stopping development server..."
    
    # Check if process is running on port 8080 (default)
    if is_process_running 8080; then
        # Try to find and kill the uvicorn process
        pkill -f "uvicorn open_webui.main:app" 2>/dev/null
        
        # Wait a moment for the process to terminate
        sleep 2
        
        # Force kill if still running
        if is_process_running 8080; then
            echo "Force killing process on port 8080..."
            kill -9 $(lsof -t -i:8080) 2>/dev/null
            sleep 1
        fi
    fi
    
    echo "Development server stopped."
}

# Function to start the development server
start_dev_server() {
    echo "Starting development server..."
    
    # Change to the script directory
    cd "$SCRIPT_DIR"
    
    # Start the development server in the background
    nohup ./dev.sh > /dev/null 2>&1 &
    
    # Wait a moment for the server to start
    sleep 5
    
    if is_process_running 8080; then
        echo "Development server started successfully."
    else
        echo "Warning: Development server may not have started correctly."
        # Try to start with explicit shell
        nohup /bin/bash ./dev.sh > /dev/null 2>&1 &
        sleep 5
        if is_process_running 8080; then
            echo "Development server started successfully with explicit shell."
        else
            echo "Error: Failed to start development server."
        fi
    fi
    
    # Change back to the original directory
    cd - > /dev/null
}

# Function to create backup
create_backup() {
    echo "Creating backup..."
    
    # Create backup directory
    mkdir -p "$BACKUP_DIR"
    
    # Copy data with rsync, excluding cache directory
    rsync -av --exclude='cache/' "$SOURCE_DATA_DIR/" "$BACKUP_DIR/"
    
    # Check if rsync was successful
    if [ $? -eq 0 ]; then
        echo "Backup created successfully at $BACKUP_DIR"
        return 0
    else
        echo "Error: Backup creation failed"
        return 1
    fi
}

# Function to clean old backups (keep last 7 days)
clean_old_backups() {
    echo "Cleaning old backups..."
    
    # Find and remove backups older than 7 days
    find "$BACKUP_BASE_DIR" -name "backup_*" -type d -mtime +7 -exec rm -rf {} + 2>/dev/null
    
    echo "Old backups cleaned."
}

# Main execution
main() {
    echo "Starting Open WebUI backup process..."
    
    # Create backup base directory if it doesn't exist
    mkdir -p "$BACKUP_BASE_DIR"
    
    # Stop the development server
    stop_dev_server
    
    # Create the backup
    if create_backup; then
        # Clean old backups
        clean_old_backups
        
        echo "Backup process completed successfully."
        echo "NOTE: The development server has been stopped and will need to be started manually."
        exit 0
    else
        echo "Backup process failed."
        echo "NOTE: The development server has been stopped and will need to be started manually."
        exit 1
    fi
}

# Run main function
main "$@"
#!/bin/bash

SERVER="server.py"  
LOG_DIR="./logs"     # Directory where logs will be stored
LOG_FILE="$LOG_DIR/$(date +'%Y-%m-%d')_gpsx.log"  # Daily log file
PID_FILE="./gpsx_pid.txt" 

check_server_running() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p $PID > /dev/null; then
            echo "GPS-X server is already running with PID $PID."
            return 1
        else
            echo "Stale PID file found. Removing..."
            rm "$PID_FILE"
        fi
    fi
    return 0
}

# Function to start the  server
start_server() {
    echo "Starting GPS-X  server..."

    # Create logs directory if it doesn't exist
    mkdir -p "$LOG_DIR"

    # Run the server in the background and log output
    nohup python3 "$SERVER" > "$LOG_FILE" 2>&1 &

    # Get the PID of the  server and save it to a file
    echo $! > "$PID_FILE"
    echo "GPS-X server started with PID $(cat "$PID_FILE"). Logs are being written to $LOG_FILE."
}

# Function to stop the  server
stop_server() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        echo "Stopping GPS-X server with PID $PID..."
        kill $PID
        rm "$PID_FILE"
        echo "GPS-X server stopped."
    else
        echo "No GPS-X server is running."
    fi
}

# Function to restart  server
restart_server() {
    stop_server
    start_server
}

# Main logic to check for user arguments and start/stop/restart  server
case "$1" in
    start)
        check_server_running
        if [ $? -eq 0 ]; then
            start_server
        fi
        ;;
    stop)
        stop_server
        ;;
    restart)
        restart_server
        ;;
    status)
        if [ -f "$PID_FILE" ]; then
            PID=$(cat "$PID_FILE")
            if ps -p $PID > /dev/null; then
                echo "GPS-X is running with PID $PID."
            else
                echo "GPS-X is not running, but PID file exists."
            fi
        else
            echo "GPS-X is not running."
        fi
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status}"
        exit 1
        ;;
esac

#!/bin/bash

# Logging Module
source core/banner.sh

LOG_FILE="results/logs.txt"

ensure_log_dir() {
    mkdir -p "$(dirname "$LOG_FILE")"
}

log_attack() {
    local method=$1
    local target=$2
    local port=$3
    local duration=$4
    local threads=$5
    
    ensure_log_dir
    
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local log_entry="[$timestamp] Attack: $method | Target: $target:$port | Duration: ${duration}s | Threads: $threads | User: $(whoami)"
    
    echo "$log_entry" >> "$LOG_FILE"
    echo -e "${GREEN}Attack logged to $LOG_FILE${NC}"
}

log_event() {
    local event=$1
    
    ensure_log_dir
    
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local log_entry="[$timestamp] EVENT: $event"
    
    echo "$log_entry" >> "$LOG_FILE"
}

log_error() {
    local error=$1
    
    ensure_log_dir
    
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local log_entry="[$timestamp] ERROR: $error"
    
    echo "$log_entry" >> "$LOG_FILE"
    echo -e "${RED}Error logged: $error${NC}"
}

show_logs() {
    if [[ -f "$LOG_FILE" ]]; then
        echo -e "${CYAN}Recent attack logs:${NC}"
        tail -20 "$LOG_FILE"
    else
        echo -e "${YELLOW}No logs found${NC}"
    fi
}

clear_logs() {
    if [[ -f "$LOG_FILE" ]]; then
        > "$LOG_FILE"
        echo -e "${GREEN}Logs cleared${NC}"
    else
        echo -e "${YELLOW}No logs to clear${NC}"
    fi
}

export_logs() {
    local export_file=$1
    
    if [[ -f "$LOG_FILE" ]]; then
        cp "$LOG_FILE" "$export_file"
        echo -e "${GREEN}Logs exported to $export_file${NC}"
    else
        echo -e "${YELLOW}No logs to export${NC}"
    fi
}


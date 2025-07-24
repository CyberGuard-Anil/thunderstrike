#!/bin/bash
#
# logger.sh - Centralized Logging Module for ThunderStrike Toolkit
# Author: CyberGuard-Anil
# Use for ETHICAL, AUTHORIZED TESTING only in labs or owned networks.
#

source core/banner.sh

LOG_FILE="results/logs.txt"
MAX_LOG_SIZE=$((1024*1024))   # 1MB

# Color codes for output
GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Print post-attack legal/ethical notice
print_logger_banner() {
    echo -e "${YELLOW}"
    echo "═════════════════════════════════════════════"
    echo "    Logging for AUTHORIZED Ethical Use Only!"
    echo "═════════════════════════════════════════════"
    echo -e "${NC}"
}

ensure_log_dir() {
    mkdir -p "$(dirname "$LOG_FILE")"
}

rotate_logfile_if_needed() {
    if [[ -f "$LOG_FILE" && $(stat -c %s "$LOG_FILE") -gt $MAX_LOG_SIZE ]]; then
        local timestamp
        timestamp=$(date '+%Y%m%d_%H%M%S')
        local backup="results/logs_$timestamp.txt"
        mv "$LOG_FILE" "$backup"
        echo -e "${YELLOW}[LOGGER] Log rotated: $backup${NC}"
        touch "$LOG_FILE"
    fi
}

# Log one attack attempt (called after every attack launch)
log_attack() {
    local method="$1"
    local target="$2"
    local port="$3"
    local duration="$4"
    local threads="$5"
    ensure_log_dir
    rotate_logfile_if_needed
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local log_entry="[$timestamp] Attack: $method | Target: $target:$port | Duration: ${duration}s | Threads: $threads | User: $(whoami)"
    echo "$log_entry" >> "$LOG_FILE"
    echo -e "${GREEN}Attack logged to $LOG_FILE${NC}"
}

# Log a generic info event
log_event() {
    local event="$1"
    ensure_log_dir
    rotate_logfile_if_needed
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local log_entry="[$timestamp] EVENT: $event"
    echo "$log_entry" >> "$LOG_FILE"
}

# Log an error condition
log_error() {
    local error="$1"
    ensure_log_dir
    rotate_logfile_if_needed
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local log_entry="[$timestamp] ERROR: $error"
    echo "$log_entry" >> "$LOG_FILE"
    echo -e "${RED}Error logged: $error${NC}"
}

# Show recent logs
show_logs() {
    if [[ -f "$LOG_FILE" ]]; then
        echo -e "${CYAN}Recent attack logs:${NC}"
        tail -20 "$LOG_FILE"
    else
        echo -e "${YELLOW}No logs found${NC}"
    fi
}

# Clear all logs (confirmation recommended)
clear_logs() {
    if [[ -f "$LOG_FILE" ]]; then
        > "$LOG_FILE"
        echo -e "${GREEN}Logs cleared${NC}"
    else
        echo -e "${YELLOW}No logs to clear${NC}"
    fi
}

# Export current log file to custom destination
export_logs() {
    local export_file="$1"
    if [[ -f "$LOG_FILE" ]]; then
        cp "$LOG_FILE" "$export_file"
        echo -e "${GREEN}Logs exported to $export_file${NC}"
    else
        echo -e "${YELLOW}No logs to export${NC}"
    fi
}

# Optional: when sourcing, print banner
print_logger_banner

# Optionally, export functions if used modularly
export log_attack log_event log_error show_logs clear_logs export_logs


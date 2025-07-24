#!/bin/bash
#
# cleanup.sh — Restore lab/test environment after ThunderStrike runs
# Author: CyberGuard-Anil
#
# Use only on your own lab/test VM/host!
# WARNING: Never run on critical or production systems.

source core/banner.sh
source utils/logger.sh

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${YELLOW}═════════════════════════════════════════════════"
echo -e "         ThunderStrike Environment Cleanup"
echo -e "═════════════════════════════════════════════════${NC}"

# Close likely background attack/test processes safely
cleanup_processes() {
    echo -e "${CYAN}Killing any running attack tools/processes...${NC}"
    PATTERNS=("hping3" "nping" "slowloris.py" "syn_flood.py" "udp_flood.go" "thunderstrike.sh" "tcp_flood.sh" "udp_flood.sh")
    for proc in "${PATTERNS[@]}"; do
        pkill -f "$proc" && echo -e " ${GREEN}Stopped $proc${NC}" || true
    done
}

# Optional: Reset the UFW firewall if used for basic testing in Ubuntu labs
reset_firewall() {
    if command -v ufw > /dev/null; then
        echo -e "${CYAN}Resetting UFW firewall rules...${NC}"
        sudo ufw disable
        sudo ufw enable
        echo -e "${GREEN}UFW (Uncomplicated Firewall) was reset to defaults.${NC}"
    else
        echo -e "${YELLOW}(UFW firewall not detected. Skipping.)${NC}"
    fi
}

# Optional: Clean custom iptables rules if you used them for SYN/UDP/ICMP tests
reset_iptables() {
    if command -v iptables > /dev/null; then
        echo -e "${CYAN}Resetting iptables rules...${NC}"
        sudo iptables -F
        sudo iptables -X
        echo -e "${GREEN}iptables rules flushed.${NC}"
    else
        echo -e "${YELLOW}(iptables not detected. Skipping.)${NC}"
    fi
}

# Optionally clear network connections by restarting networking (advanced/lab only!)
# reset_network() {
#     echo -e "${CYAN}Restarting networking (restart might disrupt SSH/tests)...${NC}"
#     sudo systemctl restart networking || true
# }

# Log the cleanup event
log_event "Test/lab environment cleanup executed by '$(whoami)'"

# Run all cleanup actions
cleanup_processes
reset_firewall
reset_iptables

# reset_network             # Uncomment if you need to reset all network settings HARD.

echo -e "${GREEN}Cleanup completed. Lab/system should be ready for next test.${NC}"


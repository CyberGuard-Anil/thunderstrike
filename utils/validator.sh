#!/bin/bash

# Input Validation Module
source core/banner.sh

validate_ip() {
    local ip=$1
    
    # Check if it's a valid IP address or hostname
    if [[ $ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        # Validate IP address format
        local IFS='.'
        local ip_array=($ip)
        [[ ${#ip_array[@]} -eq 4 ]] || {
            echo -e "${RED}Error: Invalid IP address format${NC}"
            exit 1
        }
        for octet in "${ip_array[@]}"; do
            [[ $octet -ge 0 && $octet -le 255 ]] || {
                echo -e "${RED}Error: Invalid IP address range${NC}"
                exit 1
            }
        done
    else
        # Check if hostname is reachable
        if ! ping -c 1 "$ip" &> /dev/null; then
            echo -e "${YELLOW}Warning: Target may not be reachable${NC}"
        fi
    fi
    
    echo -e "${GREEN}Target validation: OK${NC}"
}

validate_port() {
    local port=$1
    
    if ! [[ "$port" =~ ^[0-9]+$ ]] || [[ $port -lt 1 ]] || [[ $port -gt 65535 ]]; then
        echo -e "${RED}Error: Invalid port number (1-65535)${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}Port validation: OK${NC}"
}

validate_duration() {
    local duration=$1
    
    if ! [[ "$duration" =~ ^[0-9]+$ ]] || [[ $duration -lt 1 ]] || [[ $duration -gt 3600 ]]; then
        echo -e "${RED}Error: Invalid duration (1-3600 seconds)${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}Duration validation: OK${NC}"
}

validate_threads() {
    local threads=$1
    
    if ! [[ "$threads" =~ ^[0-9]+$ ]] || [[ $threads -lt 1 ]] || [[ $threads -gt 1000 ]]; then
        echo -e "${RED}Error: Invalid thread count (1-1000)${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}Thread validation: OK${NC}"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${YELLOW}Warning: Some attacks may require root privileges${NC}"
        return 1
    fi
    return 0
}

check_network() {
    local target=$1
    
    echo -e "${CYAN}Checking network connectivity...${NC}"
    
    if ping -c 1 "$target" &> /dev/null; then
        echo -e "${GREEN}Target is reachable${NC}"
        return 0
    else
        echo -e "${RED}Warning: Target may not be reachable${NC}"
        return 1
    fi
}


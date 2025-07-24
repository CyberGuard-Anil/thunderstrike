#!/bin/bash

# Dependency Checker Module
source core/banner.sh

check_dependencies() {
    echo -e "${CYAN}Checking dependencies...${NC}"
    
    local missing_deps=()
    
    # Essential tools
    local deps=("hping3" "nc" "ping" "timeout")
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        else
            echo -e "${GREEN}✓ $dep found${NC}"
        fi
    done
    
    # Optional tools
    local optional_deps=("nping" "nmap" "python3" "go")
    
    echo -e "\n${CYAN}Optional dependencies:${NC}"
    for dep in "${optional_deps[@]}"; do
        if command -v "$dep" &> /dev/null; then
            echo -e "${GREEN}✓ $dep found${NC}"
        else
            echo -e "${YELLOW}✗ $dep not found (optional)${NC}"
        fi
    done
    
    # Check if any essential deps are missing
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        echo -e "\n${RED}Missing essential dependencies:${NC}"
        for dep in "${missing_deps[@]}"; do
            echo -e "${RED}✗ $dep${NC}"
        done
        
        echo -e "\n${YELLOW}Installation commands:${NC}"
        echo -e "Ubuntu/Debian: ${CYAN}sudo apt-get install hping3 netcat-openbsd iputils-ping coreutils${NC}"
        echo -e "CentOS/RHEL:   ${CYAN}sudo yum install hping3 nc iputils coreutils${NC}"
        echo -e "Arch Linux:    ${CYAN}sudo pacman -S hping netcat iputils coreutils${NC}"
        
        exit 1
    fi
    
    echo -e "\n${GREEN}All essential dependencies satisfied!${NC}"
}

check_permissions() {
    echo -e "${CYAN}Checking permissions...${NC}"
    
    if [[ $EUID -eq 0 ]]; then
        echo -e "${GREEN}✓ Running as root - all attacks available${NC}"
    else
        echo -e "${YELLOW}! Running as user - some attacks may be limited${NC}"
        echo -e "${YELLOW}  Run with sudo for full functionality${NC}"
    fi
}

check_system_resources() {
    echo -e "${CYAN}Checking system resources...${NC}"
    
    # Check available memory
    local mem_available=$(free -m | awk 'NR==2{printf "%.1f", $7/1024}')
    echo -e "${GREEN}Available memory: ${mem_available}GB${NC}"
    
    # Check CPU cores
    local cpu_cores=$(nproc)
    echo -e "${GREEN}CPU cores: $cpu_cores${NC}"
    
    # Check network interfaces
    local interfaces=$(ip link show | grep -E "^[0-9]+" | cut -d: -f2 | tr -d ' ')
    echo -e "${GREEN}Network interfaces:${NC}"
    for iface in $interfaces; do
        if [[ $iface != "lo" ]]; then
            echo -e "  ${CYAN}$iface${NC}"
        fi
    done
}

performance_test() {
    local target=$1
    
    echo -e "${CYAN}Running performance test...${NC}"
    
    # Test ping response time
    local ping_time=$(ping -c 3 "$target" 2>/dev/null | tail -1 | awk -F '/' '{print $5}')
    if [[ -n "$ping_time" ]]; then
        echo -e "${GREEN}Average ping time: ${ping_time}ms${NC}"
    else
        echo -e "${YELLOW}Could not determine ping time${NC}"
    fi
    
    # Test bandwidth (simplified)
    echo -e "${CYAN}Network interface status:${NC}"
    ip link show | grep -E "(UP|DOWN)" | head -3
}


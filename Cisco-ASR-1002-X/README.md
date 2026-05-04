DIAGRAM
<img width="1056" height="780" alt="image" src="https://github.com/user-attachments/assets/6d8f03a3-d087-4ed9-8f84-b8e98b175cbb" />






# Cisco-ASR-1002-X
Cisco ASR 1002-X, hybrid routing demo walk thru

Cisco
https://www.cisco.com/c/en/us/products/collateral/routers/asr-1000-series-aggregation-services-routers/datasheet-c78-731632.html

Spec Overview
Cisco ASR 1000 Series Aggregation Services Routers provide a Software Defined WAN platform that aggregates multiple WAN connections and network services including encryption and traffic management, and forward them across WAN connections at line speeds from 2.5 to 200 Gbps. 
The routers contain both hardware and software redundancy in an industry-leading high-availability design.
The latest additions to the Cisco ASR 1000 Series are the Cisco ASR 1002-HX Router and the Cisco ASR 1001-HX Router. Both new routers support up to 100 Gbps in a 2-Rack-Unit (2RU) and 60 Gbps in a 1-Rack-Unit (1RU) form factor, respectively. 

The ASR 1002-HX has 8 built-in 10 Gigabit Ethernet (GE) ports and 8 1 GE ports, with the Ethernet Port Adapter (EPA) slot for expansion. The ASR 1001-HX has 4 built-in 10 GE ports, 8 1 GE ports, and 4 configurable 10 GE or 1 GE ports.



<img width="1113" height="603" alt="image" src="https://github.com/user-attachments/assets/34c46c58-e930-4f6b-af9b-2ce55b43d61f" />





basic Cisco Routing config > Platform: Cisco ASR 1002-X (IOS-XE)


Commands:
1. Enter Configuration Mode
enable
configure terminal

2. Basic System Setup (Recommended)
hostname ASR1002X
no ip domain-lookup

3. Identify RJ-45 Interfaces
GigabitEthernet0/0/0
GigabitEthernet0/0/1
GigabitEthernet0/0/2
GigabitEthernet0/0/3

Verify on your device:
show ip interface brief


4. Configure LAN Interface (RJ-45)
   Example
Interface: GigabitEthernet0/0/0
IP: 192.168.1.1 /24

interface GigabitEthernet0/0/0
 description LAN - Internal Network
 ip address 192.168.1.1 255.255.255.0
 no shutdown
 exit

5. Configure WAN Interface (RJ-45)
   Example
Interface: GigabitEthernet0/0/1
IP: 10.0.0.1 /30

interface GigabitEthernet0/0/1
 description WAN - Upstream Router
 ip address 10.0.0.1 255.255.255.252
 no shutdown
 exit


6. Verify Interface Status
   show ip interface brief

7. Configure Static Routing, Default Route (Most Common)
ip route 0.0.0.0 0.0.0.0 10.0.0.2

or:
Specific Remote Network

example >> ip route 172.16.0.0 255.255.0.0 10.0.0.2

9. Verify Routing Table
show ip route

10. Basic Connectivity Test
ping 10.0.0.2
ping 192.168.1.10
traceroute 8.8.8.8


11. Save Configuration (Critical)
copy running-config startup-config

12. Minimal Verification Commands (RJ-45 Focused)
show running-config
show ip route
show ip interface brief
show interfaces GigabitEthernet0/0/0
show interfaces GigabitEthernet0/0/1

DONE!!!

What This Config Gives You?:
✔ Router boots clean
✔ Copper LAN ↔ WAN routing
✔ Static routing operational
Ready For Next Steps>>

NEXT STEPS:
NAT
ACLs
OSPF/BGP
VRFs
Internet edge deployment

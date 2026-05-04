# Networking_Homework_010526

**Tasks** 
1.	Create a diagram that illustrates how EIGRP and BGP routes can be injected into OSPF Area 1 and Area 0. 
2.	Create OSPF configuration for router OSPF-R1 that redistributes BGP and EIGRP routes into area 1 and area 0.
3.	Create BGP configuration for router BGP-R1 that routes and receives traffic to and from EIGRP routes, OSPF areas and SD-WAN.
4.	Create Ansible playbooks to automate the configurations for BGP-R1 and OSPF-R1.

---
**Diagram** 

<img width="1095" height="690" alt="image" src="https://github.com/user-attachments/assets/db6dd926-fc5e-4fb2-96f3-7251ae76765c" />



---
**Configurations** 

**OSPF-R1**

! =========================
! Basic interfaces / IPs
! =========================
hostname OSPF-R1

interface GigabitEthernet0/0/0/0
 description To OSPF Area 0 LAN (10.10.0.0/24)
 ipv4 address 10.10.0.1 255.255.255.0
 no shutdown

interface GigabitEthernet0/0/0/1
 description OSPF Area 1 LAN (10.10.1.0/24)
 ipv4 address 10.10.1.1 255.255.255.0
 no shutdown

interface GigabitEthernet0/0/0/2
 description Transit to BGP-R1 (10.10.30.0/30)
 ipv4 address 10.10.30.1 255.255.255.252
 no shutdown

! ==========================================================
! Prefix-sets + route-policies for controlled redistribution
! ==========================================================
prefix-set EIGRP1_PREFIXES
  10.10.11.0/24
end-set

prefix-set BGP65000_PREFIXES
  10.10.22.0/24
end-set

route-policy OSPF_REDIST_FROM_BGP
  if destination in EIGRP1_PREFIXES or destination in BGP65000_PREFIXES then
    set metric 20
    set metric-type type-1
    pass
  else
    drop
  endif
end-policy


route-policy BGP_EXPORT_OSPF_CONNECTED
  if destination in (10.10.0.0/24, 10.10.1.0/24) then
    pass
  else
    drop
  endif
end-policy

route-policy BGP_IMPORT_ALL
  pass
end-policy


! =========================
! OSPF
! =========================
router ospf 1
 router-id 1.1.1.1

 area 0
  interface GigabitEthernet0/0/0/0
   passive enable
  !
  interface GigabitEthernet0/0/0/2
   passive disable
  !
 !

 area 1
  interface GigabitEthernet0/0/0/1
   passive enable
  !
 !

 ! Redistribute BGP into OSPF (includes EIGRP routes carried in BGP)
 redistribute bgp 65000 route-policy OSPF_REDIST_FROM_BGP
!


! =========================
! BGP (iBGP to BGP-R1)
! =========================
router bgp 65000
 bgp router-id 1.1.1.1

 neighbor 10.10.30.2
  remote-as 65000
  description iBGP to BGP-R1 over 10.10.30.0/30
  address-family ipv4 unicast
   route-policy BGP_IMPORT_ALL in
   route-policy BGP_EXPORT_OSPF_CONNECTED out
  !
 !

 ! Optional (if you prefer redistribution instead of explicit export):
 ! redistribute ospf 1 route-policy BGP_EXPORT_OSPF_CONNECTED
 !
!


---
**BGP-R1**

! =========================
! BASIC INTERFACES
! =========================
hostname BGP-R1
ip routing

!
! ---- Link to OSPF-R1 (OSPF Area 1) ----
interface GigabitEthernet0/0/0
 description To OSPF-R1 (10.10.30.0/30)
 ip address 10.10.30.2 255.255.255.252
 no shutdown

!
! ---- Link to EIGRP domain ----
interface GigabitEthernet0/0/1
 description To EIGRP-1 domain (10.10.30.4/30)
 ip address 10.10.30.5 255.255.255.252
 no shutdown

!
! ---- Local LAN on BGP-R1 ----
interface GigabitEthernet0/0/2
 description BGP-R1 LAN (10.10.22.0/24)
 ip address 10.10.22.1 255.255.255.0
 no shutdown


! ==========================================================
! VRF FOR "BGP VPN" PEERING TO AS 65021
! ==========================================================
vrf definition VPN65021
 rd 65000:21
 route-target export 65000:21
 route-target import 65000:21
 address-family ipv4
 exit-address-family

interface GigabitEthernet0/0/3
 description BGP VPN link to AS 65021 (169.254.30.0/30)
 vrf forwarding VPN65021
 ip address 169.254.30.1 255.255.255.252
 no shutdown


! =========================
! OSPF (AREA 1)
! =========================
router ospf 1
 router-id 2.2.2.2
 passive-interface default
 no passive-interface GigabitEthernet0/0/0
 network 10.10.30.0 0.0.0.3 area 1
 network 10.10.22.0 0.0.0.255 area 1
 !
 ! (Optional) If you want OSPF to learn EIGRP/BGP routes via redistribution from THIS router:
 ! redistribute eigrp 1 subnets route-map RM_EIGRP_TO_OSPF
 ! redistribute bgp 65000 subnets route-map RM_BGP_TO_OSPF
!

! =========================
! EIGRP 1
! =========================
router eigrp 1
 eigrp router-id 2.2.2.2
 network 10.10.30.4 0.0.0.3
 no auto-summary
 !
 ! (Optional) advertise the local LAN into EIGRP if desired:
 network 10.10.22.0 0.0.0.255
 !
 ! (Optional) If you want EIGRP to learn OSPF/BGP routes via redistribution:
 ! redistribute ospf 1 metric 10000 100 255 1 1500 route-map RM_OSPF_TO_EIGRP
 ! redistribute bgp 65000 metric 10000 100 255 1 1500 route-map RM_BGP_TO_EIGRP
!


! ==========================================================
! BGP (AS 65000)
!  - iBGP to OSPF-R1 over 10.10.30.0/30
!  - eBGP in VRF to AS 65021 over 169.254.30.0/30
! ==========================================================
router bgp 65000
 bgp log-neighbor-changes

 ! ---- iBGP to OSPF-R1 (same AS) ----
 neighbor 10.10.30.1 remote-as 65000
 neighbor 10.10.30.1 description iBGP to OSPF-R1
 !
 address-family ipv4
  neighbor 10.10.30.1 activate
  !
  ! Advertise local LAN into the core so OSPF-R1 can learn it via iBGP
  network 10.10.22.0 mask 255.255.255.0
  !
  ! If you want BGP to carry OSPF and EIGRP routes:
  redistribute ospf 1 route-map RM_OSPF_TO_BGP
  redistribute eigrp 1 route-map RM_EIGRP_TO_BGP
 exit-address-family


 ! ---- VRF eBGP "BGP VPN" to AS 65021 ----
 address-family ipv4 vrf VPN65021
  neighbor 169.254.30.2 remote-as 65021
  neighbor 169.254.30.2 description eBGP to AS65021 over VPN link
  neighbor 169.254.30.2 activate
  !
  ! Ensure 10.10.21.0/24 is accepted (learned) from AS65021
  neighbor 169.254.30.2 route-map RM_IN_65021 in
  !
  ! Optionally advertise your side into AS65021 (pick what you want them to see)
  neighbor 169.254.30.2 route-map RM_OUT_65021 out
 exit-address-family
!


! ==========================================================
! ROUTE-MAPS / PREFIX-LISTS (CONTROL WHAT MOVES WHERE)
! ==========================================================

ip prefix-list PL_10_10_21 permit 10.10.21.0/24
ip prefix-list PL_10_10_11 permit 10.10.11.0/24
ip prefix-list PL_10_10_22 permit 10.10.22.0/24

!
! Allow ONLY 10.10.21.0/24 inbound from AS65021 (per your requirement)
route-map RM_IN_65021 permit 10
 match ip address prefix-list PL_10_10_21

!
! What you advertise to AS65021 (edit as needed)
! Example: advertise only your local 10.10.22.0/24
route-map RM_OUT_65021 permit 10
 match ip address prefix-list PL_10_10_22

!
! What you redistribute from OSPF -> BGP (keep it tight)
route-map RM_OSPF_TO_BGP permit 10
 match ip address prefix-list PL_10_10_22
!
! What you redistribute from EIGRP -> BGP (so OSPF-R1 can learn 10.10.11.0/24 via iBGP)
route-map RM_EIGRP_TO_BGP permit 10
 match ip address prefix-list PL_10_10_11

!
! (Optional) If you later enable redistribution into OSPF/EIGRP, build matching controls:
route-map RM_BGP_TO_OSPF permit 10
 match ip address prefix-list PL_10_10_21
!
route-map RM_BGP_TO_EIGRP permit 10
 match ip address prefix-list PL_10_10_21


! ==========================================================
! BASIC SD-WAN CLOUD "UNDERLAY" HANDOFF
! (Generic WAN interface + default route)
! ==========================================================
interface GigabitEthernet0/0/4
 description WAN to SD-WAN Cloud / ISP Underlay
 ip address dhcp
 no shutdown

ip route 0.0.0.0 0.0.0.0 dhcp

---
***Ansible Playbook***
***OSPF-R1***

1) Install Ansible collections
```Bash
ansible-galaxy collection install cisco.iosxr ansible.netcommon
```
2) Folder layout (recommended)
   
<img width="169" height="140" alt="image" src="https://github.com/user-attachments/assets/4fa28184-6696-47b6-9de0-4c4601db8803" />

3) inventory.yml
```yml
all:
  children:
    iosxr:
      hosts:
        ospf-r1:
          ansible_host: 192.0.2.10
          ansible_user: admin
          ansible_password: "YourPasswordHere"
          ansible_connection: ansible.netcommon.network_cli
          ansible_network_os: cisco.iosxr.iosxr
          ansible_port: 22
```

4) Playbook: playbooks/ospf_r1.yml
   
`note:This renders the template and pushes it to the device.`

<img width="822" height="931" alt="image" src="https://github.com/user-attachments/assets/d8bb1e56-43b3-49be-9e47-f3c77903a479" />

5) Run it

`Optional: Quick “dry run” / diff mode`

```bash
ansible-playbook -i inventory.yml playbooks/ospf_r1.yml --check --diff
```
`Run from the iosxr-lab/ directory:`
```bash
ansible-playbook -i inventory.yml playbooks/ospf_r1.yml
```

---
***Ansible Playbook***
***BGP-R1***

1) Install collections
```bash
ansible-galaxy collection install cisco.ios ansible.netcommon
```
2) Recommended folder layout

<img width="152" height="121" alt="image" src="https://github.com/user-attachments/assets/25531db6-2208-4003-8f54-10960e79a497" />

3) inventory.yml

`Replace ansible_host, credentials, and optionally SSH port.`

```yml
all:
  children:
    iosxe:
      hosts:
        bgp-r1:
          ansible_host: 192.0.2.20
          ansible_user: admin
          ansible_password: "YourPasswordHere"
          ansible_connection: ansible.netcommon.network_cli
          ansible_network_os: cisco.ios.ios
          ansible_port: 22
```

4) Playbook: playbooks/bgp_r1.yml

<img width="971" height="1300" alt="image" src="https://github.com/user-attachments/assets/a1df0c66-3cff-481f-a351-b95d8ece90dd" />

5) Run it
   
`Optional dry-run + diff:~

```bash

ansible-playbook -i inventory.yml playbooks/bgp_r1.yml --check --diff
```
`From the iosxe-lab/ directory:`

```bash
ansible-playbook -i inventory.yml playbooks/bgp_r1.yml
```

***Quick verification commands (on BGP-R1)***

```cisco
show ip ospf neighbor
show ip eigrp neighbors
show ip bgp summary
show ip bgp vpnv4 vrf VPN65021 summary
show ip route vrf VPN65021 10.10.21.0
show ip route 10.10.21.0
```


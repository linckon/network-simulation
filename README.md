# Linux Network Namespace Simulation

Network namespaces in Linux allow for the creation of isolated network environments within a single host. This documentation will help you understand how to create and manage multiple network namespaces and connect them using bridges and routing.

## Main Objective

Create a network simulation with two separate networks connected via a router using Linux network namespaces and bridges.

## Prerequisites

- Linux operating system
- Root or sudo access
- Packages

    ```bash
    sudo apt update
    sudo apt upgrade -y
    sudo apt install iproute2
    sudo apt install net-tools
    ```


# Steps

## 1. Creating Network Namespaces

```shell
sudo ip netns add ns1
sudo ip netns add ns2
sudo ip netns add router-ns
```
- Creates three isolated network namespaces
- ns1 and ns2 represent end hosts
- router-ns acts as a router between the two networks

## 2. Creating Bridges

```shell
sudo ip link add br0 type bridge
sudo ip link add br1 type bridge
sudo ip link set dev br0 up
sudo ip link set dev br1 up
```
- Creates two bridge interfaces (br0 and br1)
- Bridges act as virtual switches
- br0 connects ns1 to router-ns
- br1 connects ns2 to router-ns
- Brings up the bridges to active state

## 3. Creating Virtual Ethernet Pairs

```shell
sudo ip link add veth0 type veth peer name veth0-ns
sudo ip link add veth1 type veth peer name veth1-ns
sudo ip link add vr0 type veth peer name vr0-ns
sudo ip link add vr1 type veth peer name vr1-ns
```
- Creates virtual ethernet pairs (like virtual network cables)
- Each pair has two ends:
   - veth0 <-> veth0-ns: Connects ns1 to br0
   - veth1 <-> veth1-ns: Connects ns2 to br1
   - vr0 <-> vr0-ns: Connects router-ns to br0
   - vr1 <-> vr1-ns: Connects router-ns to br1

## 4. Setting Up Interfaces

```shell
sudo ip link set veth0-ns netns ns1
sudo ip link set veth1-ns netns ns2
sudo ip link set veth0 master br0
sudo ip link set veth1 master br1
sudo ip link set vr0 master br0
sudo ip link set vr1 master br1
sudo ip link set vr0-ns netns router-ns
sudo ip link set vr1-ns netns router-ns
```
- Moves interface endpoints to their respective namespaces
- Connects interfaces to bridges
- Creates the complete network topology

## 5. Assigning IP Addresses

```shell
sudo ip netns exec ns1 ip addr add 10.11.0.2/24 dev veth0-ns
sudo ip netns exec ns2 ip addr add 10.12.0.3/24 dev veth1-ns
sudo ip netns exec router-ns ip addr add 10.11.0.1/24 dev vr0-ns
sudo ip netns exec router-ns ip addr add 10.12.0.1/24 dev vr1-ns
```
- Assigns IP addresses to interfaces in each namespace
- Creates two subnets:
  - 10.11.0.0/24 for ns1 network
  - 10.12.0.0/24 for ns2 network
- Router interfaces act as default gateways

## 6. Setting Interface States

```shell
sudo ip netns exec ns1 ip link set dev veth0-ns up
sudo ip netns exec ns2 ip link set dev veth1-ns up
sudo ip netns exec router-ns ip link set dev vr0-ns up
sudo ip netns exec router-ns ip link set dev vr1-ns up
sudo ip link set dev veth0 up
sudo ip link set dev veth1 up
sudo ip link set dev vr0 up
sudo ip link set dev vr1 up
```

## 7. Configuring Routes

```shell
sudo ip netns exec ns1 ip route add default via 10.11.0.1
sudo ip netns exec ns2 ip route add default via 10.12.0.1
```
- Sets up default routes in ns1 and ns2
- All traffic from ns1 goes through 10.11.0.1 (router-ns)
- All traffic from ns2 goes through 10.12.0.1 (router-ns)

## 8. Testing Connectivity

```shell
sudo ip netns exec ns1 ping -c 4 10.12.0.3
```

I have written a bash script to automate the simulation called network_simulation.sh

- Make it executable: chmod +x network_simulation.sh
- Run it with:
    - ./network_simulation.sh  - (no argument provided)

    *Output:*

    ```bash
        root@ubuntu-host ~ ➜  ./simulation.sh 
        Usage: ./simulation.sh [setup|test|cleanup]
        setup   - Set up the network configuration
        test    - Test network connectivity
        cleanup - Remove all network configurations
    ```
    - ./network_simulation.sh setup - To set up the network

    *Output:*

    ```bash
        root@ubuntu-host ~ ➜  ./simulation.sh setup
        Creating namespaces...
        Creating bridges...
        Creating virtual ethernet pairs...
        Setting up interfaces...
        Assigning IP addresses...
        Setting interface states...
        Configuring routes...
    ```

    - ./network_simulation.sh test - To test connectivity

     *Output:*

    ```bash
        root@ubuntu-host ~ ➜ ./simulation.sh test
        Testing connectivity...
        PING 10.12.0.3 (10.12.0.3) 56(84) bytes of data.
        64 bytes from 10.12.0.3: icmp_seq=1 ttl=63 time=0.085 ms
        64 bytes from 10.12.0.3: icmp_seq=2 ttl=63 time=0.066 ms
        64 bytes from 10.12.0.3: icmp_seq=3 ttl=63 time=0.078 ms
        64 bytes from 10.12.0.3: icmp_seq=4 ttl=63 time=0.061 ms

        --- 10.12.0.3 ping statistics ---
        4 packets transmitted, 4 received, 0% packet loss, time 3077ms
        rtt min/avg/max/mdev = 0.061/0.072/0.085/0.009 ms
    ```

    - ./network_simulation.sh cleanup - To clean up all configurations
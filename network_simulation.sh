#!/bin/bash

# Function to create network namespaces
create_namespaces() {
    echo "Creating namespaces..."
    sudo ip netns add ns1
    sudo ip netns add ns2
    sudo ip netns add router-ns
}

# Function to create bridges
create_bridges() {
    echo "Creating bridges..."
    sudo ip link add br0 type bridge
    sudo ip link add br1 type bridge
    sudo ip link set dev br0 up
    sudo ip link set dev br1 up
}

# Function to create virtual cables
create_cables() {
    echo "Creating virtual ethernet pairs..."
    sudo ip link add veth0 type veth peer name veth0-ns
    sudo ip link add veth1 type veth peer name veth1-ns
    sudo ip link add vr0 type veth peer name vr0-ns
    sudo ip link add vr1 type veth peer name vr1-ns
}

# Function to set up interfaces
setup_interfaces() {
    echo "Setting up interfaces..."
    sudo ip link set veth0-ns netns ns1
    sudo ip link set veth1-ns netns ns2
    sudo ip link set veth0 master br0
    sudo ip link set veth1 master br1
    sudo ip link set vr0 master br0
    sudo ip link set vr1 master br1
    sudo ip link set vr0-ns netns router-ns
    sudo ip link set vr1-ns netns router-ns
}

# Function to assign IP addresses
assign_ip_addresses() {
    echo "Assigning IP addresses..."
    sudo ip netns exec ns1 ip addr add 10.11.0.2/24 dev veth0-ns
    sudo ip netns exec ns2 ip addr add 10.12.0.3/24 dev veth1-ns
    sudo ip netns exec router-ns ip addr add 10.11.0.1/24 dev vr0-ns
    sudo ip netns exec router-ns ip addr add 10.12.0.1/24 dev vr1-ns
}

# Function to set interface states
set_interface_states() {
    echo "Setting interface states..."
    sudo ip netns exec ns1 ip link set dev veth0-ns up
    sudo ip netns exec ns2 ip link set dev veth1-ns up
    sudo ip netns exec router-ns ip link set dev vr0-ns up
    sudo ip netns exec router-ns ip link set dev vr1-ns up
    sudo ip link set dev veth0 up
    sudo ip link set dev veth1 up
    sudo ip link set dev vr0 up
    sudo ip link set dev vr1 up
}

# Function to configure routes
configure_routes() {
    echo "Configuring routes..."
    sudo ip netns exec ns1 ip route add default via 10.11.0.1
    sudo ip netns exec ns2 ip route add default via 10.12.0.1
}

# Function to test connectivity
test_connectivity() {
    echo "Testing connectivity..."
    sudo ip netns exec ns1 ping -c 4 10.12.0.3
}

# Function to cleanup resources
cleanup() {
    echo "Cleaning up resources..."
    sudo ip netns delete ns1
    sudo ip netns delete ns2
    sudo ip netns delete router-ns
    sudo ip link delete br0 type bridge
    sudo ip link delete br1 type bridge
}

# Main function to orchestrate the setup
setup_network() {
    create_namespaces
    create_bridges
    create_cables
    setup_interfaces
    assign_ip_addresses
    set_interface_states
    configure_routes
}

# Usage function
usage() {
    echo "Usage: $0 [setup|test|cleanup]"
    echo "  setup   - Set up the network configuration"
    echo "  test    - Test network connectivity"
    echo "  cleanup - Remove all network configurations"
    exit 1
}

# Main script execution
case "$1" in
    "setup")
        setup_network
        ;;
    "test")
        test_connectivity
        ;;
    "cleanup")
        cleanup
        ;;
    *)
        usage
        ;;
esac
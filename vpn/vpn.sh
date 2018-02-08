#!/bin/bash
# start openvpn tunnel and application inside Linux network namespace
#
# /!\ This file must be in the same directory as your .ovpn file !
#
# Use it like this : ./vpn.sh your_application (ex : ./vpn.sh firefox)
#
# this is a fork of schnouki's script, see original blog post
# https://schnouki.net/posts/2014/12/12/openvpn-for-a-single-application-on-linux/
#
# original script can be found here
# https://gist.github.com/Schnouki/fd171bcb2d8c556e8fdf
#
# source : http://unix.stackexchange.com/a/309865

# ------------ adjust values below ------------
# network namespace
# NS_NAME must be the name of your .ovpn file !
NS_NAME=config_name
NS_EXEC="ip netns exec $NS_NAME"
# user for starting the application
REGULAR_USER=user
# network interface to use (will be suffixed by + so just set eth or enp0 or wlan)
NETWORK_INTERFACE=eth
# ---------------------------------------------

# exit on unbound variable
set -u

# exit on error
set -e
set -o pipefail

# trace option
set -x

if [ $USER != "root" ]; then
    echo "This must be run as root."
    exit 1
fi

start_vpn() {
    echo "Add network interface"

    # Create the network namespace
    ip netns add $NS_NAME

    # Start the loopback interface in the namespace
    $NS_EXEC ip addr add 127.0.0.1/8 dev lo
    $NS_EXEC ip link set lo up

    # Create virtual network interfaces that will let OpenVPN (in the
    # namespace) access the real network, and configure the interface in the
    # namespace (vpn1) to use the interface out of the namespace (vpn0) as its
    # default gateway
    ip link add vpn0 type veth peer name vpn1
    ip link set vpn0 up
    ip link set vpn1 netns $NS_NAME up

    ip addr add 10.200.200.1/24 dev vpn0
    $NS_EXEC ip addr add 10.200.200.2/24 dev vpn1
    $NS_EXEC ip link set dev vpn1 mtu 1492
    $NS_EXEC ip route add default via 10.200.200.1 dev vpn1

    # Configure the nameserver to use inside the namespace
    # TODO use VPN-provided DNS servers in order to prevent leaks
    mkdir -p /etc/netns/$NS_NAME
    cat >/etc/netns/$NS_NAME/resolv.conf <<EOF || exit 1
nameserver 80.67.169.12
nameserver 80.67.169.40
EOF

    # IPv4 NAT
    iptables -t nat -A POSTROUTING -o $NETWORK_INTERFACE+ -m mark --mark 0x29a -j MASQUERADE
    iptables -A FORWARD -i $NETWORK_INTERFACE+ -o vpn0 -j ACCEPT
    iptables -A FORWARD -o $NETWORK_INTERFACE+ -i vpn0 -j ACCEPT
    iptables -t mangle -A PREROUTING -i vpn0 -j MARK --set-xmark 0x29a/0xffffffff

    # TODO create firewall rules for your specific application (torrent)
    # or just comment the line below
    #$NS_EXEC iptables-restore < /etc/iptables/iptables-$NS_NAME.rules

    # we should have full network access in the namespace (google ip)
    $NS_EXEC ping -c 3 216.58.205.14

    # start OpenVPN in the namespace
    echo "Starting VPN"
    $NS_EXEC openvpn --config $NS_NAME.ovpn &

    # wait for the tunnel interface to come up
    while ! $NS_EXEC ip link show dev tun0 >/dev/null 2>&1 ; do sleep .5 ; done
}

stop_vpn() {
    echo "Stopping VPN"
    ip netns pids $NS_NAME | xargs -rd'\n' kill

    # clear NAT
    iptables -t nat -D POSTROUTING -o $NETWORK_INTERFACE+ -m mark --mark 0x29a -j MASQUERADE
    iptables -D FORWARD -i $NETWORK_INTERFACE+ -o vpn0 -j ACCEPT
    iptables -D FORWARD -o $NETWORK_INTERFACE+ -i vpn0 -j ACCEPT
    iptables -t mangle -D PREROUTING -i vpn0 -j MARK --set-xmark 0x29a/0xffffffff

    echo "Delete network interface"
    rm -rf /etc/netns/$NS_NAME

    ip netns delete $NS_NAME
    ip link delete vpn0
}

# stop VPN on exit (even when error occured)
trap stop_vpn EXIT

start_vpn

# start your application (specified in the $1 argument)
$NS_EXEC sudo -u $REGULAR_USER $1

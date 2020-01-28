#!/bin/bash -x

INTERFACE=$(route | grep '^default' | grep -o '[^ ]*$')

echo "Starting Build Process"

echo "Reset DNS settings ..."

echo "supersede domain-name-servers 1.1.1.1, 9.9.9.9;" >> /etc/dhcp/dhclient.conf

dhclient -r -v ${INTERFACE} && rm /var/lib/dhcp/dhclient.* ; dhclient -v ${INTERFACE}

echo "Installing required packages ..."
apt install software-properties-common -y

echo "Adding official Wireguard Distro ..."
add-apt-repository -y ppa:wireguard/wireguard

echo "Fully update ..."

unset UCF_FORCE_CONFFOLD
export UCF_FORCE_CONFFNEW=YES
ucf --purge /boot/grub/menu.lst

export DEBIAN_FRONTEND=noninteractive
apt update
apt -o Dpkg::Options::="--force-confnew" --force-yes -fuy dist-upgrade

echo "Install packages we need ..."

apt -y install wireguard

echo "Enable and configure firewall ..."

ufw --force enable
ufw default allow outgoing
ufw allow ssh
ufw allow 51820/udp

TMPFILE=$(mktemp)

echo "# START WIREGUARD RULES
# NAT table rules
*nat
:POSTROUTING ACCEPT [0:0]
# Allow traffic from Wireguard client to ${INTERFACE}
-A POSTROUTING -s 192.168.51.0/24 -o ${INTERFACE}
COMMIT
# END WIREGUARD RULES" | cat - /etc/ufw/before.rules > ${TMPFILE}

mv -f ${TMPFILE} /etc/ufw/before.rules

sed -i.bak s/DEFAULT_FORWARD_POLICY=\"DROP\"/DEFAULT_FORWARD_POLICY=\"ACCEPT\"/g /etc/default/ufw

ufw reload

echo "Enable IP forwarding ..."

echo "net/ipv4/ip_forward=1" >> /etc/ufw/sysctl.conf
sysctl -w net.ipv4.ip_forward=1

echo "Creating keys..."

PRIVATE_KEY=$(wg genkey)
PUBLIC_KEY=$(echo ${PRIVATE_KEY} | wg pubkey)

echo "Configuring Wireguard..."

cat > /etc/wireguard/wg0.conf <<EOF
[Interface]
PrivateKey = ${PRIVATE_KEY}
Address = 192.168.51.1/24
ListenPort = 51820
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o ${INTERFACE} -j MASQUERADE; ip6tables -A FORWARD -i wg0 -j ACCEPT; ip6tables -t nat -A POSTROUTING -o ${INTERFACE} -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o ${INTERFACE} -j MASQUERADE; ip6tables -D FORWARD -i wg0 -j ACCEPT; ip6tables -t nat -D POSTROUTING -o ${INTERFACE} -j MASQUERADE
SaveConfig = true
EOF

echo "Enabling and starting Wireguard service ..."

systemctl enable wg-quick@wg0
systemctl start wg-quick@wg0

echo "Creating client file template ..."

cat > /etc/wireguard/client.conf <<EOF
[Interface]
PrivateKey = <PRIVATE KEY GENERATED ON CLIENT SYSTEM>
Address = <YOUR LOCAL IP HERE>

[Peer]
PublicKey = ${PUBLIC_KEY}
Endpoint = $(curl http://169.254.169.254/latest/meta-data/public-ipv4):51820
AllowedIPs = <YOUR LOCAL IP HERE>
EOF

chmod 444 /etc/wireguard/client.conf

echo "DONE!"

#!/bin/bash

echo "========================================================================="
echo "|                         GASTON PROVISIONER                            |"
echo "========================================================================="
echo ""
sleep 1
echo "(Q) WTF is a 'Gaztun'?"
echo "(A) Well Mr(s) Mouthbreather, Gaston has like a Bastion host but much"
echo "    better looking.  So, think of Gaston from Beauty and the Beast."
echo ""
sleep 1
echo "(Q) So you like Disney?"
echo "(A) Not entirely, I just needed a character more narasassitic than me."
echo ""
sleep 1
echo "(Q) Do your programs all need a particular personality?"
echo "(A) WTF is it with all the questions?  Let's get started!"
echo ""
sleep 1
echo "========================================================================="

# EDIT THE FOLLOWING VARIABLES!

GAZ_HOSTNAME="gaston"
GAZ_DOMAIN="kemo.lab"

# Set from file system root, no trailing slash
GAZ_REPO_CONTENT_PATH="/media/external"

GAZ_IP="192.168.42.1"
GAZ_CIDR="192.168.42.0/24"
GAZ_DHCP_RANGE_START="192.168.42.100"
GAZ_DHCP_RANGE_STOP="192.168.42.250"
GAZ_WAN_INTERFACE="enp0s3"
GAZ_LAN_INTERFACE="enp0s8"

# STOP EDITING!!!!

GAZ_FQDN=$GAZ_HOSTNAME.$GAZ_DOMAIN

echo ""
echo "===== AGENDA"
echo "|"
echo "|  1) Set Hostname to $GAZ_FQDN"
echo "|  2) Setup temporary local yum repo and update"
echo "|  3) Install needed packages"
echo "|  4) Setup networking configuration"
echo "|  5) Configure dnsmasq"
echo "|  6) Configure routing/forwarding"
echo "|  7) Setup Firewall and iptables"
echo "|  8) Configure NTP with Chronyd"
echo "|  9) Set RPMs to Apache Httpd web root"
echo "| 10) Configure self in /etc/hosts file"
echo "| 11) Start and enable interfaces and services"
echo "| 12) Remove temporary local repo and configure with served repo"
echo "|"
echo "====="

echo "===== Setting hostname to $GAZ_FQDN..."
hostnamectl set-hostname $GAZ_FQDN

echo "===== Import RH GPG Key..."
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release

echo "===== Setting local temporary yum repos..."
cp ./kemo-temp.repo.example /etc/yum.repos.d/kemo-temp.repo

echo "===== Replacing all of the variables in the temp repo file..."
sed -i "s|PATH_HERE|$GAZ_REPO_CONTENT_PATH|g" /etc/yum.repos.d/kemo-temp.repo

echo "===== Update repos..."
yum update -y

echo "===== Install needed packages..."
yum -y install firewalld dnsmasq bind-utils httpd chrony

echo "===== Configure local networking interfaces..."
nmcli con add con-name lanSide-$GAZ_LAN_INTERFACE ifname $GAZ_LAN_INTERFACE type ethernet ip4 $GAZ_IP/24 gw4 $GAZ_IP
nmcli con modify lanSide-$GAZ_LAN_INTERFACE ipv4.dns $GAZ_IP

echo "===== Backup DNSMASQ conf..."
cp /etc/dnsmasq.conf /etc/dnsmasq.conf.kemo-$(date -d "today" +"%Y%m%d%H%M").bak

echo "===== Configure DNSMASQ..."
echo "interface=$GAZ_LAN_INTERFACE" >> /etc/dnsmasq.conf
echo "bind-interfaces" >> /etc/dnsmasq.conf
echo "listen-address=$GAZ_IP" >> /etc/dnsmasq.conf
echo "server=8.8.8.8" >> /etc/dnsmasq.conf
echo "domain-needed" >> /etc/dnsmasq.conf
echo "bogus-priv" >> /etc/dnsmasq.conf
echo "dhcp-range=$GAZ_DHCP_RANGE_START,$GAZ_DHCP_RANGE_STOP,12h" >> /etc/dnsmasq.conf
echo "domain=$GAZ_DOMAIN,$GAZ_CIDR" >> /etc/dnsmasq.conf
echo "local=/$GAZ_DOMAIN/" >> /etc/dnsmasq.conf
echo "expand-hosts" >> /etc/dnsmasq.conf

echo "===== Enabling and starting Firewalld..."
systemctl enable firewalld && systemctl start firewalld

echo "===== Adding services to firewalld..."
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=dns
firewall-cmd --permanent --add-service=dhcp
firewall-cmd --permanent --add-service=ntp
firewall-cmd --reload

echo "===== Enable packet forwarding in kernel..."
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf

echo "===== Enable immediate forwarding of packets..."
echo 1 > /proc/sys/net/ipv4/ip_forward

echo "===== Set port forwarding firewall rules..."
iptables -t nat -A POSTROUTING -o $GAZ_WAN_INTERFACE -j MASQUERADE
iptables -A FORWARD -i $GAZ_WAN_INTERFACE -o $GAZ_LAN_INTERFACE -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i $GAZ_LAN_INTERFACE -o $GAZ_WAN_INTERFACE -j ACCEPT
firewall-cmd --permanent --direct --passthrough ipv4 -t nat -I POSTROUTING -o $GAZ_WAN_INTERFACE -j MASQUERADE -s $GAZ_CIDR

echo "===== Saving firewall rules..."
iptables-save > /etc/iptables.ipv4.nat

echo "===== Enabling persistent firewall rules..."
echo "iptables-restore < /etc/iptables.ipv4.nat" >> /etc/rc.local

echo "===== Bringing LAN interface online..."
nmcli con up lanSide-$GAZ_LAN_INTERFACE

echo "===== Adding self to hosts file..."
echo "$GAZ_IP $GAZ_FQDN $GAZ_HOSTNAME" >> /etc/hosts

echo "===== Enabling and starting Chronyd service..."
systemctl enable chronyd && systemctl start chronyd

echo "===== Enable NTP on host..."
timedatectl set-ntp yes

echo "===== Configuring Chronyd..."
cp /etc/chrony.conf /etc/chrony.conf.kemo-$(date -d "today" +"%Y%m%d%H%M").bak
echo "server $GAZ_IP iburst" > /etc/chrony.conf
echo "allow $GAZ_CIDR" >> /etc/chrony.conf
echo "driftfile /var/lib/chrony/drift" >> /etc/chrony.conf
echo "rtcsync" >> /etc/chrony.conf
echo "local stratum 10" >> /etc/chrony.conf
echo "logdir /var/log/chrony" >> /etc/chrony.conf
echo "stratumweight 0" >> /etc/chrony.conf

echo "===== Restarting Chrony..."
systemctl restart chronyd

echo "===== Enabling and starting dnsmasq..."
systemctl enable dnsmasq && systemctl start dnsmasq

echo "===== Remove temporary repo file..."
rm -rf /etc/yum.repos.d/kemo-temp.repo

echo "===== Copying repo file into yum directory..."
cp ./kemo-ose.repo.example /etc/yum.repos.d/kemo-ose.repo

echo "===== Replacing all of the variables in the repo file..."
sed -i "s|SERVER_IP_HERE|$GAZ_FQDN|g" /etc/yum.repos.d/kemo-ose.repo

echo "===== Setting document root..."
cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd.conf.kemo-$(date -d "today" +"%Y%m%d%H%M").bak
cp httpd.conf.example /etc/httpd/conf/httpd.conf
#cp /etc/mime.types /etc/httpd/conf/mime.types
#sed -i "s|PATH_HERE|/var/www/html|g" /etc/httpd/conf/httpd.conf
# No need to switch root, just copy files over.  Can't have documentroot in external mount due to SELinux.  Easier to copy over to /var/www/html

echo "===== Moving RPM files to /var/www/html..."
mkdir -p /var/www/html/rpms
cp -Rv $GAZ_REPO_CONTENT_PATH/* /var/www/html/rpms
chmod -R +r /var/www/html/rpms
chown -R apache:apache /var/www/html
restorecon -vR /var/www/html
#chcon -R -t httpd_sys_content_t /var/www/html

echo "===== Enabling and starting Apache HTTP..."
systemctl enable httpd && systemctl start httpd

echo "===== Updating yum repos lists..."
yum update -y

echo ""
echo ""
echo "========================================================================="
echo "|                   GASTON PROVISIONER - COMPLETE                       |"
echo "========================================================================="
echo ""
echo ""
echo "You now have configured this host as a DHCP, DNS, NTP, and RPM Repo host!"
echo ""
echo "Test Apache HTTP Server RPM distribution: http://$GAZ_FQDN/rpms/"
echo "Display DHCP leases: cat /var/lib/dnsmasq/dnsmasq.leases"
echo "Set static hostname mappings: nano /etc/hosts"
echo ""
echo "- Next, deploy your other base RHEL VMs for Gluster and OCP."
echo "-- In doing so, make sure to set at least the static IPs for the hosts:"
echo "   Network: $GAZ_CIDR"
echo "   Gateway: $GAZ_IP"
echo "   Not in following DHCP pool: $GAZ_DHCP_RANGE_START - $GAZ_DHCP_RANGE_STOP"
echo "   The hostnames can be set later with the Ansible playbook"
echo ""
echo "- Then, modify the inventory script in the 'configurator' folder, and run"
echo "   the Ansible playbook with..."
echo "    'ansible-playbook -i inventory 3_config_hosts.yml'"

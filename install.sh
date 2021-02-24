#!/usr/bin/env bash

# Check if script is run as root
if [ "$(id -u)" != 0 ]; then
	echo "Please run as root"
	exit 1
fi

if [ "$(lsb_release --id | cut --fields=2)" != "Ubuntu" ]; then
	printf "\n\tWarning! This seems to be a non-Ubuntu system.\n\tIt might just work anyway but it hasn't been tested.\n\n\tCAVEAT EMPTOR!\n\n"
fi

# Start by updating ubuntu to the latest and greatest
apt update -y
apt dist-upgrade -y

# Add logging directories to tmpfs to minimize sd card io
{
	echo "tmpfs /tmp      tmpfs nosuid,nodev  0 0"
	echo "tmpfs /var/log  tmpfs nosuid,nodev  0 0"
	echo "tmpfs /var/tmp  tmpfs nosuid,nodev  0 0"
} >>/etc/fstab

### Package installs
# Install package dependencies
apt install -y libssl-dev autoconf libtool make unzip python3-pip net-tools apt-transport-https traceroute
pip3 install jc multiprocessing-logging requests

### cURL
# Basically anything past 7.70 should be fine
cURLversion="7.75.0"

apt purge curl -y
cd /usr/local/src || echo "Something went wrong just prior to fetching the cURL package!"
exit 2

wget https://curl.haxx.se/download/curl-${cURLversion}.zip
unzip curl-${cURLversion}.zip

cd curl-${cURLversion} || echo "Something went wrong with installation of the cURL package!"
exit 2

./buildconf && ./configure --with-ssl
make && make install
ln -s /usr/local/bin/curl /usr/bin/curl

### Filebeat
# Install filebeat and copy template config
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add -
echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | tee -a /etc/apt/sources.list.d/elastic-7.x.list
apt update && apt install -y filebeat
cp /opt/rnm-sensor/filebeat/filebeat-template.yml /etc/filebeat/filebeat.yml
systemctl enable filebeat

### System maintenance
# Set permissions
chown ubuntu:ubuntu -R /opt/rnm-sensor/
chmod +x /opt/rnm-sensor/rnm_sensor.py

# Add systemd service
cp /opt/rnm-sensor/rnm-sensor.service /etc/systemd/system/rnm-sensor.service

# Enable RNM-sensor service (that's me!)
systemctl enable rnm-sensor
systemctl start rnm-sensor

# Echo ending
printf "\n\n\tALL DONE - please reboot\n"

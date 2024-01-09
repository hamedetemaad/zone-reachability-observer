#!/bin/sh
# prometheus installation
mkdir /tmp/monitoring
cd /tmp/monitoring
wget https://github.com/prometheus/prometheus/releases/download/v2.44.0/prometheus-2.44.0.linux-amd64.tar.gz
tar zxvf prometheus-2.44.0.linux-amd64.tar.gz
cd prometheus-2.44.0.linux-amd64/
cp /tmp/prometheus.yml prometheus.yml
./prometheus --config.file=prometheus.yml &

# grafana installation
cd /tmp/monitoring
sudo apt update
sudo apt-get install -y adduser libfontconfig1 musl
wget https://dl.grafana.com/oss/release/grafana_10.2.3_amd64.deb
sudo dpkg -i grafana_10.2.3_amd64.deb
sudo /bin/systemctl daemon-reload
sudo /bin/systemctl enable grafana-server
sudo /bin/systemctl start grafana-server

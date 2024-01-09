#!/bin/sh
sudo mkdir /usr/local/bin/ebpf_exporter
sudo cp /tmp/ebpf_exporter /usr/local/bin/ebpf_exporter
sudo cp /tmp/xdp.yaml /usr/local/bin/ebpf_exporter
sudo cp /tmp/xdp.bpf.o /usr/local/bin/ebpf_exporter
sudo cp /tmp/ebpf_exporter.service /etc/systemd/system/
sudo systemctl enable ebpf_exporter
sudo systemctl start  ebpf_exporter

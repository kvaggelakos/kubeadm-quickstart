#!/bin/bash

kubeadm reset --force
rm -r /etc/cni/net.d/
iptables -F
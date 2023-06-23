#!/bin/bash

kubeadm reset --force
rm -r /etc/cni/net.d/
rm -r ~/.kube
iptables -F
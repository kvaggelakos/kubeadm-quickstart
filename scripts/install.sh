swapoff --all

cat <<EOF | tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
modprobe overlay
modprobe br_netfilter
cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
sysctl --system


CONTAINERD_VERSION=1.7.2
RUNC_VERSION=1.1.7
CNI_VERSION=1.3.0
FLANNEL_VERSION=0.22.0

wget https://github.com/containerd/containerd/releases/download/v$CONTAINERD_VERSION/containerd-$CONTAINERD_VERSION-linux-amd64.tar.gz
tar Cxzvf /usr/local containerd-$CONTAINERD_VERSION-linux-amd64.tar.gz

mkdir -p /etc/containerd/
containerd config default > /etc/containerd/config.toml
sed -i 's|SystemdCgroup = false|SystemdCgroup = true|' /etc/containerd/config.toml

wget https://github.com/opencontainers/runc/releases/download/v$RUNC_VERSION/runc.amd64
install -m 755 runc.amd64 /usr/local/sbin/runc

wget https://github.com/containernetworking/plugins/releases/download/v$CNI_VERSION/cni-plugins-linux-amd64-v$CNI_VERSION.tgz
mkdir --parents /opt/cni/bin
tar Cxzvf /opt/cni/bin cni-plugins-linux-amd64-v$CNI_VERSION.tgz

wget https://raw.githubusercontent.com/containerd/containerd/main/containerd.service --output-document=/etc/systemd/system/containerd.service
systemctl daemon-reload
systemctl enable --now containerd

wget https://github.com/flannel-io/flannel/releases/download/v$FLANNEL_VERSION/flannel-v$FLANNEL_VERSION-linux-amd64.tar.gz
mkdir /opt/bin
tar --directory=/opt/bin --extract --gzip --file="flannel-v$FLANNEL_VERSION-linux-amd64.tar.gz" flanneld

apt-get update && apt-get install -y apt-transport-https ca-certificates curl
curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list
apt-get update
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

kubeadm init --pod-network-cidr=10.244.0.0/16
echo 'KUBECONFIG=/etc/kubernetes/admin.conf' >> /etc/environment
export KUBECONFIG=/etc/kubernetes/admin.conf
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml
kubectl get pods --all-namespaces
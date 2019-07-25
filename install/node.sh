#!/bin/bash

set -x
set -e

# 1. install Docker
#yum update -y

yum remove -y docker docker-common docker-selinux docker-engine
yum install -y yum-utils device-mapper-persistent-data lvm2
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum install -y docker-ce-18.09.0 docker-ce-cli-18.09.0

sed -i -e "/ExecStart/ s/$/ --exec-opt native.cgroupdriver=systemd/" /usr/lib/systemd/system/docker.service
systemctl enable docker && systemctl restart docker && systemctl status docker
docker --version && dockerd-ce --version

# 2. install kubeadm
setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

cat > /etc/yum.repos.d/kubernetes.repo << EOF
[kubernetes]
name=Kubernetes Repository
baseurl=http://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/  
enabled=1
gpgcheck=0
EOF

yum install -y kubeadm kubelet-1.14.0 --disableexcludes=kubernetes
swapoff -a
systemctl enable kubelet && systemctl restart kubelet && systemctl status kubelet

# 3. config
cat > join-config.yaml << EOF
apiVersion: kubeadm.k8s.io/v1beta1
kind: JoinConfiguration
discovery:
  bootstrapToken:
    apiServerEndpoint: 172.21.102.130:6443
    token: whk1e9.uqjkf9sgki7qyvdl
    unsafeSkipCAVerification: true
  tlsBootstrapToken: whk1e9.uqjkf9sgki7qyvdl
EOF

cat > /etc/docker/daemon.json << EOF
{
  "registry-mirrors": "https://registry.docker-cn.com"
}
EOF

echo "Manually modify join-config.yaml"
echo "* apiServerEndpoint"
echo "* token"
echo "* tlsBootstrapToken"
echo
echo "kubeadm join --config=join-config.yaml"

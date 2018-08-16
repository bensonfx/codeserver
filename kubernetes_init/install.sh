#!/bin/bash

# KUBE_REPO_PREFIX=registry.cn-hangzhou.aliyuncs.com/google-containers
# KUBE_HYPERKUBE_IMAGE=registry.cn-hangzhou.aliyuncs.com/google-containers/hyperkube-amd64:v1.7.0
# KUBE_DISCOVERY_IMAGE=registry.cn-hangzhou.aliyuncs.com/google-containers/kube-discovery-amd64:1.0
# KUBE_ETCD_IMAGE=registry.cn-hangzhou.aliyuncs.com/google-containers/etcd-amd64:3.0.17

# KUBE_REPO_PREFIX=$KUBE_REPO_PREFIX KUBE_HYPERKUBE_IMAGE=$KUBE_HYPERKUBE_IMAGE KUBE_DISCOVERY_IMAGE=$KUBE_DISCOVERY_IMAGE kubeadm init --ignore-preflight-errors=all --pod-network-cidr="10.244.0.0/16"

set -x
CWD=$(pwd)
USER=$(whoami) # 用户
GROUP=$(whoami) # 组


FLANEL_VER=$(curl -sL https://github.com/coreos/flannel/releases | grep -A 5 "Latest release" | grep -oE "v[0-9.]+")
FLANELADDR=https://raw.githubusercontent.com/coreos/flannel/$FLANEL_VER/Documentation/kube-flannel.yml
KUBECONF=${CWD}/kubeadm.conf # 文件地址, 改成你需要的路径
REGMIRROR=https://registry.docker-cn.com # docker registry mirror 地址

#TODO: 自动获取token master ip和hash 并生成配置文件. 创建node时，检测是否有配置文件
# kubeadm token create --print-join-command
ca_cert="/etc/kubernetes/pki/ca.crt"
tokens_file="/etc/kubernetes/pki/tokens.csv"
#kubeadm token list
MASTER_TOKEN=
APISERVER=
MASTER_HASH=

install_docker() {
  mkdir /etc/docker
  cat << EOF > /etc/docker/daemon.json
{
  "registry-mirrors": ["$REGMIRROR"],
}
EOF
  apt-get update
  #apt-get install -y apt-transport-https ca-certificates curl software-properties-common
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
  add-apt-repository \
    "deb [arch=amd64] https://mirrors.ustc.edu.cn/docker-ce/linux/$(. /etc/os-release; echo "$ID") \
    $(lsb_release -cs) \
    stable"
  apt-get update && apt-get install -y docker-ce
}

add_user_to_docker_group() {
  groupadd docker
  gpasswd -a $USER docker # ubuntu is the user name
}

install_kube_commands() {
  cat kube_apt_key.gpg | apt-key add -
  echo "deb [arch=amd64] https://mirrors.ustc.edu.cn/kubernetes/apt kubernetes-$(lsb_release -cs) main" >> /etc/apt/sources.list
  apt-get update && apt-get install -y kubelet kubeadm kubectl
}

restart_kubelet() {
  sed -i "s,ExecStart=$,Environment=\"KUBELET_EXTRA_ARGS=--pod-infra-container-image=registry.cn-hangzhou.aliyuncs.com/google_containers/pause-amd64:3.1\"\nExecStart=,g" /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
  systemctl daemon-reload
  systemctl restart kubelet
}

enable_kubectl() {
  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config
}

# for now, better to download from original registry
apply_flannel() {
  kubectl apply -f $FLANELADDR
}

get_master_token() {
    # kubectl describe secret $(kubectl get secrets | grep default | cut -f1 -d ' ') | grep -E '^token' | cut -f2 -d':' | tr -d '\t'
    cat ${tokens_file} | sed 's@([a-z0-9]{6}.[a-z0-9]{16}),.*@\1@g'
}

get_ca_hash() {
    openssl x509 -pubkey -in ${ca_cert} | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //'
}

case "$1" in
  "pre")
    install_docker
    add_user_to_docker_group
    install_kube_commands
    ;;
  "kubernetes-master")
    sysctl net.bridge.bridge-nf-call-iptables=1
    restart_kubelet
    kubeadm init --config $KUBECONF
    if [ $? -ne 0 ];then
        echo "=> kubeadm init failed.reset env"
        kubeadmin reset
        exit 1
    fi
    [ -n "${MASTER_TOKEN}" ] || MASTER_TOKEN=$(get_master_token)
    [ -n "${APISERVER}" ] || APISERVER=$(kubectl config view | grep server | cut -f 2- -d ":" | tr -d " ")
    [ -n "${MASTER_HASH}" ] ||  MASTER_HASH=$(get_ca_hash)
    ;;
  "kubernetes-node")
    sysctl net.bridge.bridge-nf-call-iptables=1
    restart_kubelet
    kubeadm join --token $MASTER_TOKEN $APISERVER --discovery-token-ca-cert-hash sha256:$MASTER_HASH
    ;;
  "post")
    if [[ $EUID -ne 0 ]]; then
      echo "do not run as root"
      exit
    fi
    enable_kubectl
    apply_flannel
    ;;
  *)
    echo "huh ????"
    ;;
esac

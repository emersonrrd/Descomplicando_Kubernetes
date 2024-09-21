#!/bin/bash

# Variáveis globais
MODULES_CONF="/etc/modules-load.d/k8s.conf"
SYSCTL_CONF="/etc/sysctl.d/k8s.conf"
KUBE_REPO_LIST="/etc/apt/sources.list.d/kubernetes.list"
KUBE_GPG_KEY="/etc/apt/keyrings/kubernetes-apt-keyring.gpg"
DOCKER_GPG_KEY="/usr/share/keyrings/docker-archive-keyring.gpg"
DOCKER_REPO_LIST="/etc/apt/sources.list.d/docker.list"
CONTAINERD_CONFIG="/etc/containerd/config.toml"
JOIN_COMMAND_FILE="/root/kubeadm_join_command.sh"

# Função para carregar módulos do kernel
carregar_modulos_kernel() {
    echo "[K8S-SETUP] Carregando módulos do kernel..."
    cat <<EOF > "$MODULES_CONF"
overlay
br_netfilter
EOF
    modprobe overlay
    modprobe br_netfilter
}

# Função para configurar parâmetros sysctl
configurar_sysctl() {
    echo "[K8S-SETUP] Configurando parâmetros sysctl..."
    cat <<EOF > "$SYSCTL_CONF"
net.bridge.bridge-nf-call-iptables=1
net.bridge.bridge-nf-call-ip6tables=1
net.ipv4.ip_forward=1
EOF
    sysctl --system
}

# Função para instalar dependências
instalar_dependencias() {
    echo "[K8S-SETUP] Instalando dependências..."
    apt-get update
    apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
    mkdir -p /etc/apt/keyrings
}

# Função para adicionar a chave GPG do Kubernetes
adicionar_chave_kubernetes() {
    echo "[K8S-SETUP] Adicionando chave GPG do Kubernetes..."
    curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | gpg --dearmor -o "$KUBE_GPG_KEY"
}

# Função para adicionar o repositório Kubernetes
adicionar_repositorio_kubernetes() {
    echo "[K8S-SETUP] Adicionando repositório Kubernetes..."
    cat <<EOF > "$KUBE_REPO_LIST"
deb [signed-by=$KUBE_GPG_KEY] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /
EOF
}

# Função para instalar o Kubernetes
instalar_kubernetes() {
    echo "[K8S-SETUP] Instalando kubelet, kubeadm e kubectl..."
    apt-get update
    apt-get install -y kubelet kubeadm kubectl
    apt-mark hold kubelet kubeadm kubectl
}

# Função para habilitar o kubelet
habilitar_kubelet() {
    echo "[K8S-SETUP] Habilitando e iniciando o kubelet..."
    systemctl enable --now kubelet
}

# Função para adicionar a chave GPG do Docker
adicionar_chave_docker() {
    echo "[K8S-SETUP] Adicionando chave GPG do Docker..."
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o "$DOCKER_GPG_KEY"
}

# Função para adicionar o repositório Docker
adicionar_repositorio_docker() {
    echo "[K8S-SETUP] Adicionando repositório Docker..."
    CODENAME=$(lsb_release -cs)
    cat <<EOF > "$DOCKER_REPO_LIST"
deb [arch=amd64 signed-by=$DOCKER_GPG_KEY] https://download.docker.com/linux/ubuntu $CODENAME stable
EOF
}

# Função para instalar containerd
instalar_containerd() {
    echo "[K8S-SETUP] Instalando containerd..."
    apt-get update
    apt-get install -y containerd.io
}

# Função para configurar o containerd
configurar_containerd() {
    echo "[K8S-SETUP] Configurando containerd..."
    # Gerar configuração padrão
    containerd config default > "$CONTAINERD_CONFIG"
    # Alterar SystemdCgroup para true
    sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' "$CONTAINERD_CONFIG"
}

# Função para habilitar e iniciar o containerd
habilitar_containerd() {
    echo "[K8S-SETUP] Habilitando e iniciando containerd..."
    systemctl restart containerd
    systemctl enable containerd
}

# Função para inicializar o cluster Kubernetes no nó master
inicializar_cluster_kubernetes() {
    if [ "$(hostname)" = "k8s-01" ]; then
        echo "[K8S-SETUP] Inicializando o cluster Kubernetes no nó master..."

        # Obter o endereço IP da interface eth0
        IP_ETH0=$(ip -o -4 addr list eth0 | awk '{print $4}' | cut -d/ -f1)
        echo "[K8S-SETUP] Endereço IP da interface eth0: $IP_ETH0"

        # Inicializar o cluster Kubernetes e capturar a saída
        KUBEADM_INIT_OUTPUT=$(kubeadm init --pod-network-cidr=10.10.0.0/16 --apiserver-advertise-address="$IP_ETH0" 2>&1)

        # Exibir a saída do kubeadm init nos logs
        echo "$KUBEADM_INIT_OUTPUT"

        # Capturar o comando kubeadm join
        JOIN_COMMAND=$(echo "$KUBEADM_INIT_OUTPUT" | grep -A 2 "kubeadm join")
        echo "[K8S-SETUP] Comando kubeadm join capturado: $JOIN_COMMAND"

        # Salvar o comando kubeadm join em um arquivo
        echo "#!/bin/bash" > "$JOIN_COMMAND_FILE"
        echo "$JOIN_COMMAND" >> "$JOIN_COMMAND_FILE"
        chmod +x "$JOIN_COMMAND_FILE"

        echo "[K8S-SETUP] Comando kubeadm join salvo em $JOIN_COMMAND_FILE"

        # Configurar o kubeconfig para o usuário root
        mkdir -p /root/.kube
        cp -i /etc/kubernetes/admin.conf /root/.kube/config
        chown root:root /root/.kube/config

        # Aplicar a rede do Weave Net
        kubectl apply -f https://github.com/weaveworks/weave/releases/download/v2.8.1/weave-daemonset-k8s.yaml

        echo "[K8S-SETUP] Cluster Kubernetes inicializado com sucesso!"
    else
        echo "[K8S-SETUP] Hostname não é 'k8s-01'. Ignorando a inicialização do cluster."
    fi
}

# Função principal que chama todas as outras
main() {
    echo "[K8S-SETUP] Iniciando configuração do Kubernetes..."
    carregar_modulos_kernel
    configurar_sysctl
    instalar_dependencias
    adicionar_chave_kubernetes
    adicionar_repositorio_kubernetes
    instalar_kubernetes
    adicionar_chave_docker
    adicionar_repositorio_docker
    instalar_containerd
    configurar_containerd
    habilitar_containerd
    habilitar_kubelet
    inicializar_cluster_kubernetes
    echo "[K8S-SETUP] Configuração concluída com sucesso!"
}

# Chamar a função principal
main

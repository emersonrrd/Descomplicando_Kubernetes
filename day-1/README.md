# Documentação Técnica - DevOps com Containers e Kubernetes

## 1. Introdução

Esta documentação descreve conceitos fundamentais sobre containers e Kubernetes, voltados para profissionais de DevOps e administradores de sistemas. Através de comandos e explicações detalhadas, você aprenderá a configurar, gerenciar e orquestrar containers, além de entender os componentes subjacentes como _Container Engines_ e _Container Runtimes_. O foco é fornecer uma base sólida para o uso de Kubernetes e as melhores práticas para gerenciar aplicações em produção.

Este documento inclui referências de ferramentas e conceitos amplamente adotados, como Docker, CRI-O, Kind e Kubernetes.

## 2. Conceitos Fundamentais

### 2.1 O que é um Container?

Um container é uma tecnologia de virtualização leve que permite isolar uma aplicação e seus recursos (CPU, memória, I/O) do sistema operacional subjacente. Ao contrário de máquinas virtuais, os containers compartilham o kernel do sistema operacional, tornando-os mais eficientes e leves. Isso proporciona portabilidade e facilita a execução de aplicações em diferentes ambientes, independentemente das dependências e configurações de sistema.

Containers são ideais para ambientes DevOps devido à sua capacidade de garantir que o código funcione da mesma maneira em diferentes ambientes, desde o desenvolvimento até a produção.

### 2.2 O que é um Container Engine?

O _Container Engine_ é o software que gerencia a criação, execução e destruição de containers. Ele é responsável por lidar com imagens de container, volumes, rede e garantir o isolamento de recursos. O _Container Engine_ também interage com o _Container Runtime_ para executar os containers.

#### Principais Opções de Container Engine

1. **Docker**: O mais popular dos _Container Engines_, amplamente adotado pela comunidade DevOps. Ele utiliza o `containerd` como seu _Container Runtime_ padrão. Docker é conhecido pela sua simplicidade e ampla documentação.
    
2. **CRI-O**: Uma implementação do _Container Runtime Interface_ (CRI) usada para Kubernetes. Ele oferece uma alternativa leve e compatível com OCI para gerenciar containers em ambientes Kubernetes, sem depender do Docker.
    
3. **Podman**: Similar ao Docker, mas sem a necessidade de um daemon central. Podman é utilizado em cenários onde é necessário um gerenciamento de containers mais modular e seguro, como em ambientes que requerem _rootless containers_.
    

### 2.3 O que é um Container Runtime?

O _Container Runtime_ é responsável por executar containers em um nó (máquina física ou virtual). Ele é a camada mais baixa do ecossistema de containers, interagindo diretamente com o kernel do sistema operacional para garantir que os containers sejam executados de maneira correta e isolada. Existem diferentes tipos de _Container Runtime_, cada um adequado para diferentes cenários:

#### Tipos de Container Runtimes

1. **Low-level Runtime**: Executado diretamente pelo kernel. Exemplos incluem:
    
    - `runc`: O _runtime_ padrão para containers, utilizado por Docker e outras ferramentas.
    - `crun`: Uma alternativa rápida e leve ao `runc`, especialmente para sistemas com recursos limitados.
    - `runsc`: Um _runtime_ de segurança fornecido pelo gVisor, que executa containers em um sandbox isolado.
2. **High-level Runtime**: Gerenciado por um _Container Engine_, como:
    
    - `containerd`: Usado pelo Docker e Kubernetes para o gerenciamento de containers.
    - `CRI-O`: Utilizado em clusters Kubernetes, oferece integração direta com a interface CRI do Kubernetes.
    - `Podman`: Funciona tanto como _Container Engine_ quanto como _Container Runtime_, especialmente popular em ambientes rootless.
3. **Sandbox Runtime**: Oferece execução segura em ambientes mais restritivos, como _unikernels_ ou proxys:
    
    - `gVisor`: Um _runtime_ que executa containers dentro de um ambiente seguro e isolado, com foco em segurança.
4. **Virtualized Runtime**: Containers são executados em máquinas virtuais, proporcionando maior isolamento:
    
    - `Kata Containers`: Usa VMs leves para garantir maior segurança e isolamento, embora com uma leve perda de performance em comparação com _runtimes_ nativos.

#### OCI - Open Container Initiative

A _Open Container Initiative_ (OCI) é uma organização que define padrões abertos para containers. Fundada em 2015 por empresas como Docker, CoreOS, Google e Red Hat, a OCI tem como objetivo garantir que containers sejam interoperáveis entre diferentes sistemas e _Container Engines_. O projeto mais significativo da OCI é o `runc`, um _runtime_ open-source escrito em Go, que se tornou o padrão de fato para execução de containers.

Mais informações sobre a OCI podem ser encontradas [neste link](https://www.opencontainers.org/).

## 3. Kubernetes

### 3.1 O que é o Kubernetes?

Kubernetes, também conhecido como k8s, é uma plataforma de orquestração de containers open-source criada pelo Google em 2014. Ela permite que você gerencie, automatize e escale aplicações em containers em larga escala. O Kubernetes é baseado nas lições aprendidas com o sistema Borg, utilizado pelo Google para gerenciar seus serviços internos.

Kubernetes automatiza tarefas como:

- O provisionamento de máquinas virtuais ou físicas para execução de containers.
- A implantação e atualização de aplicações em containers.
- O gerenciamento da rede e do armazenamento para containers.
- A escalabilidade automática de aplicações com base no uso de recursos.

Kubernetes é amplamente adotado devido à sua capacidade de facilitar o gerenciamento de clusters complexos e o balanceamento de carga entre múltiplos containers.

Mais detalhes podem ser encontrados no [blog oficial do Kubernetes](https://kubernetes.io/blog/2015/04/borg-predecessor-to-kubernetes/).

### 3.2 Arquitetura do Kubernetes

A arquitetura do Kubernetes segue um modelo _cliente-servidor_ com os seguintes componentes principais:

- **Master Node**: Contém os principais componentes de controle, como o `kube-apiserver`, que gerencia as requisições e a comunicação entre os nós.
- **Worker Nodes**: Executam os containers e são controlados pelo master node. Cada worker node tem o `kubelet`, responsável por garantir que os containers sejam executados corretamente.

A interação com o Kubernetes é feita através da ferramenta de linha de comando `kubectl`. A seguir, estão os passos para instalar o `kubectl` e criar um cluster Kubernetes local usando o Kind.

### 3.3 Instalando o `kubectl`

O `kubectl` é a interface de linha de comando que permite interagir com clusters Kubernetes, executar comandos e gerenciar recursos.

Para instalar o `kubectl` no Linux, utilize os seguintes comandos:

```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" 
chmod +x kubectl 
sudo mv kubectl /usr/local/bin/ 
kubectl version
```

Documentação oficial para instalação do `kubectl`: [Install and Set Up kubectl on Linux | Kubernetes](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/)

### 3.4 Criando um Cluster Kubernetes com o Kind

O Kind (Kubernetes in Docker) é uma ferramenta que permite criar clusters Kubernetes localmente utilizando containers Docker como nós do cluster. O Kind é especialmente útil para desenvolvimento, testes e experimentação com Kubernetes.

#### Passos para instalação do Kind:

```bash
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.24.0/kind-linux-amd64 
chmod +x ./kind 
sudo mv ./kind /usr/local/bin/kind
```

Verifique se a instalação foi concluída corretamente:

```bash
kind version
```

Para criar um cluster Kubernetes local, basta rodar o comando:

```bash
kind create cluster
```

Mais informações sobre a instalação e uso do Kind estão disponíveis [aqui](https://kind.sigs.k8s.io/docs/user/quick-start/#installation).

### 3.5 Configuração de Cluster com Arquivo YAML

Crie um arquivo `kind-cluster.yaml` para definir o cluster com múltiplos nós:

```yaml
kind: Cluster 
apiVersion: kind.x-k8s.io/v1alpha4 
nodes: 
- role: control-plane 
- role: worker 
- role: worker
```

Depois, crie o cluster utilizando o arquivo de configuração:

```bash
kind create cluster --config kind-cluster.yaml --name giropops 
kubectl get nodes
```

## 4. Primeiros Passos no Kubernetes

Aqui estão alguns comandos comuns usados para obter informações no Kubernetes:

```bash
kubectl get nodes
kubectl get pods
kubectl get namespaces
kubectl get pods -n kube-system
kubectl get pods -A
kubectl get deployment -A
kubectl get service
kubectl get replicaset -A
```

## 5. Alias e Autocompletar no `kubectl`

Para facilitar o uso do `kubectl`, você pode configurar um alias e habilitar autocompletar no terminal:

```bash
alias k=kubectl
source <(kubectl completion bash)
echo "source <(kubectl completion bash)" >> ~/.bashrc
source ~/.bashrc
```

Agora você pode usar `k` como alias para `kubectl` e o autocompletar estará habilitado.

## 6. Explorando e Expondo Pods

Com o `kubectl`, você pode interagir diretamente com o container rodando no pod. Caso o comando `ps -ef` não esteja disponível, você pode explorar o conteúdo de processos diretamente pelo sistema de arquivos `/proc`:

```bash
kubectl exec -ti nginx -- bash
cd /proc
ls
cd 1
cat cmdline
```

- Expor o pod como um serviço:

```bash
kubectl expose pod nginx --type NodePort
```

- Remover o serviço:

```bash
kubectl delete svc nginx
```

## 7. Trabalhando com YAML e o `kubectl`

Você pode usar o `kubectl` com a flag `--dry-run` para gerar um arquivo YAML antes de aplicar as alterações:

```bash
kubectl run nginx --image=nginx --port=8080 --dry-run=client -o yaml > pod.yaml
kubectl apply -f pod.yaml
```

Exemplo de arquivo `pod.yaml` gerado:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx
spec:
  containers:
  - image: nginx
	name: nginx
    ports:
    - containerPort: 8080
```
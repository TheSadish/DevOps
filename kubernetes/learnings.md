## commands (snap vs apt)
sudo snap install kubectl - Why snap ??
Snap is a tool to install containerised applications on Linux.

apt-get
apt-get fetches from internet repositories and installs packages on Debian-based Linux distributions.

apt-install
installs packages on your system using apt-get.

## Namespace
A namespace is a logical grouping of resources in Kubernetes. It helps to organize and manage resources within a cluster.
Mechanism for isolating groups of resources within a single cluster.
Assigned a namespace to a node or pod, so that kubectl commands can be scoped to that namespace.

kubectl -> API-Server -> gets from namespace
kubectl get pods --namespace=<namespace-name>

Types of namespace:
- Default : All resources are created in default namespace if no namespace is specified.
- kube-node-lease
- kube-public
- kube-system: Reserved for system components managed by Kubernetes.

kubectl get pods --namespace=kube-system

Inside POD you need to run container not build an image.


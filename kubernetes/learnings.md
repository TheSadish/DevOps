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


## Pods
A Pod is the smallest and simplest Kubernetes object. It represents a single instance of a running process in your cluster.

kubectl apply -f <pod-definition-file>.yaml

## Deployments

A Deployment is a higher-level abstraction that manages a set of replicas of a pod.
It provides declarative updates for pods and replica sets.

kubectl create deployment <deployment-name> --image=<image-name>

labels and selectors:
Labels are key-value pairs attached to objects, such as pods, that can be used to organize and select subsets of objects.
Selectors are used to filter and identify objects based on their labels.

## Services

Service is a method for exposing a network application that is running as one or more Pods in your cluster.
Services enable communication between different components of an application.

5 types of services:
- ClusterIP (default): Exposes the service on a cluster-internal IP. Accessible only within the cluster.
- NodePort: Exposes the service on each node's IP at a static port (the NodePort). Accessible from outside the cluster.
- LoadBalancer: Creates an external load balancer in the cloud (if supported) and assigns a fixed, external IP to the service.
- ExternalName: Maps the service to the contents of the externalName field (e.g., foo.bar.example.com), by returning a CNAME record with its value.

## Ingress

Ingress is a set of rules that control how external HTTP/HTTPS traffic enters the Kubernetes cluster.
Ingress = traffic entry rules, not traffic itself.

1. User hits: http://myapp.com
2. Cloud LoadBalancer / NodePort receives traffic
3. Ingress Controller receives traffic
4. Ingress rules are checked
5. Traffic is routed to the correct Service
6. Service routes to Pod (via kube-proxy)

Ingress is a RULE.
Ingress Controller - is the ENGINE that applies the rule.

Runs as Pods in your cluster
Listens for incoming traffic

Ingress is by default disabled in minikube. You can enable it using the following command:
minikube addons enable ingress

To get the data from ingress host you need to update your local hosts file with the ingress IP and hostname mapping.
sudo vim /etc/hosts

192.168.49.2 django-app-ingress.net

## Exercise 3 - ConfigMap

After creating a ConfigMap and Pod, you check the environment variables inside the Pod to verify that the ConfigMap data has been correctly injected.

kubectl exec -it configmap-demo-pod -- /bin/sh
printenv
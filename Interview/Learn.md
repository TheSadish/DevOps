# DevOps Interview Prep - 2 Days (Fincrime RCE)
## Focus: Kubernetes, Docker, Azure, DevSecOps, Scripting

---

## **DAY 1: KUBERNETES & DOCKER + AZURE SERVICES**

### **PART 1: Docker (1 hour)**

#### Core Concepts You MUST Know:
1. **What is Docker?**
   - Containerization technology that packages app + dependencies
   - Solves "works on my machine" problem
   - Lightweight vs VMs

2. **Key Docker Commands:**
   ```bash
   docker build -t myapp:1.0 .              # Build image
   docker run -d -p 8080:8080 myapp:1.0    # Run container
   docker ps                                 # List running containers
   docker logs <container_id>               # View logs
   docker exec -it <container_id> bash      # Enter container
   docker push <registry>/myapp:1.0         # Push to registry
   docker inspect <container_id>            # Inspect details
   ```

3. **Dockerfile Best Practices:**
   ```dockerfile
   # ❌ BAD - Large image, security risk
   FROM ubuntu:latest
   RUN apt-get update && apt-get install nodejs
   COPY app /app
   RUN npm install
   ENTRYPOINT ["node", "app.js"]

   # ✅ GOOD - Multi-stage, optimized
   FROM node:18-alpine AS builder
   WORKDIR /app
   COPY package*.json ./
   RUN npm ci --only=production

   FROM node:18-alpine
   WORKDIR /app
   COPY --from=builder /app/node_modules ./node_modules
   COPY app ./
   USER node
   EXPOSE 3000
   ENTRYPOINT ["node", "app.js"]
   ```

4. **Interview Questions:**
   - Q: "What's the difference between CMD and ENTRYPOINT?"
     - A: CMD can be overridden; ENTRYPOINT usually can't
   - Q: "Why use multi-stage builds?"
     - A: Reduce final image size, remove build dependencies, better security
   - Q: "How do you optimize Docker images?"
     - A: Use alpine, multi-stage, layer caching, .dockerignore, minimal base

---

### **PART 2: Kubernetes (2 hours)**

#### Architecture Overview (Know This!)
```
Kubernetes Cluster
├── Control Plane (Master)
│   ├── API Server
│   ├── Scheduler
│   ├── Controller Manager
│   └── etcd (database)
├── Worker Nodes
│   ├── Node 1 (kubelet, kube-proxy)
│   ├── Node 2 (kubelet, kube-proxy)
│   └── Node 3 (kubelet, kube-proxy)
└── Add-ons (DNS, monitoring, logging)
```

#### Key Objects to Master:

**1. Pod (Smallest deployable unit)**
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-app
spec:
  containers:
  - name: app
    image: myapp:1.0
    ports:
    - containerPort: 8080
```

**2. Deployment (Manage replica sets)**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app-deployment
spec:
  replicas: 3                    # Run 3 pods
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1               # Max additional pods during update
      maxUnavailable: 0         # Keep all pods available
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
      - name: app
        image: myapp:1.0
        resources:
          requests:
            memory: "256Mi"      # Minimum needed
            cpu: "250m"
          limits:
            memory: "512Mi"      # Maximum allowed
            cpu: "500m"
        livenessProbe:          # Restart if unhealthy
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:         # Remove from traffic if unhealthy
          httpGet:
            path: /ready
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5
```

**3. Service (Expose pods to network)**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-app-service
spec:
  type: LoadBalancer          # Types: ClusterIP, NodePort, LoadBalancer
  selector:
    app: my-app
  ports:
  - port: 80                  # External port
    targetPort: 8080          # Pod port
```

**4. ConfigMap & Secret (Configuration)**
```yaml
# ConfigMap - non-sensitive data
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  DATABASE_URL: "postgres://db:5432"
  LOG_LEVEL: "INFO"

---

# Secret - sensitive data (base64 encoded, NOT encrypted)
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
type: Opaque
data:
  DB_PASSWORD: cGFzc3dvcmQxMjM=  # base64 encoded
  API_KEY: YWJjZGVmMTIzNDU2      # base64 encoded
```

**5. StatefulSet (For stateful apps like databases)**
```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
spec:
  replicas: 3
  serviceName: postgres
  selector:
    matchLabels:
      app: postgres
  template:
    # ... pod spec ...
```

#### Essential Kubectl Commands:
```bash
# Cluster info
kubectl cluster-info
kubectl get nodes
kubectl describe node <node-name>

# Deployments
kubectl create deployment myapp --image=myapp:1.0
kubectl apply -f deployment.yaml
kubectl get deployments
kubectl describe deployment myapp
kubectl logs deployment/myapp
kubectl set image deployment/myapp myapp=myapp:2.0  # Update image

# Pods
kubectl get pods
kubectl get pods -o wide              # More details
kubectl describe pod <pod-name>
kubectl logs <pod-name>
kubectl logs <pod-name> --previous    # Previous crashed container
kubectl exec -it <pod-name> bash      # Enter pod
kubectl port-forward <pod-name> 8080:8080

# Services
kubectl get svc
kubectl expose deployment myapp --type=LoadBalancer --port=80

# Debugging
kubectl get events
kubectl top nodes                     # Resource usage
kubectl top pods
```

#### Common Interview Questions:

**Q: "A pod keeps crashing. How do you troubleshoot?"**
```
A: Follow this sequence:
1. kubectl get pods                          # Check status
2. kubectl describe pod <pod-name>           # Check events
3. kubectl logs <pod-name> --previous        # Previous logs
4. kubectl logs <pod-name>                   # Current logs
5. kubectl exec -it <pod-name> bash          # Interactive debugging
6. Check resource limits: kubectl top pods
7. Check node resources: kubectl top nodes
8. Check networking: kubectl get svc, endpoints
```

**Q: "How do you update an image in Kubernetes?"**
```
A: Three ways:
1. kubectl set image deployment/myapp myapp=newimage:2.0
2. kubectl edit deployment myapp             # Edit YAML inline
3. kubectl apply -f updated-deployment.yaml
   
Rolling update strategy ensures zero downtime:
- New pods start before old ones stop
- Health checks (readiness/liveness probes) verify before traffic shift
```

**Q: "What's the difference between resources.requests and resources.limits?"**
```
A:
- requests: Minimum guaranteed resources pod needs
  → Scheduler uses this to find suitable node
  → If node doesn't have 256Mi, pod won't schedule
  
- limits: Maximum resources pod can consume
  → If exceeded, container is killed (OOMKilled)
  → Prevents runaway processes
  
Why both matter:
- Too low requests → pod doesn't get scheduled
- Too high limits → resource waste
- No limits → one pod can starve others
```

**Q: "How do you handle configuration in Kubernetes?"**
```
A:
- ConfigMap: Non-sensitive config (env vars, config files)
- Secret: Sensitive data (passwords, API keys, tokens)
  ⚠️ Note: Secrets are base64 encoded, NOT encrypted by default
  → Use encryption-at-rest for sensitive data
```

---

### **PART 3: Azure Services (1 hour)**

#### Must-Know Azure Services for This Role:

**1. Azure Container Registry (ACR)**
```yaml
# Push image to ACR
docker tag myapp:1.0 myregistry.azurecr.io/myapp:1.0
docker push myregistry.azurecr.io/myapp:1.0

# Key features:
- Geo-replication for global access
- Webhook support (trigger CI/CD on push)
- Image scanning (Trivy integration)
- Network isolation with private endpoints
```

**2. Azure Kubernetes Service (AKS)**
```bash
# Create AKS cluster
az aks create --resource-group myRG \
  --name myAKSCluster \
  --node-count 3 \
  --vm-set-type VirtualMachineScaleSets \
  --load-balancer-sku standard

# Get credentials
az aks get-credentials --resource-group myRG --name myAKSCluster

# Scale cluster
az aks scale --resource-group myRG --name myAKSCluster --node-count 5

# Update AKS version
az aks upgrade --resource-group myRG --name myAKSCluster --kubernetes-version 1.28
```

**3. Azure Key Vault (Secrets Management)**
```bash
# Store secrets
az keyvault secret set --vault-name myVault --name DBPassword --value "secret123"

# Retrieve secrets
az keyvault secret show --vault-name myVault --name DBPassword

# In CI/CD pipeline - retrieve and use
az keyvault secret show --vault-name myVault --name DBPassword --query value -o tsv
```

**4. Azure Container Instances (ACI)**
- Quick container deployment (no Kubernetes overhead)
- Used for one-off jobs, testing
- Cheaper for occasional workloads

**5. Azure DevOps (for CI/CD)**
- We'll cover in Day 2 scripting section

#### Key Azure Interview Questions:

**Q: "How would you set up a secure ACR with AKS?"**
```
A:
1. Create ACR in private endpoint mode
2. Create AKS cluster with managed identity
3. Grant AKS identity ACRPull role on ACR
4. Store ACR credentials in Key Vault
5. Configure pod identity to access Key Vault
6. Use private ACR endpoint within cluster
```

**Q: "How do you manage environment-specific configurations in Azure?"**
```
A:
- Dev/Staging/Prod: Separate Azure Resource Groups
- ConfigMaps for non-sensitive data
- Key Vault for sensitive data (passwords, API keys)
- Helm values.yaml per environment
- Azure DevOps variable groups (with secrets)
```

---

## **DAY 2: DEVSECOPS + SCRIPTING + MOCK INTERVIEW**

### **PART 1: DevSecOps (1.5 hours)**

#### Key DevSecOps Tools & Practices:

**1. Container Scanning (Vulnerability Detection)**

```bash
# Trivy - Scan images for vulnerabilities
trivy image myapp:1.0
trivy image --severity HIGH,CRITICAL myapp:1.0

# In CI/CD pipeline:
trivy image --exit-code 1 --severity HIGH myapp:1.0
# Exit with error if HIGH/CRITICAL found → fails build

# Snyk - Alternative (developer-friendly)
snyk test --docker myapp:1.0
```

**2. Secrets Scanning**
```bash
# TruffleHog - Detect secrets in code
trufflehog filesystem /path/to/repo --json

# In CI/CD: Prevent secrets from being committed
# Use pre-commit hooks or git-secrets
git-secrets --scan
```

**3. Azure Key Vault in CI/CD**
```yaml
# Azure DevOps Pipeline - Secure secret handling
trigger:
  - main

pool:
  vmImage: 'ubuntu-latest'

variables:
  - group: 'KeyVault-Secrets'  # Linked to Key Vault

steps:
- task: AzureKeyVault@2
  inputs:
    azureSubscription: 'MySubscription'
    KeyVaultName: 'myKeyVault'
    SecretsFilter: '*'  # Fetch all secrets
    RunAsPreJob: true

- script: |
    # Secret is now available as env var
    echo "Deploying with password: $(DBPassword)"
  displayName: 'Deploy'
```

**4. Role-Based Access Control (RBAC)**
```yaml
# Example: Limit pod access to specific namespaces
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
  namespace: default
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list"]

---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods
  namespace: default
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: pod-reader
subjects:
- kind: ServiceAccount
  name: myapp
  namespace: default
```

**5. Network Policies (Micro-segmentation)**
```yaml
# Restrict traffic to only specific pods
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all
spec:
  podSelector: {}
  policyTypes:
  - Ingress

---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
```

#### DevSecOps Interview Questions:

**Q: "How do you prevent secrets from being exposed in CI/CD?"**
```
A:
1. Never hardcode secrets in code/config files
2. Use Azure Key Vault for storage
3. Retrieve secrets at runtime using managed identities
4. Mask secrets in pipeline logs ($(VarName) gets masked)
5. Use git-secrets/TruffleHog to scan before commit
6. Implement secret rotation policies
7. Audit access logs in Key Vault
```

**Q: "What's your approach to securing container images?"**
```
A:
1. Use minimal base images (alpine, distroless)
2. Scan for vulnerabilities (Trivy, Snyk) in CI/CD
3. Fail build if HIGH/CRITICAL vulnerabilities found
4. Keep base images updated
5. Use image signing and verification
6. Store images in private registry (ACR)
7. Implement image retention policies
```

---

### **PART 2: Bash/PowerShell Scripting (1.5 hours)**

#### Bash Essentials (Most Common in DevOps):

**1. Variables & String Operations**
```bash
# Variables
NAME="DevOps"
echo "Hello $NAME"
echo "Hello ${NAME}"  # Cleaner syntax

# String manipulation
echo ${NAME:0:3}      # First 3 chars: "Dev"
echo ${NAME#Dev}      # Remove prefix: "Ops"
echo ${NAME%ps}       # Remove suffix: "DevO"
echo ${NAME^^}        # Uppercase: "DEVOPS"
echo ${NAME,,}        # Lowercase: "devops"

# Command substitution
TIMESTAMP=$(date +%Y%m%d)
echo "Backup-$TIMESTAMP"
```

**2. Conditionals**
```bash
# If-else
if [ -f "/etc/passwd" ]; then
    echo "File exists"
else
    echo "File not found"
fi

# String comparison
if [ "$NAME" = "DevOps" ]; then
    echo "Equal"
fi

# Numeric comparison
if [ $COUNT -gt 5 ]; then
    echo "Greater than 5"
fi

# File tests
if [ -d "/tmp" ]; then echo "Directory exists"; fi
if [ -f "$FILE" ]; then echo "File exists"; fi
if [ -r "$FILE" ]; then echo "Readable"; fi
if [ -w "$FILE" ]; then echo "Writable"; fi
if [ -x "$FILE" ]; then echo "Executable"; fi
```

**3. Loops**
```bash
# For loop
for i in {1..5}; do
    echo "Iteration $i"
done

# While loop
while [ $count -lt 5 ]; do
    echo $count
    ((count++))
done

# Loop through array
APPS=("app1" "app2" "app3")
for app in "${APPS[@]}"; do
    echo "Deploying $app"
done
```

**4. Functions**
```bash
# Function definition
deploy_app() {
    local APP_NAME=$1
    local VERSION=$2
    
    echo "Deploying $APP_NAME version $VERSION"
    docker pull $APP_NAME:$VERSION
    docker run -d $APP_NAME:$VERSION
}

# Call function
deploy_app "myapp" "1.0"
```

**5. Real-World DevOps Examples:**

**Example 1: Health Check Script**
```bash
#!/bin/bash

HOSTS=("api.example.com" "db.example.com" "cache.example.com")
FAILED=0

for host in "${HOSTS[@]}"; do
    if ping -c 1 "$host" > /dev/null 2>&1; then
        echo "✓ $host is up"
    else
        echo "✗ $host is down"
        ((FAILED++))
    fi
done

if [ $FAILED -gt 0 ]; then
    echo "ALERT: $FAILED hosts are down"
    exit 1
fi
```

**Example 2: Log Rotation Script**
```bash
#!/bin/bash

LOG_DIR="/var/log/myapp"
DAYS=7

# Find and compress logs older than 7 days
find "$LOG_DIR" -name "*.log" -type f -mtime +$DAYS | while read file; do
    gzip "$file"
    echo "Compressed: $file"
done

# Remove files older than 30 days
find "$LOG_DIR" -name "*.log.gz" -type f -mtime +30 -delete
```

**Example 3: Kubernetes Pod Restart Check**
```bash
#!/bin/bash

NAMESPACE="production"
RESTART_THRESHOLD=3

kubectl get pods -n "$NAMESPACE" -o json | \
jq -r '.items[] | "\(.metadata.name) \(.status.containerStatuses[0].restartCount)"' | \
while read POD RESTARTS; do
    if [ "$RESTARTS" -gt "$RESTART_THRESHOLD" ]; then
        echo "WARNING: $POD restarted $RESTARTS times"
    fi
done
```

#### PowerShell Essentials:

**1. Basic Syntax (Azure-focused)**
```powershell
# Variables
$Name = "DevOps"
$Count = 5

# String interpolation
Write-Host "Hello $Name"
Write-Host "Count: $Count"

# Arrays
$Apps = @("app1", "app2", "app3")
$Apps[0]          # First element
$Apps.Length      # Array length
$Apps += "app4"   # Add to array

# Conditionals
if ($Count -gt 5) {
    Write-Host "Greater than 5"
} else {
    Write-Host "Less than or equal to 5"
}

# Loops
foreach ($app in $Apps) {
    Write-Host "App: $app"
}

for ($i = 0; $i -lt 5; $i++) {
    Write-Host "Number: $i"
}

# Functions
function Deploy-App {
    param (
        [string]$AppName,
        [string]$Version
    )
    Write-Host "Deploying $AppName version $Version"
}

Deploy-App -AppName "myapp" -Version "1.0"
```

**2. Azure PowerShell Examples**
```powershell
# Connect to Azure
Connect-AzAccount

# Get Azure resources
Get-AzResourceGroup
Get-AzVM -ResourceGroupName "myRG"

# Create VM
New-AzVM -ResourceGroupName "myRG" -Name "myVM" -Image "UbuntuLTS"

# Scale AKS cluster
$aks = Get-AzAks -ResourceGroupName "myRG" -Name "myCluster"
Set-AzAksNodePool -ResourceGroupName "myRG" -ClusterName "myCluster" `
    -Name "default" -Count 5

# Get Key Vault secret
$secret = Get-AzKeyVaultSecret -VaultName "myVault" -Name "DBPassword"
$password = $secret.SecretValue | ConvertFrom-SecureString -AsPlainText
```

#### Scripting Interview Questions:

**Q: "Write a script to check if a service is running and restart it if not"**
```bash
A (Bash):
#!/bin/bash

SERVICE="nginx"

if systemctl is-active --quiet $SERVICE; then
    echo "$SERVICE is running"
else
    echo "$SERVICE is down, restarting..."
    systemctl restart $SERVICE
    sleep 5
    
    if systemctl is-active --quiet $SERVICE; then
        echo "$SERVICE restarted successfully"
    else
        echo "Failed to restart $SERVICE"
        exit 1
    fi
fi
```

**Q: "How would you automate image pushing to ACR?"**
```bash
A (Bash):
#!/bin/bash

IMAGE_NAME=$1
VERSION=$2
REGISTRY="myregistry.azurecr.io"

# Build image
docker build -t $IMAGE_NAME:$VERSION .

# Tag for registry
docker tag $IMAGE_NAME:$VERSION $REGISTRY/$IMAGE_NAME:$VERSION
docker tag $IMAGE_NAME:$VERSION $REGISTRY/$IMAGE_NAME:latest

# Login to ACR (using service principal or managed identity)
az acr login --name myregistry

# Push image
docker push $REGISTRY/$IMAGE_NAME:$VERSION
docker push $REGISTRY/$IMAGE_NAME:latest

echo "Image pushed: $REGISTRY/$IMAGE_NAME:$VERSION"
```

---

### **PART 3: Mock Interview & STAR Stories (1.5 hours)**

#### STAR Method for Behavioral Questions:
**Situation → Task → Action → Result**

#### Practice Stories from Your Resume:

**Story 1: "Tell us about your most complex CI/CD pipeline project"**
```
Situation: At Accenture, we had multiple teams deploying microservices 
          independently, causing deployment conflicts and downtime.

Task:     I was tasked to design a standardized, scalable CI/CD pipeline 
          for 15+ microservices.

Action:   - Created multi-stage Azure DevOps pipelines with approval gates
          - Implemented automated testing (unit, integration, security scans)
          - Set up artifact versioning and deployment tracking
          - Configured rollback mechanisms for failed deployments
          - Documented standards for all teams to follow

Result:   - Reduced deployment time by 60% (4 hours → 40 minutes)
          - Zero unplanned downtime in 6 months
          - 95% first-time deployment success rate
```

**Story 2: "Describe a Kubernetes incident and how you resolved it"**
```
Situation: Production microservices were experiencing random pod crashes
          and performance degradation.

Task:     Investigate root cause and implement fix within 2 hours.

Action:   - Used kubectl logs and describe pod to check events
          - Found OOMKilled errors (out of memory)
          - Checked node capacity: nodes were at 95% memory
          - Analyzed pod resource requests/limits
          - Updated deployment with appropriate resource limits
          - Implemented Horizontal Pod Autoscaler (HPA)

Result:   - Pods stabilized immediately
          - Implemented monitoring alerting for resource usage
          - Prevented similar incidents through HPA
```

**Story 3: "How did you improve security in your DevOps pipeline?"**
```
Situation: Security audit found hardcoded secrets in configuration files
          and container images with known vulnerabilities.

Task:     Implement DevSecOps practices to meet compliance requirements.

Action:   - Moved all secrets to Azure Key Vault
          - Integrated Trivy scanning in CI/CD pipeline (fail on HIGH)
          - Implemented image signing and verification
          - Set up RBAC in Kubernetes clusters
          - Created network policies for pod isolation
          - Established secret rotation policies

Result:   - Zero secrets in code repositories
          - All vulnerabilities remediated before production
          - Passed security audit with zero findings
          - Reduced incident response time by 70%
```

#### Common Technical Questions (Have Answers Ready):

**Q: "What's the biggest challenge you faced in your DevOps role?"**
- Answer: Balancing speed with stability
- How you solved it: Automated testing, gradual rollouts, monitoring

**Q: "How do you stay updated with DevOps trends?"**
- Answer: Azure certifications, online courses, community projects
- Be specific: Which courses? Which projects?

**Q: "Why do you want to join this company?"**
- Research Fincrime (regulatory compliance, security-critical)
- Answer: "Your focus on security aligns with my DevSecOps expertise"

**Q: "What's your experience with infrastructure as code?"**
- Answer: Terraform, ARM templates, Helm for Kubernetes
- Give examples: "Automated deployment of 50+ Azure resources"

---

## **QUICK REFERENCE - Interview Day Checklist**

### **Day Before:**
- [ ] Review this guide one more time
- [ ] Run through 3 STAR stories from your resume
- [ ] Test Docker commands locally
- [ ] Get good sleep

### **Interview Day:**
- [ ] Arrive 10 minutes early
- [ ] Bring laptop (might ask for live coding)
- [ ] Have Azure DevOps/GitHub examples ready to discuss
- [ ] Speak clearly - explain your thinking process
- [ ] Ask questions about their infrastructure/challenges

### **Key Talking Points:**
✅ Your OpenTelemetry Kubernetes project  
✅ Your 30% automation improvement metrics  
✅ Your Azure certifications  
✅ Your CI/CD pipeline experience  
✅ Your DevSecOps initiatives  

---

## **Final Tips**

1. **For Kubernetes questions:** Always mention probes (readiness/liveness), resource limits, and troubleshooting steps
2. **For Azure questions:** Show familiarity with ACR, AKS, Key Vault integration
3. **For DevSecOps:** Emphasize secrets management and vulnerability scanning
4. **For scripting:** Have 2-3 real automation scripts you've written
5. **Listen carefully:** If they ask about a tool you don't know, say "I haven't used that specific tool, but I'm experienced with similar solutions"

Good luck! You've got this! 🚀

# DevOps Interview Prep - 2 Days (Fincrime RCE)
## Focus: Kubernetes, Docker, Azure, DevSecOps, Scripting

---

## **DAY 1: CI/CD + KUBERNETES & DOCKER + AZURE SERVICES**

### **PART 0: CI/CD PIPELINES (2 hours) - CRITICAL FOR THIS ROLE**

#### **What is CI/CD?**

**CI (Continuous Integration):**
- Developers commit code frequently (multiple times/day)
- Automated tests run on every commit
- Code quality checks (linting, security scanning)
- Builds happen automatically
- Quick feedback (pass/fail in minutes)

**CD (Continuous Deployment/Delivery):**
- **Continuous Delivery**: Automated deployment to staging, manual to production
- **Continuous Deployment**: Fully automated to production
- Artifacts versioned and trackable
- Rollback capability if needed

**Benefits:**
- Faster time to market (deploy multiple times/day)
- Higher quality (automated tests catch bugs)
- Reduced manual errors
- Better collaboration between teams

---

#### **1. GitHub Actions (Modern, Cloud-Native)**

**What it is:**
- GitHub's native CI/CD platform
- Runs workflows on GitHub events (push, PR, schedule)
- Free for public repos, minutes-based for private
- Integrated directly with your code

**Basic Workflow Structure:**
```yaml
name: CI/CD Pipeline

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  # Job 1: Build & Test
  build-and-test:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
    
    steps:
    - uses: actions/checkout@v3
      with:
        fetch-depth: 0
    
    - name: Set up Node.js
      uses: actions/setup-node@v3
      with:
        node-version: '18'
        cache: 'npm'
    
    - name: Install dependencies
      run: npm ci
    
    - name: Run tests
      run: npm test
    
    - name: Run linting
      run: npm run lint
    
    - name: Run security scan
      uses: aquasecurity/trivy-action@master
      with:
        scan-type: 'fs'
        scan-ref: '.'
        format: 'sarif'
        output: 'trivy-results.sarif'
    
    - name: Upload to GitHub Security
      uses: github/codeql-action/upload-sarif@v2
      with:
        sarif_file: 'trivy-results.sarif'
    
    - name: Build Docker image
      run: docker build -t ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }} .
    
    - name: Scan Docker image
      run: |
        docker run aquasec/trivy image --exit-code 1 --severity HIGH,CRITICAL \
          ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}

  # Job 2: Push to Registry
  push-image:
    needs: build-and-test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    permissions:
      contents: read
      packages: write
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Log in to Container Registry
      uses: docker/login-action@v2
      with:
        registry: ${{ env.REGISTRY }}
        username: ${{ github.actor }}
        password: ${{ secrets.GITHUB_TOKEN }}
    
    - name: Build and push Docker image
      uses: docker/build-push-action@v4
      with:
        context: .
        push: true
        tags: |
          ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:latest
          ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}
        cache-from: type=gha
        cache-to: type=gha,mode=max

  # Job 3: Deploy
  deploy:
    needs: push-image
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Deploy to production
      run: |
        echo "Deploying image to Kubernetes"
        kubectl set image deployment/myapp myapp=${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }} \
          --record \
          -n production
    
    - name: Wait for rollout
      run: kubectl rollout status deployment/myapp -n production --timeout=5m
    
    - name: Health check
      run: |
        for i in {1..10}; do
          if curl -f http://myapp-service/health; then
            echo "Application is healthy"
            exit 0
          fi
          echo "Attempt $i - waiting for app to be ready..."
          sleep 10
        done
        exit 1
    
    - name: Rollback on failure
      if: failure()
      run: kubectl rollout undo deployment/myapp -n production
```

**Key Concepts:**
- **Triggers**: When workflow runs (push, PR, schedule, manual)
- **Jobs**: Parallel or sequential tasks
- **Steps**: Individual commands in a job
- **Actions**: Reusable components from community
- **Secrets**: Store sensitive data (API keys, tokens)

**GitHub Actions Best Practices:**
1. Use specific action versions (not `@latest`)
2. Cache dependencies (`cache: 'npm'`)
3. Run security scans before deployment
4. Implement approval gates for production
5. Use branch protection rules
6. Tag releases automatically
7. Keep logs clean (don't expose secrets)

---

#### **2. Azure DevOps Pipelines (Enterprise, Flexible)**

**What it is:**
- Microsoft's CI/CD platform (part of Azure ecosystem)
- Supports multiple languages and deployment targets
- Can be YAML-based or graphical UI
- Better for enterprises with complex workflows

**Multi-Stage Pipeline (Full Example):**
```yaml
trigger:
  - main
  - develop

pr:
  - main

variables:
  vmImage: 'ubuntu-latest'
  imageName: 'myapp'
  buildNumber: $(Build.BuildNumber)
  commitHash: $(Build.SourceVersion)
  registryConnection: 'myRegistry'
  registryUrl: 'myregistry.azurecr.io'
  kubernetesConnection: 'myAKSCluster'
  kubernetesNamespace: 'default'

stages:
# ============ STAGE 1: BUILD & TEST ============
- stage: Build
  displayName: 'Build & Test'
  jobs:
  - job: BuildJob
    displayName: 'Build Application'
    pool:
      vmImage: $(vmImage)
    
    steps:
    - checkout: self
      fetchDepth: 0
      displayName: 'Checkout Code'
    
    - task: NodeTool@0
      inputs:
        versionSpec: '18.x'
      displayName: 'Install Node.js'
    
    - task: Npm@1
      inputs:
        command: 'install'
        workingDir: '$(Build.SourcesDirectory)'
      displayName: 'npm install'
    
    - task: Npm@1
      inputs:
        command: 'custom'
        customCommand: 'run test'
        workingDir: '$(Build.SourcesDirectory)'
      displayName: 'Run Unit Tests'
      continueOnError: false
    
    - task: Npm@1
      inputs:
        command: 'custom'
        customCommand: 'run lint'
        workingDir: '$(Build.SourcesDirectory)'
      displayName: 'Run Code Linting'
      continueOnError: true
    
    - task: PublishBuildArtifacts@1
      inputs:
        pathToPublish: '$(Build.SourcesDirectory)/dist'
        artifactName: 'build-output'
        publishLocation: 'Container'
      displayName: 'Publish Build Artifacts'

# ============ STAGE 2: SECURITY SCANNING ============
- stage: Security
  displayName: 'Security Scanning'
  dependsOn: Build
  condition: succeeded()
  
  jobs:
  - job: SecurityScan
    displayName: 'Container & Code Security'
    pool:
      vmImage: $(vmImage)
    
    steps:
    - checkout: self
      displayName: 'Checkout Code'
    
    - task: Docker@2
      inputs:
        command: 'build'
        Dockerfile: '$(Build.SourcesDirectory)/Dockerfile'
        tags: |
          $(imageName):$(buildNumber)
          $(imageName):latest
      displayName: 'Build Docker Image'
    
    - task: AquaSecurityScanner@2
      inputs:
        image: '$(imageName):$(buildNumber)'
        hideBaseImageVulnerabilities: false
        threshold: 'high'
      displayName: 'Scan Docker Image (Trivy)'
      continueOnError: false
    
    - task: SnykSecurityScan@1
      inputs:
        serviceConnectionEndpoint: 'Snyk'
        testDirectory: '$(Build.SourcesDirectory)'
        failOnThreshold: 'high'
      displayName: 'Snyk Vulnerability Scan'
      continueOnError: true
    
    - script: |
        git secrets --scan
      displayName: 'Scan for Hardcoded Secrets'
      continueOnError: true

# ============ STAGE 3: BUILD & PUSH TO ACR ============
- stage: BuildAndPush
  displayName: 'Build & Push Container'
  dependsOn: Security
  condition: succeeded()
  
  jobs:
  - job: DockerBuild
    displayName: 'Build & Push Docker Image'
    pool:
      vmImage: $(vmImage)
    
    steps:
    - checkout: self
      displayName: 'Checkout Code'
    
    - task: Docker@2
      displayName: 'Login to ACR'
      inputs:
        command: login
        containerRegistry: $(registryConnection)
    
    - task: Docker@2
      displayName: 'Build Docker Image'
      inputs:
        command: build
        Dockerfile: '$(Build.SourcesDirectory)/Dockerfile'
        repository: $(imageName)
        tags: |
          $(buildNumber)
          latest
          $(commitHash)
    
    - task: Docker@2
      displayName: 'Push to ACR'
      inputs:
        command: push
        repository: $(imageName)
        containerRegistry: $(registryConnection)
        tags: |
          $(buildNumber)
          latest
          $(commitHash)
    
    - script: |
        echo "Image pushed: $(registryUrl)/$(imageName):$(buildNumber)"
      displayName: 'Print Image Info'

# ============ STAGE 4: DEPLOY TO DEV ============
- stage: DeployDev
  displayName: 'Deploy to Development'
  dependsOn: BuildAndPush
  condition: succeeded()
  
  jobs:
  - deployment: DeployDev
    displayName: 'Deploy to Dev Cluster'
    environment: 'development'
    strategy:
      runOnce:
        deploy:
          steps:
          - task: KubernetesManifest@0
            displayName: 'Create/Update Deployment'
            inputs:
              action: 'deploy'
              kubernetesServiceConnection: $(kubernetesConnection)
              namespace: $(kubernetesNamespace)-dev
              manifests: |
                $(Pipeline.Workspace)/manifests/deployment.yaml
                $(Pipeline.Workspace)/manifests/service.yaml
              containers: |
                $(registryUrl)/$(imageName):$(buildNumber)
          
          - task: Kubernetes@1
            displayName: 'Verify Deployment'
            inputs:
              connectionType: 'Kubernetes Service Connection'
              kubernetesServiceConnection: $(kubernetesConnection)
              namespace: $(kubernetesNamespace)-dev
              command: 'rollout'
              arguments: 'status deployment/myapp --timeout=5m'

# ============ STAGE 5: SMOKE TESTS ============
- stage: SmokeTests
  displayName: 'Smoke Tests'
  dependsOn: DeployDev
  condition: succeeded()
  
  jobs:
  - job: SmokeTest
    displayName: 'Run Smoke Tests'
    pool:
      vmImage: $(vmImage)
    
    steps:
    - checkout: self
      displayName: 'Checkout Code'
    
    - task: Npm@1
      inputs:
        command: 'install'
        workingDir: '$(Build.SourcesDirectory)/tests/smoke'
      displayName: 'Install Test Dependencies'
    
    - script: |
        npx jest --config=$(Build.SourcesDirectory)/tests/smoke/jest.config.js
      displayName: 'Run Smoke Tests'
      env:
        TEST_ENVIRONMENT: 'dev'
        APP_URL: 'http://myapp-dev-service'

# ============ STAGE 6: DEPLOY TO STAGING ============
- stage: DeployStaging
  displayName: 'Deploy to Staging'
  dependsOn: SmokeTests
  condition: succeeded()
  
  jobs:
  - deployment: DeployStaging
    displayName: 'Deploy to Staging'
    environment: 'staging'
    strategy:
      runOnce:
        deploy:
          steps:
          - task: KubernetesManifest@0
            displayName: 'Deploy to Staging'
            inputs:
              action: 'deploy'
              kubernetesServiceConnection: $(kubernetesConnection)
              namespace: $(kubernetesNamespace)-staging
              manifests: |
                $(Pipeline.Workspace)/manifests/deployment.yaml
                $(Pipeline.Workspace)/manifests/service.yaml

# ============ STAGE 7: APPROVAL & DEPLOY TO PRODUCTION ============
- stage: DeployProduction
  displayName: 'Deploy to Production'
  dependsOn: DeployStaging
  condition: succeeded()
  
  jobs:
  - deployment: DeployProd
    displayName: 'Deploy to Production'
    environment: 'production'
    strategy:
      runOnce:
        preDeploy:
          steps:
          - task: Bash@3
            displayName: 'Pre-deployment Health Check'
            inputs:
              targetType: 'inline'
              script: |
                echo "Checking current production health..."
                kubectl get deployment myapp -n production
        
        deploy:
          steps:
          - task: KubernetesManifest@0
            displayName: 'Deploy with Rolling Update'
            inputs:
              action: 'deploy'
              kubernetesServiceConnection: $(kubernetesConnection)
              namespace: $(kubernetesNamespace)-prod
              strategy: 'canary'
              percentage: '25'
              manifests: |
                $(Pipeline.Workspace)/manifests/deployment.yaml
          
          - task: Bash@3
            displayName: 'Monitor Canary Deployment'
            inputs:
              targetType: 'inline'
              script: |
                kubectl rollout status deployment/myapp -n production --timeout=10m
                kubectl top pods -n production
        
        routeTraffic:
          steps:
          - task: Bash@3
            displayName: 'Route 100% Traffic'
            inputs:
              targetType: 'inline'
              script: |
                echo "Shifting 100% traffic to new version"
                kubectl set env deployment/myapp -n production CANARY=false
        
        postRouteTraffic:
          steps:
          - task: Bash@3
            displayName: 'Production Health Check'
            inputs:
              targetType: 'inline'
              script: |
                for i in {1..5}; do
                  if curl -f https://api.example.com/health; then
                    echo "✓ Health check passed"
                  else
                    echo "✗ Health check failed"
                    exit 1
                  fi
                  sleep 10
                done
        
        onFailure:
          steps:
          - task: Kubernetes@1
            displayName: 'Automatic Rollback'
            inputs:
              connectionType: 'Kubernetes Service Connection'
              kubernetesServiceConnection: $(kubernetesConnection)
              namespace: production
              command: 'rollout'
              arguments: 'undo deployment/myapp'
```

**Key Azure DevOps Concepts:**
- **Triggers**: What initiates the pipeline
- **Stages**: Logical groupings (Build → Test → Deploy)
- **Jobs**: Parallel or sequential work units
- **Tasks**: Individual steps (built-in or from marketplace)
- **Variables**: Store configuration values
- **Variable Groups**: Linked to Key Vault for secrets
- **Approvals**: Manual gates before prod deployment
- **Environments**: Deployment targets (dev/staging/prod)
- **Strategy**: Deployment pattern (rolling, blue-green, canary)

**Azure DevOps Best Practices:**
1. Use YAML pipelines (version controlled)
2. Link variable groups to Key Vault
3. Implement approval gates for production
4. Use service connections (not personal credentials)
5. Tag releases automatically
6. Keep build artifacts for rollback
7. Run security scans before deployment
8. Monitor pipeline execution time
9. Use predefined tasks (tested by Microsoft)
10. Implement notifications (Teams, email)

---

#### **3. CI/CD Pipeline Design Patterns**

**Pattern 1: Build Once, Deploy Everywhere**
```
Code Commit → Build (generate artifact) → Dev Deploy → Staging Deploy → Prod Deploy
                          ↓
                   Versioned Artifact (reused)
```
✅ Benefits: Single source of truth, identical builds
❌ Risk: Bug in one might affect all

**Pattern 2: Blue-Green Deployment**
```
Blue (Old)     Green (New)
  ↓               ↓
Load Balancer switches traffic instantly
  ↓
Instant rollback if needed
```
✅ Benefits: Zero downtime, instant rollback
❌ Cost: Double infrastructure

**Pattern 3: Canary Deployment**
```
Version 1: 95% traffic
Version 2: 5% traffic → Monitor metrics → Increase gradually
```
✅ Benefits: Early detection of issues
❌ Complexity: Traffic management logic needed

**Pattern 4: Feature Flags (Release Toggle)**
```
Deploy to production → Feature disabled → Monitor → Enable for users
```
✅ Benefits: Deploy anytime, control release
❌ Complexity: Flag management needed

---

#### **4. Multi-Branch Strategy (GitFlow)**

```
main (production) ← release branch ← develop ← feature branches
    ↓
  tags (v1.0.0)
```

**Branch Protection Rules:**
```yaml
# main branch
- Require pull request reviews (minimum 2)
- Require status checks to pass (CI/CD)
- Require branches to be up to date
- Require code review from code owners
- Require approval from 2 reviewers
- Dismiss stale reviews
- Block automatic merges
```

---

#### **5. CI/CD Common Interview Questions**

**Q: "Design a CI/CD pipeline for a microservices application"**
```
A:
Stages:
1. Commit: Developer pushes code
2. Build: Compile + unit tests
3. Security: Scan code/containers for vulnerabilities
4. Build Image: Create Docker image
5. Dev Deploy: Automated to dev cluster
6. Smoke Tests: Basic functionality tests
7. Staging Deploy: Automated to staging
8. Integration Tests: Full suite
9. Approval Gate: Manual approval required
10. Prod Deploy: Blue-green/canary strategy
11. Health Check: Verify production is healthy
12. Notification: Slack/email on success/failure

Key practices:
- Fail fast (stop pipeline on first failure)
- Parallel jobs (build & scan simultaneously)
- Artifact versioning (tag with git commit hash)
- Secrets in Key Vault (never in code/YAML)
- Rollback capability (keep previous version)
- Audit trail (log all deployments)
```

**Q: "What's the difference between CI and CD?"**
```
A:
CI (Continuous Integration):
- Merge code frequently (multiple times/day)
- Automated tests on every commit
- Catch bugs early
- Focuses on merging code

CD (Continuous Delivery/Deployment):
- Delivery: Automated to staging, manual to prod
- Deployment: Fully automated to prod
- Focuses on releasing code
```

**Q: "How do you handle secrets in CI/CD pipelines?"**
```
A:
1. Never store in code/YAML
2. Use Azure Key Vault / GitHub Secrets
3. Retrieve at runtime using managed identity
4. Mask in pipeline logs (logs show ***)
5. Use RBAC to control access
6. Audit access (check who accessed what)
7. Rotate secrets regularly
8. Don't commit .env files

Example (Azure DevOps):
variables:
  - group: 'KeyVault-Secrets'  # Linked to Key Vault

steps:
- task: AzureKeyVault@2
  inputs:
    KeyVaultName: 'myVault'
    SecretsFilter: '*'

- script: echo "Password: $(DBPassword)"  # Shows as ***
```

**Q: "How do you ensure zero-downtime deployments?"**
```
A:
1. Rolling updates:
   - Start new pods before stopping old
   - Health checks verify readiness
   - Traffic shift happens gradually
   
2. Blue-green deployment:
   - Run new version alongside old
   - Switch all traffic at once
   - Instant rollback if issues

3. Canary deployment:
   - Release to 5% users first
   - Monitor metrics (errors, latency)
   - Gradually increase percentage
   
4. Health checks critical:
   - Readiness probe: Can accept traffic?
   - Liveness probe: Still alive?
   - Pod must pass readiness before traffic

5. Deployment verification:
   - Wait for rollout status
   - Run smoke tests
   - Monitor logs/metrics
```

**Q: "What happens when deployment fails?"**
```
A:
1. Automated rollback:
   - kubectl rollout undo deployment/myapp
   - Revert to previous version
   - Fast recovery (seconds)

2. Monitoring & alerting:
   - Prometheus detects error rate spike
   - Alert sent (Slack/PagerDuty)
   - On-call engineer notified

3. Investigation:
   - Check logs (kubectl logs)
   - Check metrics (CPU, memory)
   - Compare versions (what changed?)
   - Review deployment YAML

4. Remediation:
   - Fix code issue
   - Create hotfix branch
   - Re-run pipeline
   - Deploy fixed version

5. Root cause analysis:
   - Postmortem meeting
   - Document what happened
   - Implement safeguards
```

**Q: "How do you test in CI/CD pipeline?"**
```
A:
1. Unit tests:
   - Test individual functions
   - Run on every commit
   - Must pass before build

2. Integration tests:
   - Test component interactions
   - Run in staging environment
   - Before production deployment

3. Security scanning:
   - SAST (static): Scan code for vulnerabilities
   - DAST (dynamic): Scan running app
   - Dependency scanning: Check libraries
   - Container scanning: Check image layers

4. Smoke tests:
   - Critical path tests (login, main flow)
   - Run in dev/staging
   - Quick check before prod

5. Load tests:
   - Simulate production traffic
   - Check performance under load
   - Before major releases

6. Manual testing:
   - Acceptance testing (before prod)
   - Exploratory testing (edge cases)
```

---

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

### **Recommended Study Schedule (2 Days):**

**Day 1 (5-6 hours):**
- [ ] **CI/CD Pipelines** (1.5 hours) ← MOST IMPORTANT
  - GitHub Actions workflow structure
  - Azure DevOps multi-stage pipelines
  - Deployment strategies (rolling, blue-green, canary)
  - Branch protection & GitFlow
  
- [ ] **Docker** (1 hour)
  - Dockerfile optimization
  - Multi-stage builds
  - Common commands

- [ ] **Kubernetes** (2 hours)
  - Architecture overview
  - Key objects (Deployment, Service, ConfigMap, Secret)
  - kubectl troubleshooting commands

- [ ] **Azure Services** (1 hour)
  - ACR, AKS, Key Vault basics
  - Integration patterns

**Day 2 (4-5 hours):**
- [ ] **DevSecOps** (1.5 hours)
  - Container scanning, secrets management
  - RBAC, network policies

- [ ] **Scripting** (1.5 hours)
  - Bash automation scripts
  - PowerShell for Azure

- [ ] **Mock Interview** (1.5 hours)
  - Practice STAR stories
  - Technical Q&A
  - Design a CI/CD pipeline

### **Day Before Interview:**
- [ ] Review CI/CD pipeline design (most asked)
- [ ] Run through 3 STAR stories from your resume
- [ ] Test Docker/kubectl commands locally
- [ ] Prepare your own CI/CD pipeline questions
- [ ] Get good sleep

### **Interview Day:**
- [ ] Arrive 10 minutes early
- [ ] Bring laptop (might ask for live coding/pipeline design)
- [ ] Have your GitHub/Azure DevOps pipeline examples ready
- [ ] Be ready to design a CI/CD pipeline from scratch
- [ ] Speak clearly - explain your thinking process
- [ ] Ask them about their CI/CD challenges and bottlenecks

### **Key Talking Points (In Order of Importance):**
✅ **Your CI/CD pipeline experience** (most critical for this role)
✅ **GitHub & Azure DevOps pipelines** (they specifically ask for both)
✅ **Your Kubernetes projects** (OpenTelemetry Demo)
✅ **Multi-stage pipeline design** (build → test → deploy)
✅ **Your automation improvements** (30% metric)
✅ **DevSecOps practices** (Fincrime = security-critical)
✅ **Your Azure certifications**

---

## **Final Tips**

1. **For Kubernetes questions:** Always mention probes (readiness/liveness), resource limits, and troubleshooting steps
2. **For Azure questions:** Show familiarity with ACR, AKS, Key Vault integration
3. **For DevSecOps:** Emphasize secrets management and vulnerability scanning
4. **For scripting:** Have 2-3 real automation scripts you've written
5. **Listen carefully:** If they ask about a tool you don't know, say "I haven't used that specific tool, but I'm experienced with similar solutions"

Good luck! You've got this! 🚀

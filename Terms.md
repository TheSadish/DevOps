# AZ-104 Azure Administrator
## Complete Quick Revision Guide

**Purpose:** Simple definitions, exam keywords, important values, and scenario-based shortcuts.

---

# 1. Azure Networking

## Virtual Networks and IP Addressing

| Term | Meaning |
|---|---|
| VNet | Private network in Azure. |
| Subnet | Smaller network inside a VNet. |
| CIDR | Notation defining an IP range, such as `10.0.0.0/16`. |
| Public IP | IP used for internet communication. |
| Private IP | IP used within private networks. |
| Address Space | IP range assigned to a VNet. |
| Subnet Mask | Defines network and host portions of an IP address. |
| Default Gateway | Routes traffic to other networks. |
| DNS | Resolves domain names to IP addresses. |
| DHCP | Automatically assigns network configuration. |
| Service Tag | Represents Azure IP ranges or services. |
| ASG | Groups VMs logically for NSG rules. |

### CIDR Values

| CIDR | Total IPv4 addresses |
|---|---:|
| /16 | 65,536 |
| /17 | 32,768 |
| /18 | 16,384 |
| /20 | 4,096 |
| /22 | 1,024 |
| /24 | 256 |
| /25 | 128 |
| /26 | 64 |
| /27 | 32 |
| /28 | 16 |

**Azure reserves 5 IPv4 addresses in every subnet.**

Formula: Total addresses = 2^(32 − prefix)

## VNet Peering

| Term | Meaning |
|---|---|
| VNet Peering | Connects two VNets privately using Microsoft's network. |
| Global Peering | Connects VNets across Azure regions. |
| Non-transitive Peering | A-B and B-C peering does not automatically connect A-C. |
| Address Overlap | VNets with overlapping address spaces cannot be peered. |
| Allow Gateway Transit | Allows a VNet to share its gateway with a peered VNet. |
| Use Remote Gateways | Allows a peered VNet to use the remote gateway. |

**Exam:** Peering requires non-overlapping address spaces.

## VPN and Connectivity

| Term | Meaning |
|---|---|
| VPN Gateway | Connects Azure networks through encrypted VPN tunnels. |
| Site-to-Site VPN | Connects an entire on-premises network to Azure. |
| Point-to-Site VPN | Connects an individual computer to Azure. |
| VNet-to-VNet VPN | Connects two Azure VNets using VPN tunnels. |
| ExpressRoute | Private connectivity from on-premises to Azure through a provider. |
| BGP | Dynamically exchanges network routes. |
| Static Routing | Routes are manually configured. |
| Azure Virtual WAN | Centralized networking for branches, VNets and remote networks. |
| Virtual Hub | Central routing point in Virtual WAN. |
| Azure Bastion | Secure RDP/SSH access without public IPs on VMs. |
| NAT Gateway | Provides predictable outbound internet connectivity for a subnet. |

**Exam shortcuts:**
- Individual computer → P2S
- Entire office → S2S
- Dedicated private connection → ExpressRoute
- Secure VM administration → Bastion
- Dynamic route exchange → BGP

## Network Security

| Term | Meaning |
|---|---|
| NSG | Filters inbound and outbound network traffic. |
| Inbound Rule | Controls traffic entering a resource or subnet. |
| Outbound Rule | Controls traffic leaving a resource or subnet. |
| NSG Priority | Lower number is evaluated first. |
| UDR | Custom route that overrides default routing. |
| Route Table | Contains routes for network traffic. |
| NVA | Network Virtual Appliance, such as a firewall VM. |
| Service Chaining | Routes traffic through an NVA. |
| Azure Firewall | Managed centralized network firewall. |
| Private Endpoint | Gives an Azure service a private IP in your VNet. |
| Private Link | Privately accesses supported services. |
| Service Endpoint | Allows subnet access to Azure services using service endpoint network identity. |

## DNS

| Term | Meaning |
|---|---|
| Azure DNS | Hosts DNS records for domains. |
| Private DNS Zone | Resolves names inside private Azure networks. |
| A Record | Maps name to IPv4. |
| AAAA Record | Maps name to IPv6. |
| CNAME | Maps one DNS name to another. |
| MX Record | Identifies mail servers. |
| TXT Record | Stores text-based DNS information. |

---

# 2. Azure Load Balancing

| Term | Meaning |
|---|---|
| Azure Load Balancer | Distributes TCP/UDP traffic at Layer 4. |
| Standard Load Balancer | Production-grade load balancer with zone-aware capabilities. |
| Frontend IP | Entry point for incoming traffic. |
| Backend Pool | Group of VMs receiving traffic. |
| Health Probe | Checks whether backend resources are healthy. |
| Load Balancing Rule | Maps frontend IP/port to backend IP/port. |
| Inbound NAT Rule | Maps a frontend port to a specific VM and backend port. |
| HA Ports | Handles all TCP/UDP ports through a load-balancing rule. |
| Floating IP | Enables Direct Server Return (DSR) in supported Azure Load Balancer configurations. |
| Application Gateway | Layer 7 HTTP/HTTPS load balancer. |
| WAF | Protects web applications against web attacks. |
| Path-Based Routing | Routes based on URL paths. |
| Host-Based Routing | Routes based on hostname. |
| Azure Front Door | Global HTTP/HTTPS delivery and routing. |
| Traffic Manager | DNS-based traffic distribution. |

## Floating IP (Direct Server Return)

**Floating IP is a setting on an Azure Load Balancer rule.**

Normally, traffic is translated so the backend VM receives traffic addressed to its own private IP.

When Floating IP is enabled:
- The backend receives traffic addressed to the frontend IP.
- The backend must be configured to handle that frontend IP appropriately.
- The destination IP is preserved for supported Direct Server Return scenarios.
- It is used in special configurations such as SQL Server Always On availability group listeners.

**Important:** Floating IP does not mean a VM automatically gets a movable public IP. It is a load-balancing rule setting.

### Load Balancer Exam Shortcuts

| Scenario | Answer |
|---|---|
| TCP/UDP traffic | Load Balancer |
| HTTP/HTTPS web traffic | Application Gateway |
| Global web delivery | Front Door |
| DNS-based global routing | Traffic Manager |
| Backend VM availability | Health Probe |
| Send traffic to a particular VM | Inbound NAT Rule |
| Preserve frontend destination IP | Floating IP / DSR |

---

# 3. Azure Virtual Machines

| Term | Meaning |
|---|---|
| Azure VM | Virtual computer running an OS in Azure. |
| VM Size | Defines CPU, RAM and capabilities. |
| VM Image | Template containing an OS and configuration. |
| OS Disk | Contains the operating system. |
| Data Disk | Additional storage for data. |
| Temporary Disk | Local temporary storage; data can be lost. |
| Availability Set | Distributes VMs across fault and update domains. |
| Availability Zone | Separate physical datacenter location within a region. |
| Fault Domain | Physical infrastructure failure boundary. |
| Update Domain | Planned maintenance boundary. |
| Proximity Placement Group | Places resources close together to reduce latency. |
| Dedicated Host | Physical server dedicated to your organization. |
| VM Scale Set | Group of VMs that can scale automatically. |
| Spot VM | Discounted unused capacity that can be evicted. |
| Custom Script Extension | Executes scripts inside a VM. |
| Run Command | Executes commands remotely on a VM. |
| Redeploy | Moves a VM to another host. |
| Deallocate | Releases VM compute allocation. |

## Availability Set Values

| Property | Value |
|---|---:|
| Maximum Fault Domains | 3 in classic exam scenarios |
| Maximum Update Domains | 20 in classic exam scenarios |

**Remember:**
- Fault Domain = Hardware failure
- Update Domain = Planned maintenance
- Maximum FD = Spread across maximum hardware failure groups
- Maximum UD = Spread across maximum maintenance groups

---

# 4. Azure App Service

| Term | Meaning |
|---|---|
| App Service | Managed platform for web apps and APIs. |
| App Service Plan | Defines compute, pricing tier and scaling. |
| Runtime Stack | Language/runtime, such as .NET, PHP or Java. |
| Deployment Slot | Separate environment for testing and staged deployment. |
| Swap | Exchanges a deployment slot with production. |
| Scale Up | Increases CPU/RAM or changes pricing tier. |
| Scale Out | Adds more instances. |
| Scale In | Removes instances. |
| Autoscale | Automatically adjusts instance count. |
| Always On | Prevents supported apps from unloading due to inactivity. |
| Custom Domain | Uses your own domain for an app. |
| Managed Certificate | Azure-provided certificate for supported configurations. |

### Scaling Terms

| Term | Meaning |
|---|---|
| Threshold | Metric value that triggers scaling. |
| Duration | Time a condition must persist. |
| Cooldown | Wait period before another scaling action. |
| Minimum | Lowest permitted instance count. |
| Maximum | Highest permitted instance count. |
| Default | Starting or fallback instance count. |

---

# 5. Azure Storage

## Storage Services

| Term | Meaning |
|---|---|
| Storage Account | Resource providing Azure Storage services. |
| Blob Storage | Stores unstructured files and objects. |
| Azure Files | Managed file shares using SMB or NFS. |
| Queue Storage | Stores messages for asynchronous processing. |
| Table Storage | NoSQL key-value storage. |
| Container | Logical grouping of blobs. |
| File Share | Shared filesystem in Azure Files. |
| SAS | Shared Access Signature; limited access to storage. |
| Storage Key | Account-level authorization key. |
| AzCopy | Command-line tool for copying storage data. |
| Storage Explorer | GUI for managing storage. |

## Storage Tiers

| Tier | Meaning |
|---|---|
| Hot | Frequently accessed data. |
| Cool | Infrequently accessed data. |
| Cold | Rarely accessed data. |
| Archive | Offline long-term blob storage. |

## Storage Redundancy

| Type | Meaning |
|---|---|
| LRS | Copies within one physical datacenter. |
| ZRS | Copies across availability zones in one region. |
| GRS | LRS in primary region + asynchronous geo-replication. |
| RA-GRS | GRS with read access to secondary region. |
| GZRS | ZRS in primary region + asynchronous geo-replication. |
| RA-GZRS | GZRS with read access to secondary region. |

**Memory trick:**
- L = Local
- Z = Zone
- G = Geo
- RA = Read Access to secondary

## Storage Protection

| Term | Meaning |
|---|---|
| Soft Delete | Recover deleted data within retention period. |
| Versioning | Keeps previous blob versions. |
| Snapshot | Point-in-time copy of a blob. |
| Immutability | Prevents modification/deletion during retention. |
| Lifecycle Management | Automatically moves or deletes data. |
| Encryption at Rest | Encrypts stored data. |
| Customer-Managed Key | Encryption key managed by customer. |

---

# 6. Azure Backup and Disaster Recovery

| Term | Meaning |
|---|---|
| Azure Backup | Protects data and workloads with recovery points. |
| Recovery Services Vault | Stores backup data and configuration for supported workloads. |
| Backup Vault | Vault used for supported newer backup scenarios. |
| Recovery Point | Saved state of data at a particular time. |
| File Recovery | Restores individual files from supported VM backups. |
| VM Restore | Restores a VM or creates a new VM from backup. |
| Instant Restore | Uses snapshots for faster recovery in supported scenarios. |
| Azure Site Recovery | Replicates workloads for disaster recovery. |
| Failover | Switches workloads to recovery location. |
| Test Failover | Tests DR without affecting normal production operation. |
| Failback | Returns workloads to original location. |
| Recovery Plan | Defines recovery steps for multiple machines. |
| RPO | Maximum acceptable data loss measured in time. |
| RTO | Maximum acceptable recovery time. |

**Exam shortcuts:**
- Individual file recovery → Azure Backup
- Regional disaster → Site Recovery
- Test DR → Test Failover
- Return to original site → Failback

---

# 7. Identity and Access Management

## Microsoft Entra ID

| Term | Meaning |
|---|---|
| Microsoft Entra ID | Cloud identity service, formerly Azure AD. |
| Tenant | Organization's identity directory. |
| User | Identity representing a person. |
| Group | Collection of users or supported identities. |
| Guest User | External identity invited into tenant. |
| Service Principal | Identity used by an application. |
| Managed Identity | Azure-managed identity for accessing services without managing credentials. |
| System-Assigned Identity | Identity lifecycle tied to one Azure resource. |
| User-Assigned Identity | Separate identity assignable to multiple resources. |
| MFA | Requires multiple verification methods. |
| Conditional Access | Access rules based on user, device, location or risk. |
| SSO | Single Sign-On across applications. |
| PIM | Privileged Identity Management. |

## Azure RBAC

| Role | Meaning |
|---|---|
| Owner | Manage resources and access permissions. |
| Contributor | Manage resources, but cannot grant Azure RBAC access. |
| Reader | View resources only. |
| User Access Administrator | Manage Azure resource access assignments. |

Other terms:

- **Scope:** Where permissions apply.
- **Role Assignment:** Connects identity, role and scope.
- **Least Privilege:** Give only required permissions.
- **Access Review:** Reviews whether access is still needed.

---

# 8. Governance and Policy

| Term | Meaning |
|---|---|
| Management Group | Organizes subscriptions hierarchically. |
| Subscription | Billing and resource management boundary. |
| Resource Group | Logical container for resources. |
| Azure Policy | Enforces or audits resource configuration. |
| Policy Definition | Rule describing allowed or required configuration. |
| Policy Assignment | Applies policy to a scope. |
| Initiative | Collection of policy definitions. |
| Append | Adds specified properties during policy evaluation. |
| Modify | Adds, updates or removes properties. |
| Deny | Blocks noncompliant requests. |
| Audit | Records noncompliance without blocking. |
| AuditIfNotExists | Audits when related required configuration is missing. |
| DeployIfNotExists | Deploys related resources if they do not exist, when configured. |
| Tag | Metadata attached to resources. |
| CanNotDelete Lock | Allows modification but prevents deletion. |
| ReadOnly Lock | Prevents modification and deletion. |
| Budget | Spending threshold that triggers alerts. |
| Advisor | Recommendations for cost, reliability, security and performance. |
| Resource Graph | Queries Azure resources across scopes. |

**Remember:** A budget alert does not automatically stop resources.

---

# 9. Azure Monitor

| Term | Meaning |
|---|---|
| Azure Monitor | Collects and analyzes monitoring data. |
| Metric | Numeric measurement over time, such as CPU percentage. |
| Log | Recorded event or diagnostic information. |
| Log Analytics Workspace | Stores and queries logs using KQL. |
| KQL | Kusto Query Language for log analysis. |
| Diagnostic Settings | Sends resource logs and metrics to destinations. |
| Activity Log | Records Azure control-plane operations. |
| Alert Rule | Triggers an alert when a condition is met. |
| Action Group | Defines email, SMS, webhook or other alert actions. |
| Metric Alert | Alert based on numeric metrics. |
| Log Alert | Alert based on query results. |
| Application Insights | Monitors application performance and failures. |
| Network Watcher | Diagnoses network connectivity. |
| Connection Troubleshoot | Tests connectivity between endpoints. |
| Service Health | Shows Azure service incidents and planned maintenance. |
| Resource Health | Shows health status of an individual resource. |

---

# 10. ARM Templates and Deployment

| Term | Meaning |
|---|---|
| ARM | Azure Resource Manager; Azure management and deployment layer. |
| ARM Template | JSON template defining Azure resources. |
| Bicep | Declarative language that compiles to ARM templates. |
| Deployment | Creates or updates resources from a template. |
| Parameter | Input supplied to a template. |
| Variable | Reusable value defined in a template. |
| Resource | Azure service or object deployed. |
| Dependency | Specifies deployment order. |
| Incremental Mode | Adds or updates resources without deleting unrelated resources. |
| Complete Mode | Historically deletes resources not in the template at deployment scope; use carefully. |
| What-if | Previews changes before deployment. |
| Template Spec | Stores reusable ARM templates as an Azure resource. |
| Azure CLI | Command-line tool for Azure management. |
| Azure PowerShell | PowerShell modules for Azure. |
| Cloud Shell | Browser-accessible shell with Azure tools. |

---

# 11. Containers and App Integration

## Containers

| Term | Meaning |
|---|---|
| Docker Image | Template used to create containers. |
| Container | Running application package with dependencies. |
| ACR | Azure Container Registry; stores container images. |
| ACI | Runs containers without managing VMs. |
| Container Apps | Managed platform for containerized applications. |
| AKS | Managed Kubernetes service. |
| Kubernetes | Orchestrates container deployment and scaling. |
| Pod | Smallest deployable Kubernetes unit. |
| Node | Machine running Kubernetes workloads. |
| Deployment | Kubernetes object managing replicated pods. |
| Ingress | Routes external HTTP/HTTPS traffic into Kubernetes. |
| Helm | Package manager for Kubernetes applications. |

## Application Integration

| Term | Meaning |
|---|---|
| Azure Functions | Serverless event-driven code execution. |
| Function App | Azure resource hosting functions. |
| Trigger | Event that starts a function. |
| Binding | Connects a function to input/output services. |
| Logic Apps | Workflow automation with connectors. |
| Event Grid | Event routing service. |
| Service Bus | Enterprise messaging with queues and topics. |
| Queue | Point-to-point message delivery. |
| Topic | Publish-subscribe messaging. |
| Event Hub | High-throughput event streaming. |
| API Management | Publishes, secures and manages APIs. |
| Key Vault | Stores secrets, keys and certificates. |
| Managed Identity | Allows Azure resources to access services without stored credentials. |

---

# 12. Azure Database Services

| Term | Meaning |
|---|---|
| Azure SQL Database | Managed relational SQL database. |
| SQL Managed Instance | Managed SQL environment with broader SQL Server compatibility. |
| SQL Server on VM | SQL Server installed on an Azure virtual machine. |
| Cosmos DB | Globally distributed NoSQL database. |
| PostgreSQL | Managed PostgreSQL database service. |
| MySQL | Managed MySQL database service. |
| Read Replica | Read-only database copy for scaling reads. |
| Geo-Replication | Replicates data to another region. |
| Redis Cache | In-memory caching service; check current Azure product availability and migration guidance. |

---

# 13. Availability and Resilience

| Term | Meaning |
|---|---|
| Region | Geographic area containing Azure datacenters. |
| Region Pair | Two Azure regions paired for certain DR considerations. |
| Availability Zone | Separate physical datacenter location in a region. |
| Availability Set | Groups VMs across fault and update domains. |
| Fault Domain | Physical infrastructure failure boundary. |
| Update Domain | Planned maintenance boundary. |
| Zone-Redundant | Resource distributed or replicated across zones. |
| SLA | Service Level Agreement defining availability commitments. |
| High Availability | Design that minimizes service downtime. |
| Disaster Recovery | Recovery from major outage or disaster. |

---

# 14. Important Exam Values

| Topic | Value / Rule |
|---|---|
| Availability Set fault domains | Classic exam maximum: 3 |
| Availability Set update domains | Classic exam maximum: 20 |
| NSG priority | Lower number evaluated first |
| Azure subnet reserved IPv4 addresses | 5 |
| VNet peering | Address spaces must not overlap |
| P2S VPN | Individual client connection |
| S2S VPN | Network-to-network connection |
| ExpressRoute | Private connectivity |
| Load Balancer | Layer 4 |
| Application Gateway | Layer 7 |
| Front Door | Global HTTP/HTTPS delivery |
| GRS | Geo-replication |
| RA-GRS | Read access to secondary |
| Policy Deny | Blocks noncompliant requests |
| Policy Audit | Records noncompliance |
| Managed Identity | Avoids managing application credentials |
| Budget | Alert, not automatic shutdown |

---

# 15. Scenario-Based Exam Shortcuts

## Networking

| Question clue | Answer |
|---|---|
| Individual laptop connecting to Azure | P2S VPN |
| Entire office connecting to Azure | S2S VPN |
| Dedicated private connectivity | ExpressRoute |
| Secure VM login without public IP | Bastion |
| TCP/UDP traffic distribution | Load Balancer |
| URL path-based routing | Application Gateway |
| Global web delivery | Front Door |
| DNS-based global routing | Traffic Manager |
| Private access to Azure service | Private Endpoint |
| Hardware failure | Fault Domain |
| Planned maintenance | Update Domain |

## Storage

| Question clue | Answer |
|---|---|
| Datacenter failure protection | ZRS |
| Regional disaster protection | GRS / GZRS |
| Read secondary region | RA-GRS / RA-GZRS |
| Recover deleted blob | Soft Delete |
| Previous blob versions | Versioning |
| Long-term offline storage | Archive |
| Automatically move data | Lifecycle Management |

## Compute

| Question clue | Answer |
|---|---|
| More CPU or RAM | Scale Up |
| More VM instances | Scale Out |
| Hardware failure protection | Fault Domains |
| Maintenance protection | Update Domains |
| Run container without managing VM | ACI |
| Automatically manage container replicas | AKS |
| Secure application access to Key Vault | Managed Identity |

## Governance

| Question clue | Answer |
|---|---|
| Block noncompliant resources | Policy Deny |
| Record noncompliance | Policy Audit |
| Prevent resource deletion | CanNotDelete Lock |
| Prevent modification and deletion | ReadOnly Lock |
| Spending threshold notifications | Budget |
| Manage resource permissions | Azure RBAC |
| Manage privileged access temporarily | PIM |

---

## Final Memory Tricks

**Networking**
- Fault = Failure
- Update = Maintenance
- P2S = Person
- S2S = Site
- Load Balancer = Layer 4
- Application Gateway = Layer 7
- Floating IP = Direct Server Return

**Storage**
- L = Local
- Z = Zone
- G = Geo
- RA = Read Access

**Compute**
- Scale Up = Bigger
- Scale Out = More
- Availability Set = Fault + Update Domains

**Governance**
- Deny = Block
- Audit = Record
- Owner = Resources + Permissions
- Contributor = Resources only
- Reader = View only

**Monitoring**
- Metric = Number
- Log = Event
- Alert = Condition
- Action Group = Notification/action

---

**Study strategy:** Understand what each service does, then identify the exact requirement in the question. AZ-104 questions often test choosing the correct service or configuration rather than memorizing definitions alone.

*Note: Azure service limits, SKUs, and feature availability can change. Verify current limits for real deployments; the values above are common AZ-104 exam revision values.*

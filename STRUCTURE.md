# 📦 Immutable Infrastructure Project - GCP

## 🎯 Executive Summary

This project demonstrates a complete implementation of **Immutable Infrastructure** on Google Cloud Platform using the tools:
- **Packer**: Custom image creation
- **Ansible**: Configuration and provisioning
- **Terraform**: Infrastructure management

## 📂 Project Structure

```
infraestrutura-imutavel-gcp/
│
├── 📄 README.md                 # Complete and detailed documentation
├── 📄 QUICKSTART.md             # Quick guide (5 minutes)
├── 📄 COMMANDS.md               # Quick command reference
├── 📄 .gitignore                # Configured gitignore file
├── 🔧 deploy.sh                 # Complete automation script
│
├── 📁 ansible/
│   └── nginx.yml                # Ansible playbook to install Nginx
│
├── 📁 packer/
│   ├── gce-nginx.pkr.hcl       # Packer template to create GCE image
│   └── variables.pkrvars.hcl.example
│
└── 📁 terraform/
    ├── main.tf                  # Main Terraform resources
    ├── variables.tf             # Variable definitions
    ├── outputs.tf               # Terraform outputs
    └── terraform.tfvars.example # Configuration example
```

## 🚀 What Does This Project Do?

### 1. **Packer + Ansible**
Creates a customized GCE image with:
- ✅ Ubuntu 22.04 LTS
- ✅ Nginx installed and configured
- ✅ Customized HTML page
- ✅ Organizational tags and labels
- ✅ Size optimizations

### 2. **Terraform**
Provisions complete infrastructure:
- ✅ GCE instance using the created image
- ✅ Public static IP
- ✅ Firewall rules (HTTP + SSH)
- ✅ Organizational tags and metadata

## 📊 Architecture Diagram

```
┌─────────────────────────────────────────────────────────┐
│  STEP 1: ANSIBLE                                         │
│  • Defines configuration (nginx.yml)                     │
│  • Installs and configures Nginx                        │
│  • Creates customized HTML page                         │
└──────────────────┬──────────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────────┐
│  STEP 2: PACKER                                          │
│  • Creates temporary VM on GCP                          │
│  • Executes Ansible playbook                            │
│  • Creates image from configured VM                     │
│  • Adds tags: environment, managed_by, etc              │
│  • Destroys temporary VM                                │
└──────────────────┬──────────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────────┐
│  STEP 3: TERRAFORM                                       │
│  • Fetches the most recent image                        │
│  • Creates static IP                                    │
│  • Configures firewall (HTTP/SSH)                       │
│  • Provisions GCE instance                              │
└─────────────────────────────────────────────────────────┘
                   │
                   ▼
        🎉 Application Running!
```

## ⚡ Quick Start

### 1. Initial Configuration (2 minutes)
```bash
# Define GCP project
export PROJECT_ID="your-gcp-project"
gcloud config set project $PROJECT_ID

# Enable APIs
gcloud services enable compute.googleapis.com

# Authenticate
gcloud auth application-default login
```

### 2. Configure Variables (1 minute)
```bash
# Packer
cp packer/variables.pkrvars.hcl.example packer/variables.pkrvars.hcl
nano packer/variables.pkrvars.hcl  # Edit project_id

# Terraform
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
nano terraform/terraform.tfvars     # Edit project_id
```

### 3. Execute Deploy (10-15 minutes)
```bash
# Option 1: Automatic (recommended)
chmod +x deploy.sh
./deploy.sh --full

# Option 2: Manual
packer build -var-file=packer/variables.pkrvars.hcl packer/gce-nginx.pkr.hcl
cd terraform && terraform init && terraform apply
```

### 4. Access Application (immediate)
```bash
# Get URL
cd terraform
terraform output nginx_url

# Test
curl $(terraform output -raw nginx_url)

# Open in browser
xdg-open $(terraform output -raw nginx_url)  # Linux
open $(terraform output -raw nginx_url)       # macOS
```

## 🎯 Immutable Infrastructure Concepts

### ✅ What It Is
- Servers are **never modified** after deployment
- Updates = create new image + replace instance
- Configuration is "baked in" to the image

### ✅ Benefits
- **Reliability**: Same image = same result
- **Fast Rollback**: Return to previous image
- **No Configuration Drift**: No manual changes
- **Testable**: Test image before deploy
- **Traceability**: Complete version history

### ❌ Anti-Patterns to Avoid
- ❌ SSH to instance to make changes
- ❌ Execute configuration scripts at startup
- ❌ Modify files manually
- ❌ Direct "hotfixes" in production

### ✅ Correct Workflow
1. Modify Ansible playbook
2. Create new image with Packer
3. Test image in staging
4. Deploy with Terraform
5. Validate
6. Destroy old instance

## 🛠️ Main Features

### Automation Script (`deploy.sh`)
```bash
./deploy.sh               # Interactive menu
./deploy.sh --full        # Complete Build + Deploy
./deploy.sh --packer      # Only create image
./deploy.sh --terraform   # Only deploy
./deploy.sh --destroy     # Destroy resources
./deploy.sh --validate    # Validate configurations
```

### Ansible (`ansible/nginx.yml`)
- Installs Nginx
- Creates customized HTML page
- Configures firewall
- Validates installation

### Packer (`packer/gce-nginx.pkr.hcl`)
- Uses Ubuntu 22.04 LTS image
- Executes Ansible provisioner
- Adds labels and tags
- Optimizes image size
- Generates JSON manifest

### Terraform (`terraform/*.tf`)
- Fetches most recent image from family
- Creates static IP
- Configures firewall (HTTP/SSH)
- Provisions e2-micro instance (free tier)
- Outputs with access information

## 📚 Documentation

- **[README.md](README.md)** - Complete documentation (12+ pages)
  - Immutable infrastructure concepts
  - Detailed architecture
  - Step-by-step instructions
  - Troubleshooting
  - Best practices
  - Next steps

- **[QUICKSTART.md](QUICKSTART.md)** - 5-minute guide
  - Essential commands
  - Minimal configuration
  - Quick deploy

- **[COMANDOS.md](COMANDOS.md)** - Quick reference
  - Packer commands
  - Terraform commands
  - Ansible commands
  - gcloud commands
  - Useful aliases
  - Debug tips

## 🎓 Use Cases

### For Demonstration
✅ Perfect for presentations about:
- Infrastructure as Code
- DevOps practices
- Cloud automation
- Immutable infrastructure
- CI/CD pipelines

### For Development
✅ Solid foundation for:
- Development environments
- Staging/QA environments
- Microservices deployment
- Auto-scaling configurations

### For Production
✅ Production-ready components:
- High availability (add load balancer)
- Auto scaling (add instance group)
- Multi-region (replicate configuration)
- CI/CD integration (GitLab/GitHub Actions)

## 🔐 Security

### Implemented
✅ Restrictive firewall rules
✅ Tags for organization
✅ Service account with minimal scopes
✅ Images with security patches

### For Production (TODO)
- [ ] Secrets management (Vault/Secret Manager)
- [ ] Network isolation (VPC/Subnets)
- [ ] SSL/TLS certificates
- [ ] Granular IAM roles
- [ ] Security scanning (Trivy/Clair)
- [ ] Audit logging

## 💰 Estimated Costs

### Development/Testing
- **e2-micro instance**: ~$7.00/month (eligible for free tier)
- **Static IP**: ~$3.00/month (if not used)
- **Images**: ~$0.05/GB/month (~0.10/month)
- **Total**: ~$10/month or FREE (with free tier)

### Production
- Depends on instance size and region
- Use GCP calculator to estimate

## 🚧 Next Steps

### Intermediate Level
1. Add Load Balancer
2. Implement Auto Scaling
3. Configure Health Checks
4. Add Cloud Monitoring

### Advanced Level
5. Multi-region deployment
6. Blue-Green deployment
7. Canary releases
8. GitOps with ArgoCD/Flux

### Production
9. Secrets management
10. Disaster recovery
11. Backup strategy
12. Compliance and audit

## 🤝 Contributing

This is an educational project. Feel free to:
- Adapt to your needs
- Add new features
- Improve documentation
- Share learnings

## 📝 License

This project is open-source and available for educational use.

## 🎉 Conclusion

You now have:
✅ Functional immutable infrastructure on GCP
✅ Complete automation scripts
✅ Comprehensive documentation
✅ Foundation for expansion

**Next step:** Run `./deploy.sh` and see the magic happen! 🚀

---

**Created with ❤️ to demonstrate modern DevOps practices**

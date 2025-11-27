# 🚀 Quick Start - 5 Minutes to Deploy

## Prerequisites
- Google Cloud SDK installed and configured
- Terraform, Packer and Ansible installed
- Active GCP project

## Quick Commands

### 1. Configure GCP Project
```bash
export PROJECT_ID="your-gcp-project"
gcloud config set project $PROJECT_ID
gcloud services enable compute.googleapis.com
gcloud auth application-default login
```

### 2. Configure Variables
```bash
# Packer
cp packer/variables.pkrvars.hcl.example packer/variables.pkrvars.hcl
nano packer/variables.pkrvars.hcl  # Add your project_id

# Terraform
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
nano terraform/terraform.tfvars  # Add your project_id
```

### 3. Execute Automated Deploy
```bash
# Option 1: Interactive script
./deploy.sh

# Option 2: Complete direct deploy
./deploy.sh --full

# Option 3: Step-by-step manual
./deploy.sh --packer    # Create image
./deploy.sh --terraform # Deploy infrastructure
```

### 4. Access Application
```bash
# Get URL
cd terraform
terraform output nginx_url

# Test
curl $(terraform output -raw nginx_url)
```

## Cleanup
```bash
./deploy.sh --destroy
```

---

**Estimated total time:** 10-15 minutes (including image build)

For complete documentation, see [README.md](README.md)

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
cp clouds/gcp/packer/variables.pkrvars.hcl.example clouds/gcp/packer/variables.pkrvars.hcl
nano clouds/gcp/packer/variables.pkrvars.hcl  # Add your project_id

# Terraform
cp clouds/gcp/terraform/terraform.tfvars.example clouds/gcp/terraform/terraform.tfvars
nano clouds/gcp/terraform/terraform.tfvars  # Add your project_id
```

### 3. Execute Automated Deploy
```bash
# Option 1: Interactive script
./bin/deploy.sh

# Option 2: Complete direct deploy
./bin/deploy.sh --full

# Option 3: Step-by-step manual
./bin/deploy.sh --packer    # Create image
./bin/deploy.sh --terraform # Deploy infrastructure
```

### 4. Access Application
```bash
# Get URL
cd clouds/gcp/terraform
terraform output nginx_url

# Test
curl $(terraform output -raw nginx_url)
```

## Cleanup
```bash
./bin/deploy.sh --destroy
```

---

**Estimated total time:** 10-15 minutes (including image build)

For complete documentation, see [README.md](../README.md)

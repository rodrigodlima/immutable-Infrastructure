# 🔧 Useful Commands - Quick Reference

## 📦 Packer

### Build and Validation
```bash
# Validate template
packer validate -var-file=packer/variables.pkrvars.hcl packer/gce-nginx.pkr.hcl

# Build image
packer build -var-file=packer/variables.pkrvars.hcl packer/gce-nginx.pkr.hcl

# Build in debug mode (keeps VM on error)
packer build -debug -var-file=packer/variables.pkrvars.hcl packer/gce-nginx.pkr.hcl

# Build with verbose output
PACKER_LOG=1 packer build -var-file=packer/variables.pkrvars.hcl packer/gce-nginx.pkr.hcl

# View generated manifest
cat packer-manifest.json | jq
```

### Manage Images
```bash
# List images from family
gcloud compute images list --filter="family:nginx-immutable-family"

# View details of latest image
gcloud compute images describe-from-family nginx-immutable-family

# View image labels
gcloud compute images describe IMAGE_NAME --format="value(labels)"

# Delete specific image
gcloud compute images delete IMAGE_NAME

# Delete all images from family
gcloud compute images list --filter="family:nginx-immutable-family" --format="value(name)" | \
  xargs -I {} gcloud compute images delete {} --quiet
```

## 🏗️ Terraform

### Initialization and Validation
```bash
cd terraform

# Initialize (first time)
terraform init

# Update providers
terraform init -upgrade

# Validate configuration
terraform validate

# Format code
terraform fmt -recursive
```

### Plan and Apply
```bash
# View execution plan
terraform plan

# Save plan to file
terraform plan -out=tfplan

# Apply changes
terraform apply

# Apply saved plan
terraform apply tfplan

# Apply without confirmation (use with caution!)
terraform apply -auto-approve

# Apply only specific resource
terraform apply -target=google_compute_instance.nginx_server
```

### Outputs and State
```bash
# View all outputs
terraform output

# View specific output (raw)
terraform output -raw nginx_url

# View current state
terraform show

# List resources in state
terraform state list

# View details of specific resource
terraform state show google_compute_instance.nginx_server

# Refresh state (sync with reality)
terraform refresh
```

### Destroy and Recreate
```bash
# Destroy everything
terraform destroy

# Destroy without confirmation
terraform destroy -auto-approve

# Destroy specific resource
terraform destroy -target=google_compute_instance.nginx_server

# Recreate resource (taint + apply)
terraform apply -replace=google_compute_instance.nginx_server

# Force recreation on next apply
terraform taint google_compute_instance.nginx_server
terraform apply
```

### Workspaces (Environments)
```bash
# List workspaces
terraform workspace list

# Create workspace
terraform workspace new staging

# Switch workspace
terraform workspace select production

# Delete workspace
terraform workspace delete staging
```

## 🎭 Ansible

### Validation and Testing
```bash
# Check playbook syntax
ansible-playbook ansible/nginx.yml --syntax-check

# Dry-run (doesn't execute, only simulates)
ansible-playbook ansible/nginx.yml --check

# List playbook tasks
ansible-playbook ansible/nginx.yml --list-tasks

# Execute only specific tasks
ansible-playbook ansible/nginx.yml --tags "install"

# Skip specific tasks
ansible-playbook ansible/nginx.yml --skip-tags "config"
```

### Local Execution (Testing)
```bash
# Execute locally
ansible-playbook ansible/nginx.yml -i localhost, --connection=local

# With sudo
ansible-playbook ansible/nginx.yml -i localhost, --connection=local --become

# Verbose mode
ansible-playbook ansible/nginx.yml -v
ansible-playbook ansible/nginx.yml -vv
ansible-playbook ansible/nginx.yml -vvv
```

## ☁️ GCP / gcloud

### Configuration
```bash
# List projects
gcloud projects list

# Set default project
gcloud config set project PROJECT_ID

# View current configuration
gcloud config list

# Authenticate
gcloud auth login
gcloud auth application-default login

# List authenticated accounts
gcloud auth list
```

### Compute Engine
```bash
# List instances
gcloud compute instances list

# View instance details
gcloud compute instances describe nginx-immutable-demo --zone=us-central1-a

# SSH into instance
gcloud compute ssh nginx-immutable-demo --zone=us-central1-a

# Start/stop instance
gcloud compute instances start nginx-immutable-demo --zone=us-central1-a
gcloud compute instances stop nginx-immutable-demo --zone=us-central1-a

# Delete instance
gcloud compute instances delete nginx-immutable-demo --zone=us-central1-a

# View instance serial logs
gcloud compute instances get-serial-port-output nginx-immutable-demo --zone=us-central1-a
```

### Firewall
```bash
# List firewall rules
gcloud compute firewall-rules list

# View rule details
gcloud compute firewall-rules describe allow-http-nginx-demo

# Create rule
gcloud compute firewall-rules create RULE_NAME \
  --allow tcp:80 \
  --source-ranges=0.0.0.0/0 \
  --target-tags=nginx-server

# Delete rule
gcloud compute firewall-rules delete RULE_NAME
```

### IPs and Networking
```bash
# List static IPs
gcloud compute addresses list

# Create static IP
gcloud compute addresses create IP_NAME --region=us-central1

# Delete static IP
gcloud compute addresses delete IP_NAME --region=us-central1

# View network information
gcloud compute networks list
gcloud compute networks describe default
```

### Quotas and Limits
```bash
# View project quotas
gcloud compute project-info describe --project=PROJECT_ID

# View quotas for specific region
gcloud compute regions describe us-central1
```

## 🔍 Debugging and Monitoring

### Instance Logs
```bash
# Via gcloud
gcloud compute instances get-serial-port-output nginx-immutable-demo --zone=us-central1-a

# Via SSH
gcloud compute ssh nginx-immutable-demo --zone=us-central1-a
sudo journalctl -u nginx -f
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log
```

### Connectivity Testing
```bash
# Get instance IP
NGINX_IP=$(cd terraform && terraform output -raw external_ip)

# Test HTTP
curl -v http://$NGINX_IP
curl -I http://$NGINX_IP

# Test port
nc -zv $NGINX_IP 80

# Test DNS
nslookup $NGINX_IP
dig $NGINX_IP
```

### Performance
```bash
# Test latency
ping $NGINX_IP

# Simple benchmark
ab -n 1000 -c 10 http://$NGINX_IP/

# Concurrent requests
siege -c 100 -t 1M http://$NGINX_IP/
```

## 🛠️ Maintenance

### Update Complete Stack
```bash
# 1. Modify Ansible playbook
nano ansible/nginx.yml

# 2. Validate changes
ansible-playbook ansible/nginx.yml --syntax-check

# 3. Create new image
packer build -var-file=packer/variables.pkrvars.hcl packer/gce-nginx.pkr.hcl

# 4. Recreate instance
cd terraform
terraform apply -replace=google_compute_instance.nginx_server
```

### Rollback
```bash
# 1. List old images
gcloud compute images list --filter="family:nginx-immutable-family"

# 2. In Terraform, modify to use specific image
# Edit main.tf to point to old image

# 3. Apply
terraform apply -replace=google_compute_instance.nginx_server
```

### Backup
```bash
# Backup Terraform state
cd terraform
cp terraform.tfstate terraform.tfstate.backup

# Create instance disk snapshot
gcloud compute disks snapshot nginx-immutable-demo \
  --zone=us-central1-a \
  --snapshot-names=nginx-backup-$(date +%Y%m%d)
```

## 📊 Cost Monitoring

```bash
# View cost estimate (requires billing configuration)
gcloud beta billing projects describe PROJECT_ID

# List resources that generate costs
gcloud compute instances list --format="table(name,zone,machineType,status)"
gcloud compute addresses list --format="table(name,region,status)"
gcloud compute images list --format="table(name,diskSizeGb)"
```

## 🔐 Security

```bash
# Check open firewall rules
gcloud compute firewall-rules list --filter="sourceRanges:0.0.0.0/0"

# Check instances without tags
gcloud compute instances list --filter="-tags:*"

# View service accounts in use
gcloud iam service-accounts list

# Audit project permissions
gcloud projects get-iam-policy PROJECT_ID
```

## 💡 Tips

### Useful Aliases
Add to your `.bashrc` or `.zshrc`:

```bash
# Terraform
alias tf='terraform'
alias tfi='terraform init'
alias tfp='terraform plan'
alias tfa='terraform apply'
alias tfd='terraform destroy'
alias tfo='terraform output'

# Packer
alias pk='packer'
alias pkv='packer validate'
alias pkb='packer build'

# GCloud
alias gci='gcloud compute instances'
alias gcil='gcloud compute instances list'
alias gcim='gcloud compute images'
alias gciml='gcloud compute images list'

# Project
alias deploy-full='./deploy.sh --full'
alias deploy-packer='./deploy.sh --packer'
alias deploy-tf='./deploy.sh --terraform'
```

### Useful Environment Variables
```bash
# Terraform
export TF_LOG=DEBUG
export TF_LOG_PATH=./terraform.log

# Packer
export PACKER_LOG=1
export PACKER_LOG_PATH=./packer.log

# GCloud
export CLOUDSDK_CORE_PROJECT=your-gcp-project
export CLOUDSDK_COMPUTE_ZONE=us-central1-a
```

---

**Tip:** Bookmark this file for quick reference!

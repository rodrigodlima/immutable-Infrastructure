# 🔗 Complete Integration: Packer + Ansible + Terraform

## 📋 Integration Overview

This guide shows how the three components work together to create immutable infrastructure.

```
ANSIBLE ──> PACKER ──> TERRAFORM
  ↓           ↓           ↓
Config    Image       Infra
```

## 🎯 Complete Integration Flow

### STEP 1: Prepare Environment (5 minutes)

```bash
# 1.1 - Configure GCP project
export PROJECT_ID="your-gcp-project"
export ZONE="us-central1-a"
export REGION="us-central1"

gcloud config set project $PROJECT_ID
gcloud config set compute/zone $ZONE
gcloud config set compute/region $REGION

# 1.2 - Enable necessary APIs
gcloud services enable compute.googleapis.com \
  cloudresourcemanager.googleapis.com \
  servicemanagement.googleapis.com \
  storage.googleapis.com

# 1.3 - Create credentials
gcloud auth application-default login

# 1.4 - Verify authentication
gcloud auth application-default print-access-token
```

### STEP 2: Configure Variables (3 minutes)

```bash
# 2.1 - Create Packer variables file
cat > packer/variables.pkrvars.hcl <<EOF
project_id   = "$PROJECT_ID"
zone         = "$ZONE"
image_name   = "nginx-immutable"
image_family = "nginx-immutable-family"
EOF

# 2.2 - Create Terraform variables file
cat > terraform/terraform.tfvars <<EOF
project_id    = "$PROJECT_ID"
region        = "$REGION"
zone          = "$ZONE"
instance_name = "nginx-immutable-demo"
machine_type  = "e2-micro"
image_family  = "nginx-immutable-family"
environment   = "demo"
EOF

# 2.3 - Verify configurations
echo "=== Packer Configuration ==="
cat packer/variables.pkrvars.hcl

echo -e "\n=== Terraform Configuration ==="
cat terraform/terraform.tfvars
```

### STEP 3: Validate Configurations (2 minutes)

```bash
# 3.1 - Validate Ansible playbook
echo "Validating Ansible..."
ansible-playbook ansible/nginx.yml --syntax-check

# 3.2 - Validate Packer template
echo "Validating Packer..."
packer validate -var-file=packer/variables.pkrvars.hcl packer/gce-nginx.pkr.hcl

# 3.3 - Validate Terraform configuration
echo "Validating Terraform..."
cd terraform
terraform init
terraform validate
cd ..

echo "✅ All validations passed!"
```

### STEP 4: Create Image with Packer (8-10 minutes)

```bash
# 4.1 - Start Packer build
echo "=== Starting image build ==="
packer build -var-file=packer/variables.pkrvars.hcl packer/gce-nginx.pkr.hcl

# Expected output:
# ==> googlecompute: Creating temporary RSA SSH key...
# ==> googlecompute: Using image: ubuntu-2204-jammy-v20240319
# ==> googlecompute: Creating instance...
# ==> googlecompute: Waiting for the instance to become running...
# ==> googlecompute: Provisioning with Ansible...
# ==> googlecompute: Deleting instance...
# ==> googlecompute: Creating image nginx-immutable-20240512123456...
# Build 'googlecompute.nginx' finished after 8 minutes 32 seconds.

# 4.2 - Verify created image
echo -e "\n=== Verifying created image ==="
gcloud compute images list --filter="family:nginx-immutable-family"

# 4.3 - View image details
IMAGE_NAME=$(gcloud compute images list \
  --filter="family:nginx-immutable-family" \
  --format="value(name)" \
  --limit=1)

echo -e "\n=== Image details: $IMAGE_NAME ==="
gcloud compute images describe $IMAGE_NAME --format=json | jq '{
  name: .name,
  family: .family,
  status: .status,
  diskSizeGb: .diskSizeGb,
  labels: .labels,
  creationTimestamp: .creationTimestamp
}'

# 4.4 - View Packer manifest
if [ -f "packer-manifest.json" ]; then
  echo -e "\n=== Packer Manifest ==="
  cat packer-manifest.json | jq
fi
```

### STEP 5: Provision Infrastructure with Terraform (5 minutes)

```bash
# 5.1 - Initialize Terraform (if not done yet)
cd terraform
terraform init

# 5.2 - View execution plan
echo "=== Execution Plan ==="
terraform plan -out=tfplan

# Expected output:
# Terraform will perform the following actions:
#   + google_compute_address.nginx_static_ip
#   + google_compute_firewall.allow_http
#   + google_compute_firewall.allow_ssh
#   + google_compute_instance.nginx_server
# Plan: 4 to add, 0 to change, 0 to destroy.

# 5.3 - Apply changes
echo -e "\n=== Applying changes ==="
terraform apply tfplan

# 5.4 - View outputs
echo -e "\n=== Infrastructure Information ==="
terraform output

# Expected output:
# external_ip = "34.xxx.xxx.xxx"
# image_family = "nginx-immutable-family"
# image_used = "nginx-immutable-20240512123456"
# instance_id = "1234567890123456789"
# instance_name = "nginx-immutable-demo"
# instance_tags = tolist(["http-server", "immutable-infrastructure", "nginx-server"])
# instance_zone = "us-central1-a"
# nginx_url = "http://34.xxx.xxx.xxx"
# ssh_command = "gcloud compute ssh nginx-immutable-demo --zone=us-central1-a"

cd ..
```

### STEP 6: Validate Deployment (2 minutes)

```bash
# 6.1 - Get information
cd terraform
NGINX_IP=$(terraform output -raw external_ip)
NGINX_URL=$(terraform output -raw nginx_url)
SSH_CMD=$(terraform output -raw ssh_command)
cd ..

# 6.2 - Test HTTP
echo "=== Testing HTTP ==="
echo "URL: $NGINX_URL"
curl -I $NGINX_IP

# 6.3 - Get HTML content
echo -e "\n=== Page Content ==="
curl $NGINX_IP

# 6.4 - Test SSH (optional)
echo -e "\n=== SSH Command ==="
echo "$SSH_CMD"

# 6.5 - Open in browser (Linux)
if command -v xdg-open &> /dev/null; then
  xdg-open $NGINX_URL
fi

# 6.6 - Open in browser (macOS)
if command -v open &> /dev/null; then
  open $NGINX_URL
fi
```

### STEP 7: Monitor Resources (optional)

```bash
# 7.1 - Instance status
gcloud compute instances describe nginx-immutable-demo \
  --zone=us-central1-a \
  --format=json | jq '{
    name: .name,
    status: .status,
    machineType: .machineType,
    networkInterfaces: .networkInterfaces[0].networkIP,
    externalIp: .networkInterfaces[0].accessConfigs[0].natIP
  }'

# 7.2 - Startup logs
gcloud compute instances get-serial-port-output \
  nginx-immutable-demo \
  --zone=us-central1-a

# 7.3 - CPU/Memory metrics
gcloud compute instances describe nginx-immutable-demo \
  --zone=us-central1-a \
  --format="table(
    status,
    cpuPlatform,
    scheduling.automaticRestart,
    scheduling.preemptible
  )"
```

## 🔄 Update Workflow

### Scenario: Update Nginx version or configuration

```bash
# 1. Modify Ansible playbook
nano ansible/nginx.yml

# 2. Validate changes
ansible-playbook ansible/nginx.yml --syntax-check

# 3. Create new image
packer build -var-file=packer/variables.pkrvars.hcl packer/gce-nginx.pkr.hcl

# 4. View available new images
gcloud compute images list --filter="family:nginx-immutable-family" \
  --format="table(name,family,creationTimestamp)"

# 5. Recreate instance with new image
cd terraform
terraform apply -replace=google_compute_instance.nginx_server

# 6. Validate new version
NGINX_IP=$(terraform output -raw external_ip)
curl $NGINX_IP
```

## 🎯 Blue-Green Deployment Workflow

```bash
# 1. Create new image (Green)
packer build -var-file=packer/variables.pkrvars.hcl packer/gce-nginx.pkr.hcl

# 2. Create new Green instance (without destroying Blue)
cd terraform
terraform apply -var="instance_name=nginx-green"

# 3. Test Green
GREEN_IP=$(terraform output -raw external_ip)
curl http://$GREEN_IP

# 4. Switch traffic (update Load Balancer or DNS)
# ... (load balancer configuration)

# 5. Monitor for some time

# 6. Destroy Blue instance
terraform destroy -target=google_compute_instance.nginx_blue
```

## 🧹 Complete Cleanup

```bash
# 1. Destroy Terraform infrastructure
cd terraform
terraform destroy -auto-approve
cd ..

# 2. Delete all images (optional)
echo "Deleting images..."
gcloud compute images list \
  --filter="family:nginx-immutable-family" \
  --format="value(name)" | \
  xargs -I {} gcloud compute images delete {} --quiet

# 3. Verify cleanup
echo -e "\n=== Verifying remaining resources ==="
gcloud compute instances list
gcloud compute images list --filter="family:nginx-immutable-family"
gcloud compute addresses list

echo "✅ Complete cleanup!"
```

## 🐛 Debug and Troubleshooting

### If Packer Fails

```bash
# 1. Run in debug mode
PACKER_LOG=1 packer build \
  -var-file=packer/variables.pkrvars.hcl \
  packer/gce-nginx.pkr.hcl

# 2. Check logs
cat packer.log

# 3. Verify SSH connectivity
gcloud compute firewall-rules list

# 4. Create temporary rule if needed
gcloud compute firewall-rules create allow-packer-ssh \
  --allow tcp:22 \
  --source-ranges=0.0.0.0/0 \
  --target-tags=packer
```

### If Terraform Fails

```bash
# 1. View detailed logs
TF_LOG=DEBUG terraform apply

# 2. Verify state
terraform show

# 3. List resources
terraform state list

# 4. Refresh state
terraform refresh

# 5. Import existing resource (if needed)
terraform import google_compute_instance.nginx_server \
  projects/$PROJECT_ID/zones/$ZONE/instances/nginx-immutable-demo
```

### If Nginx Doesn't Respond

```bash
# 1. Verify instance status
gcloud compute instances describe nginx-immutable-demo \
  --zone=us-central1-a \
  --format="value(status)"

# 2. View startup logs
gcloud compute instances get-serial-port-output \
  nginx-immutable-demo \
  --zone=us-central1-a | tail -50

# 3. SSH to instance
gcloud compute ssh nginx-immutable-demo --zone=us-central1-a

# 4. Inside instance, verify Nginx
sudo systemctl status nginx
sudo journalctl -u nginx -n 50
sudo nginx -t
curl localhost
```

## 📊 Cost Monitoring

```bash
# View cost estimate
gcloud compute instances describe nginx-immutable-demo \
  --zone=us-central1-a \
  --format="table(
    name,
    machineType,
    status,
    networkInterfaces[0].accessConfigs[0].natIP
  )"

# Calculate approximate costs
echo "Monthly estimate (e2-micro):"
echo "Instance: ~$7.00"
echo "Static IP: ~$3.00"
echo "Images: ~$0.10"
echo "Total: ~$10.10/month"
```

## 🎓 Next Integrations

### Add CI/CD

```yaml
# .gitlab-ci.yml or .github/workflows/deploy.yml
stages:
  - validate
  - build
  - deploy

validate:
  script:
    - ansible-playbook ansible/nginx.yml --syntax-check
    - packer validate packer/gce-nginx.pkr.hcl
    - terraform validate

build:
  script:
    - packer build packer/gce-nginx.pkr.hcl

deploy:
  script:
    - terraform apply -auto-approve
```

### Add Secrets Management

```bash
# Use Google Secret Manager
gcloud secrets create nginx-config --data-file=nginx.conf
gcloud secrets versions access latest --secret=nginx-config
```

### Add Monitoring

```bash
# Enable Cloud Monitoring
gcloud services enable monitoring.googleapis.com

# Create alert
gcloud alpha monitoring policies create \
  --notification-channels=$CHANNEL_ID \
  --display-name="Nginx Down" \
  --condition-display-name="Nginx HTTP Check" \
  --condition-threshold-value=1 \
  --condition-threshold-duration=60s
```

---

## ✅ Integration Checklist

- [ ] GCP environment configured
- [ ] Variables created (Packer + Terraform)
- [ ] Validations executed (Ansible + Packer + Terraform)
- [ ] Image created with Packer
- [ ] Infrastructure provisioned with Terraform
- [ ] Nginx accessible via HTTP
- [ ] Documentation read
- [ ] Update tests performed
- [ ] Cleanup process tested

**🎉 Congratulations! You have a complete functional immutable infrastructure!**

# 🚀 Immutable Infrastructure Demo - GCP

Complete demonstration of **Immutable Infrastructure** using **Packer**, **Ansible** and **Terraform** on Google Cloud Platform.

## 📋 What is Immutable Infrastructure?

Immutable infrastructure is a paradigm where servers are **never modified** after deployment. Instead of updating existing servers, you:

1. **Create a new image** with all configurations
2. **Replace the old instance** with the new one
3. **Eliminate runtime configurations**

### Benefits:
- ✅ More reliable and predictable deployments
- ✅ Instant rollback to previous versions
- ✅ Eliminates "configuration drift"
- ✅ Facilitates testing and validation
- ✅ Identical environments (dev/staging/prod)

## 🏗️ Project Architecture

```
┌─────────────────────────────────────────────────────────┐
│  1. ANSIBLE                                              │
│  - Defines configuration (installs Nginx)               │
│  - Playbook: ansible/nginx.yml                          │
└──────────────────┬──────────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────────┐
│  2. PACKER                                               │
│  - Executes Ansible playbook                            │
│  - Creates customized GCE image                         │
│  - Adds tags and labels                                 │
│  - Template: packer/gce-nginx.pkr.hcl                   │
└──────────────────┬──────────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────────┐
│  3. TERRAFORM                                            │
│  - Fetches image created by Packer                     │
│  - Provisions GCE instance                              │
│  - Configures firewall and networking                   │
│  - Code: terraform/*.tf                                 │
└─────────────────────────────────────────────────────────┘
```

## 📂 Project Structure

```
.
├── ansible/
│   └── nginx.yml                    # Ansible Playbook
├── packer/
│   ├── gce-nginx.pkr.hcl           # Packer Template
│   └── variables.pkrvars.hcl.example
└── terraform/
    ├── main.tf                      # Main resources
    ├── variables.tf                 # Variable definitions
    ├── outputs.tf                   # Outputs
    └── terraform.tfvars.example     # Variables example
```

## 🔧 Prerequisites

### Required Tools

1. **Google Cloud SDK** (gcloud CLI)
2. **Terraform** (>= 1.0)
3. **Packer** (>= 1.8)
4. **Ansible** (>= 2.9)

### Quick Install (Ubuntu/Debian)

```bash
# Google Cloud SDK
curl https://sdk.cloud.google.com | bash
exec -l $SHELL
gcloud init

# Terraform
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

# Packer
sudo apt install packer

# Ansible
sudo apt install ansible
```

## 🚀 Step by Step - Complete Deploy

### 1️⃣ Configure GCP Project

```bash
# Define GCP project
export PROJECT_ID="your-gcp-project"
gcloud config set project $PROJECT_ID

# Enable required APIs
gcloud services enable compute.googleapis.com
gcloud services enable cloudresourcemanager.googleapis.com

# Create credentials for Packer and Terraform
gcloud auth application-default login
```

### 2️⃣ Configure Variables

**For Packer:**

```bash
# Copy example file
cd packer
cp variables.pkrvars.hcl.example variables.pkrvars.hcl

# Edit file and add your project_id
nano variables.pkrvars.hcl
```

Content of `variables.pkrvars.hcl`:
```hcl
project_id   = "your-gcp-project"
zone         = "us-central1-a"
image_name   = "nginx-immutable"
image_family = "nginx-immutable-family"
```

**For Terraform:**

```bash
# Copy example file
cd ../terraform
cp terraform.tfvars.example terraform.tfvars

# Edit file
nano terraform.tfvars
```

Content of `terraform.tfvars`:
```hcl
project_id    = "your-gcp-project"
region        = "us-central1"
zone          = "us-central1-a"
instance_name = "nginx-immutable-demo"
machine_type  = "e2-micro"
image_family  = "nginx-immutable-family"
environment   = "demo"
```

### 3️⃣ Create Image with Packer

```bash
# Return to project root directory
cd ..

# Validate Packer template
packer validate -var-file=packer/variables.pkrvars.hcl packer/gce-nginx.pkr.hcl

# Build image (takes ~5-10 minutes)
packer build -var-file=packer/variables.pkrvars.hcl packer/gce-nginx.pkr.hcl
```

**What happens:**
1. Packer creates a temporary VM on GCP
2. Executes Ansible playbook to install Nginx
3. Creates an image from configured VM
4. Adds tags and labels to image
5. Destroys temporary VM

**Verify created image:**
```bash
# List images in family
gcloud compute images list --filter="family:nginx-immutable-family"

# View details of most recent image
gcloud compute images describe-from-family nginx-immutable-family
```

### 4️⃣ Provision Infrastructure with Terraform

```bash
cd terraform

# Initialize Terraform (download providers)
terraform init

# Validate configuration
terraform validate

# View execution plan
terraform plan

# Apply changes (create resources)
terraform apply
```

Type `yes` when prompted.

**What happens:**
1. Terraform fetches the most recent image from family
2. Creates a static IP for instance
3. Configures firewall rules (HTTP and SSH)
4. Creates GCE instance using Packer image

### 5️⃣ Access Application

After `terraform apply`, you'll see the outputs:

```bash
# Nginx URL
nginx_url = "http://34.xxx.xxx.xxx"

# SSH command
ssh_command = "gcloud compute ssh nginx-immutable-demo --zone=us-central1-a"
```

**Test Nginx:**

```bash
# Get instance IP
NGINX_IP=$(terraform output -raw external_ip)

# Test via curl
curl http://$NGINX_IP

# Open in browser
xdg-open http://$NGINX_IP  # Linux
open http://$NGINX_IP       # macOS
```

You'll see the customized HTML page showing the immutable infrastructure stack!

### 6️⃣ Access Instance via SSH

```bash
# Via gcloud
gcloud compute ssh nginx-immutable-demo --zone=us-central1-a

# Check Nginx status
sudo systemctl status nginx

# View logs
sudo journalctl -u nginx -f
```

## 🔄 Update Workflow (Immutability in Practice)

When you need to make a change (e.g., update Nginx or add a package):

```bash
# 1. Modify Ansible playbook
nano ansible/nginx.yml

# 2. Create new image with Packer
packer build -var-file=packer/variables.pkrvars.hcl packer/gce-nginx.pkr.hcl

# 3. Recreate instance with Terraform
cd terraform
terraform apply -replace=google_compute_instance.nginx_server

# Or destroy and recreate
terraform destroy -target=google_compute_instance.nginx_server
terraform apply
```

**Important:** Never SSH to the instance to make manual changes! This breaks the immutability principle.

## 🧹 Resource Cleanup

```bash
# Destroy instance and Terraform resources
cd terraform
terraform destroy

# Delete images created by Packer (optional)
gcloud compute images list --filter="family:nginx-immutable-family" --format="value(name)" | \
  xargs -I {} gcloud compute images delete {} --quiet
```

## 📊 Useful Commands

### Check Created Images

```bash
# List all images in family
gcloud compute images list --filter="family:nginx-immutable-family"

# View labels of a specific image
gcloud compute images describe IMAGE_NAME --format="value(labels)"
```

### Monitor Resources on GCP

```bash
# List instances
gcloud compute instances list

# View instance details
gcloud compute instances describe nginx-immutable-demo --zone=us-central1-a

# View instance logs
gcloud compute instances get-serial-port-output nginx-immutable-demo --zone=us-central1-a
```

### Debug Packer

```bash
# Debug mode (keeps temporary VM in case of error)
packer build -debug -var-file=packer/variables.pkrvars.hcl packer/gce-nginx.pkr.hcl

# View generated manifest
cat packer-manifest.json | jq
```

### Terraform State Management

```bash
cd terraform

# View current state
terraform show

# List managed resources
terraform state list

# View specific output
terraform output nginx_url
```

## 🎯 Use Cases

### Create Multiple Instances

To create multiple instances from the same image:

```bash
cd terraform

# Modify main.tf to add count or for_each
# Or use Terraform modules

terraform apply
```

### Blue-Green Deployment

```bash
# 1. Create new image (green)
packer build -var-file=packer/variables.pkrvars.hcl packer/gce-nginx.pkr.hcl

# 2. Create new instance (green)
terraform apply -var="instance_name=nginx-green"

# 3. Test new instance
curl http://NEW_IP

# 4. Switch traffic (load balancer)
# 5. Destroy old instance (blue)
terraform destroy -target=google_compute_instance.nginx_server
```

## 🔐 Best Practices

1. **Never make manual changes to instances** - always recreate via Packer + Terraform
2. **Use image versioning** - Packer automatically adds timestamp
3. **Keep old images** - facilitates rollback
4. **Test images before deploy** - use staging environments
5. **Use Terraform workspaces** - to manage multiple environments
6. **Document changes** - maintain a CHANGELOG for images

## 🐛 Troubleshooting

### Error: "Image not found"

```bash
# Verify image exists
gcloud compute images list --filter="family:nginx-immutable-family"

# Verify image_family is correct in both files
grep image_family packer/variables.pkrvars.hcl
grep image_family terraform/terraform.tfvars
```

### Error: Packer timeout or SSH

```bash
# Check firewall rules
gcloud compute firewall-rules list

# Create temporary rule for Packer
gcloud compute firewall-rules create allow-packer-ssh \
  --allow tcp:22 \
  --source-ranges=0.0.0.0/0 \
  --target-tags=packer
```

### Error: Insufficient permissions

```bash
# Check active account
gcloud auth list

# Re-authenticate
gcloud auth application-default login

# Check project permissions
gcloud projects get-iam-policy $PROJECT_ID
```

## 📚 Important Concepts

### Packer
- **Builder**: Creates VMs on different clouds (GCP, AWS, Azure)
- **Provisioner**: Executes scripts/tools to configure VM (Ansible, Shell)
- **Post-processor**: Executes actions after creation (export, manifest, tags)

### Ansible
- **Playbook**: YAML file that defines what to install/configure
- **Idempotency**: Running multiple times produces same result
- **Tasks**: Minimum unit of work (install package, copy file)

### Terraform
- **Provider**: Plugin to interact with cloud (google, aws, azure)
- **Resource**: Infrastructure component (instance, network, disk)
- **Data Source**: Fetches existing information (images, VPCs)
- **State**: File that tracks managed resources

## 🎓 Next Steps

1. **Add Load Balancer**: Distribute traffic among multiple instances
2. **Implement Auto Scaling**: Scale based on metrics
3. **Add Monitoring**: Integrate with Cloud Monitoring
4. **CI/CD Pipeline**: Automate image build and deploy
5. **Vault Integration**: Manage secrets securely
6. **Multi-region**: Deploy in multiple regions

## 🤝 Contributing

Feel free to adapt this project to your needs!

## 📄 License

This project is open-source and available for educational use.

---

**Developed to demonstrate Immutable Infrastructure** 🚀

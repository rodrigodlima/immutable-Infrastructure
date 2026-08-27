# 📝 CHEAT SHEET - Quick Demo

## ⚡ Essential Commands for Demo

### 🚀 Initial Setup (Run ONCE)

```bash
# Configure project
export PROJECT_ID="your-gcp-project"
gcloud config set project $PROJECT_ID
gcloud services enable compute.googleapis.com
gcloud auth application-default login

# Configure variables
cp clouds/gcp/packer/variables.pkrvars.hcl.example clouds/gcp/packer/variables.pkrvars.hcl
cp clouds/gcp/terraform/terraform.tfvars.example clouds/gcp/terraform/terraform.tfvars

# Edit with your project_id (Linux/Mac)
sed -i "s/your-gcp-project/$PROJECT_ID/g" clouds/gcp/packer/variables.pkrvars.hcl
sed -i "s/your-gcp-project/$PROJECT_ID/g" clouds/gcp/terraform/terraform.tfvars
```

---

## 📦 PART 1: Deploy V1

```bash
# Create V1 image
packer build -var-file=clouds/gcp/packer/variables.pkrvars.hcl clouds/gcp/packer/gce-nginx.pkr.hcl

# Note V1 image name
export IMAGE_V1=$(gcloud compute images list --filter="family:nginx-immutable-family" --format="value(name)" --sort-by=creationTimestamp --limit=1)
echo "V1: $IMAGE_V1"

# Deploy infrastructure
cd clouds/gcp/terraform
terraform init
terraform apply -auto-approve

# Get URL
export NGINX_URL=$(terraform output -raw nginx_url)
export NGINX_IP=$(terraform output -raw external_ip)
echo "URL: $NGINX_URL"
cd ..

# Test V1
curl $NGINX_IP
xdg-open $NGINX_URL  # or 'open' on macOS
```

---

## 🆕 PART 2: Create and Deploy V2

```bash
# Backup V1
cp shared/ansible/nginx.yml shared/ansible/nginx.yml.v1

# Create V2 content (copy entire block below)
cat > shared/ansible/nginx.yml << 'EOF'
---
- name: Install and Configure Nginx - VERSION 2
  hosts: all
  become: yes
  tasks:
    - name: Update apt cache
      apt:
        update_cache: yes
        cache_valid_time: 3600

    - name: Install Nginx
      apt:
        name: nginx
        state: present

    - name: Create HTML page - VERSION 2
      copy:
        content: |
          <!DOCTYPE html>
          <html>
          <head>
              <title>V2 - Atualizada!</title>
              <style>
                  body { 
                      font-family: Arial; 
                      max-width: 800px; 
                      margin: 50px auto; 
                      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                  }
                  .container { 
                      background: white; 
                      padding: 30px; 
                      border-radius: 15px;
                      box-shadow: 0 10px 30px rgba(0,0,0,0.3);
                  }
                  h1 { color: #667eea; font-size: 2.5em; }
                  .version-badge {
                      padding: 10px 20px;
                      background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
                      color: white;
                      border-radius: 25px;
                      font-size: 1.5em;
                      font-weight: bold;
                      display: inline-block;
                      animation: pulse 2s infinite;
                  }
                  @keyframes pulse {
                      0%, 100% { transform: scale(1); }
                      50% { transform: scale(1.05); }
                  }
                  .new { background: #fff3cd; border-left: 4px solid #ffc107; padding: 15px; margin: 20px 0; }
              </style>
          </head>
          <body>
              <div class="container">
                  <h1>🚀 Infraestrutura Imutável</h1>
                  <div class="version-badge">✨ VERSÃO 2.0 ✨</div>
                  <div class="new">
                      <h3>🎉 What's New in V2:</h3>
                      <ul>
                          <li>✅ New design with purple gradient</li>
                          <li>✅ Animated version badge</li>
                          <li>✅ Completely new layout</li>
                          <li>✅ Demonstration of immutable update</li>
                      </ul>
                  </div>
                  <hr>
                  <p>✅ Created with Packer + Ansible + Terraform</p>
                  <p>🔄 Rollback available to V1!</p>
                  <p><strong style="color: #f5576c;">⚡ IMAGE: 2.0 ⚡</strong></p>
              </div>
          </body>
          </html>
        dest: /var/www/html/index.html
        mode: '0644'

    - name: Ensure Nginx is running
      systemd:
        name: nginx
        state: started
        enabled: yes
EOF

# Create V2 image
packer build -var-file=clouds/gcp/packer/variables.pkrvars.hcl clouds/gcp/packer/gce-nginx.pkr.hcl

# Note V2 image name
export IMAGE_V2=$(gcloud compute images list --filter="family:nginx-immutable-family" --format="value(name)" --sort-by=~creationTimestamp --limit=1)
echo "V2: $IMAGE_V2"

# List both images
gcloud compute images list --filter="family:nginx-immutable-family" --format="table(name,creationTimestamp)"

# Deploy V2
cd clouds/gcp/terraform
terraform apply -replace=google_compute_instance.nginx_server -auto-approve
cd ..

# Test V2
sleep 10
curl $NGINX_IP | grep -i "version"
xdg-open $NGINX_URL
```

---

## 🔄 PART 3: Rollback to V1

```bash
# Check available images
echo "V1 Image: $IMAGE_V1"
echo "V2 Image: $IMAGE_V2"

# Rollback via Terraform
cd clouds/gcp/terraform

# Backup main.tf
cp main.tf main.tf.backup

# Force use of V1 (change 'family' to 'name')
sed "s|family  = var.image_family|name    = \"$IMAGE_V1\"|" main.tf.backup > main.tf

# Apply rollback
terraform apply -replace=google_compute_instance.nginx_server -auto-approve

# Restore main.tf
mv main.tf.backup main.tf

cd ..

# Test rollback
sleep 10
curl $NGINX_IP
xdg-open $NGINX_URL

# Restore ansible to V1
mv shared/ansible/nginx.yml.v1 shared/ansible/nginx.yml
```

---

## 🧹 Cleanup

```bash
# Destroy infrastructure
cd clouds/gcp/terraform
terraform destroy -auto-approve
cd ..

# List images
gcloud compute images list --filter="family:nginx-immutable-family"

# Delete ALL images (optional)
gcloud compute images list --filter="family:nginx-immutable-family" --format="value(name)" | xargs -I {} gcloud compute images delete {} --quiet
```

---

## 🎯 Verification Commands

```bash
# View instance status
gcloud compute instances describe nginx-immutable-demo --zone=us-central1-a --format="value(status)"

# View instance IP
cd clouds/gcp/terraform && terraform output external_ip && cd ..

# Test HTTP
curl -I $NGINX_IP

# View HTML content
curl $NGINX_IP

# View available images
gcloud compute images list --filter="family:nginx-immutable-family" --format="table(name,family,creationTimestamp,diskSizeGb)"

# View which image is in use
cd clouds/gcp/terraform && terraform show | grep "image.*nginx" && cd ..
```

---

## 💡 Quick Tips

### Prepare Demo Before Presentation

```bash
# Run V1 before presentation (saves 10 min)
export PROJECT_ID="your-gcp-project"
# ... configure variables ...
packer build -var-file=clouds/gcp/packer/variables.pkrvars.hcl clouds/gcp/packer/gce-nginx.pkr.hcl
cd clouds/gcp/terraform && terraform init && terraform apply -auto-approve && cd ..

# Note variable names
export IMAGE_V1=$(gcloud compute images list --filter="family:nginx-immutable-family" --format="value(name)" --limit=1)
export NGINX_URL=$(cd clouds/gcp/terraform && terraform output -raw nginx_url && cd ..)
```

### During the Demo

```bash
# Prepare side-by-side windows:
# 1. Terminal with commands
# 2. Browser with $NGINX_URL
# 3. Slides (optional)

# Have aliases ready:
alias v1-to-v2="packer build -var-file=clouds/gcp/packer/variables.pkrvars.hcl clouds/gcp/packer/gce-nginx.pkr.hcl && cd clouds/gcp/terraform && terraform apply -replace=google_compute_instance.nginx_server -auto-approve && cd .."
alias rollback="cd clouds/gcp/terraform && terraform apply -replace=google_compute_instance.nginx_server && cd .."
```

### Quick Troubleshooting

```bash
# If Packer fails
PACKER_LOG=1 packer build -var-file=clouds/gcp/packer/variables.pkrvars.hcl clouds/gcp/packer/gce-nginx.pkr.hcl

# If Terraform fails
cd clouds/gcp/terraform && terraform show && terraform refresh

# If Nginx doesn't respond
gcloud compute ssh nginx-immutable-demo --zone=us-central1-a -- sudo systemctl status nginx
```

---

## ⏱️ Demo Timing

- **Initial setup:** 2 min (or pre-done)
- **V1 build + deploy:** 10 min (or pre-done)
- **Show V1:** 2 min
- **Create V2:** 2 min (just modify file)
- **V2 build:** 8 min (time to explain concepts!)
- **Deploy V2:** 3 min
- **Show V2:** 2 min
- **Rollback:** 5 min
- **Conclusion:** 1 min

**Total:** ~35 min (or 15 min if V1 is pre-deployed)

---

## 🎤 Talking Points

While waiting for Packer builds (8 min):

- "Immutable infrastructure = DVD, not cassette tape"
- "Never modify servers, always create new ones"
- "Same image = same result, always"
- "Rollback in minutes, not hours"
- "Zero configuration drift"
- "Ideal for microservices and containers"
- "Foundation for modern CI/CD"

---

## 📱 One-Liners to Copy/Paste

```bash
# Complete V1 deploy
packer build -var-file=clouds/gcp/packer/variables.pkrvars.hcl clouds/gcp/packer/gce-nginx.pkr.hcl && cd clouds/gcp/terraform && terraform init && terraform apply -auto-approve && cd ..

# View and open V1
export NGINX_URL=$(cd clouds/gcp/terraform && terraform output -raw nginx_url && cd ..) && echo $NGINX_URL && xdg-open $NGINX_URL

# Build and deploy V2 (after modifying shared/ansible/nginx.yml)
packer build -var-file=clouds/gcp/packer/variables.pkrvars.hcl clouds/gcp/packer/gce-nginx.pkr.hcl && cd clouds/gcp/terraform && terraform apply -replace=google_compute_instance.nginx_server -auto-approve && cd ..

# Complete cleanup
cd clouds/gcp/terraform && terraform destroy -auto-approve && cd .. && gcloud compute images list --filter="family:nginx-immutable-family" --format="value(name)" | xargs -I {} gcloud compute images delete {} --quiet
```

---

**🎉 Success with your demo!**

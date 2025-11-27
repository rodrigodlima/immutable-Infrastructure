# Demonstration Guide - Immutable Infrastructure

This guide explains how to demonstrate the concept of immutable infrastructure by changing the application version between deploys.

## How It Works

The Nginx page displays a visual **version banner** that you can easily change between deploys to demonstrate that a new image has been created.

## Step-by-Step Demonstration

### 1. Initial Deploy (Version 1.0)

The initial version is already configured in the `ansible/nginx.yml` file:

```yaml
deployment_version: "v1.0"
deployment_message: "Initial deploy - First version of the application"
deployment_color: "#4285f4"  # Blue
```

Run the complete deploy:

```bash
./deploy.sh --full
```

Access the page and show:
- Blue banner with "v1.0"
- Message: "Initial deploy - First version of the application"

### 2. Simulating an Update (Version 2.0)

Edit the `ansible/nginx.yml` file (lines 7-9) and change to:

```yaml
deployment_version: "v2.0"
deployment_message: "New feature - Monitoring system added"
deployment_color: "#34a853"  # Green
```

Recreate the image and redeploy:

```bash
./deploy.sh --packer    # Creates new image with v2.0
./deploy.sh --update    # Updates the instance (replaces with new one)
```

Or use the direct Terraform command:
```bash
./deploy.sh --packer
cd terraform
terraform apply -replace=google_compute_instance.nginx_server -auto-approve
```

**What happens:**
- Terraform detects that the image has changed
- Creates a new instance with a unique name (based on the image timestamp)
- The old instance remains until the new one is ready (create_before_destroy)
- The static IP is automatically migrated to the new instance
- The old instance is destroyed

Access the page again and show:
- Green banner with "v2.0"
- New version message
- **Different Build Time** (proof that it's a new image)
- **Different instance name** (demonstrates that it's a new VM)

### 3. Simulating a Hotfix (Version 2.1)

To demonstrate a quick hotfix:

```yaml
deployment_version: "v2.1"
deployment_message: "🔥 Hotfix - Critical security fix"
deployment_color: "#ea4335"  # Red
```

Run again:

```bash
./deploy.sh --packer
./deploy.sh --terraform
```

## Version Suggestions for Demonstration

### Version 1.0 - Initial Deploy
```yaml
deployment_version: "v1.0"
deployment_message: "Initial deploy - First version of the application"
deployment_color: "#4285f4"  # Blue
```

### Version 2.0 - New Feature
```yaml
deployment_version: "v2.0"
deployment_message: "✨ New feature - Monitoring system"
deployment_color: "#34a853"  # Green
```

### Version 2.1 - Hotfix
```yaml
deployment_version: "v2.1"
deployment_message: "🔥 Hotfix - Critical fix applied"
deployment_color: "#ea4335"  # Red
```

### Version 3.0 - Major Release
```yaml
deployment_version: "v3.0"
deployment_message: "🚀 Major Release - Performance improved by 50%"
deployment_color: "#fbbc04"  # Yellow
```

## Key Points to Highlight in the Demo

1. **Immutability**: Each change requires a new image (we don't make in-place changes)
2. **Zero Downtime**: The static IP is maintained during instance swap
3. **Create Before Destroy**: New instance is created before destroying the old one
4. **Build Time**: Always different for each version (shows it's a new image)
5. **Unique Name**: Each instance has a name based on the image timestamp
6. **Visual Versioning**: Colored banner makes it easy to identify which version is running
7. **Automated Process**: The entire process is automated via Packer + Terraform

## Resolving Deploy Conflicts

### Problem: IP is already in use

If you receive the error `Error 400: External IP address is already in-use`, use one of these options:

### Option 1: Use the replace command (Recommended - Zero Downtime)
```bash
cd terraform
terraform apply -replace=google_compute_instance.nginx_server
cd ..
```

This command:
- Destroys the old instance first
- Releases the IP
- Creates the new instance
- Reassigns the IP

### Option 2: Use the Blue-Green script (Automatic)
```bash
./scripts/update-instance.sh
```

### Option 3: Destroy and recreate manually
```bash
./deploy.sh --destroy  # Remove everything
./deploy.sh --terraform # Create again
```

### Option 4: Remove only the instance via gcloud
```bash
gcloud compute instances delete nginx-immutable-demo-TIMESTAMP --zone=us-central1-a
./deploy.sh --terraform
```

## Deploy Strategies

### For Demonstration (Acceptable to have downtime)
Use **Option 1** or **Option 3** - simpler and more direct

### For Production (Zero Downtime)
Ideally, use:
- Load Balancer with multiple instances
- Rolling updates
- Blue-Green deployment with DNS switching

### Current Configuration
- Dynamic name based on image: `nginx-immutable-demo-TIMESTAMP`
- Reusable static IP
- `replace_triggered_by` to force recreation when image changes

## Demonstrating Rollback

To demonstrate a rollback to a previous version:

1. List available images:
```bash
./deploy.sh --list
```

2. Edit `terraform/main.tf` and change `image_family` to use a specific image:
```hcl
boot_disk {
  initialize_params {
    image = "projects/YOUR_PROJECT/global/images/nginx-immutable-TIMESTAMP"
  }
}
```

3. Apply:
```bash
./deploy.sh --terraform
```

## Presentation Tips

- Keep two terminal windows open (side by side)
- Have the browser open on a separate screen
- Use F5 to refresh the page after each deploy
- Highlight the image creation time (5-10 minutes)
- Show Packer/Terraform logs during the process
- Compare Build Time between versions

## Available Colors

- **Blue**: `#4285f4` (Google Blue - default)
- **Green**: `#34a853` (success/new feature)
- **Red**: `#ea4335` (urgent/hotfix)
- **Yellow**: `#fbbc04` (attention/major release)
- **Purple**: `#8e44ad` (special)
- **Orange**: `#ff6b35` (beta/experimental)

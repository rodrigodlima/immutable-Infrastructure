#!/bin/bash

# Automated Deploy Script - Immutable Infrastructure (multi-cloud)
# Automates the image build with Packer and the deploy with Terraform
#
# Usage: ./bin/deploy.sh [--cloud gcp|aws|azure] [option]

set -e

# Repository root (the script can be called from any directory)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Target cloud (default: gcp). Can come from --cloud or from the CLOUD variable.
CLOUD="${CLOUD:-gcp}"

# Output colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Resolve the paths and the specifics of the selected cloud
setup_cloud() {
    CLOUD_DIR="$ROOT_DIR/clouds/$CLOUD"

    if [ ! -d "$CLOUD_DIR" ]; then
        print_error "Cloud '$CLOUD' not found under clouds/"
        print_info "Available clouds: $(ls "$ROOT_DIR/clouds" | tr '\n' ' ')"
        exit 1
    fi

    PACKER_DIR="$CLOUD_DIR/packer"
    TERRAFORM_DIR="$CLOUD_DIR/terraform"
    ANSIBLE_PLAYBOOK="$ROOT_DIR/shared/ansible/nginx.yml"

    # Packer template: the first .pkr.hcl found in the cloud directory
    PACKER_TEMPLATE="$(find "$PACKER_DIR" -maxdepth 1 -name '*.pkr.hcl' | head -n 1)"
    PACKER_VARS="$PACKER_DIR/variables.pkrvars.hcl"
    TFVARS="$TERRAFORM_DIR/terraform.tfvars"

    if [ -z "$PACKER_TEMPLATE" ]; then
        print_error "No Packer template (*.pkr.hcl) found in $PACKER_DIR"
        print_warning "The '$CLOUD' implementation does not exist yet. See clouds/$CLOUD/README.md"
        exit 1
    fi

    # Per-cloud specifics
    case "$CLOUD" in
        gcp)
            CLOUD_CLI="gcloud"
            CLOUD_LABEL="GCP"
            TF_INSTANCE_RESOURCE="google_compute_instance.nginx_server"
            ;;
        aws)
            CLOUD_CLI="aws"
            CLOUD_LABEL="AWS"
            TF_INSTANCE_RESOURCE="aws_instance.nginx_server"
            ;;
        azure)
            CLOUD_CLI="az"
            CLOUD_LABEL="Azure"
            TF_INSTANCE_RESOURCE="azurerm_linux_virtual_machine.nginx_server"
            ;;
        *)
            print_error "Cloud '$CLOUD' is not supported by this script"
            exit 1
            ;;
    esac
}

# Check dependencies
check_dependencies() {
    print_header "Checking Dependencies ($CLOUD_LABEL)"

    local missing_deps=0

    if ! command -v "$CLOUD_CLI" &> /dev/null; then
        print_error "$CLOUD_CLI CLI not found"
        missing_deps=1
    else
        print_success "$CLOUD_CLI CLI installed"
    fi

    if ! command -v packer &> /dev/null; then
        print_error "Packer not found"
        missing_deps=1
    else
        print_success "Packer installed ($(packer version))"
    fi

    if ! command -v terraform &> /dev/null; then
        print_error "Terraform not found"
        missing_deps=1
    else
        print_success "Terraform installed ($(terraform version | head -n 1))"
    fi

    if ! command -v ansible &> /dev/null; then
        print_error "Ansible not found"
        missing_deps=1
    else
        print_success "Ansible installed ($(ansible --version | head -n 1))"
    fi

    if [ $missing_deps -eq 1 ]; then
        print_error "Missing dependencies. Please install the required tools."
        exit 1
    fi
}

# Check configuration
check_config() {
    print_header "Checking Configuration ($CLOUD_LABEL)"

    # Check the Packer variables file
    if [ ! -f "$PACKER_VARS" ]; then
        print_error "File clouds/$CLOUD/packer/variables.pkrvars.hcl not found"
        print_info "Copy the example file: cp clouds/$CLOUD/packer/variables.pkrvars.hcl.example clouds/$CLOUD/packer/variables.pkrvars.hcl"
        exit 1
    fi
    print_success "Packer variables configured"

    # Check the Terraform variables file
    if [ ! -f "$TFVARS" ]; then
        print_error "File clouds/$CLOUD/terraform/terraform.tfvars not found"
        print_info "Copy the example file: cp clouds/$CLOUD/terraform/terraform.tfvars.example clouds/$CLOUD/terraform/terraform.tfvars"
        exit 1
    fi
    print_success "Terraform variables configured"

    check_credentials
}

# Check cloud authentication
check_credentials() {
    case "$CLOUD" in
        gcp)
            if ! gcloud auth application-default print-access-token &> /dev/null; then
                print_warning "GCP credentials not configured"
                print_info "Run: gcloud auth application-default login"
                read -p "Run it now? (y/n) " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    gcloud auth application-default login
                else
                    exit 1
                fi
            fi
            ;;
        aws)
            if ! aws sts get-caller-identity &> /dev/null; then
                print_error "AWS credentials not configured"
                print_info "Run: aws configure (or aws sso login)"
                exit 1
            fi
            ;;
        azure)
            if ! az account show &> /dev/null; then
                print_error "Azure credentials not configured"
                print_info "Run: az login"
                exit 1
            fi
            ;;
    esac
    print_success "$CLOUD_LABEL credentials configured"
}

# Validate configurations
validate_configs() {
    print_header "Validating Configurations"

    # Initialize Packer (download plugins)
    print_info "Initializing Packer and installing plugins..."
    if packer init "$PACKER_TEMPLATE"; then
        print_success "Packer plugins installed"
    else
        print_error "Failed to install Packer plugins"
        exit 1
    fi

    # Validate Packer
    print_info "Validating Packer template..."
    if packer validate -var-file="$PACKER_VARS" "$PACKER_TEMPLATE"; then
        print_success "Packer template is valid"
    else
        print_error "Packer template is invalid"
        exit 1
    fi

    # Validate Ansible
    print_info "Validating Ansible playbook..."
    if ansible-playbook "$ANSIBLE_PLAYBOOK" --syntax-check; then
        print_success "Ansible playbook is valid"
    else
        print_error "Ansible playbook is invalid"
        exit 1
    fi
}

# Build image with Packer
build_image() {
    print_header "Building Image with Packer ($CLOUD_LABEL)"

    print_info "Starting image build... (this may take 5-10 minutes)"

    if packer build -var-file="$PACKER_VARS" "$PACKER_TEMPLATE"; then
        print_success "Image created successfully"

        # Extract the image name from the manifest
        local manifest="$CLOUD_DIR/packer-manifest.json"
        if [ -f "$manifest" ]; then
            IMAGE_NAME=$(jq -r '.builds[-1].artifact_id' "$manifest" | cut -d: -f2)
            print_info "Image created: $IMAGE_NAME"
        fi
    else
        print_error "Failed to create image"
        exit 1
    fi
}

# List created images
list_images() {
    print_header "Available Images ($CLOUD_LABEL)"

    case "$CLOUD" in
        gcp)
            print_info "Looking up images in family nginx-immutable-family..."
            gcloud compute images list --filter="family:nginx-immutable-family" --format="table(name,family,creationTimestamp,status)"
            ;;
        aws)
            print_info "Looking up AMIs tagged Project=nginx-immutable..."
            aws ec2 describe-images --owners self \
                --filters "Name=tag:Project,Values=nginx-immutable" \
                --query 'sort_by(Images,&CreationDate)[].[Name,ImageId,CreationDate,State]' \
                --output table
            ;;
        azure)
            print_info "Looking up Shared Image Gallery versions..."
            az sig image-version list \
                --resource-group "${AZURE_RESOURCE_GROUP:-nginx-immutable-rg}" \
                --gallery-name "${AZURE_GALLERY:-nginx_immutable_gallery}" \
                --gallery-image-definition "${AZURE_IMAGE_DEF:-nginx-immutable}" \
                --output table
            ;;
    esac
}

# Deploy with Terraform
deploy_infrastructure() {
    print_header "Infrastructure Deploy with Terraform ($CLOUD_LABEL)"

    cd "$TERRAFORM_DIR"

    # Initialize Terraform if needed
    if [ ! -d ".terraform" ]; then
        print_info "Initializing Terraform..."
        terraform init
    fi

    # Validate configuration
    print_info "Validating Terraform configuration..."
    if terraform validate; then
        print_success "Terraform configuration is valid"
    else
        print_error "Terraform configuration is invalid"
        exit 1
    fi

    # Show the plan
    print_info "Generating execution plan..."
    terraform plan -out=tfplan

    # Confirm the deploy
    echo
    read -p "Apply the changes? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "Applying changes..."
        if terraform apply tfplan; then
            print_success "Infrastructure created successfully"

            # Show outputs
            print_header "Access Information"
            terraform output

            echo
            print_success "Deploy complete"
            print_info "Access Nginx at: $(terraform output -raw nginx_url)"
            print_info "SSH: $(terraform output -raw ssh_command)"
        else
            print_error "Failed to apply changes"
            exit 1
        fi
    else
        print_warning "Deploy cancelled by the user"
    fi

    cd "$ROOT_DIR"
}

# Update the instance (replace it with the newest image)
update_instance() {
    print_header "Updating Instance with the Newest Image ($CLOUD_LABEL)"

    cd "$TERRAFORM_DIR"

    print_warning "This will destroy the current instance and create a new one"
    print_info "The static IP is kept and reassigned to the new instance"

    echo
    read -p "Continue? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "Replacing instance..."
        if terraform apply -replace="$TF_INSTANCE_RESOURCE" -auto-approve; then
            print_success "Instance updated successfully"

            # Show outputs
            print_header "Access Information"
            terraform output

            echo
            print_success "Update complete"
            print_info "Access Nginx at: $(terraform output -raw nginx_url)"
        else
            print_error "Failed to update the instance"
            exit 1
        fi
    else
        print_warning "Update cancelled"
    fi

    cd "$ROOT_DIR"
}

# Destroy the infrastructure
destroy_infrastructure() {
    print_header "Destroying Infrastructure ($CLOUD_LABEL)"

    cd "$TERRAFORM_DIR"

    print_warning "WARNING: this will destroy every resource created by Terraform"
    read -p "Are you sure? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "Destroying resources..."
        if terraform destroy -auto-approve; then
            print_success "Resources destroyed successfully"
        else
            print_error "Failed to destroy resources"
            exit 1
        fi
    else
        print_warning "Destroy cancelled"
    fi

    cd "$ROOT_DIR"
}

# Main menu
show_menu() {
    echo
    echo "=========================================="
    echo "  Immutable Infrastructure - $CLOUD_LABEL"
    echo "=========================================="
    echo
    echo "1) Full Build (Packer + Terraform)"
    echo "2) Packer only (Create Image)"
    echo "3) Terraform only (Deploy)"
    echo "4) Update Instance (Newest Image)"
    echo "5) List Images"
    echo "6) Destroy Infrastructure"
    echo "7) Validate Configurations"
    echo "0) Exit"
    echo
    read -p "Choose an option: " choice

    case $choice in
        1)
            check_dependencies
            check_config
            validate_configs
            build_image
            list_images
            deploy_infrastructure
            ;;
        2)
            check_dependencies
            check_config
            validate_configs
            build_image
            list_images
            ;;
        3)
            check_dependencies
            check_config
            deploy_infrastructure
            ;;
        4)
            update_instance
            ;;
        5)
            list_images
            ;;
        6)
            destroy_infrastructure
            ;;
        7)
            check_dependencies
            check_config
            validate_configs
            print_success "All validations passed"
            ;;
        0)
            print_info "Exiting..."
            exit 0
            ;;
        *)
            print_error "Invalid option"
            show_menu
            ;;
    esac
}

show_help() {
    echo "Automated Deploy Script - Immutable Infrastructure (multi-cloud)"
    echo
    echo "Usage: ./bin/deploy.sh [--cloud gcp|aws|azure] [option]"
    echo
    echo "Options:"
    echo "  --cloud <name>  Target cloud: gcp (default), aws, azure"
    echo "  --full          Full build (Packer + Terraform)"
    echo "  --packer        Packer build only"
    echo "  --terraform     Terraform deploy only"
    echo "  --update        Update the instance with the newest image"
    echo "  --destroy       Destroy the infrastructure"
    echo "  --list          List images"
    echo "  --validate      Validate configurations"
    echo "  --help, -h      Show this help"
    echo
    echo "With no arguments (other than --cloud), shows the interactive menu"
    echo
    echo "Examples:"
    echo "  ./bin/deploy.sh --full"
    echo "  ./bin/deploy.sh --cloud aws --packer"
    echo "  CLOUD=azure ./bin/deploy.sh --validate"
}

# Parse arguments: --cloud is consumed here, the rest becomes the action
ACTION=""
while [ $# -gt 0 ]; do
    case "$1" in
        --cloud)
            CLOUD="$2"
            shift 2
            ;;
        --cloud=*)
            CLOUD="${1#*=}"
            shift
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        *)
            ACTION="$1"
            shift
            ;;
    esac
done

setup_cloud

case "$ACTION" in
    --full)
        check_dependencies
        check_config
        validate_configs
        build_image
        list_images
        deploy_infrastructure
        ;;
    --packer)
        check_dependencies
        check_config
        validate_configs
        build_image
        list_images
        ;;
    --terraform)
        check_dependencies
        check_config
        deploy_infrastructure
        ;;
    --update)
        update_instance
        ;;
    --destroy)
        destroy_infrastructure
        ;;
    --list)
        list_images
        ;;
    --validate)
        check_dependencies
        check_config
        validate_configs
        print_success "All validations passed"
        ;;
    "")
        show_menu
        ;;
    *)
        print_error "Invalid option: $ACTION"
        show_help
        exit 1
        ;;
esac

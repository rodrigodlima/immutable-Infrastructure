# GCP — Immutable Infrastructure

Reference implementation. Status: ✅ **working**.

| Layer | Resource |
|-------|----------|
| Image | Compute Engine image (family `nginx-immutable-family`) |
| Compute | GCE instance (`e2-micro`) |
| Network | Default VPC + firewall rules for HTTP/SSH |
| Address | Reserved static external IP (survives instance replacement) |

## Layout

```
clouds/gcp/
├── packer/
│   ├── gce-nginx.pkr.hcl             # builds the image, runs shared/ansible/nginx.yml
│   └── variables.pkrvars.hcl.example
├── terraform/
│   ├── main.tf                       # static IP, firewall, instance
│   ├── variables.tf
│   ├── outputs.tf
│   └── terraform.tfvars.example
└── scripts/
    └── update-instance.sh            # Blue-Green replacement of the instance
```

## Setup

```bash
export PROJECT_ID="your-gcp-project"
gcloud config set project "$PROJECT_ID"
gcloud services enable compute.googleapis.com
gcloud auth application-default login

cp clouds/gcp/packer/variables.pkrvars.hcl.example clouds/gcp/packer/variables.pkrvars.hcl
cp clouds/gcp/terraform/terraform.tfvars.example clouds/gcp/terraform/terraform.tfvars
# edit both files and set project_id
```

## Deploy

```bash
./bin/deploy.sh --cloud gcp --validate   # check tooling, credentials and templates
./bin/deploy.sh --cloud gcp --full       # Packer build + Terraform apply
./bin/deploy.sh --cloud gcp --update     # rebuild image, replace instance
./bin/deploy.sh --cloud gcp --destroy    # tear everything down
```

`--cloud gcp` is the default, so it can be omitted.

## Manual commands

```bash
packer init clouds/gcp/packer/gce-nginx.pkr.hcl
packer build -var-file=clouds/gcp/packer/variables.pkrvars.hcl clouds/gcp/packer/gce-nginx.pkr.hcl

cd clouds/gcp/terraform
terraform init
terraform apply
terraform output nginx_url
```

The Packer template resolves the playbook through `${path.root}`, so it can be
run from any working directory.

## Notes

- Terraform state is local (`clouds/gcp/terraform/terraform.tfstate`) and gitignored.
  For anything beyond a demo, move it to a GCS backend.
- The instance name embeds the image timestamp, which forces recreation whenever a
  newer image appears in the family — that is what makes the infrastructure immutable.

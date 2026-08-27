# AWS — Immutable Infrastructure

Status: 🚧 **not implemented yet**. This directory is a placeholder that mirrors
`clouds/gcp/` so the same workflow (`./bin/deploy.sh --cloud aws ...`) works once
the files below exist.

## Target design

| Layer | GCP equivalent | AWS resource |
|-------|----------------|--------------|
| Image | Compute Engine image | **AMI** (`amazon-ebs` Packer builder) |
| Compute | GCE instance | **EC2 instance** (`t3.micro` / `t4g.micro`) |
| Network | Default VPC + firewall | **Default VPC + Security Group** (80, 22) |
| Address | Static external IP | **Elastic IP** + `aws_eip_association` |
| Image lookup | image family | `aws_ami` data source filtered by tag/name prefix, `most_recent = true` |

## Files to create

```
clouds/aws/
├── packer/
│   ├── ami-nginx.pkr.hcl             # amazon-ebs source + ansible provisioner
│   └── variables.pkrvars.hcl.example # region, instance_type, ami_name_prefix
├── terraform/
│   ├── main.tf                       # data.aws_ami, aws_security_group, aws_eip, aws_instance
│   ├── variables.tf                  # region, instance_type, ami_name_prefix, environment
│   ├── outputs.tf                    # external_ip, nginx_url, ssh_command, image_used
│   └── terraform.tfvars.example
└── scripts/
    └── update-instance.sh            # Blue-Green replacement
```

## Contract expected by `bin/deploy.sh`

The driver is already wired for AWS and expects:

- Packer template: the single `*.pkr.hcl` file in `clouds/aws/packer/`
- Packer vars: `clouds/aws/packer/variables.pkrvars.hcl`
- Terraform vars: `clouds/aws/terraform/terraform.tfvars`
- Terraform instance resource address: `aws_instance.nginx_server`
- Terraform outputs: `nginx_url` and `ssh_command`
- Ansible playbook: reused from `shared/ansible/nginx.yml` — do **not** copy it here
- Packer manifest post-processor writing to `${path.root}/../packer-manifest.json`
- AMIs tagged `Project=nginx-immutable` (that is what `--list` filters on)

## Notes when implementing

- Base image: Ubuntu 22.04 LTS via `source_ami_filter` on owner `099720109477`.
- The `ansible` provisioner needs `ssh_username = "ubuntu"` and `use_proxy = false`.
- Keep the same immutability trick as GCP: derive the instance name from the AMI id
  so a new AMI forces `terraform apply` to replace the instance.
- Auth check used by the driver: `aws sts get-caller-identity`.

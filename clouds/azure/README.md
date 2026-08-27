# Azure — Immutable Infrastructure

Status: 🚧 **not implemented yet**. This directory is a placeholder that mirrors
`clouds/gcp/` so the same workflow (`./bin/deploy.sh --cloud azure ...`) works once
the files below exist.

## Target design

| Layer | GCP equivalent | Azure resource |
|-------|----------------|----------------|
| Image | Compute Engine image | **Shared Image Gallery** image version (`azure-arm` Packer builder) |
| Compute | GCE instance | **Linux Virtual Machine** (`Standard_B1s`) |
| Network | Default VPC + firewall | **VNet + Subnet + Network Security Group** (80, 22) |
| Address | Static external IP | **Public IP** with `allocation_method = "Static"` |
| Image lookup | image family | `azurerm_shared_image_version` data source with `name = "latest"` |

## Files to create

```
clouds/azure/
├── packer/
│   ├── image-nginx.pkr.hcl           # azure-arm source + ansible provisioner
│   └── variables.pkrvars.hcl.example # subscription_id, resource_group, location, gallery
├── terraform/
│   ├── main.tf                       # rg, vnet, subnet, nsg, public ip, nic, linux vm
│   ├── variables.tf
│   ├── outputs.tf                    # external_ip, nginx_url, ssh_command, image_used
│   └── terraform.tfvars.example
└── scripts/
    └── update-instance.sh            # Blue-Green replacement
```

## Contract expected by `bin/deploy.sh`

The driver is already wired for Azure and expects:

- Packer template: the single `*.pkr.hcl` file in `clouds/azure/packer/`
- Packer vars: `clouds/azure/packer/variables.pkrvars.hcl`
- Terraform vars: `clouds/azure/terraform/terraform.tfvars`
- Terraform instance resource address: `azurerm_linux_virtual_machine.nginx_server`
- Terraform outputs: `nginx_url` and `ssh_command`
- Ansible playbook: reused from `shared/ansible/nginx.yml` — do **not** copy it here
- Packer manifest post-processor writing to `${path.root}/../packer-manifest.json`
- A Shared Image Gallery; `--list` reads these env vars (with defaults):
  `AZURE_RESOURCE_GROUP` (`nginx-immutable-rg`), `AZURE_GALLERY`
  (`nginx_immutable_gallery`), `AZURE_IMAGE_DEF` (`nginx-immutable`)

## Notes when implementing

- Base image: `Canonical:0001-com-ubuntu-server-jammy:22_04-lts:latest`.
- The gallery, image definition and resource group must exist before the first
  `packer build` — create them once with `az sig create` / `az sig image-definition create`,
  or add them to a small bootstrap Terraform config.
- Keep the same immutability trick: derive the VM name from the image version so a
  new version forces replacement.
- Auth check used by the driver: `az account show`.

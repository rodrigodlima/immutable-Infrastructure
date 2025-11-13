# 🚀 Demo de Infraestrutura Imutável - GCP

Demonstração completa de **Infraestrutura Imutável** usando **Packer**, **Ansible** e **Terraform** no Google Cloud Platform.

## 📋 O que é Infraestrutura Imutável?

Infraestrutura imutável é um paradigma onde os servidores **nunca são modificados** após o deployment. Em vez de atualizar servidores existentes, você:

1. **Cria uma nova imagem** com todas as configurações
2. **Substitui a instância antiga** pela nova
3. **Elimina configurações em tempo de execução**

### Benefícios:
- ✅ Deployments mais confiáveis e previsíveis
- ✅ Rollback instantâneo para versões anteriores
- ✅ Elimina "configuration drift"
- ✅ Facilita testes e validação
- ✅ Ambientes idênticos (dev/staging/prod)

## 🏗️ Arquitetura do Projeto

```
┌─────────────────────────────────────────────────────────┐
│  1. ANSIBLE                                              │
│  - Define a configuração (instala Nginx)                │
│  - Playbook: ansible/nginx.yml                          │
└──────────────────┬──────────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────────┐
│  2. PACKER                                               │
│  - Executa o playbook Ansible                           │
│  - Cria a imagem GCE customizada                        │
│  - Adiciona tags e labels                               │
│  - Template: packer/gce-nginx.pkr.hcl                   │
└──────────────────┬──────────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────────┐
│  3. TERRAFORM                                            │
│  - Busca a imagem criada pelo Packer                    │
│  - Provisiona a instância GCE                           │
│  - Configura firewall e networking                      │
│  - Código: terraform/*.tf                               │
└─────────────────────────────────────────────────────────┘
```

## 📂 Estrutura do Projeto

```
.
├── ansible/
│   └── nginx.yml                    # Playbook Ansible
├── packer/
│   ├── gce-nginx.pkr.hcl           # Template Packer
│   └── variables.pkrvars.hcl.example
└── terraform/
    ├── main.tf                      # Recursos principais
    ├── variables.tf                 # Definição de variáveis
    ├── outputs.tf                   # Outputs
    └── terraform.tfvars.example     # Exemplo de variáveis
```

## 🔧 Pré-requisitos

### Ferramentas Necessárias

1. **Google Cloud SDK** (gcloud CLI)
2. **Terraform** (>= 1.0)
3. **Packer** (>= 1.8)
4. **Ansible** (>= 2.9)

### Instalação Rápida (Ubuntu/Debian)

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

## 🚀 Passo a Passo - Deploy Completo

### 1️⃣ Configurar Projeto GCP

```bash
# Definir o projeto GCP
export PROJECT_ID="seu-projeto-gcp"
gcloud config set project $PROJECT_ID

# Habilitar APIs necessárias
gcloud services enable compute.googleapis.com
gcloud services enable cloudresourcemanager.googleapis.com

# Criar credenciais para o Packer e Terraform
gcloud auth application-default login
```

### 2️⃣ Configurar Variáveis

**Para o Packer:**

```bash
# Copiar arquivo de exemplo
cd packer
cp variables.pkrvars.hcl.example variables.pkrvars.hcl

# Editar o arquivo e adicionar seu project_id
nano variables.pkrvars.hcl
```

Conteúdo do `variables.pkrvars.hcl`:
```hcl
project_id   = "seu-projeto-gcp"
zone         = "us-central1-a"
image_name   = "nginx-immutable"
image_family = "nginx-immutable-family"
```

**Para o Terraform:**

```bash
# Copiar arquivo de exemplo
cd ../terraform
cp terraform.tfvars.example terraform.tfvars

# Editar o arquivo
nano terraform.tfvars
```

Conteúdo do `terraform.tfvars`:
```hcl
project_id    = "seu-projeto-gcp"
region        = "us-central1"
zone          = "us-central1-a"
instance_name = "nginx-immutable-demo"
machine_type  = "e2-micro"
image_family  = "nginx-immutable-family"
environment   = "demo"
```

### 3️⃣ Criar a Imagem com Packer

```bash
# Voltar para o diretório raiz do projeto
cd ..

# Validar o template Packer
packer validate -var-file=packer/variables.pkrvars.hcl packer/gce-nginx.pkr.hcl

# Construir a imagem (isso leva ~5-10 minutos)
packer build -var-file=packer/variables.pkrvars.hcl packer/gce-nginx.pkr.hcl
```

**O que acontece:**
1. Packer cria uma VM temporária no GCP
2. Executa o playbook Ansible para instalar o Nginx
3. Cria uma imagem da VM configurada
4. Adiciona tags e labels na imagem
5. Destrói a VM temporária

**Verificar a imagem criada:**
```bash
# Listar imagens da família
gcloud compute images list --filter="family:nginx-immutable-family"

# Ver detalhes da imagem mais recente
gcloud compute images describe-from-family nginx-immutable-family
```

### 4️⃣ Provisionar Infraestrutura com Terraform

```bash
cd terraform

# Inicializar Terraform (baixar providers)
terraform init

# Validar a configuração
terraform validate

# Ver o plano de execução
terraform plan

# Aplicar as mudanças (criar os recursos)
terraform apply
```

Digite `yes` quando solicitado.

**O que acontece:**
1. Terraform busca a imagem mais recente da família
2. Cria um IP estático para a instância
3. Configura regras de firewall (HTTP e SSH)
4. Cria a instância GCE usando a imagem do Packer

### 5️⃣ Acessar a Aplicação

Após o `terraform apply`, você verá os outputs:

```bash
# URL do Nginx
nginx_url = "http://34.xxx.xxx.xxx"

# Comando SSH
ssh_command = "gcloud compute ssh nginx-immutable-demo --zone=us-central1-a"
```

**Testar o Nginx:**

```bash
# Obter o IP da instância
NGINX_IP=$(terraform output -raw external_ip)

# Testar via curl
curl http://$NGINX_IP

# Abrir no navegador
xdg-open http://$NGINX_IP  # Linux
open http://$NGINX_IP       # macOS
```

Você verá a página HTML customizada mostrando a stack de infraestrutura imutável!

### 6️⃣ Acessar a Instância via SSH

```bash
# Via gcloud
gcloud compute ssh nginx-immutable-demo --zone=us-central1-a

# Verificar status do Nginx
sudo systemctl status nginx

# Ver logs
sudo journalctl -u nginx -f
```

## 🔄 Workflow de Atualização (Imutabilidade na Prática)

Quando você precisa fazer uma mudança (ex: atualizar Nginx ou adicionar um pacote):

```bash
# 1. Modificar o playbook Ansible
nano ansible/nginx.yml

# 2. Criar nova imagem com Packer
packer build -var-file=packer/variables.pkrvars.hcl packer/gce-nginx.pkr.hcl

# 3. Recriar a instância com Terraform
cd terraform
terraform apply -replace=google_compute_instance.nginx_server

# Ou destruir e recriar
terraform destroy -target=google_compute_instance.nginx_server
terraform apply
```

**Importante:** Nunca faça SSH na instância para fazer mudanças manuais! Isso quebra o princípio da imutabilidade.

## 🧹 Limpeza de Recursos

```bash
# Destruir a instância e recursos do Terraform
cd terraform
terraform destroy

# Deletar as imagens criadas pelo Packer (opcional)
gcloud compute images list --filter="family:nginx-immutable-family" --format="value(name)" | \
  xargs -I {} gcloud compute images delete {} --quiet
```

## 📊 Comandos Úteis

### Verificar Imagens Criadas

```bash
# Listar todas as imagens da família
gcloud compute images list --filter="family:nginx-immutable-family"

# Ver labels de uma imagem específica
gcloud compute images describe IMAGE_NAME --format="value(labels)"
```

### Monitorar Recursos no GCP

```bash
# Listar instâncias
gcloud compute instances list

# Ver detalhes da instância
gcloud compute instances describe nginx-immutable-demo --zone=us-central1-a

# Ver logs da instância
gcloud compute instances get-serial-port-output nginx-immutable-demo --zone=us-central1-a
```

### Debug do Packer

```bash
# Modo debug (mantém a VM temporária em caso de erro)
packer build -debug -var-file=packer/variables.pkrvars.hcl packer/gce-nginx.pkr.hcl

# Ver o manifest gerado
cat packer-manifest.json | jq
```

### Terraform State Management

```bash
cd terraform

# Ver estado atual
terraform show

# Listar recursos gerenciados
terraform state list

# Ver output específico
terraform output nginx_url
```

## 🎯 Casos de Uso

### Criar Múltiplas Instâncias

Para criar múltiplas instâncias da mesma imagem:

```bash
cd terraform

# Modificar main.tf para adicionar count ou for_each
# Ou usar Terraform modules

terraform apply
```

### Blue-Green Deployment

```bash
# 1. Criar nova imagem (green)
packer build -var-file=packer/variables.pkrvars.hcl packer/gce-nginx.pkr.hcl

# 2. Criar nova instância (green)
terraform apply -var="instance_name=nginx-green"

# 3. Testar a nova instância
curl http://NEW_IP

# 4. Trocar o tráfego (load balancer)
# 5. Destruir instância antiga (blue)
terraform destroy -target=google_compute_instance.nginx_server
```

## 🔐 Boas Práticas

1. **Nunca faça mudanças manuais nas instâncias** - sempre recrie via Packer + Terraform
2. **Use versionamento de imagens** - o Packer já adiciona timestamp automaticamente
3. **Mantenha as imagens antigas** - facilita rollback
4. **Teste as imagens antes do deploy** - use ambientes staging
5. **Use Terraform workspaces** - para gerenciar múltiplos ambientes
6. **Documente as mudanças** - mantenha um CHANGELOG das imagens

## 🐛 Troubleshooting

### Erro: "Image not found"

```bash
# Verificar se a imagem existe
gcloud compute images list --filter="family:nginx-immutable-family"

# Verificar se o image_family está correto em ambos os arquivos
grep image_family packer/variables.pkrvars.hcl
grep image_family terraform/terraform.tfvars
```

### Erro: Packer timeout ou SSH

```bash
# Verificar regras de firewall
gcloud compute firewall-rules list

# Criar regra temporária para Packer
gcloud compute firewall-rules create allow-packer-ssh \
  --allow tcp:22 \
  --source-ranges=0.0.0.0/0 \
  --target-tags=packer
```

### Erro: Permissões insuficientes

```bash
# Verificar conta ativa
gcloud auth list

# Re-autenticar
gcloud auth application-default login

# Verificar permissões do projeto
gcloud projects get-iam-policy $PROJECT_ID
```

## 📚 Conceitos Importantes

### Packer
- **Builder**: Cria VMs em diferentes clouds (GCP, AWS, Azure)
- **Provisioner**: Executa scripts/ferramentas para configurar a VM (Ansible, Shell)
- **Post-processor**: Executa ações após a criação (export, manifest, tags)

### Ansible
- **Playbook**: Arquivo YAML que define o que instalar/configurar
- **Idempotência**: Executar múltiplas vezes produz o mesmo resultado
- **Tasks**: Unidade mínima de trabalho (instalar pacote, copiar arquivo)

### Terraform
- **Provider**: Plugin para interagir com cloud (google, aws, azure)
- **Resource**: Componente de infraestrutura (instância, rede, disco)
- **Data Source**: Busca informações existentes (imagens, VPCs)
- **State**: Arquivo que rastreia os recursos gerenciados

## 🎓 Próximos Passos

1. **Adicionar Load Balancer**: Distribuir tráfego entre múltiplas instâncias
2. **Implementar Auto Scaling**: Escalar baseado em métricas
3. **Adicionar Monitoring**: Integrar com Cloud Monitoring
4. **CI/CD Pipeline**: Automatizar build de imagens e deploy
5. **Vault Integration**: Gerenciar secrets de forma segura
6. **Multi-region**: Deploy em múltiplas regiões

## 🤝 Contribuindo

Sinta-se livre para adaptar este projeto para suas necessidades!

## 📄 Licença

Este projeto é open-source e está disponível para uso educacional.

---

**Desenvolvido para demonstração de Infraestrutura Imutável** 🚀

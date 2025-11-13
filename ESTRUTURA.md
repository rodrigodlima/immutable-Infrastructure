# 📦 Projeto de Infraestrutura Imutável - GCP

## 🎯 Resumo Executivo

Este projeto demonstra uma implementação completa de **Infraestrutura Imutável** no Google Cloud Platform utilizando as ferramentas:
- **Packer**: Criação de imagens customizadas
- **Ansible**: Configuração e provisionamento
- **Terraform**: Gerenciamento de infraestrutura

## 📂 Estrutura do Projeto

```
infraestrutura-imutavel-gcp/
│
├── 📄 README.md                 # Documentação completa e detalhada
├── 📄 QUICKSTART.md             # Guia rápido (5 minutos)
├── 📄 COMANDOS.md               # Referência rápida de comandos
├── 📄 .gitignore                # Arquivo gitignore configurado
├── 🔧 deploy.sh                 # Script de automação completo
│
├── 📁 ansible/
│   └── nginx.yml                # Playbook Ansible para instalar Nginx
│
├── 📁 packer/
│   ├── gce-nginx.pkr.hcl       # Template Packer para criar imagem GCE
│   └── variables.pkrvars.hcl.example
│
└── 📁 terraform/
    ├── main.tf                  # Recursos principais do Terraform
    ├── variables.tf             # Definição de variáveis
    ├── outputs.tf               # Outputs do Terraform
    └── terraform.tfvars.example # Exemplo de configuração
```

## 🚀 O Que Este Projeto Faz?

### 1. **Packer + Ansible**
Cria uma imagem GCE customizada com:
- ✅ Ubuntu 22.04 LTS
- ✅ Nginx instalado e configurado
- ✅ Página HTML personalizada
- ✅ Tags e labels organizacionais
- ✅ Otimizações de tamanho

### 2. **Terraform**
Provisiona infraestrutura completa:
- ✅ Instância GCE usando a imagem criada
- ✅ IP estático público
- ✅ Regras de firewall (HTTP + SSH)
- ✅ Tags e metadados organizacionais

## 📊 Diagrama de Arquitetura

```
┌─────────────────────────────────────────────────────────┐
│  PASSO 1: ANSIBLE                                        │
│  • Define configuração (nginx.yml)                       │
│  • Instala e configura Nginx                            │
│  • Cria página HTML customizada                         │
└──────────────────┬──────────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────────┐
│  PASSO 2: PACKER                                         │
│  • Cria VM temporária no GCP                            │
│  • Executa playbook Ansible                             │
│  • Cria imagem da VM configurada                        │
│  • Adiciona tags: environment, managed_by, etc          │
│  • Destrói VM temporária                                │
└──────────────────┬──────────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────────┐
│  PASSO 3: TERRAFORM                                      │
│  • Busca a imagem mais recente                          │
│  • Cria IP estático                                     │
│  • Configura firewall (HTTP/SSH)                        │
│  • Provisiona instância GCE                             │
└─────────────────────────────────────────────────────────┘
                   │
                   ▼
        🎉 Aplicação Rodando!
```

## ⚡ Quick Start

### 1. Configuração Inicial (2 minutos)
```bash
# Definir projeto GCP
export PROJECT_ID="seu-projeto-gcp"
gcloud config set project $PROJECT_ID

# Habilitar APIs
gcloud services enable compute.googleapis.com

# Autenticar
gcloud auth application-default login
```

### 2. Configurar Variáveis (1 minuto)
```bash
# Packer
cp packer/variables.pkrvars.hcl.example packer/variables.pkrvars.hcl
nano packer/variables.pkrvars.hcl  # Editar project_id

# Terraform
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
nano terraform/terraform.tfvars     # Editar project_id
```

### 3. Executar Deploy (10-15 minutos)
```bash
# Opção 1: Automático (recomendado)
chmod +x deploy.sh
./deploy.sh --full

# Opção 2: Manual
packer build -var-file=packer/variables.pkrvars.hcl packer/gce-nginx.pkr.hcl
cd terraform && terraform init && terraform apply
```

### 4. Acessar Aplicação (imediato)
```bash
# Obter URL
cd terraform
terraform output nginx_url

# Testar
curl $(terraform output -raw nginx_url)

# Abrir no navegador
xdg-open $(terraform output -raw nginx_url)  # Linux
open $(terraform output -raw nginx_url)       # macOS
```

## 🎯 Conceitos de Infraestrutura Imutável

### ✅ O Que É
- Servidores **nunca são modificados** após deployment
- Atualizações = criar nova imagem + substituir instância
- Configuração é "baked in" na imagem

### ✅ Benefícios
- **Confiabilidade**: Mesma imagem = mesmo resultado
- **Rollback Rápido**: Voltar para imagem anterior
- **Sem Configuration Drift**: Não há mudanças manuais
- **Testável**: Testar imagem antes do deploy
- **Rastreabilidade**: Histórico completo de versões

### ❌ Anti-Padrões a Evitar
- ❌ SSH na instância para fazer mudanças
- ❌ Executar scripts de configuração na inicialização
- ❌ Modificar arquivos manualmente
- ❌ "Hotfixes" diretos em produção

### ✅ Workflow Correto
1. Modificar playbook Ansible
2. Criar nova imagem com Packer
3. Testar imagem em staging
4. Deploy com Terraform
5. Validar
6. Destruir instância antiga

## 🛠️ Recursos Principais

### Script de Automação (`deploy.sh`)
```bash
./deploy.sh               # Menu interativo
./deploy.sh --full        # Build + Deploy completo
./deploy.sh --packer      # Apenas criar imagem
./deploy.sh --terraform   # Apenas deploy
./deploy.sh --destroy     # Destruir recursos
./deploy.sh --validate    # Validar configurações
```

### Ansible (`ansible/nginx.yml`)
- Instala Nginx
- Cria página HTML personalizada
- Configura firewall
- Valida instalação

### Packer (`packer/gce-nginx.pkr.hcl`)
- Usa imagem Ubuntu 22.04 LTS
- Executa Ansible provisioner
- Adiciona labels e tags
- Otimiza tamanho da imagem
- Gera manifest JSON

### Terraform (`terraform/*.tf`)
- Busca imagem mais recente da família
- Cria IP estático
- Configura firewall (HTTP/SSH)
- Provisiona instância e2-micro (free tier)
- Outputs com informações de acesso

## 📚 Documentação

- **[README.md](README.md)** - Documentação completa (12+ páginas)
  - Conceitos de infraestrutura imutável
  - Arquitetura detalhada
  - Instruções passo a passo
  - Troubleshooting
  - Boas práticas
  - Próximos passos

- **[QUICKSTART.md](QUICKSTART.md)** - Guia de 5 minutos
  - Comandos essenciais
  - Configuração mínima
  - Deploy rápido

- **[COMANDOS.md](COMANDOS.md)** - Referência rápida
  - Comandos Packer
  - Comandos Terraform
  - Comandos Ansible
  - Comandos gcloud
  - Aliases úteis
  - Dicas de debug

## 🎓 Casos de Uso

### Para Demonstração
✅ Perfeito para apresentações sobre:
- Infraestrutura como Código
- DevOps practices
- Cloud automation
- Imutable infrastructure
- CI/CD pipelines

### Para Desenvolvimento
✅ Base sólida para:
- Ambientes de desenvolvimento
- Staging/QA environments
- Microservices deployment
- Auto-scaling configurations

### Para Produção
✅ Componentes prontos para produção:
- Alta disponibilidade (adicionar load balancer)
- Auto scaling (adicionar instance group)
- Multi-region (replicar configuração)
- CI/CD integration (GitLab/GitHub Actions)

## 🔐 Segurança

### Implementado
✅ Regras de firewall restritivas
✅ Tags para organização
✅ Service account com scopes mínimos
✅ Imagens com security patches

### Para Produção (TODO)
- [ ] Secrets management (Vault/Secret Manager)
- [ ] Network isolation (VPC/Subnets)
- [ ] SSL/TLS certificates
- [ ] IAM roles granulares
- [ ] Security scanning (Trivy/Clair)
- [ ] Audit logging

## 💰 Custos Estimados

### Desenvolvimento/Teste
- **Instância e2-micro**: ~$7.00/mês (elegível para free tier)
- **IP estático**: ~$3.00/mês (se não usado)
- **Imagens**: ~$0.05/GB/mês (~0.10/mês)
- **Total**: ~$10/mês ou GRÁTIS (com free tier)

### Produção
- Depende do tamanho da instância e região
- Use calculadora GCP para estimar

## 🚧 Próximos Passos

### Nível Intermediário
1. Adicionar Load Balancer
2. Implementar Auto Scaling
3. Configurar Health Checks
4. Adicionar Cloud Monitoring

### Nível Avançado
5. Multi-region deployment
6. Blue-Green deployment
7. Canary releases
8. GitOps com ArgoCD/Flux

### Produção
9. Secrets management
10. Disaster recovery
11. Backup strategy
12. Compliance e audit

## 🤝 Contribuindo

Este é um projeto educacional. Sinta-se livre para:
- Adaptar para suas necessidades
- Adicionar novos recursos
- Melhorar a documentação
- Compartilhar aprendizados

## 📝 Licença

Este projeto é open-source e está disponível para uso educacional.

## 🎉 Conclusão

Você agora tem:
✅ Infraestrutura imutável funcional no GCP
✅ Scripts de automação completos
✅ Documentação abrangente
✅ Base para expansão

**Próximo passo:** Executar `./deploy.sh` e ver a mágica acontecer! 🚀

---

**Criado com ❤️ para demonstrar práticas modernas de DevOps**

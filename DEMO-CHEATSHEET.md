# 📝 CHEAT SHEET - Demo Rápida

## ⚡ Comandos Essenciais para a Demo

### 🚀 Setup Inicial (Execute UMA vez)

```bash
# Configurar projeto
export PROJECT_ID="seu-projeto-gcp"
gcloud config set project $PROJECT_ID
gcloud services enable compute.googleapis.com
gcloud auth application-default login

# Configurar variáveis
cp packer/variables.pkrvars.hcl.example packer/variables.pkrvars.hcl
cp terraform/terraform.tfvars.example terraform/terraform.tfvars

# Editar com seu project_id (Linux/Mac)
sed -i "s/seu-projeto-gcp/$PROJECT_ID/g" packer/variables.pkrvars.hcl
sed -i "s/seu-projeto-gcp/$PROJECT_ID/g" terraform/terraform.tfvars
```

---

## 📦 PARTE 1: Deploy V1

```bash
# Criar imagem V1
packer build -var-file=packer/variables.pkrvars.hcl packer/gce-nginx.pkr.hcl

# Anotar nome da imagem V1
export IMAGE_V1=$(gcloud compute images list --filter="family:nginx-immutable-family" --format="value(name)" --sort-by=creationTimestamp --limit=1)
echo "V1: $IMAGE_V1"

# Deploy infraestrutura
cd terraform
terraform init
terraform apply -auto-approve

# Obter URL
export NGINX_URL=$(terraform output -raw nginx_url)
export NGINX_IP=$(terraform output -raw external_ip)
echo "URL: $NGINX_URL"
cd ..

# Testar V1
curl $NGINX_IP
xdg-open $NGINX_URL  # ou 'open' no macOS
```

---

## 🆕 PARTE 2: Criar e Deploy V2

```bash
# Backup V1
cp ansible/nginx.yml ansible/nginx.yml.v1

# Criar conteúdo V2 (copie todo o bloco abaixo)
cat > ansible/nginx.yml << 'EOF'
---
- name: Instalar e Configurar Nginx - VERSÃO 2
  hosts: all
  become: yes
  tasks:
    - name: Atualizar cache do apt
      apt:
        update_cache: yes
        cache_valid_time: 3600

    - name: Instalar Nginx
      apt:
        name: nginx
        state: present

    - name: Criar página HTML - VERSÃO 2
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
                      <h3>🎉 Novidades da V2:</h3>
                      <ul>
                          <li>✅ Novo design com gradiente roxo</li>
                          <li>✅ Badge animado de versão</li>
                          <li>✅ Layout completamente novo</li>
                          <li>✅ Demonstração de atualização imutável</li>
                      </ul>
                  </div>
                  <hr>
                  <p>✅ Criado com Packer + Ansible + Terraform</p>
                  <p>🔄 Rollback disponível para V1!</p>
                  <p><strong style="color: #f5576c;">⚡ IMAGEM: 2.0 ⚡</strong></p>
              </div>
          </body>
          </html>
        dest: /var/www/html/index.html
        mode: '0644'

    - name: Garantir Nginx rodando
      systemd:
        name: nginx
        state: started
        enabled: yes
EOF

# Criar imagem V2
packer build -var-file=packer/variables.pkrvars.hcl packer/gce-nginx.pkr.hcl

# Anotar nome da imagem V2
export IMAGE_V2=$(gcloud compute images list --filter="family:nginx-immutable-family" --format="value(name)" --sort-by=~creationTimestamp --limit=1)
echo "V2: $IMAGE_V2"

# Listar ambas as imagens
gcloud compute images list --filter="family:nginx-immutable-family" --format="table(name,creationTimestamp)"

# Deploy V2
cd terraform
terraform apply -replace=google_compute_instance.nginx_server -auto-approve
cd ..

# Testar V2
sleep 10
curl $NGINX_IP | grep -i "versão"
xdg-open $NGINX_URL
```

---

## 🔄 PARTE 3: Rollback para V1

```bash
# Verificar imagens disponíveis
echo "Imagem V1: $IMAGE_V1"
echo "Imagem V2: $IMAGE_V2"

# Rollback via Terraform
cd terraform

# Backup do main.tf
cp main.tf main.tf.backup

# Forçar uso da V1 (trocar 'family' por 'name')
sed "s|family  = var.image_family|name    = \"$IMAGE_V1\"|" main.tf.backup > main.tf

# Aplicar rollback
terraform apply -replace=google_compute_instance.nginx_server -auto-approve

# Restaurar main.tf
mv main.tf.backup main.tf

cd ..

# Testar rollback
sleep 10
curl $NGINX_IP
xdg-open $NGINX_URL

# Restaurar ansible para V1
mv ansible/nginx.yml.v1 ansible/nginx.yml
```

---

## 🧹 Limpeza

```bash
# Destruir infraestrutura
cd terraform
terraform destroy -auto-approve
cd ..

# Listar imagens
gcloud compute images list --filter="family:nginx-immutable-family"

# Deletar TODAS as imagens (opcional)
gcloud compute images list --filter="family:nginx-immutable-family" --format="value(name)" | xargs -I {} gcloud compute images delete {} --quiet
```

---

## 🎯 Comandos de Verificação

```bash
# Ver status da instância
gcloud compute instances describe nginx-immutable-demo --zone=us-central1-a --format="value(status)"

# Ver IP da instância
cd terraform && terraform output external_ip && cd ..

# Testar HTTP
curl -I $NGINX_IP

# Ver conteúdo HTML
curl $NGINX_IP

# Ver imagens disponíveis
gcloud compute images list --filter="family:nginx-immutable-family" --format="table(name,family,creationTimestamp,diskSizeGb)"

# Ver qual imagem está em uso
cd terraform && terraform show | grep "image.*nginx" && cd ..
```

---

## 💡 Dicas Rápidas

### Preparar Demo Antes da Apresentação

```bash
# Execute V1 antes da apresentação (economiza 10 min)
export PROJECT_ID="seu-projeto-gcp"
# ... configurar variáveis ...
packer build -var-file=packer/variables.pkrvars.hcl packer/gce-nginx.pkr.hcl
cd terraform && terraform init && terraform apply -auto-approve && cd ..

# Anote os nomes das variáveis
export IMAGE_V1=$(gcloud compute images list --filter="family:nginx-immutable-family" --format="value(name)" --limit=1)
export NGINX_URL=$(cd terraform && terraform output -raw nginx_url && cd ..)
```

### Durante a Demo

```bash
# Preparar janelas side-by-side:
# 1. Terminal com comandos
# 2. Browser com $NGINX_URL
# 3. Slides (opcional)

# Ter aliases prontos:
alias v1-to-v2="packer build -var-file=packer/variables.pkrvars.hcl packer/gce-nginx.pkr.hcl && cd terraform && terraform apply -replace=google_compute_instance.nginx_server -auto-approve && cd .."
alias rollback="cd terraform && terraform apply -replace=google_compute_instance.nginx_server && cd .."
```

### Troubleshooting Rápido

```bash
# Se Packer falhar
PACKER_LOG=1 packer build -var-file=packer/variables.pkrvars.hcl packer/gce-nginx.pkr.hcl

# Se Terraform falhar
cd terraform && terraform show && terraform refresh

# Se Nginx não responder
gcloud compute ssh nginx-immutable-demo --zone=us-central1-a -- sudo systemctl status nginx
```

---

## ⏱️ Timing da Demo

- **Setup inicial:** 2 min (ou pré-feito)
- **V1 build + deploy:** 10 min (ou pré-feito)
- **Mostrar V1:** 2 min
- **Criar V2:** 2 min (apenas modificar arquivo)
- **V2 build:** 8 min (momento para explicar conceitos!)
- **Deploy V2:** 3 min
- **Mostrar V2:** 2 min
- **Rollback:** 5 min
- **Conclusão:** 1 min

**Total:** ~35 min (ou 15 min se V1 estiver pré-deployada)

---

## 🎤 Talking Points

Enquanto espera builds do Packer (8 min):

- "Infraestrutura imutável = DVD, não fita cassete"
- "Nunca modificamos servidores, sempre criamos novos"
- "Mesma imagem = mesmo resultado, sempre"
- "Rollback em minutos, não horas"
- "Zero configuration drift"
- "Ideal para microservices e containers"
- "Base para CI/CD moderno"

---

## 📱 One-Liners para Copiar/Colar

```bash
# Deploy completo V1
packer build -var-file=packer/variables.pkrvars.hcl packer/gce-nginx.pkr.hcl && cd terraform && terraform init && terraform apply -auto-approve && cd ..

# Ver e abrir V1
export NGINX_URL=$(cd terraform && terraform output -raw nginx_url && cd ..) && echo $NGINX_URL && xdg-open $NGINX_URL

# Build e deploy V2 (após modificar ansible/nginx.yml)
packer build -var-file=packer/variables.pkrvars.hcl packer/gce-nginx.pkr.hcl && cd terraform && terraform apply -replace=google_compute_instance.nginx_server -auto-approve && cd ..

# Limpeza completa
cd terraform && terraform destroy -auto-approve && cd .. && gcloud compute images list --filter="family:nginx-immutable-family" --format="value(name)" | xargs -I {} gcloud compute images delete {} --quiet
```

---

**🎉 Sucesso na sua demo!**

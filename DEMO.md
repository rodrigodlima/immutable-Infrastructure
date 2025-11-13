# 🎯 ROTEIRO DE DEMONSTRAÇÃO - Infraestrutura Imutável

## 📋 Objetivo da Demo

Demonstrar o ciclo completo de infraestrutura imutável:
1. ✅ Deploy inicial
2. ✅ Modificação de conteúdo
3. ✅ Nova versão (imagem v2)
4. ✅ Deploy da v2
5. ✅ Rollback para v1

**Tempo estimado:** 25-30 minutos

---

## 🎬 PARTE 1: Deploy Inicial (v1)

### Passo 1.1 - Preparar Ambiente (2 min)

```bash
# Definir variáveis
export PROJECT_ID="seu-projeto-gcp"
gcloud config set project $PROJECT_ID

# Habilitar APIs
gcloud services enable compute.googleapis.com

# Autenticar
gcloud auth application-default login

# Criar arquivos de configuração
cp packer/variables.pkrvars.hcl.example packer/variables.pkrvars.hcl
cp terraform/terraform.tfvars.example terraform/terraform.tfvars

# Editar com seu project_id
sed -i "s/seu-projeto-gcp/$PROJECT_ID/g" packer/variables.pkrvars.hcl
sed -i "s/seu-projeto-gcp/$PROJECT_ID/g" terraform/terraform.tfvars
```

### Passo 1.2 - Criar Primeira Imagem (8-10 min)

```bash
echo "🔨 Criando VERSÃO 1 da imagem..."

# Validar template
packer validate -var-file=packer/variables.pkrvars.hcl packer/gce-nginx.pkr.hcl

# Build da imagem v1
packer build -var-file=packer/variables.pkrvars.hcl packer/gce-nginx.pkr.hcl

# Verificar imagem criada
echo ""
echo "📸 Imagens disponíveis:"
gcloud compute images list --filter="family:nginx-immutable-family" \
  --format="table(name,family,creationTimestamp,status)"

# Anotar o nome da primeira imagem (v1)
export IMAGE_V1=$(gcloud compute images list \
  --filter="family:nginx-immutable-family" \
  --format="value(name)" \
  --sort-by=creationTimestamp \
  --limit=1)

echo "✅ Imagem V1 criada: $IMAGE_V1"
```

### Passo 1.3 - Deploy da Infraestrutura v1 (3-5 min)

```bash
echo "🚀 Fazendo deploy da VERSÃO 1..."

cd terraform

# Inicializar
terraform init

# Ver plano
terraform plan

# Aplicar
terraform apply -auto-approve

# Aguardar alguns segundos para o Nginx iniciar
sleep 10

# Obter informações
export NGINX_IP=$(terraform output -raw external_ip)
export NGINX_URL=$(terraform output -raw nginx_url)

echo ""
echo "✅ VERSÃO 1 DEPLOYED!"
echo "📍 URL: $NGINX_URL"
echo "🌐 IP: $NGINX_IP"

cd ..
```

### Passo 1.4 - Validar v1 e Mostrar Conteúdo (2 min)

```bash
echo ""
echo "🌐 Acessando VERSÃO 1..."
echo "================================"

# Testar HTTP
curl -I $NGINX_IP

echo ""
echo "📄 CONTEÚDO DA VERSÃO 1:"
echo "================================"
curl $NGINX_IP

echo ""
echo "🎯 PONTOS A DESTACAR:"
echo "- Esta é a VERSÃO 1 original"
echo "- Página mostra 'Infraestrutura Imutável - Demo'"
echo "- Agora vamos fazer uma MODIFICAÇÃO e criar V2"

# Abrir no navegador
echo ""
echo "Abrindo no navegador..."
xdg-open $NGINX_URL 2>/dev/null || open $NGINX_URL 2>/dev/null || echo "Acesse manualmente: $NGINX_URL"
```

---

## 🎬 PARTE 2: Modificação e Nova Versão (v2)

### Passo 2.1 - Criar Versão 2 do HTML (1 min)

```bash
echo "✏️ Criando VERSÃO 2 do conteúdo HTML..."

# Backup da versão original
cp ansible/nginx.yml ansible/nginx.yml.v1

# Criar versão 2 com conteúdo modificado
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

    - name: Criar página HTML customizada - VERSÃO 2
      copy:
        content: |
          <!DOCTYPE html>
          <html>
          <head>
              <title>Infraestrutura Imutável - V2</title>
              <style>
                  body {
                      font-family: Arial, sans-serif;
                      max-width: 800px;
                      margin: 50px auto;
                      padding: 20px;
                      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                  }
                  .container {
                      background-color: white;
                      padding: 30px;
                      border-radius: 15px;
                      box-shadow: 0 10px 30px rgba(0,0,0,0.3);
                  }
                  h1 {
                      color: #667eea;
                      font-size: 2.5em;
                  }
                  .version-badge {
                      display: inline-block;
                      padding: 10px 20px;
                      margin: 10px 0;
                      background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
                      color: white;
                      border-radius: 25px;
                      font-size: 1.5em;
                      font-weight: bold;
                  }
                  .badge {
                      display: inline-block;
                      padding: 5px 10px;
                      margin: 5px;
                      background-color: #764ba2;
                      color: white;
                      border-radius: 5px;
                  }
                  .new-feature {
                      background-color: #fff3cd;
                      border-left: 4px solid #ffc107;
                      padding: 15px;
                      margin: 20px 0;
                  }
              </style>
          </head>
          <body>
              <div class="container">
                  <h1>🚀 Infraestrutura Imutável</h1>
                  <div class="version-badge">✨ VERSÃO 2.0 ✨</div>
                  
                  <p><strong>Esta instância foi provisionada usando:</strong></p>
                  <div>
                      <span class="badge">Packer</span>
                      <span class="badge">Ansible</span>
                      <span class="badge">Terraform</span>
                      <span class="badge">GCP</span>
                  </div>
                  
                  <div class="new-feature">
                      <h3>🎉 Novidades da Versão 2.0:</h3>
                      <ul>
                          <li>✅ Novo design visual com gradiente</li>
                          <li>✅ Badge de versão destacado</li>
                          <li>✅ Layout melhorado</li>
                          <li>✅ Demonstração de atualização imutável</li>
                      </ul>
                  </div>
                  
                  <hr>
                  <p>✅ Nginx instalado via Ansible</p>
                  <p>✅ Imagem criada pelo Packer (V2)</p>
                  <p>✅ Instância provisionada pelo Terraform</p>
                  <p>✅ Infraestrutura 100% imutável</p>
                  <p>🔄 Rollback fácil para V1 a qualquer momento!</p>
                  
                  <hr>
                  <p><em>Hostname: {{ ansible_hostname }}</em></p>
                  <p><em>Build Time: {{ ansible_date_time.iso8601 }}</em></p>
                  <p><strong>Versão da Imagem: 2.0</strong></p>
              </div>
          </body>
          </html>
        dest: /var/www/html/index.html
        mode: '0644'

    - name: Garantir que o Nginx está rodando e habilitado
      systemd:
        name: nginx
        state: started
        enabled: yes

    - name: Configurar firewall para permitir HTTP
      ufw:
        rule: allow
        port: '80'
        proto: tcp
      ignore_errors: yes

    - name: Verificar status do Nginx
      command: nginx -t
      register: nginx_test
      changed_when: false

    - name: Exibir status do Nginx
      debug:
        msg: "Nginx V2 configurado com sucesso: {{ nginx_test.stdout }}"
EOF

echo "✅ Playbook Ansible atualizado para VERSÃO 2"
```

### Passo 2.2 - Validar Mudanças (1 min)

```bash
echo "🔍 Validando mudanças..."

# Mostrar diff
echo ""
echo "📊 DIFERENÇAS entre V1 e V2:"
echo "================================"
diff -u ansible/nginx.yml.v1 ansible/nginx.yml || echo "Mudanças detectadas!"

# Validar sintaxe
ansible-playbook ansible/nginx.yml --syntax-check

echo "✅ Validação concluída!"
```

### Passo 2.3 - Criar Nova Imagem (v2) (8-10 min)

```bash
echo ""
echo "🔨 Criando VERSÃO 2 da imagem..."

# Build da nova imagem
packer build -var-file=packer/variables.pkrvars.hcl packer/gce-nginx.pkr.hcl

# Listar todas as imagens
echo ""
echo "📸 Imagens disponíveis agora:"
gcloud compute images list --filter="family:nginx-immutable-family" \
  --format="table(name,family,creationTimestamp,status)" \
  --sort-by=creationTimestamp

# Anotar o nome da segunda imagem (v2)
export IMAGE_V2=$(gcloud compute images list \
  --filter="family:nginx-immutable-family" \
  --format="value(name)" \
  --sort-by=~creationTimestamp \
  --limit=1)

echo ""
echo "✅ Agora temos DUAS imagens:"
echo "   V1: $IMAGE_V1"
echo "   V2: $IMAGE_V2 (mais recente)"
```

---

## 🎬 PARTE 3: Deploy da Versão 2

### Passo 3.1 - Atualizar para v2 (3-5 min)

```bash
echo ""
echo "🚀 Fazendo deploy da VERSÃO 2..."
echo "================================"

cd terraform

# O Terraform vai buscar automaticamente a imagem mais recente da família
# Forçar recriação da instância
terraform apply -replace=google_compute_instance.nginx_server -auto-approve

# Aguardar Nginx iniciar
sleep 10

echo "✅ VERSÃO 2 DEPLOYED!"

cd ..
```

### Passo 3.2 - Validar v2 (2 min)

```bash
echo ""
echo "🌐 Acessando VERSÃO 2..."
echo "================================"

# Testar
curl -I $NGINX_IP

echo ""
echo "📄 CONTEÚDO DA VERSÃO 2:"
echo "================================"
curl $NGINX_IP | grep -i "versão"

echo ""
echo "🎯 PONTOS A DESTACAR:"
echo "- Nova imagem foi criada (V2)"
echo "- Instância antiga foi destruída"
echo "- Nova instância criada com imagem V2"
echo "- Design e conteúdo completamente diferentes"
echo "- ZERO downtime se usar load balancer"
echo "- Imagem V1 ainda existe para rollback!"

# Abrir no navegador
xdg-open $NGINX_URL 2>/dev/null || open $NGINX_URL 2>/dev/null
```

---

## 🎬 PARTE 4: Rollback para Versão 1

### Passo 4.1 - Preparar Rollback (1 min)

```bash
echo ""
echo "⚠️ SIMULANDO PROBLEMA NA V2..."
echo "Vamos fazer ROLLBACK para V1!"
echo "================================"

# Mostrar imagens disponíveis
echo ""
echo "📸 Imagens disponíveis para rollback:"
gcloud compute images list --filter="family:nginx-immutable-family" \
  --format="table(name,family,creationTimestamp)" \
  --sort-by=creationTimestamp
```

### Passo 4.2 - Executar Rollback (3-5 min)

```bash
echo ""
echo "🔄 Executando ROLLBACK para V1..."
echo "================================"

cd terraform

# Modificar temporariamente o Terraform para usar imagem específica (V1)
# Editar main.tf para usar imagem específica

# Criar versão temporária do main.tf que força uso da imagem V1
cat > main.tf.rollback << EOF
terraform {
  required_version = ">= 1.0"
  
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# Usar imagem específica (V1) em vez da mais recente
data "google_compute_image" "nginx_image" {
  name    = "$IMAGE_V1"
  project = var.project_id
}

resource "google_compute_address" "nginx_static_ip" {
  name   = "\${var.instance_name}-static-ip"
  region = var.region
}

resource "google_compute_firewall" "allow_http" {
  name    = "allow-http-nginx-demo"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["nginx-server"]
}

resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-ssh-nginx-demo"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["nginx-server"]
}

resource "google_compute_instance" "nginx_server" {
  name         = var.instance_name
  machine_type = var.machine_type
  zone         = var.zone

  tags = ["nginx-server", "immutable-infrastructure", "http-server"]

  boot_disk {
    initialize_params {
      image = data.google_compute_image.nginx_image.self_link
      size  = 20
      type  = "pd-standard"
    }
  }

  network_interface {
    network = "default"

    access_config {
      nat_ip = google_compute_address.nginx_static_ip.address
    }
  }

  metadata = {
    environment              = var.environment
    managed_by               = "terraform"
    immutable_infrastructure = "true"
    image_family             = var.image_family
    rollback                 = "true"
  }

  labels = {
    environment = var.environment
    managed_by  = "terraform"
    app         = "nginx"
    type        = "immutable"
    version     = "v1-rollback"
  }

  service_account {
    scopes = ["cloud-platform"]
  }

  lifecycle {
    create_before_destroy = true
  }
}
EOF

# Fazer backup do main.tf original
cp main.tf main.tf.backup

# Usar versão de rollback
mv main.tf.rollback main.tf

# Aplicar rollback
terraform apply -replace=google_compute_instance.nginx_server -auto-approve

# Restaurar main.tf original
mv main.tf.backup main.tf

sleep 10

echo ""
echo "✅ ROLLBACK CONCLUÍDO!"
echo "Voltamos para a VERSÃO 1"

cd ..
```

### Passo 4.3 - Validar Rollback (2 min)

```bash
echo ""
echo "🔍 Validando ROLLBACK..."
echo "================================"

# Testar
curl -I $NGINX_IP

echo ""
echo "📄 CONTEÚDO após ROLLBACK:"
echo "================================"
curl $NGINX_IP | head -30

echo ""
echo "🎯 PONTOS A DESTACAR:"
echo "- Voltamos para V1 em minutos"
echo "- Instância V2 foi destruída"
echo "- Nova instância criada com imagem V1 (antiga)"
echo "- Design original restaurado"
echo "- Ambas as imagens ainda existem!"
echo "- Podemos fazer rollback/forward a qualquer momento"

# Abrir no navegador
xdg-open $NGINX_URL 2>/dev/null || open $NGINX_URL 2>/dev/null

echo ""
echo "🎉 DEMONSTRAÇÃO COMPLETA!"
```

---

## 📊 Resumo da Demonstração

```bash
echo ""
echo "═══════════════════════════════════════"
echo "📊 RESUMO DA DEMONSTRAÇÃO"
echo "═══════════════════════════════════════"
echo ""
echo "✅ Parte 1: Deploy inicial (V1)"
echo "   - Criada imagem V1 com Packer + Ansible"
echo "   - Deployed instância V1 com Terraform"
echo "   - Página original acessível"
echo ""
echo "✅ Parte 2: Modificação e V2"
echo "   - Modificado conteúdo HTML (design novo)"
echo "   - Criada imagem V2 com Packer"
echo "   - Duas imagens agora disponíveis"
echo ""
echo "✅ Parte 3: Deploy da V2"
echo "   - Deployed nova instância com imagem V2"
echo "   - Instância V1 destruída"
echo "   - Novo design visível"
echo ""
echo "✅ Parte 4: Rollback para V1"
echo "   - Rolled back para imagem V1"
echo "   - Instância V2 destruída"
echo "   - Design original restaurado"
echo ""
echo "═══════════════════════════════════════"
echo "🎓 CONCEITOS DEMONSTRADOS:"
echo "═══════════════════════════════════════"
echo ""
echo "1. ♻️  IMUTABILIDADE"
echo "   - Servidores nunca são modificados"
echo "   - Mudanças = nova imagem"
echo ""
echo "2. 📦 VERSIONAMENTO"
echo "   - Múltiplas versões coexistem"
echo "   - Histórico completo de imagens"
echo ""
echo "3. 🔄 ROLLBACK FÁCIL"
echo "   - Voltar para qualquer versão anterior"
echo "   - Sem dependência de backups"
echo ""
echo "4. 🎯 CONFIABILIDADE"
echo "   - Mesma imagem = mesmo resultado"
echo "   - Zero configuration drift"
echo ""
echo "5. 🧪 TESTABILIDADE"
echo "   - Testar imagem antes do deploy"
echo "   - Imagem = ambiente completo"
echo ""
echo "═══════════════════════════════════════"
```

---

## 🧹 Limpeza Final

```bash
echo "🧹 Limpando recursos..."

# Destruir infraestrutura
cd terraform
terraform destroy -auto-approve
cd ..

# Listar imagens
echo ""
echo "📸 Imagens criadas durante a demo:"
gcloud compute images list --filter="family:nginx-immutable-family" \
  --format="table(name,family,creationTimestamp,diskSizeGb)"

# Deletar todas as imagens (opcional)
read -p "Deseja deletar TODAS as imagens? (s/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Ss]$ ]]; then
    gcloud compute images list \
      --filter="family:nginx-immutable-family" \
      --format="value(name)" | \
      xargs -I {} gcloud compute images delete {} --quiet
    echo "✅ Imagens deletadas"
else
    echo "ℹ️ Imagens mantidas para referência"
fi

echo ""
echo "🎉 Demo concluída! Obrigado!"
```

---

## 🎤 Scripts de Apresentação

### Script Curto (Para Públicos Técnicos)
*"Vou demonstrar infraestrutura imutável. Primeiro, criei uma imagem com Packer e Ansible contendo o Nginx. Depois deployei com Terraform. Agora modifiquei o HTML, criei uma nova imagem, e fiz deploy da v2. Veja - design completamente diferente! E se houver problema? Simples - rollback para a imagem anterior em minutos. Infraestrutura imutável significa: nunca modificar servidores, sempre criar novas versões."*

### Script Longo (Para Públicos Menos Técnicos)
*"Hoje vou mostrar um conceito importante: infraestrutura imutável. Imagine que sua aplicação seja um DVD - você não modifica o DVD, você grava um novo. Aqui está nossa v1 rodando. Agora preciso mudar algo - em vez de editar o servidor, criei uma nova 'gravação' - uma nova imagem com as mudanças. Deploy dessa v2. Viu? Completamente diferente! E se der problema? Volto para a 'gravação' anterior - a v1. Nenhuma modificação manual, tudo versionado, rollback instantâneo. É assim que se constrói sistemas confiáveis."*

---

## 💡 Dicas para a Apresentação

1. **Preparar com antecedência:**
   - Criar a imagem V1 antes da apresentação (economiza 10 min)
   - Já deixar deployed e funcionando
   - Ter os comandos em arquivos prontos

2. **Durante a demo:**
   - Mostrar o browser side-by-side com terminal
   - Explicar o que está acontecendo durante os builds
   - Destacar os timestamps das imagens

3. **Pontos chave:**
   - "Nunca SSH para fazer mudanças"
   - "Mesma imagem = mesmo resultado"
   - "Rollback em minutos, não horas"

4. **Possíveis perguntas:**
   - "E o downtime?" → Blue-Green deployment
   - "E os dados?" → Separar dados da aplicação
   - "E o custo?" → Imagens baratas, instâncias temporárias

---

**🎉 Boa sorte com sua demonstração!**

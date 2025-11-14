# Guia de Demonstração - Infraestrutura Imutável

Este guia explica como demonstrar o conceito de infraestrutura imutável alterando a versão da aplicação entre deploys.

## Como Funciona

A página Nginx exibe um **banner de versão** visual que você pode alterar facilmente entre deploys para demonstrar que uma nova imagem foi criada.

## Passo a Passo da Demonstração

### 1. Deploy Inicial (Versão 1.0)

A versão inicial já está configurada no arquivo `ansible/nginx.yml`:

```yaml
deployment_version: "v1.0"
deployment_message: "Deploy inicial - Primeira versão da aplicação"
deployment_color: "#4285f4"  # Azul
```

Execute o deploy completo:

```bash
./deploy.sh --full
```

Acesse a página e mostre:
- Banner azul com "v1.0"
- Mensagem: "Deploy inicial - Primeira versão da aplicação"

### 2. Simulando uma Atualização (Versão 2.0)

Edite o arquivo `ansible/nginx.yml` (linhas 7-9) e altere para:

```yaml
deployment_version: "v2.0"
deployment_message: "Nova funcionalidade - Sistema de monitoramento adicionado"
deployment_color: "#34a853"  # Verde
```

Recrie a imagem e faça o redeploy:

```bash
./deploy.sh --packer    # Cria nova imagem com v2.0
./deploy.sh --update    # Atualiza a instância (substitui pela nova)
```

Ou use o comando direto do Terraform:
```bash
./deploy.sh --packer
cd terraform
terraform apply -replace=google_compute_instance.nginx_server -auto-approve
```

**O que acontece:**
- Terraform detecta que a imagem mudou
- Cria uma nova instância com nome único (baseado no timestamp da imagem)
- A instância antiga permanece até a nova estar pronta (create_before_destroy)
- O IP estático é migrado automaticamente para a nova instância
- A instância antiga é destruída

Acesse a página novamente e mostre:
- Banner verde com "v2.0"
- Nova mensagem de versão
- **Build Time diferente** (prova que é uma nova imagem)
- **Nome da instância diferente** (demonstra que é uma nova VM)

### 3. Simulando um Hotfix (Versão 2.1)

Para demonstrar um hotfix rápido:

```yaml
deployment_version: "v2.1"
deployment_message: "🔥 Hotfix - Correção crítica de segurança"
deployment_color: "#ea4335"  # Vermelho
```

Execute novamente:

```bash
./deploy.sh --packer
./deploy.sh --terraform
```

## Sugestões de Versões para Demonstração

### Versão 1.0 - Deploy Inicial
```yaml
deployment_version: "v1.0"
deployment_message: "Deploy inicial - Primeira versão da aplicação"
deployment_color: "#4285f4"  # Azul
```

### Versão 2.0 - Nova Funcionalidade
```yaml
deployment_version: "v2.0"
deployment_message: "✨ Nova funcionalidade - Sistema de monitoramento"
deployment_color: "#34a853"  # Verde
```

### Versão 2.1 - Hotfix
```yaml
deployment_version: "v2.1"
deployment_message: "🔥 Hotfix - Correção crítica aplicada"
deployment_color: "#ea4335"  # Vermelho
```

### Versão 3.0 - Major Release
```yaml
deployment_version: "v3.0"
deployment_message: "🚀 Major Release - Performance melhorada em 50%"
deployment_color: "#fbbc04"  # Amarelo
```

## Pontos-Chave para Destacar na Demo

1. **Imutabilidade**: Cada mudança requer uma nova imagem (não fazemos alterações in-place)
2. **Zero Downtime**: O IP estático é mantido durante a troca de instâncias
3. **Create Before Destroy**: Nova instância é criada antes de destruir a antiga
4. **Build Time**: Sempre diferente em cada versão (mostra que é uma nova imagem)
5. **Nome Único**: Cada instância tem um nome baseado no timestamp da imagem
6. **Versionamento Visual**: Banner colorido facilita identificar qual versão está rodando
7. **Processo Automatizado**: Todo o processo é automatizado via Packer + Terraform

## Resolvendo Conflitos de Deploy

### Problema: IP já está em uso

Se você receber o erro `Error 400: External IP address is already in-use`, use uma destas opções:

### Opção 1: Usar o comando replace (Recomendado - Zero Downtime)
```bash
cd terraform
terraform apply -replace=google_compute_instance.nginx_server
cd ..
```

Este comando:
- Destrói a instância antiga primeiro
- Libera o IP
- Cria a nova instância
- Reatribui o IP

### Opção 2: Usar o script Blue-Green (Automático)
```bash
./scripts/update-instance.sh
```

### Opção 3: Destruir e recriar manualmente
```bash
./deploy.sh --destroy  # Remove tudo
./deploy.sh --terraform # Cria novamente
```

### Opção 4: Remover apenas a instância via gcloud
```bash
gcloud compute instances delete nginx-immutable-demo-TIMESTAMP --zone=us-central1-a
./deploy.sh --terraform
```

## Estratégias de Deploy

### Para Demonstração (Aceitável ter downtime)
Use a **Opção 1** ou **Opção 3** - mais simples e direto

### Para Produção (Zero Downtime)
Idealmente, use:
- Load Balancer com múltiplas instâncias
- Rolling updates
- Blue-Green deployment com DNS switching

### Configuração Atual
- Nome dinâmico baseado na imagem: `nginx-immutable-demo-TIMESTAMP`
- IP estático reutilizável
- `replace_triggered_by` para forçar recriação quando imagem muda

## Demonstrando Rollback

Para demonstrar um rollback para uma versão anterior:

1. Liste as imagens disponíveis:
```bash
./deploy.sh --list
```

2. Edite `terraform/main.tf` e altere `image_family` para usar uma imagem específica:
```hcl
boot_disk {
  initialize_params {
    image = "projects/SEU_PROJECT/global/images/nginx-immutable-TIMESTAMP"
  }
}
```

3. Aplique:
```bash
./deploy.sh --terraform
```

## Dicas para a Apresentação

- Mantenha duas janelas de terminal abertas (lado a lado)
- Tenha o browser aberto em uma tela separada
- Use F5 para atualizar a página após cada deploy
- Destaque o tempo de criação da imagem (5-10 minutos)
- Mostre os logs do Packer/Terraform durante o processo
- Compare o Build Time entre as versões

## Cores Disponíveis

- **Azul**: `#4285f4` (Google Blue - padrão)
- **Verde**: `#34a853` (sucesso/nova feature)
- **Vermelho**: `#ea4335` (urgente/hotfix)
- **Amarelo**: `#fbbc04` (atenção/major release)
- **Roxo**: `#8e44ad` (especial)
- **Laranja**: `#ff6b35` (beta/experimental)

# 📚 ÍNDICE DO PROJETO

## 🎯 Por Onde Começar?

### Se você quer...

#### 🎬 **Fazer a demonstração** → Comece aqui!
1. **[README-DEMO.md](README-DEMO.md)** - Visão geral da demo
2. **[DEMO.md](DEMO.md)** - Roteiro completo passo a passo
3. **[DEMO-CHEATSHEET.md](DEMO-CHEATSHEET.md)** - Comandos prontos para copiar/colar

#### 🚀 **Deploy rápido (sem apresentação)**
1. **[QUICKSTART.md](QUICKSTART.md)** - 5 minutos para deploy
2. Execute: `./deploy.sh --full`

#### 📖 **Entender o projeto em detalhes**
1. **[README.md](README.md)** - Documentação completa (12+ páginas)
2. **[ESTRUTURA.md](ESTRUTURA.md)** - Resumo executivo
3. **[INTEGRACAO.md](INTEGRACAO.md)** - Como tudo se integra

#### 🔧 **Referência de comandos**
1. **[COMANDOS.md](COMANDOS.md)** - Todos os comandos úteis

---

## 📂 Estrutura de Arquivos

```
📁 infraestrutura-imutavel-gcp/
│
├── 📖 DOCUMENTAÇÃO
│   ├── README.md                    ⭐ Documentação principal
│   ├── README-DEMO.md               🎬 Guia da demonstração
│   ├── INDICE.md                    📚 Este arquivo (navegação)
│   ├── QUICKSTART.md                ⚡ Início rápido (5 min)
│   ├── ESTRUTURA.md                 📊 Resumo executivo
│   ├── INTEGRACAO.md                🔗 Integração completa
│   └── COMANDOS.md                  💻 Referência de comandos
│
├── 🎬 DEMONSTRAÇÃO
│   ├── DEMO.md                      📝 Roteiro completo da demo
│   ├── DEMO-CHEATSHEET.md           ⚡ Comandos rápidos
│   └── run-demo.sh                  🤖 Script automatizado
│
├── 🔧 SCRIPTS
│   ├── deploy.sh                    🚀 Deploy automático
│   └── setup-project.sh             ⚙️ Setup inicial
│
├── 📁 CÓDIGO FONTE
│   ├── ansible/                     🔧 Configuração
│   │   └── nginx.yml
│   ├── packer/                      📦 Criação de imagens
│   │   ├── gce-nginx.pkr.hcl
│   │   └── variables.pkrvars.hcl.example
│   └── terraform/                   🏗️ Infraestrutura
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── terraform.tfvars.example
│
└── 📄 OUTROS
    └── .gitignore
```

---

## 🎯 Fluxos de Uso

### 1️⃣ Primeira Vez Usando o Projeto

```
INDICE.md (você está aqui!)
    ↓
README.md (entender o projeto)
    ↓
QUICKSTART.md (deploy inicial)
    ↓
DEMO.md (fazer demonstração)
```

### 2️⃣ Preparar Apresentação

```
README-DEMO.md (overview da demo)
    ↓
DEMO.md (roteiro completo)
    ↓
DEMO-CHEATSHEET.md (ter aberto durante demo)
    ↓
Executar demo!
```

### 3️⃣ Uso Diário / Referência

```
COMANDOS.md
    ↓
Copiar comando necessário
    ↓
Executar
```

---

## 📋 Descrição Detalhada dos Arquivos

### 📖 Documentação

| Arquivo | Descrição | Quando Usar |
|---------|-----------|-------------|
| **README.md** | Documentação técnica completa<br>12+ páginas com tudo sobre o projeto | Primeira leitura<br>Entender conceitos<br>Referência completa |
| **README-DEMO.md** | Guia específico para demonstração<br>3 formas de fazer a demo | Antes de apresentar<br>Decidir formato da demo |
| **INDICE.md** | Este arquivo - índice de navegação | Sempre que estiver perdido |
| **QUICKSTART.md** | Guia de 5 minutos para começar | Deploy rápido<br>Teste inicial |
| **ESTRUTURA.md** | Resumo executivo do projeto | Overview rápido<br>Apresentação executiva |
| **INTEGRACAO.md** | Como Packer+Ansible+Terraform se integram | Entender fluxo completo<br>Debug de problemas |
| **COMANDOS.md** | Referência de todos os comandos<br>Packer, Terraform, Ansible, gcloud | Dia a dia<br>Lookup rápido |

### 🎬 Demonstração

| Arquivo | Descrição | Quando Usar |
|---------|-----------|-------------|
| **DEMO.md** | Roteiro completo da demonstração<br>Passo a passo detalhado<br>Talking points incluídos | Fazer apresentação<br>Seguir roteiro completo |
| **DEMO-CHEATSHEET.md** | Comandos prontos para copiar/colar<br>Divididos por parte da demo | Durante a demo<br>Referência rápida |
| **run-demo.sh** | Script automatizado que executa toda a demo | Demo automática<br>Teste completo |

### 🔧 Scripts

| Arquivo | Descrição | Quando Usar |
|---------|-----------|-------------|
| **deploy.sh** | Menu interativo para deploy<br>Validação automática | Deploy diário<br>Gestão do projeto |
| **setup-project.sh** | Cria estrutura do zero | Setup inicial<br>Recriar projeto |

### 📁 Código Fonte

| Diretório/Arquivo | Descrição |
|-------------------|-----------|
| **ansible/nginx.yml** | Playbook para instalar e configurar Nginx |
| **packer/gce-nginx.pkr.hcl** | Template para criar imagem GCE |
| **packer/variables.pkrvars.hcl.example** | Exemplo de variáveis do Packer |
| **terraform/main.tf** | Recursos principais (instância, firewall, IP) |
| **terraform/variables.tf** | Definição de variáveis |
| **terraform/outputs.tf** | Outputs (IP, URL, comandos SSH) |
| **terraform/terraform.tfvars.example** | Exemplo de variáveis do Terraform |

---

## 🎓 Cenários de Uso

### Cenário 1: "Nunca usei, quero aprender"
```
1. Leia: README.md
2. Execute: QUICKSTART.md
3. Estude: INTEGRACAO.md
4. Pratique: Modifique os arquivos
```

### Cenário 2: "Preciso fazer demo amanhã"
```
1. Leia: README-DEMO.md
2. Teste hoje: DEMO.md (roteiro completo)
3. Amanhã use: DEMO-CHEATSHEET.md
```

### Cenário 3: "Quero adaptar para meu projeto"
```
1. Entenda: README.md + ESTRUTURA.md
2. Modifique: ansible/nginx.yml (sua app)
3. Ajuste: packer/*.pkr.hcl (suas configs)
4. Customize: terraform/*.tf (sua infra)
```

### Cenário 4: "Algo deu errado"
```
1. Consulte: COMANDOS.md (troubleshooting)
2. Confira: INTEGRACAO.md (fluxo correto)
3. Debug: Executar comandos um a um
```

---

## 💡 Dicas de Navegação

### Atalhos Mentais

🎬 **"Como fazer demo?"** → README-DEMO.md  
⚡ **"Deploy rápido?"** → QUICKSTART.md  
📖 **"Entender tudo?"** → README.md  
💻 **"Que comando usar?"** → COMANDOS.md  
🤔 **"Como funciona?"** → INTEGRACAO.md  
📊 **"Apresentar para chefe?"** → ESTRUTURA.md  

### Ordem de Leitura Sugerida

**Para Iniciantes:**
```
1. README.md (conceitos)
2. QUICKSTART.md (prática)
3. DEMO.md (demonstração)
```

**Para Experts:**
```
1. ESTRUTURA.md (overview)
2. INTEGRACAO.md (detalhes técnicos)
3. COMANDOS.md (referência)
```

---

## 📞 Você Quer...

| Objetivo | Arquivo(s) |
|----------|------------|
| 🎬 **Fazer uma demo agora** | README-DEMO.md → DEMO-CHEATSHEET.md |
| 📖 **Entender o projeto** | README.md |
| ⚡ **Deploy em 5 min** | QUICKSTART.md |
| 🎓 **Aprender conceitos** | README.md + ESTRUTURA.md |
| 🔧 **Ver um comando** | COMANDOS.md |
| 🐛 **Resolver erro** | COMANDOS.md (troubleshooting) + INTEGRACAO.md |
| 📊 **Apresentar para time** | ESTRUTURA.md + DEMO.md |
| 🤖 **Automatizar tudo** | run-demo.sh ou deploy.sh |
| 🔄 **Modificar e adaptar** | Todos os arquivos em ansible/, packer/, terraform/ |

---

## ✅ Próximos Passos

Agora que você entende a estrutura:

1. **Escolha seu objetivo** (demo, deploy, aprendizado)
2. **Siga o arquivo correspondente** (veja tabela acima)
3. **Execute** os comandos
4. **Customize** para suas necessidades

---

## 🎉 Você está pronto!

Escolha um arquivo acima e comece. Tudo está documentado e testado.

**Boa sorte! 🚀**

---

*💡 Dica: Marque este arquivo (INDICE.md) nos favoritos para navegação rápida!*

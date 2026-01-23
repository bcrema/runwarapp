# CI/CD Setup Guide

Este documento explica como configurar o pipeline CI/CD para o frontend.

## Pipeline Overview

O pipeline é acionado automaticamente em commits no branch `master` que modifiquem arquivos em `frontend/`.

### Jobs

1. **Test & Lint** - Executa lint e testes unitários
2. **Deploy** - Build da imagem Docker e deploy no GCP Cloud Run (só executa se os testes passarem)

## Configuração dos Secrets no GitHub

Vá em **Settings → Secrets and variables → Actions** no seu repositório e adicione os seguintes secrets:

### 1. `GCP_PROJECT_ID`
O ID do seu projeto no Google Cloud.

```bash
# Para descobrir o ID do projeto:
gcloud config get-value project
```

### 2. `GCP_SA_KEY`
Chave JSON de uma Service Account com permissões para deploy.

#### Criar Service Account:

```bash
# Definir variáveis
PROJECT_ID=$(gcloud config get-value project)
SA_NAME="github-actions"
SA_EMAIL="$SA_NAME@$PROJECT_ID.iam.gserviceaccount.com"

# Criar Service Account
gcloud iam service-accounts create $SA_NAME \
    --display-name="GitHub Actions CI/CD"

# Conceder permissões necessárias
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$SA_EMAIL" \
    --role="roles/run.admin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$SA_EMAIL" \
    --role="roles/storage.admin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$SA_EMAIL" \
    --role="roles/artifactregistry.writer"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$SA_EMAIL" \
    --role="roles/iam.serviceAccountUser"

# Gerar chave JSON
gcloud iam service-accounts keys create ~/github-actions-key.json \
    --iam-account=$SA_EMAIL

# Exibir o conteúdo para copiar ao GitHub
cat ~/github-actions-key.json
```

Copie todo o conteúdo JSON e cole no secret `GCP_SA_KEY`.

> ⚠️ **Importante**: Delete o arquivo de chave local após copiar:
> ```bash
> rm ~/github-actions-key.json
> ```

### 3. `MAPBOX_TOKEN`
Seu token público do Mapbox (o mesmo usado no `.env.local`).

## Testando o Pipeline

Após configurar os secrets, faça um commit em `master` que modifique algo em `frontend/`:

```bash
cd frontend
echo "// trigger ci" >> src/app/page.tsx
git add .
git commit -m "test: trigger CI/CD pipeline"
git push origin master
```

Acompanhe a execução em **Actions** no GitHub.

## Estrutura do Workflow

```
.github/
└── workflows/
    └── frontend-ci-cd.yml    # Pipeline do frontend
```

## Troubleshooting

### Erro de autenticação GCP
- Verifique se o secret `GCP_SA_KEY` contém o JSON completo
- Confirme que a Service Account tem as permissões corretas

### Erro de push para Artifact Registry
- Verifique se o Artifact Registry está habilitado:
  ```bash
  gcloud services enable artifactregistry.googleapis.com
  ```

### Testes falhando
- Execute localmente para verificar:
  ```bash
  cd frontend
  npm ci
  npm run lint
  npm run test
  ```

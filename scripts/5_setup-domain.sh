#!/bin/bash
set -euo pipefail

# Configurações (pode sobrescrever via env)
PROJECT_ID="${PROJECT_ID:-$(gcloud config get-value project)}"
REGION="${REGION:-us-central1}"
FRONTEND_SERVICE="${FRONTEND_SERVICE:-runwar-frontend}"
DOMAIN="${DOMAIN:-ligarun.com}"           # domínio raiz comprado na Cloudflare
WWW_DOMAIN="${WWW_DOMAIN:-www.$DOMAIN}"   # subdomínio opcional para o frontend

echo "Projeto.............: $PROJECT_ID"
echo "Região..............: $REGION"
echo "Serviço frontend....: $FRONTEND_SERVICE"
echo "Domínio raiz........: $DOMAIN"
echo "Domínio www.........: $WWW_DOMAIN"
echo
echo "Pré-requisitos:"
echo "- Domínio verificado no GCP (Search Console)."
echo "- gcloud autenticado com acesso ao projeto."
echo

map_domain() {
  local service="$1"
  local domain="$2"

  echo "------------------------------------------------------------"
  echo "Mapeando domínio '$domain' para serviço '$service'"
  echo "------------------------------------------------------------"

  if gcloud beta run domain-mappings describe --domain "$domain" --region "$REGION" --project "$PROJECT_ID" >/dev/null 2>&1; then
    echo "Domain mapping já existe, mantendo."
  else
    gcloud beta run domain-mappings create \
      --service "$service" \
      --domain "$domain" \
      --region "$REGION" \
      --project "$PROJECT_ID"
  fi

  echo "DNS a configurar na Cloudflare:"
  gcloud beta run domain-mappings describe \
    --domain "$domain" \
    --region "$REGION" \
    --project "$PROJECT_ID" \
    --format="table(status.resourceRecords[].type,status.resourceRecords[].name,status.resourceRecords[].rrdata)"

  local url
  url=$(gcloud run services describe "$service" --platform managed --region "$REGION" --project "$PROJECT_ID" --format='value(status.url)')
  echo "Service URL (origem Cloud Run): $url"
  echo
}

map_domain "$FRONTEND_SERVICE" "$DOMAIN"

# Mapear www apenas se for diferente do raiz
if [[ "$WWW_DOMAIN" != "$DOMAIN" ]]; then
  map_domain "$FRONTEND_SERVICE" "$WWW_DOMAIN"
fi

echo "Pronto. Adicione os registros DNS acima na Cloudflare (desative proxy laranja para finalizar a verificação inicial)."

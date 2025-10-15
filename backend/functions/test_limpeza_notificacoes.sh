#!/bin/bash

# Script para testar a limpeza automática de notificações
# Execute: bash test_limpeza_notificacoes.sh

echo "🧹 Testando limpeza automática de notificações..."
echo "URL da função: https://us-central1-coisarapida-4d39b.cloudfunctions.net/limparNotificacoesAntigas"
echo ""

# Fazer requisição POST para a função
curl -X POST https://us-central1-coisarapida-4d39b.cloudfunctions.net/limparNotificacoesAntigas \
  -H "Content-Type: application/json" \
  -d '{}' \
  -w "\nStatus Code: %{http_code}\n"

echo ""
echo "✅ Teste concluído!"
echo ""
echo "📋 Para configurar limpeza automática diária:"
echo "1. Use um serviço de cron jobs (como cron-job.org)"
echo "2. Configure para chamar a URL acima diariamente às 2:00 AM"
echo "3. Método: POST"
echo "4. Sem corpo na requisição"

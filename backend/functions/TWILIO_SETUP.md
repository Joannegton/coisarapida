# Configuração do Twilio para Verificação de Telefone

## 1. Conta Twilio
1. Acesse [Twilio Console](https://console.twilio.com/)
2. Copie o **Account SID** e **Auth Token** da dashboard

## 2. Serviço Verify
1. Vá para [Verify Services](https://console.twilio.com/us1/develop/verify/services)
2. Clique em "Create new Verify Service"
3. Configure:
   - **Friendly Name**: "Coisa Rápida - Verificação de Telefone"
   - **Code Length**: 6 digits
   - Deixe outras configurações padrão
4. Copie o **Service SID**

## 3. Configuração Local (.env.local)
```bash
TWILIO_ACCOUNT_SID=ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
TWILIO_AUTH_TOKEN=your_auth_token_here
TWILIO_VERIFY_SERVICE_SID=VAxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

## 4. Configuração Firebase (Produção)
```bash
# Configurar via Firebase CLI
firebase functions:config:set \
  twilio.account_sid="ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" \
  twilio.auth_token="your_auth_token_here" \
  twilio.verify_service_sid="VAxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"

# Ou via Firebase Console:
# 1. Acesse https://console.firebase.google.com/
# 2. Selecione seu projeto
# 3. Functions > Configuration
# 4. Adicione as variáveis de ambiente
```

## 5. Teste
```bash
# Instalar dependências
npm install

# Testar localmente
firebase emulators:start --only functions

# Deploy para produção
firebase deploy --only functions
```

## 6. Custos Twilio
- **Verificação SMS**: ~$0.05 por SMS no Brasil
- **Criação de Serviço**: Gratuito
- Consulte [preços Twilio](https://www.twilio.com/pricing) para detalhes

## 7. Segurança
- Nunca commite chaves reais no código
- Use variáveis de ambiente sempre
- Monitore uso no Twilio Console

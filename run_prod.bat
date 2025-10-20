@echo off
REM Script para executar o app em modo produção/teste
REM Carrega automaticamente as variáveis do arquivo .env

echo 🚀 Iniciando CoisaRápida - Produção/Teste
echo.

REM Verificar se .env existe
if not exist ".env" (
    echo ❌ Arquivo .env não encontrado!
    echo 📝 Copie .env.example para .env e configure suas chaves.
    pause
    exit /b 1
)

REM Ler variáveis do .env
for /f "tokens=1,2 delims==" %%a in (.env) do (
    if "%%a"=="GOOGLE_MAPS_API_KEY" set GOOGLE_MAPS_API_KEY=%%b
    if "%%a"=="API_BASE_URL_DEV" set API_BASE_URL_DEV=%%b
    if "%%a"=="API_BASE_URL_PROD" set API_BASE_URL_PROD=%%b
    if "%%a"=="ENVIRONMENT" set ENVIRONMENT=prod
    if "%%a"=="ENABLE_DETAILED_LOGS" set ENABLE_DETAILED_LOGS=%%b
)

echo 📍 Ambiente: Produção
echo 🌐 API URL: %API_BASE_URL_PROD%
echo 🗺️  Google Maps: Configurado
echo.

REM Executar Flutter com as variáveis definidas (modo produção)
flutter run --release ^
    --dart-define=GOOGLE_MAPS_API_KEY=%GOOGLE_MAPS_API_KEY% ^
    --dart-define=API_BASE_URL_DEV=%API_BASE_URL_DEV% ^
    --dart-define=API_BASE_URL_PROD=%API_BASE_URL_PROD% ^
    --dart-define=ENVIRONMENT=prod ^
    --dart-define=ENABLE_DETAILED_LOGS=false
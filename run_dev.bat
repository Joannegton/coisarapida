@echo off
REM Script para executar o app em modo desenvolvimento
REM Carrega automaticamente as variáveis do arquivo .env

echo 🚀 Iniciando CoisaRápida - Desenvolvimento
echo.

REM Verificar se .env existe
if not exist ".env" (
    echo ❌ Arquivo .env não encontrado!
    echo 📝 Copie .env.example para .env e configure suas chaves.
    pause
    exit /b 1
)

REM Ler variáveis do .env e executar flutter run
for /f "tokens=1,2 delims==" %%a in (.env) do (
    if "%%a"=="MELHOR_ENVIO_BASE_URL" set MELHOR_ENVIO_BASE_URL=%%b
    if "%%a"=="MELHOR_ENVIO_ACCESS_TOKEN" set MELHOR_ENVIO_ACCESS_TOKEN=%%b
    if "%%a"=="API_BASE_URL_DEV" set API_BASE_URL_DEV=%%b
    if "%%a"=="API_BASE_URL_PROD" set API_BASE_URL_PROD=%%b
    if "%%a"=="ENVIRONMENT" set ENVIRONMENT=%%b
    if "%%a"=="ENABLE_DETAILED_LOGS" set ENABLE_DETAILED_LOGS=%%b
)

echo 📍 Ambiente: %ENVIRONMENT%
echo 🌐 API URL: %API_BASE_URL_DEV%
echo.

REM Executar Flutter com as variáveis definidas
flutter run ^
    --dart-define=MELHOR_ENVIO_BASE_URL=%MELHOR_ENVIO_BASE_URL% ^
    --dart-define=MELHOR_ENVIO_ACCESS_TOKEN=%MELHOR_ENVIO_ACCESS_TOKEN% ^
    --dart-define=API_BASE_URL_DEV=%API_BASE_URL_DEV% ^
    --dart-define=API_BASE_URL_PROD=%API_BASE_URL_PROD% ^
    --dart-define=ENVIRONMENT=%ENVIRONMENT% ^
    --dart-define=ENABLE_DETAILED_LOGS=%ENABLE_DETAILED_LOGS%
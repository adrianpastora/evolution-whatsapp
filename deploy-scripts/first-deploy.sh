#!/bin/bash

# ===========================================
# Evolution API Lite - Primer Despliegue
# ===========================================

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para imprimir mensajes
print_message() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}==========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}==========================================${NC}"
}

# Verificar si se ejecuta como usuario evolution
if [[ $USER != "evolution" ]]; then
    print_error "Este script debe ejecutarse como usuario 'evolution'"
    print_message "Ejecuta: sudo su - evolution"
    exit 1
fi

print_header "Evolution API Lite - Primer Despliegue"

# Verificar que estamos en el directorio correcto
if [[ ! -f "/opt/evolution-api-lite/docker-compose.yaml" ]]; then
    print_error "No se encontró docker-compose.yaml en /opt/evolution-api-lite"
    print_message "Asegúrate de que el script de configuración se ejecutó correctamente"
    exit 1
fi

cd /opt/evolution-api-lite

# Verificar archivo .env
if [[ ! -f ".env" ]]; then
    print_warning "No se encontró archivo .env"
    print_message "Copiando plantilla..."
    cp env-template.env .env
    print_warning "⚠️  IMPORTANTE: Edita el archivo .env con tus configuraciones"
    print_message "Ejecuta: nano .env"
    read -p "Presiona Enter cuando hayas configurado el archivo .env..."
fi

# Verificar configuración básica
print_message "Verificando configuración..."

# Verificar que las variables básicas estén configuradas
if ! grep -q "AUTHENTICATION_API_KEY=tu-api-key-super-secreta" .env; then
    print_message "✅ API Key configurada"
else
    print_warning "⚠️  API Key no configurada. Edita el archivo .env"
    exit 1
fi

if ! grep -q "SERVER_URL=http://tu-dominio.com" .env; then
    print_message "✅ URL del servidor configurada"
else
    print_warning "⚠️  URL del servidor no configurada. Edita el archivo .env"
    exit 1
fi

# Instalar dependencias
print_message "Instalando dependencias..."
npm ci --only=production

# Generar cliente Prisma
print_message "Generando cliente Prisma..."
npm run db:generate

# Ejecutar migraciones
print_message "Ejecutando migraciones de base de datos..."
npm run db:deploy

# Verificar que Docker esté funcionando
print_message "Verificando Docker..."
if ! docker info > /dev/null 2>&1; then
    print_error "Docker no está funcionando"
    print_message "Ejecuta: sudo systemctl start docker"
    exit 1
fi

# Detener servicios existentes si los hay
print_message "Deteniendo servicios existentes..."
docker-compose down || true

# Iniciar servicios
print_message "Iniciando servicios con Docker Compose..."
docker-compose up -d

# Esperar a que los servicios estén listos
print_message "Esperando a que los servicios estén listos..."
sleep 30

# Verificar que el servicio esté funcionando
print_message "Verificando que el servicio esté funcionando..."
for i in {1..10}; do
    if curl -f http://localhost:8080/ > /dev/null 2>&1; then
        print_message "✅ Servicio funcionando correctamente!"
        break
    else
        print_warning "⏳ Esperando servicio... (intento $i/10)"
        sleep 10
    fi
done

if ! curl -f http://localhost:8080/ > /dev/null 2>&1; then
    print_error "❌ El servicio no responde después de 10 intentos"
    print_message "Verificando logs..."
    docker-compose logs api
    exit 1
fi

# Verificar estado de los contenedores
print_message "Verificando estado de los contenedores..."
docker-compose ps

# Configurar monitoreo
print_message "Configurando monitoreo..."
chmod +x monitor.sh
./monitor.sh

# Configurar backup
print_message "Configurando backup..."
chmod +x backup.sh
mkdir -p backups

# Habilitar servicio systemd
print_message "Habilitando servicio systemd..."
sudo systemctl enable evolution-api-lite
sudo systemctl start evolution-api-lite

print_header "Despliegue Completado"

print_message "🎉 ¡Evolution API Lite ha sido desplegado exitosamente!"
print_message "📍 URL: $(grep SERVER_URL .env | cut -d'=' -f2)"
print_message "🔑 API Key: $(grep AUTHENTICATION_API_KEY .env | cut -d'=' -f2 | cut -c1-10)..."
print_message "🐳 Docker containers ejecutándose"
print_message "🗄️ Base de datos: PostgreSQL"
print_message "🔧 Cache: Redis"

print_message "📊 Comandos útiles:"
echo "  - Ver logs: docker-compose logs -f"
echo "  - Reiniciar: docker-compose restart"
echo "  - Detener: docker-compose down"
echo "  - Estado: sudo systemctl status evolution-api-lite"

print_message "🔍 Para verificar que todo funciona:"
echo "  curl -H 'apikey: TU_API_KEY' http://localhost:8080/instance/fetchInstances"

print_warning "⚠️  Próximos pasos:"
echo "1. Configura tu dominio y SSL si es necesario"
echo "2. Configura GitHub Secrets para despliegues automáticos"
echo "3. Configura webhooks si los necesitas"
echo "4. Revisa la documentación para más configuraciones"

print_message "🚀 ¡Tu Evolution API Lite está listo para usar!" 
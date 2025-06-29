#!/bin/bash

# ===========================================
# Evolution API Lite - Script de Configuración del Servidor
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

# Verificar si se ejecuta como root
if [[ $EUID -eq 0 ]]; then
   print_error "Este script no debe ejecutarse como root"
   exit 1
fi

print_header "Evolution API Lite - Configuración del Servidor"

# Actualizar sistema
print_message "Actualizando sistema..."
sudo apt update && sudo apt upgrade -y

# Instalar dependencias básicas
print_message "Instalando dependencias básicas..."
sudo apt install -y curl wget git unzip software-properties-common apt-transport-https ca-certificates gnupg lsb-release

# Instalar Docker
print_message "Instalando Docker..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    sudo usermod -aG docker $USER
    print_message "Docker instalado correctamente"
else
    print_message "Docker ya está instalado"
fi

# Instalar Docker Compose
print_message "Verificando Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    print_message "Docker Compose instalado correctamente"
else
    print_message "Docker Compose ya está instalado"
fi

# Instalar Node.js
print_message "Instalando Node.js..."
if ! command -v node &> /dev/null; then
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt install -y nodejs
    print_message "Node.js instalado correctamente"
else
    print_message "Node.js ya está instalado"
fi

# Instalar PostgreSQL (opcional, ya que usamos Docker)
print_message "Verificando PostgreSQL..."
if ! command -v psql &> /dev/null; then
    print_warning "PostgreSQL no está instalado localmente. Se usará la versión de Docker."
else
    print_message "PostgreSQL ya está instalado"
fi

# Crear usuario y directorio para la aplicación
print_message "Configurando usuario y directorios..."
sudo useradd -m -s /bin/bash evolution || print_message "Usuario evolution ya existe"

# Crear directorio de la aplicación
sudo mkdir -p /opt/evolution-api-lite
sudo chown evolution:evolution /opt/evolution-api-lite

# Configurar firewall
print_message "Configurando firewall..."
sudo ufw allow ssh
sudo ufw allow 8080/tcp
sudo ufw allow 5432/tcp
sudo ufw allow 6379/tcp
sudo ufw --force enable

# Crear archivo de configuración de sistema
print_message "Creando archivo de configuración de sistema..."
sudo tee /etc/systemd/system/evolution-api-lite.service > /dev/null <<EOF
[Unit]
Description=Evolution API Lite
After=network.target

[Service]
Type=simple
User=evolution
WorkingDirectory=/opt/evolution-api-lite
ExecStart=/usr/bin/docker-compose up
ExecStop=/usr/bin/docker-compose down
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Crear script de monitoreo
print_message "Creando script de monitoreo..."
sudo tee /opt/evolution-api-lite/monitor.sh > /dev/null <<EOF
#!/bin/bash

# Script de monitoreo para Evolution API Lite
LOG_FILE="/opt/evolution-api-lite/monitor.log"

log() {
    echo "\$(date '+%Y-%m-%d %H:%M:%S') - \$1" >> \$LOG_FILE
}

# Verificar si el servicio está funcionando
if ! curl -f http://localhost:8080/ > /dev/null 2>&1; then
    log "ERROR: Evolution API Lite no responde. Reiniciando..."
    cd /opt/evolution-api-lite
    docker-compose restart api
    log "Servicio reiniciado"
else
    log "INFO: Evolution API Lite funcionando correctamente"
fi

# Verificar uso de recursos
MEMORY_USAGE=\$(free | grep Mem | awk '{printf "%.2f", \$3/\$2 * 100.0}')
DISK_USAGE=\$(df / | tail -1 | awk '{print \$5}' | sed 's/%//')

if (( \$(echo "\$MEMORY_USAGE > 80" | bc -l) )); then
    log "WARNING: Uso de memoria alto: \${MEMORY_USAGE}%"
fi

if (( DISK_USAGE > 80 )); then
    log "WARNING: Uso de disco alto: \${DISK_USAGE}%"
fi
EOF

sudo chmod +x /opt/evolution-api-lite/monitor.sh
sudo chown evolution:evolution /opt/evolution-api-lite/monitor.sh

# Configurar cron job para monitoreo
print_message "Configurando monitoreo automático..."
(crontab -l 2>/dev/null; echo "*/5 * * * * /opt/evolution-api-lite/monitor.sh") | crontab -

# Crear archivo de variables de entorno de ejemplo
print_message "Creando archivo de variables de entorno de ejemplo..."
sudo tee /opt/evolution-api-lite/env-template.env > /dev/null <<EOF
# ===========================================
# Evolution API Lite - Variables de Entorno
# ===========================================

# Base de datos
DATABASE_PROVIDER=postgresql
DATABASE_CONNECTION_URI=postgresql://user:pass@localhost:5432/evolution
DATABASE_CONNECTION_CLIENT_NAME=evolution-api

# Cache
CACHE_REDIS_URI=redis://localhost:6379

# Servidor
SERVER_PORT=8080
SERVER_TYPE=http
SERVER_URL=http://tu-dominio.com

# Autenticación
AUTHENTICATION_API_KEY=tu-api-key-super-secreta

# CORS
CORS_ORIGIN=["*"]
CORS_METHODS=["GET","POST","PUT","DELETE"]
CORS_CREDENTIALS=true

# Logs
LOG_LEVEL=["ERROR","WARN","INFO"]
LOG_COLOR=true
LOG_BAILEYS=error

# Idioma
LANGUAGE=es

# Producción
PRODUCTION=true
EOF

sudo chown evolution:evolution /opt/evolution-api-lite/env-template.env

# Configurar logs
print_message "Configurando sistema de logs..."
sudo mkdir -p /var/log/evolution-api-lite
sudo chown evolution:evolution /var/log/evolution-api-lite

# Crear script de backup
print_message "Creando script de backup..."
sudo tee /opt/evolution-api-lite/backup.sh > /dev/null <<EOF
#!/bin/bash

# Script de backup para Evolution API Lite
BACKUP_DIR="/opt/evolution-api-lite/backups"
DATE=\$(date +%Y%m%d_%H%M%S)

mkdir -p \$BACKUP_DIR

# Backup de la base de datos
docker-compose exec -T postgres pg_dump -U user evolution > \$BACKUP_DIR/db_backup_\$DATE.sql

# Backup de archivos de configuración
tar -czf \$BACKUP_DIR/config_backup_\$DATE.tar.gz .env docker-compose.yaml

# Mantener solo los últimos 7 backups
find \$BACKUP_DIR -name "*.sql" -mtime +7 -delete
find \$BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete

echo "Backup completado: \$DATE"
EOF

sudo chmod +x /opt/evolution-api-lite/backup.sh
sudo chown evolution:evolution /opt/evolution-api-lite/backup.sh

# Configurar backup diario
(crontab -l 2>/dev/null; echo "0 2 * * * /opt/evolution-api-lite/backup.sh") | crontab -

# Configurar logrotate
print_message "Configurando rotación de logs..."
sudo tee /etc/logrotate.d/evolution-api-lite > /dev/null <<EOF
/var/log/evolution-api-lite/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 644 evolution evolution
    postrotate
        systemctl reload evolution-api-lite
    endscript
}
EOF

print_header "Configuración Completada"

print_message "✅ Servidor configurado correctamente!"
print_message "📁 Directorio de la aplicación: /opt/evolution-api-lite"
print_message "🐳 Docker y Docker Compose instalados"
print_message "📊 Monitoreo automático configurado (cada 5 minutos)"
print_message "💾 Backup automático configurado (diario a las 2:00 AM)"
print_message "📝 Archivo de variables de entorno: /opt/evolution-api-lite/env-template.env"

print_warning "⚠️  Pasos adicionales requeridos:"
echo "1. Copiar el archivo env-template.env a .env y configurar las variables"
echo "2. Configurar GitHub Secrets para el despliegue automático"
echo "3. Configurar dominio y SSL si es necesario"
echo "4. Reiniciar sesión para que los cambios de grupo de Docker surtan efecto"

print_message "🚀 El servidor está listo para recibir despliegues de Evolution API Lite!" 
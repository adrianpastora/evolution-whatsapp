#!/bin/bash

# Script para configurar auto-inicio de Evolution API Lite
# Ejecutar como root o con sudo

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE} $1${NC}"
    echo -e "${BLUE}================================${NC}"
}

print_header "Configurando Auto-Inicio de Evolution API Lite"

# Verificar si estamos ejecutando como root
if [ "$EUID" -ne 0 ]; then
    print_error "Este script debe ejecutarse como root o con sudo"
    exit 1
fi

# Verificar si Docker está instalado
if ! command -v docker &> /dev/null; then
    print_error "Docker no está instalado. Instala Docker primero."
    exit 1
fi

# Verificar si Docker Compose está instalado
if ! command -v docker-compose &> /dev/null; then
    print_error "Docker Compose no está instalado. Instala Docker Compose primero."
    exit 1
fi

# Obtener el directorio del proyecto
PROJECT_DIR="/home/ape/evolution-api-lite"

if [ ! -d "$PROJECT_DIR" ]; then
    print_error "El directorio del proyecto no existe: $PROJECT_DIR"
    exit 1
fi

print_message "Configurando servicio systemd para Evolution API Lite..."

# Crear archivo de servicio systemd
cat > /etc/systemd/system/evolution-api-lite.service << EOF
[Unit]
Description=Evolution API Lite Docker Compose
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=$PROJECT_DIR
ExecStart=/usr/local/bin/docker-compose up -d
ExecStop=/usr/local/bin/docker-compose down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

# Habilitar el servicio
print_message "Habilitando servicio systemd..."
systemctl daemon-reload
systemctl enable evolution-api-lite.service

# Crear script de inicio personalizado
print_message "Creando script de inicio personalizado..."
cat > /usr/local/bin/evolution-api-start.sh << 'EOF'
#!/bin/bash

# Script de inicio personalizado para Evolution API Lite
PROJECT_DIR="/home/ape/evolution-api-lite"
LOG_FILE="/var/log/evolution-api-lite/startup.log"

# Crear directorio de logs si no existe
mkdir -p /var/log/evolution-api-lite

# Función de logging
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

log "Iniciando Evolution API Lite..."

# Cambiar al directorio del proyecto
cd "$PROJECT_DIR" || {
    log "ERROR: No se pudo cambiar al directorio $PROJECT_DIR"
    exit 1
}

# Verificar que docker-compose.yml existe
if [ ! -f "docker-compose.yaml" ]; then
    log "ERROR: docker-compose.yaml no encontrado"
    exit 1
fi

# Verificar que .env existe
if [ ! -f ".env" ]; then
    log "ERROR: archivo .env no encontrado"
    exit 1
fi

# Esperar a que Docker esté listo
log "Esperando a que Docker esté listo..."
timeout=60
while [ $timeout -gt 0 ]; do
    if docker info >/dev/null 2>&1; then
        log "Docker está listo"
        break
    fi
    sleep 1
    timeout=$((timeout - 1))
done

if [ $timeout -eq 0 ]; then
    log "ERROR: Docker no está disponible después de 60 segundos"
    exit 1
fi

# Levantar servicios
log "Levantando servicios con Docker Compose..."
docker-compose up -d

# Verificar que los servicios estén funcionando
log "Verificando estado de los servicios..."
sleep 10

if docker-compose ps | grep -q "Up"; then
    log "SUCCESS: Evolution API Lite iniciado correctamente"
else
    log "ERROR: Algunos servicios no están funcionando"
    docker-compose ps >> "$LOG_FILE" 2>&1
    exit 1
fi

log "Inicio completado"
EOF

# Hacer el script ejecutable
chmod +x /usr/local/bin/evolution-api-start.sh

# Actualizar el servicio systemd para usar el script personalizado
cat > /etc/systemd/system/evolution-api-lite.service << EOF
[Unit]
Description=Evolution API Lite Docker Compose
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/local/bin/evolution-api-start.sh
ExecStop=/usr/local/bin/docker-compose -f $PROJECT_DIR/docker-compose.yaml down
TimeoutStartSec=300

[Install]
WantedBy=multi-user.target
EOF

# Recargar systemd y habilitar el servicio
systemctl daemon-reload
systemctl enable evolution-api-lite.service

# Crear script de monitoreo
print_message "Creando script de monitoreo..."
cat > /usr/local/bin/evolution-api-monitor.sh << 'EOF'
#!/bin/bash

# Script de monitoreo para Evolution API Lite
PROJECT_DIR="/home/ape/evolution-api-lite"
LOG_FILE="/var/log/evolution-api-lite/monitor.log"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Verificar si los contenedores están ejecutándose
cd "$PROJECT_DIR" || exit 1

if ! docker-compose ps | grep -q "Up"; then
    log "WARNING: Servicios no están ejecutándose, reiniciando..."
    docker-compose up -d
    log "Servicios reiniciados"
fi

# Verificar salud de la API
if curl -f http://localhost:3016/ >/dev/null 2>&1; then
    log "API funcionando correctamente"
else
    log "WARNING: API no responde, reiniciando..."
    docker-compose restart api
fi
EOF

chmod +x /usr/local/bin/evolution-api-monitor.sh

# Configurar cron job para monitoreo cada 5 minutos
print_message "Configurando monitoreo automático..."
(crontab -l 2>/dev/null; echo "*/5 * * * * /usr/local/bin/evolution-api-monitor.sh") | crontab -

# Configurar logrotate para los logs
print_message "Configurando rotación de logs..."
cat > /etc/logrotate.d/evolution-api-lite << EOF
/var/log/evolution-api-lite/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 644 root root
}
EOF

print_header "Configuración Completada"

print_message "✅ Auto-inicio configurado correctamente!"
print_message "📁 Directorio del proyecto: $PROJECT_DIR"
print_message "📋 Servicio systemd: evolution-api-lite.service"
print_message "📊 Logs: /var/log/evolution-api-lite/"
print_message "🔍 Monitoreo: Cada 5 minutos"

print_message "Comandos útiles:"
echo "  systemctl start evolution-api-lite    # Iniciar manualmente"
echo "  systemctl stop evolution-api-lite     # Detener manualmente"
echo "  systemctl status evolution-api-lite   # Ver estado"
echo "  journalctl -u evolution-api-lite -f   # Ver logs en tiempo real"

print_warning "Reinicia el servidor para probar el auto-inicio:"
echo "  sudo reboot"

print_message "El servicio se iniciará automáticamente después del reinicio." 
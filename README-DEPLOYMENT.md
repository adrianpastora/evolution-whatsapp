# Guía de Despliegue - Evolution API Lite

Esta guía te ayudará a configurar el despliegue automático de Evolution API Lite en tu servidor usando GitHub Actions.

## 📋 Prerrequisitos

### En tu servidor:
- Ubuntu 20.04+ o similar
- Acceso SSH con clave privada
- Usuario con permisos sudo
- Dominio configurado (opcional pero recomendado)

### En GitHub:
- Repositorio con el código de Evolution API Lite
- Acceso a GitHub Secrets

## 🚀 Configuración del Servidor

### 1. Ejecutar script de configuración

```bash
# Conectar a tu servidor
ssh usuario@tu-servidor.com

# Descargar y ejecutar el script de configuración
curl -fsSL https://raw.githubusercontent.com/tu-usuario/evolution-api-lite/main/deploy-scripts/setup-server.sh | sudo bash
```

O manualmente:

```bash
# Clonar el repositorio
git clone https://github.com/tu-usuario/evolution-api-lite.git
cd evolution-api-lite

# Ejecutar script de configuración
sudo chmod +x deploy-scripts/setup-server.sh
sudo ./deploy-scripts/setup-server.sh
```

### 2. Configurar variables de entorno

```bash
# Copiar plantilla de variables de entorno
sudo cp deploy-scripts/env-template.env /opt/evolution-api-lite/.env

# Editar variables de entorno
sudo nano /opt/evolution-api-lite/.env
```

**Variables importantes a configurar:**

```bash
# URL de tu servidor
SERVER_URL=https://tu-dominio.com

# Base de datos PostgreSQL
DATABASE_CONNECTION_URI=postgresql://usuario:password@localhost:5432/evolution

# Redis
CACHE_REDIS_URI=redis://localhost:6379

# API Key (generar una clave segura)
AUTHENTICATION_API_KEY=tu-api-key-super-secreta
```

### 3. Configurar base de datos

```bash
# Conectar como usuario evolution
sudo su - evolution

# Navegar al directorio de la aplicación
cd /opt/evolution-api-lite

# Generar cliente Prisma
npm run db:generate

# Ejecutar migraciones
npm run db:deploy
```

## 🔧 Configuración de GitHub Secrets

Ve a tu repositorio en GitHub → Settings → Secrets and variables → Actions

### Secrets requeridos:

| Secret | Descripción | Ejemplo |
|--------|-------------|---------|
| `SERVER_HOST` | IP o dominio del servidor | `192.168.1.100` o `tu-servidor.com` |
| `SERVER_USERNAME` | Usuario SSH | `evolution` |
| `SERVER_SSH_KEY` | Clave privada SSH | Contenido de `~/.ssh/id_rsa` |
| `SERVER_PORT` | Puerto SSH | `22` |
| `DATABASE_CONNECTION_URI` | URI de conexión a PostgreSQL | `postgresql://usuario:password@localhost:5432/evolution` |
| `CACHE_REDIS_URI` | URI de conexión a Redis | `redis://localhost:6379` |
| `API_KEY` | API Key para autenticación | `tu-api-key-super-secreta` |
| `SERVER_URL` | URL pública del servidor | `https://tu-dominio.com` |

### Cómo generar la clave SSH:

```bash
# En tu máquina local
ssh-keygen -t rsa -b 4096 -C "github-actions@tu-dominio.com"

# Copiar la clave pública al servidor
ssh-copy-id -i ~/.ssh/id_rsa.pub evolution@tu-servidor.com

# Copiar la clave privada a GitHub Secrets
cat ~/.ssh/id_rsa
```

## 📦 Workflows de GitHub Actions

### Workflow Principal (`deploy.yml`)

Este workflow:
1. Ejecuta tests con PostgreSQL y Redis
2. Construye la aplicación
3. Despliega en el servidor usando SSH

### Workflow Docker (`docker-deploy.yml`)

Este workflow:
1. Ejecuta tests
2. Construye y empaqueta la aplicación
3. Despliega usando Docker Compose

## 🔄 Proceso de Despliegue

### Despliegue automático:
1. Haz push a la rama `main` o `master`
2. GitHub Actions ejecutará automáticamente el workflow
3. El código se desplegará en tu servidor

### Despliegue manual:
```bash
# En GitHub: Actions → Deploy Evolution API Lite → Run workflow
```

## 📊 Monitoreo y Logs

### Verificar estado del servicio:
```bash
# Verificar estado del servicio
sudo systemctl status evolution-api-lite

# Ver logs en tiempo real
sudo journalctl -u evolution-api-lite -f

# Ver logs de la aplicación
tail -f /opt/evolution-api-lite/logs/*.log
```

### Monitoreo automático:
- El script de configuración instala un monitor que se ejecuta cada 5 minutos
- Verifica que el servicio esté funcionando
- Reinicia automáticamente si es necesario
- Monitorea uso de recursos

### Logs de Docker:
```bash
# Ver logs de todos los contenedores
docker-compose logs

# Ver logs de un servicio específico
docker-compose logs api
docker-compose logs postgres
docker-compose logs redis
```

## 🔧 Comandos útiles

### Gestión del servicio:
```bash
# Iniciar servicio
sudo systemctl start evolution-api-lite

# Detener servicio
sudo systemctl stop evolution-api-lite

# Reiniciar servicio
sudo systemctl restart evolution-api-lite

# Ver estado
sudo systemctl status evolution-api-lite
```

### Gestión de Docker:
```bash
# Ver contenedores
docker ps

# Ver logs
docker-compose logs -f

# Reiniciar servicios
docker-compose restart

# Detener todos los servicios
docker-compose down

# Iniciar servicios
docker-compose up -d
```

### Base de datos:
```bash
# Conectar a PostgreSQL
sudo -u postgres psql evolution

# Verificar conexión
psql -h localhost -U usuario -d evolution

# Backup de la base de datos
pg_dump -h localhost -U usuario evolution > backup.sql

# Restaurar backup
psql -h localhost -U usuario evolution < backup.sql
```

## 🚨 Solución de problemas

### El servicio no inicia:
```bash
# Verificar logs del sistema
sudo journalctl -u evolution-api-lite -n 50

# Verificar configuración
sudo systemctl status evolution-api-lite

# Verificar puertos
sudo netstat -tlnp | grep :8080
```

### Problemas de base de datos:
```bash
# Verificar conexión a PostgreSQL
sudo -u postgres psql -c "\l"

# Verificar migraciones
cd /opt/evolution-api-lite
npm run db:deploy

# Regenerar cliente Prisma
npm run db:generate
```

### Problemas de Redis:
```bash
# Verificar estado de Redis
sudo systemctl status redis

# Conectar a Redis
redis-cli ping

# Ver logs de Redis
sudo journalctl -u redis -f
```

### Problemas de red:
```bash
# Verificar firewall
sudo ufw status

# Verificar puertos abiertos
sudo netstat -tlnp

# Verificar conectividad
curl -f http://localhost:8080/
```

## 📈 Escalabilidad

### Para múltiples instancias:
1. Usar un load balancer (nginx, haproxy)
2. Configurar múltiples servidores
3. Usar una base de datos compartida
4. Configurar Redis cluster

### Para alta disponibilidad:
1. Configurar backup automático de la base de datos
2. Usar un sistema de monitoreo (Prometheus, Grafana)
3. Configurar alertas
4. Implementar health checks

## 🔒 Seguridad

### Recomendaciones:
1. Cambiar puertos por defecto
2. Usar HTTPS con certificados SSL
3. Configurar firewall restrictivo
4. Usar API keys seguras
5. Mantener el sistema actualizado
6. Configurar backup automático

### Configuración de SSL:
```bash
# Instalar Certbot
sudo apt-get install certbot

# Obtener certificado SSL
sudo certbot certonly --standalone -d tu-dominio.com

# Configurar nginx con SSL
sudo nano /etc/nginx/sites-available/evolution-api-lite
```

## 📞 Soporte

Si tienes problemas:
1. Revisar logs del sistema
2. Verificar configuración de variables de entorno
3. Comprobar conectividad de red
4. Verificar estado de servicios dependientes
5. Revisar documentación oficial de Evolution API

## 🔄 Actualizaciones

Para actualizar la aplicación:
1. Hacer push de los cambios a la rama principal
2. GitHub Actions ejecutará automáticamente el despliegue
3. El servicio se reiniciará automáticamente

Para actualizaciones manuales:
```bash
cd /opt/evolution-api-lite
git pull origin main
npm install
npm run build
sudo systemctl restart evolution-api-lite
``` 
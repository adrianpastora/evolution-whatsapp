# 🚀 Guía de Despliegue - Evolution API Lite

Esta guía te ayudará a configurar y desplegar **Evolution API Lite** en tu servidor usando Docker y GitHub Actions.

## 📋 Prerrequisitos

### En tu servidor:
- **Ubuntu 20.04+** o distribución Linux similar
- **Acceso SSH** con clave privada
- **Usuario con permisos sudo**
- **Dominio configurado** (opcional pero recomendado)
- **Mínimo 2GB RAM** y **20GB espacio en disco**

### En GitHub:
- **Repositorio** con el código de Evolution API Lite
- **Acceso a GitHub Secrets**

## 🛠️ Configuración del Servidor

### 1. Ejecutar script de configuración automática

```bash
# Conectar a tu servidor
ssh usuario@tu-servidor.com

# Descargar y ejecutar el script de configuración
curl -fsSL https://raw.githubusercontent.com/tu-usuario/evolution-api-lite/main/deploy-scripts/setup-server.sh | bash
```

**O manualmente:**

```bash
# Clonar el repositorio
git clone https://github.com/tu-usuario/evolution-api-lite.git
cd evolution-api-lite

# Ejecutar script de configuración
chmod +x deploy-scripts/setup-server.sh
./deploy-scripts/setup-server.sh
```

### 2. Configurar variables de entorno

```bash
# Copiar plantilla de variables de entorno
sudo cp /opt/evolution-api-lite/env-template.env /opt/evolution-api-lite/.env

# Editar variables de entorno
sudo nano /opt/evolution-api-lite/.env
```

**Variables importantes a configurar:**

```bash
# URL de tu servidor
SERVER_URL=https://tu-dominio.com

# Base de datos PostgreSQL
DATABASE_CONNECTION_URI=postgresql://user:pass@localhost:5432/evolution

# Redis
CACHE_REDIS_URI=redis://localhost:6379

# API Key (generar una clave segura)
AUTHENTICATION_API_KEY=tu-api-key-super-secreta
```

### 3. Generar clave SSH para GitHub Actions

```bash
# En tu máquina local
ssh-keygen -t rsa -b 4096 -C "github-actions@tu-dominio.com"

# Copiar la clave pública al servidor
ssh-copy-id -i ~/.ssh/id_rsa.pub usuario@tu-servidor.com

# Copiar la clave privada a GitHub Secrets
cat ~/.ssh/id_rsa
```

## 🔧 Configuración de GitHub Secrets

Ve a tu repositorio en GitHub → **Settings** → **Secrets and variables** → **Actions**

### Secrets requeridos:

| Secret | Descripción | Ejemplo |
|--------|-------------|---------|
| `SERVER_HOST` | IP o dominio del servidor | `192.168.1.100` o `tu-servidor.com` |
| `SERVER_USERNAME` | Usuario SSH | `evolution` |
| `SERVER_SSH_KEY` | Clave privada SSH | Contenido de `~/.ssh/id_rsa` |
| `SERVER_PORT` | Puerto SSH | `22` |
| `DATABASE_CONNECTION_URI` | URI de conexión a PostgreSQL | `postgresql://user:pass@localhost:5432/evolution` |
| `CACHE_REDIS_URI` | URI de conexión a Redis | `redis://localhost:6379` |
| `API_KEY` | API Key para autenticación | `tu-api-key-super-secreta` |
| `SERVER_URL` | URL pública del servidor | `https://tu-dominio.com` |

## 🔄 Proceso de Despliegue

### Despliegue automático:
1. **Haz push** a la rama `main` o `master`
2. **GitHub Actions** ejecutará automáticamente el workflow
3. El código se **desplegará** en tu servidor

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
tail -f /opt/evolution-api-lite/monitor.log
```

### Monitoreo automático:
- **Script de monitoreo** se ejecuta cada 5 minutos
- **Verifica** que el servicio esté funcionando
- **Reinicia automáticamente** si es necesario
- **Monitorea** uso de recursos

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

### Gestión de base de datos:
```bash
# Conectar a PostgreSQL
docker-compose exec postgres psql -U user -d evolution

# Backup de la base de datos
docker-compose exec postgres pg_dump -U user evolution > backup.sql

# Restaurar backup
docker-compose exec -T postgres psql -U user -d evolution < backup.sql
```

## 🚨 Solución de problemas

### El servicio no inicia:
```bash
# Verificar logs
sudo journalctl -u evolution-api-lite -n 50

# Verificar configuración
docker-compose config

# Reiniciar Docker
sudo systemctl restart docker
```

### Problemas de conectividad:
```bash
# Verificar puertos
sudo netstat -tlnp | grep :8080

# Verificar firewall
sudo ufw status

# Verificar DNS
nslookup tu-dominio.com
```

### Problemas de base de datos:
```bash
# Verificar conexión a PostgreSQL
docker-compose exec postgres pg_isready -U user

# Verificar logs de PostgreSQL
docker-compose logs postgres

# Reiniciar PostgreSQL
docker-compose restart postgres
```

## 📈 Optimización

### Configuración de recursos:
```bash
# Ajustar límites de memoria en docker-compose.yaml
services:
  api:
    deploy:
      resources:
        limits:
          memory: 1G
        reservations:
          memory: 512M
```

### Configuración de PostgreSQL:
```bash
# Ajustar configuración en docker-compose.yaml
services:
  postgres:
    command: >
      postgres
      -c max_connections=200
      -c shared_buffers=256MB
      -c effective_cache_size=1GB
```

## 🔒 Seguridad

### Configurar SSL/HTTPS:
```bash
# Instalar Certbot
sudo apt install certbot

# Obtener certificado SSL
sudo certbot certonly --standalone -d tu-dominio.com

# Configurar nginx como proxy reverso
```

### Configurar firewall:
```bash
# Verificar reglas de firewall
sudo ufw status

# Agregar reglas adicionales si es necesario
sudo ufw allow 443/tcp  # HTTPS
sudo ufw deny 22        # Denegar SSH si usas otro puerto
```

## 📞 Soporte

Si tienes problemas con el despliegue:

1. **Revisa los logs** del servicio
2. **Verifica la configuración** de variables de entorno
3. **Comprueba la conectividad** de red
4. **Revisa los recursos** del servidor

### Enlaces útiles:
- [Documentación oficial](https://doc.evolution-api.com)
- [GitHub del proyecto](https://github.com/EvolutionAPI/evolution-api)
- [Grupo de WhatsApp](https://evolution-api.com/whatsapp)
- [Discord](https://evolution-api.com/discord)

---

**¡Tu Evolution API Lite está listo para funcionar! 🎉** 
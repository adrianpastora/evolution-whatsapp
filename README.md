<h1 align="center">Evolution API Lite</h1>

<div align="center">

[![Whatsapp Group](https://img.shields.io/badge/Group-WhatsApp-%2322BC18)](https://evolution-api.com/whatsapp)
[![Discord Community](https://img.shields.io/badge/Discord-Community-blue)](https://evolution-api.com/discord)
[![Postman Collection](https://img.shields.io/badge/Postman-Collection-orange)](https://evolution-api.com/postman) 
[![Documentation](https://img.shields.io/badge/Documentation-Official-green)](https://doc.evolution-api.com)
[![License](https://img.shields.io/badge/license-Apache--2.0-blue)](./LICENSE)
[![Sponsors](https://img.shields.io/badge/Github-sponsor-orange)](https://github.com/sponsors/EvolutionAPI)

</div>
  
<div align="center"><img src="./public/images/cover.png"></div>

## 📖 Introducción

**Evolution API Lite** es una versión ligera de Evolution API, enfocada únicamente en la conectividad sin las integraciones y características de conversión de audio. Está diseñada para ser más eficiente e ideal para entornos de microservicios donde el rendimiento y la simplicidad son clave.

## ✨ Características Principales

- **🔗 Conectividad WhatsApp**: Proporciona conectividad vía WhatsApp Web usando la biblioteca [Baileys](https://github.com/WhiskeySockets/Baileys).
- **☁️ API Oficial de WhatsApp Cloud**: Se conecta vía la API oficial de Meta para un uso más confiable y escalable.
- **🐳 Docker Ready**: Configuración completa con Docker y Docker Compose.
- **🚀 CI/CD**: Workflows de GitHub Actions para despliegue automático.
- **📊 Monitoreo**: Scripts de monitoreo y backup automáticos.
- **🗄️ Base de Datos**: Soporte para PostgreSQL y MySQL con Prisma ORM.

## 🚀 Despliegue Rápido

### Opción 1: Despliegue Automático con GitHub Actions

1. **Configura tu servidor**:
```bash
curl -fsSL https://raw.githubusercontent.com/tu-usuario/evolution-api-lite/main/deploy-scripts/setup-server.sh | bash
```

2. **Configura GitHub Secrets** (Settings → Secrets and variables → Actions):
   - `SERVER_HOST`: IP o dominio de tu servidor
   - `SERVER_USERNAME`: Usuario SSH (evolution)
   - `SERVER_SSH_KEY`: Clave privada SSH
   - `DATABASE_CONNECTION_URI`: URI de PostgreSQL
   - `CACHE_REDIS_URI`: URI de Redis
   - `API_KEY`: Tu API key secreta
   - `SERVER_URL`: URL pública del servidor

3. **Haz push a main/master** y el despliegue será automático!

### Opción 2: Despliegue Manual

```bash
# Clonar repositorio
git clone https://github.com/tu-usuario/evolution-api-lite.git
cd evolution-api-lite

# Configurar servidor
chmod +x deploy-scripts/setup-server.sh
./deploy-scripts/setup-server.sh

# Configurar variables de entorno
sudo cp /opt/evolution-api-lite/env-template.env /opt/evolution-api-lite/.env
sudo nano /opt/evolution-api-lite/.env

# Primer despliegue
sudo su - evolution
chmod +x /opt/evolution-api-lite/deploy-scripts/first-deploy.sh
/opt/evolution-api-lite/deploy-scripts/first-deploy.sh
```

### Opción 3: Docker Compose Local

```bash
# Clonar y configurar
git clone https://github.com/tu-usuario/evolution-api-lite.git
cd evolution-api-lite

# Copiar variables de entorno
cp env.example .env
# Editar .env con tus configuraciones

# Iniciar servicios
docker-compose up -d
```

## 📚 Documentación

- **[📖 Guía de Despliegue Completa](./DEPLOYMENT.md)**: Instrucciones detalladas paso a paso
- **[🔧 Configuración de Variables](./env.example)**: Todas las variables de entorno disponibles
- **[📋 README de Despliegue](./README-DEPLOYMENT.md)**: Documentación técnica avanzada

## 🛠️ Tecnologías

- **Backend**: Node.js, TypeScript, Express
- **Base de Datos**: PostgreSQL, MySQL (con Prisma ORM)
- **Cache**: Redis
- **Containerización**: Docker, Docker Compose
- **CI/CD**: GitHub Actions
- **WhatsApp**: Baileys, WhatsApp Business API

## 📊 Monitoreo y Mantenimiento

### Comandos útiles:

```bash
# Ver estado del servicio
sudo systemctl status evolution-api-lite

# Ver logs en tiempo real
docker-compose logs -f

# Reiniciar servicios
docker-compose restart

# Backup de base de datos
/opt/evolution-api-lite/backup.sh

# Monitoreo manual
/opt/evolution-api-lite/monitor.sh
```

### Monitoreo automático:
- ✅ **Health checks** cada 5 minutos
- ✅ **Backup diario** de base de datos
- ✅ **Rotación de logs** automática
- ✅ **Reinicio automático** en caso de fallo

## 🔒 Seguridad

- **API Key Authentication**: Autenticación por API key
- **CORS Configurable**: Configuración de CORS personalizable
- **Firewall**: Configuración automática de UFW
- **SSL/HTTPS**: Soporte para certificados SSL
- **Variables de Entorno**: Configuración segura de credenciales

## 🤝 Contribuir

1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## 📞 Soporte

- **📖 Documentación**: [doc.evolution-api.com](https://doc.evolution-api.com)
- **💬 WhatsApp Group**: [evolution-api.com/whatsapp](https://evolution-api.com/whatsapp)
- **🎮 Discord**: [evolution-api.com/discord](https://evolution-api.com/discord)
- **🐛 Issues**: [GitHub Issues](https://github.com/EvolutionAPI/evolution-api/issues)

## ⚠️ Aviso de Telemetría

Para mejorar continuamente nuestros servicios, hemos implementado telemetría que recopila datos sobre las rutas utilizadas, las rutas más accedidas y la versión de la API en uso. Nos gustaría asegurarle que no se recopilan datos sensibles o personales durante este proceso. La telemetría nos ayuda a identificar mejoras y proporcionar una mejor experiencia para los usuarios.

## 💝 Donar al Proyecto

#### Github Sponsors

https://github.com/sponsors/EvolutionAPI

## 📄 Licencia

Evolution API Lite está licenciado bajo la Licencia Apache 2.0. Ver [LICENSE](./LICENSE) para más detalles.

© 2024 Evolution API
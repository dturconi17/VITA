# CRM Vendedores

Sistema de gestión y análisis comercial desarrollado con Next.js, TypeScript y SQL Server.

## Funcionalidades principales

* Dashboard comercial
* Ventas por vendedor
* Ventas por supervisión
* Ventas por región
* Análisis de clientes
* Indicadores de retención
* Indicadores de stickiness
* Gestión de usuarios
* Recuperación de contraseña
* Exportación de reportes

## Tecnologías utilizadas

* Next.js 16
* React
* TypeScript
* SQL Server
* Recharts
* Docker
* GitHub

## Requisitos

* Node.js 22+
* SQL Server accesible
* npm

## Instalación local

Instalar dependencias:

```bash
npm install
```

Ejecutar en modo desarrollo:

```bash
npm run dev
```

La aplicación estará disponible en:

```text
http://localhost:3000
```

## Variables de entorno

Crear un archivo `.env.local` utilizando como referencia el archivo `.env.example`.

## Docker

Construir la imagen:

```bash
docker compose build
```

Levantar el contenedor:

```bash
docker compose up
```

Detener el contenedor:

```bash
docker compose down
```

## Estructura del proyecto

```text
app/
components/
lib/
public/
docker-compose.yml
Dockerfile
```

## Control de versiones

* main: versión estable
* develop: rama de desarrollo

## Autor

Diego Turconi

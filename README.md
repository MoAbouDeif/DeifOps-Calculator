# DeifOps-Calculator

**Full-stack Calculator App** – A production-ready calculator web application with complete DevOps integration. This repository includes:

* **CI/CD pipelines** for automated build, test, and deployment
* **Infrastructure as Code (IaC)** with Terraform to provision an **EKS (Elastic Kubernetes Service) cluster**
* **Helm charts** for EKS ELB-Ingress-Clontroller and Application deployment and management

Designed as a modern reference project combining application development with cloud-native infrastructure and DevOps best practices.

# Simple Calculator Application

![Calculator Application UI](app-ui.png)

A robust full-stack calculator app featuring a **React** frontend, **Flask** backend, **MySQL** database, and **Nginx** reverse proxy. Designed for seamless local development—no Docker or Kubernetes required. Supports basic arithmetic, persistent history, dark/light theme, and easy Nginx proxy setup.

---

## Table of Contents

1. [Features](#features)
2. [Architecture](#architecture)
3. [Project Structure](#project-structure)
4. [Prerequisites](#prerequisites)
5. [Environment Setup (`.env`) & Templates](#environment-setup-env--templates)
6. [Local Setup Guide](#local-setup-guide)
  * [1. Clone Repository](#1-clone-repository)
  * [2. Prepare `.env`](#2-prepare-env)
  * [3. Process Database Templates](#3-process-database-templates)
  * [4. Initialize Database](#4-initialize-database)
  * [5. Start Backend (Flask)](#5-start-backend-flask)
  * [6. Start Frontend (React)](#6-start-frontend-react)
  * [7. Configure & Start Nginx](#7-configure--start-nginx)
  * [8. Access the App](#8-access-the-app)
7. [Configuration Reference](#configuration-reference)
  * [Environment Variables by Component](#environment-variables-by-component)
  * [Frontend Dev vs Production](#frontend-dev-vs-production)
8. [Database Initialization Scripts](#database-initialization-scripts)
9. [Recommended Nginx Configuration](#recommended-nginx-configuration)
10. [CORS Guidance](#cors-guidance)
11. [Platform Notes](#platform-notes)
12. [Testing](#testing)
13. [Troubleshooting](#troubleshooting)
14. [Security & Production](#security--production)
15. [Contributing](#contributing)
16. [License](#license)

---

## Features

* Responsive React UI with dark/light theme toggle
* Arithmetic operations: add, subtract, multiply, divide
* Calculation history stored in MySQL with timestamps
* Nginx reverse proxy: `/` → frontend, `/api` → backend
* Optimized for local development and CI

---

## Architecture

```
User → Nginx (Proxy)
      ├── /       → Frontend (React)
      └── /api/   → Backend (Flask) → MySQL
```

Nginx unifies endpoints, allowing the frontend to call `/api/...` without cross-origin issues.

---

## Project Structure

```
calculator-app/
├── backend/         # Flask API server
│   ├── app.py
│   ├── calculator.py
│   ├── db.py
│   ├── models.py
│   ├── requirements.txt
│   └── tests/
├── database/        # DB templates & init scripts
│   ├── init-db.sh
│   ├── init.sql.template
│   └── seed.sql.template
├── frontend/        # React app
│   ├── public/
│   ├── src/
│   └── package.json
├── nginx/           # Nginx templates & helpers
│   ├── nginx.conf.template
│   └── entrypoint.sh
└── README.md
```

> `nginx/entrypoint.sh` and `database/init-db.sh` are helper scripts for local setup, using `envsubst` to process templates.

---

## Prerequisites

Install before setup:

* **Python 3.9+** (with `venv`)
* **Node.js 16+** & **npm**
* **MySQL 8.0+** (local or accessible server)
* **Nginx** (reverse proxy)
* **gettext** (`envsubst` for templates)
  * Debian/Ubuntu: `sudo apt-get install gettext`
  * macOS: `brew install gettext && brew link --force gettext`
  * Windows: use WSL/Git Bash or edit templates manually

Optional for development:

* `curl`, `jq` for API testing
* `make` (if Makefile present)

---

## Environment Setup (`.env`) & Templates

Copy and edit the example:

```bash
cp .env.example .env
```

**Sample `.env.example`**

```env
# Backend
MYSQL_HOST=localhost
MYSQL_DB=calculator_db
MYSQL_USER=calculator_user
MYSQL_PASSWORD=securepassword
SECRET_KEY=secretkey

# Frontend (dev)
REACT_APP_API_BASE_URL=/api

# Nginx
SERVER_NAME=localhost
FRONTEND_HOST=localhost
FRONTEND_PORT=3000
BACKEND_HOST=localhost
BACKEND_PORT=5000
```

**Notes:**

* `REACT_APP_...` variables are read at build time; restart/rebuild frontend after changes.
* Keep secrets out of source control—add `.env` to `.gitignore`.

---

## Local Setup Guide

Follow these steps for local development.

### 1. Clone Repository

```bash
git clone https://github.com/MoAboDaif/calculator-app.git
cd calculator-app
```

### 2. Prepare Environment

Install required tools:

```bash
./requirements.sh
```

Copy and edit `.env`:

```bash
cp .env.example .env
# Edit .env to match your environment
```

### 3. Process Database Templates

Generate SQL from templates:

```bash
cd database
./init-db.sh
# Uses envsubst to create init.sql and seed.sql
```

If `envsubst` is missing, install `gettext` or edit templates manually.

### 4. Initialize Database

With MySQL running:

```bash
mysql -u root -p < database/init.sql
mysql -u root -p < database/seed.sql  # optional
```

If not root, use an admin account or request DBA help.

### 5. Start Backend (Flask)

```bash
cd backend
python -m venv venv
source venv/bin/activate  # Windows: .\venv\Scripts\Activate.ps1
pip install -r requirements.txt

# Export environment variables or use a loader
export MYSQL_HOST=localhost
export MYSQL_USER=calculator_user
export MYSQL_PASSWORD=securepassword
export MYSQL_DB=calculator_db
export SECRET_KEY=secretkey
export FLASK_APP=app.py
export FLASK_ENV=development

flask run --host=127.0.0.1 --port=5000
```

### 6. Start Frontend (React)

```bash
cd frontend
npm install
export REACT_APP_API_BASE_URL=/api
npm start
```

* Dev server: `http://localhost:3000`
* For production, build and copy to Nginx root:

  ```bash
  npm run build
  sudo cp -r build/* /var/www/html
  sudo chown www-data:www-data /var/www/html
  ```

  Update Nginx config as needed and reload:

  ```bash
  sudo systemctl reload nginx
  ```

### 7. Configure & Start Nginx

Generate config from template:

```bash
cd nginx
./entrypoint.sh
```

Validate and reload:

```bash
sudo nginx -t
sudo systemctl reload nginx
```

### 8. Access the App

Visit:

```
http://localhost
```

Nginx serves the frontend and proxies `/api` requests to Flask.

---

## Configuration Reference

### Environment Variables by Component

* **Backend (Flask):** `MYSQL_*`, `SECRET_KEY`
* **Frontend (React):** `REACT_APP_API_BASE_URL`
* **Nginx:** `SERVER_NAME`, `FRONTEND_HOST`, `FRONTEND_PORT`, `BACKEND_HOST`, `BACKEND_PORT`

### Frontend Dev vs Production

* Dev: Hot reload, API base URL can be direct or proxied.
* Production: Static build served by Nginx, API base URL should be `/api`.

---

## Database Initialization Scripts

* `init.sql.template`: Creates DB, tables, user (variables replaced by `envsubst`)
* `seed.sql.template`: Optional sample data
* `init-db.sh`: Processes templates to final SQL

---

## Recommended Nginx Configuration

SPA fallback and proxy headers:

```nginx
server {
   server_name _;
   listen 80 default_server;

#    root /var/www/html;   # uncomment for static build
#    index index.html;     # uncomment for static build

   location / {                                              # comment for static build
      proxy_pass http://localhost:3000;  # comment for static build
   }                                                         # comment for static build
   
   location /api/ {
      proxy_pass http://localhost:5000/;
      proxy_set_header Host $host;
      proxy_set_header X-Real-IP $remote_addr;

      # Preflight requests
      if ($request_method = 'OPTIONS') {
        add_header 'Access-Control-Allow-Origin' '*';
        add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS';
        add_header 'Access-Control-Allow-Headers' 'Content-Type';
        add_header 'Access-Control-Allow-Credentials' 'true';
        add_header 'Content-Length' 0;
        return 204;
      }
   }
}
```

* For SPA builds, use `try_files $uri /index.html` for deep-linking.

---

## CORS Guidance

* Direct frontend-backend calls (no Nginx): enable CORS in Flask:

```python
from flask_cors import CORS
app = Flask(__name__)
CORS(app, resources={r"/api/*": {"origins": "http://localhost:3000"}})
```

* With Nginx proxying, CORS is usually not required.

---

## Platform Notes

* **Windows venv activation:**  
  PowerShell: `.\venv\Scripts\Activate.ps1`  
  CMD: `.\venv\Scripts\activate.bat`
* **envsubst:** Use WSL/Git Bash or edit templates manually on Windows.
* **MySQL:** Use Workbench or CLI for SQL imports.
* **Nginx on macOS:** Install via Homebrew; config path may differ.

---

## Testing

**Backend:**

```bash
cd backend
source venv/bin/activate
python -m unittest discover tests
```

**Frontend:**

```bash
cd frontend
npm run test # or npm run test:ci
```

**API check:**

```bash
curl -X POST http://localhost/api/calculate \
  -H "Content-Type: application/json" \
  -d '{"operand1": 3, "operand2": 4, "operation": "add"}'
```

---

## Troubleshooting

**Templates not rendered:**  
Run `./database/init-db.sh`; install `gettext` if needed.

**MySQL connection issues:**  
Check service status and credentials.

**Frontend-backend connectivity:**  
Set correct API base URL and enable CORS if needed.

**Nginx config errors:**  
Run `sudo nginx -t` and reload after fixing.

**Port conflicts:**  
Default: frontend 3000, backend 5000, nginx 80. Adjust as needed.

**SQL import permissions:**  
Use admin account or request DBA help.

---

## Security & Production

* Use strong secrets and passwords in production.
* Run Flask with a WSGI server (Gunicorn/uvicorn) behind Nginx.
* Enable HTTPS and DB password policies.
* Never commit `.env` or secrets.

---

## Contributing

Contributions welcome! Workflow:

1. Fork the repo
2. Create a feature branch
3. Run tests and verify setup
4. Open a pull request with a clear summary

If you modify templates, update helper scripts accordingly.


*This project has been created as part of the 42 curriculum by bsamy.*

---

# Inception

## Table of Contents

- [Description](#description)
- [Instructions](#instructions)
- [Resources](#resources)

---

## Description

Inception is a system administration project from the 42 Common Core curriculum. The goal is to set up a small but complete web infrastructure using **Docker** and **Docker Compose**, running inside a personal virtual machine.

The infrastructure is composed of three services, each isolated in its own Docker container:

- **NGINX** — the sole entry point, acting as a reverse proxy with TLSv1.2/1.3 enforce
- **WordPress + PHP-FPM** — the CMS, handling dynamic PHP content
- **MariaDB** — the relational database storing WordPress data

All containers are built from scratch using custom Dockerfiles based on Debian (bullseye). Pulling pre-built images from DockerHub is strictly forbidden. The entire infrastructure is orchestrated by a single `make` command via Docker Compose.

```
                        Internet
                            │
                    https://samy.42.fr
                            │ :443 (only open port)
                            ▼
                    ┌───────────────┐
                    │     NGINX     │
                    │  TLSv1.2/1.3  │  ← only entrypoint
                    └───────┬───────┘
                            │ FastCGI :9000
                    ┌───────▼───────┐
                    │   WordPress   │
                    │   + PHP-FPM   │
                    └───────┬───────┘
                            │ MySQL :3306
                    ┌───────▼───────┐
                    │    MariaDB    │
                    └───────────────┘
```

### Use of Docker

Docker is a containerization platform that allows each service to run in an **isolated environment** without being installed directly on the host machine. Unlike a full virtual machine, a Docker container is simply an isolated process sharing the host Linux kernel — making it lightweight, fast to start, and fully reproducible.

In this project, Docker is used to:
- Isolate each service (NGINX, WordPress, MariaDB) in its own container
- Define each container's environment via a custom `Dockerfile`
- Orchestrate all services together via `docker-compose.yml`
- Persist data across container restarts using volumes
- Enable internal communication between services via a private Docker network

### Sources Included

```
srcs/
├── docker-compose.yml         ← orchestrates all services
├── .env                       ← environment variables (not committed to git)
└── requirements/
    ├── nginx/
    │   ├── Dockerfile
    │   ├── conf/nginx.conf    ← NGINX server configuration
    │   └── tools/init.sh      ← startup script
    ├── wordpress/
    │   ├── Dockerfile
    │   ├── conf/www.conf      ← PHP-FPM pool configuration
    │   └── tools/init.sh      ← WordPress initialization script
    └── mariadb/
        ├── Dockerfile
        ├── conf/50-server.cnf ← MariaDB server configuration
        └── tools/init.sh      ← database initialization script
```

### Main Design Choices

**One container, one service.** Each container runs a single process as PID 1. Docker monitors this process — if it stops, the container stops. This enforces clean separation of responsibilities, independent restarts, and easier debugging.

**NGINX as the only entry point.** Only port 443 is exposed to the outside world. WordPress and MariaDB are never directly accessible from outside the Docker network.

**TLSv1.2/1.3 enforced.** Earlier versions of TLS have known vulnerabilities. A self-signed certificate is generated at build time using OpenSSL inside the NGINX Dockerfile.

**Startup scripts over complex Dockerfiles.** Each service uses a shell script (`init.sh`) as its entrypoint to handle initialization logic at runtime (e.g., creating the database, configuring WordPress), keeping the Dockerfile clean and readable.

---

### Virtual Machines vs Docker

| | Virtual Machine | Docker Container |
|---|---|---|
| **Isolation** | Full OS emulation | Process-level isolation |
| **Kernel** | Own kernel per VM | Shares host kernel |
| **Size** | ~10–20 GB | ~50–200 MB |
| **Startup time** | ~30s – 2min | < 1 second |
| **RAM overhead** | ~1–2 GB minimum | A few MB |
| **Use case** | Strong isolation, different OS | Lightweight, reproducible services |

A VM simulates a complete machine including its own OS and kernel. A Docker container is simply an isolated process — it uses Linux **namespaces** (to restrict what it sees) and **cgroups** (to restrict what it consumes), without duplicating the OS. This makes containers dramatically lighter and faster, at the cost of slightly weaker isolation.

In this project, both are used together: the VM provides the host environment, and Docker runs inside it.

---

### Secrets vs Environment Variables

| | Environment Variables | Docker Secrets |
|---|---|---|
| **Storage** | `.env` file or shell | Encrypted, stored in memory (`tmpfs`) |
| **Access** | Any process in the container | Only the targeted service |
| **Security** | Visible in `docker inspect` | Not exposed in inspect or logs |
| **Use case** | Development, simple projects | Production, sensitive credentials |

In this project, **environment variables** via a `.env` file are used. This is sufficient for a local development environment, as the infrastructure is not exposed to the internet. The `.env` file is never committed to git (listed in `.gitignore`).

In a production setup, **Docker Secrets** would be the appropriate choice — credentials are stored encrypted and only made available to the containers that explicitly need them, without ever appearing in environment variables or image layers.

---

### Docker Network vs Host Network

| | Docker Network (bridge) | Host Network |
|---|---|---|
| **Isolation** | Containers have their own network namespace | Container shares the host's network stack |
| **Port conflicts** | No conflict between containers | Possible conflicts with host services |
| **Security** | Services only reachable within the network | All container ports directly exposed on host |
| **DNS** | Containers resolve each other by service name | No automatic DNS between containers |

In this project, a **custom bridge network** (`inception_network`) is used. All three containers are connected to it and communicate using their service names as hostnames (e.g., `wordpress:9000`, `mariadb:3306`). Only NGINX exposes port 443 to the outside.

Using `network: host` is explicitly **forbidden** by the project subject, as it bypasses container isolation entirely and exposes all services directly on the host machine.

---

### Docker Volumes vs Bind Mounts

| | Docker Volumes | Bind Mounts |
|---|---|---|
| **Managed by** | Docker | The host filesystem |
| **Location** | Docker's internal storage | Any path you specify on the host |
| **Portability** | High (Docker manages the path) | Low (depends on host path existing) |
| **Performance** | Optimized by Docker | Depends on host OS |
| **Use case** | Persistent data, production | Development, sharing host files |

In this project, **bind mounts** are used, pointing to `/home/samy/data/` on the host VM. This is required by the project subject, which explicitly specifies that volumes must be available at that path.

```
/home/samy/data/
├── wordpress/     ← WordPress files (shared between NGINX and WordPress containers)
└── mariadb/       ← MariaDB database files
```

The `wordpress` volume is shared between the NGINX and WordPress containers so that NGINX can serve static files (images, CSS, JS) directly without going through PHP-FPM.

---

## Instructions

### Prerequisites

Docker and Docker Compose must be installed on your VM. Then run the following commands:

**Add the domain to your hosts file:**
```bash
echo "127.0.0.1 samy.42.fr" | sudo tee -a /etc/hosts
```

**Create the data directories:**
```bash
mkdir -p /home/samy/data/wordpress /home/samy/data/mariadb
```

**Create the environment file at `srcs/.env`:**
```bash
DOMAIN_NAME=samy.42.fr

# MariaDB
MYSQL_ROOT_PASSWORD=your_root_password
MYSQL_DATABASE=wordpress
MYSQL_USER=your_user
MYSQL_PASSWORD=your_password

# WordPress
WP_TITLE=Inception
WP_ADMIN_USER=your_admin
WP_ADMIN_PASSWORD=your_admin_password
WP_ADMIN_EMAIL=admin@samy.42.fr
WP_USER=your_user
WP_USER_PASSWORD=your_user_password
WP_USER_EMAIL=user@samy.42.fr
```

### Build and Run

```bash
# Build images and start all containers
make

# Stop and remove containers
make clean

# Full reset: remove containers, images, and volumes
make fclean

# Rebuild everything from scratch
make re
```

### Access

Once running, open your browser and navigate to:

```
https://samy.42.fr
```

> The browser will show a security warning because the SSL certificate is self-signed. This is expected — proceed to the site manually.

### Useful Debugging Commands

```bash
# Check running containers
docker compose -f srcs/docker-compose.yml ps

# View logs for a specific service
docker compose -f srcs/docker-compose.yml logs nginx
docker compose -f srcs/docker-compose.yml logs wordpress
docker compose -f srcs/docker-compose.yml logs mariadb

# Open a shell inside a container
docker exec -it nginx bash
docker exec -it wordpress bash
docker exec -it mariadb bash
```

---

## Resources

### Docker & Containerization

- [Docker Official Documentation](https://docs.docker.com/) — reference for all Docker concepts, CLI, and Dockerfile syntax
- [Docker Compose Documentation](https://docs.docker.com/compose/) — reference for `docker-compose.yml` syntax and CLI
- [Dockerfile Best Practices](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/) — official guide to writing efficient Dockerfiles
- [Namespaces and cgroups](https://www.nginx.com/blog/what-are-namespaces-cgroups-how-do-they-work/) — deep dive into how container isolation works at the Linux kernel level

### NGINX

- [NGINX Official Documentation](https://nginx.org/en/docs/) — complete reference for directives and configuration
- [NGINX Beginner's Guide](https://nginx.org/en/docs/beginners_guide.html) — introduction to NGINX concepts and configuration structure
- [PHP-FPM Documentation](https://www.php.net/manual/en/install.fpm.php) — official PHP-FPM reference

### MariaDB

- [MariaDB Official Documentation](https://mariadb.com/kb/en/documentation/) — complete reference for MariaDB configuration and SQL
- [MariaDB vs MySQL Compatibility](https://mariadb.com/kb/en/mariadb-vs-mysql-compatibility/) — compatibility overview between the two

### WordPress

- [WordPress Official Documentation](https://wordpress.org/documentation/) — WordPress installation and configuration reference
- [WP-CLI Documentation](https://wp-cli.org/) — command-line interface used to automate WordPress installation

### TLS / SSL

- [OpenSSL Documentation](https://www.openssl.org/docs/) — reference for generating self-signed certificates
- [TLS 1.3 Overview — Cloudflare](https://www.cloudflare.com/learning/ssl/why-use-tls-1.3/) — accessible explanation of TLS versions and why older ones are deprecated

### AI Usage

**Claude (Anthropic)** was used throughout this project for the following purposes:

- **Understanding concepts** — Docker architecture, container vs VM differences, TLS/SSL mechanisms, NGINX reverse proxy configuration, FastCGI protocol, and MariaDB initialization
- **Explaining configuration files** — line-by-line breakdown of `nginx.conf`, MariaDB `.cnf` files, PHP-FPM `www.conf`, and shell startup scripts
- **Debugging guidance** — understanding error messages and identifying common pitfalls such as processes running as daemons instead of foreground, and `depends_on` limitations in Docker Compose
- **Documentation** — assistance structuring and writing this README according to the 42 project requirements

All code was written and understood by the author. AI was used strictly as a learning and explanation tool, not as a code generator.
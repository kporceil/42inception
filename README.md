*This project has been created as part of the 42 curriculum by kporceil.*

# Inception

## Description

Inception is a system administration project from the 42 curriculum. The goal is to build a small but complete web infrastructure using Docker, where each service runs in its own dedicated container.

The stack consists of three services orchestrated with Docker Compose:
- **NGINX** — the sole entry point, handling HTTPS (TLS 1.2/1.3) on port 443
- **WordPress + PHP-FPM** — the CMS and its PHP interpreter
- **MariaDB** — the relational database storing all WordPress data

All Docker images are built from scratch using custom Dockerfiles based on `alpine:3.22`. No pre-built images are pulled from DockerHub.

---

## Instructions

### Prerequisites

- Docker and Docker Compose installed
- A virtual machine running Linux
- `sudo` access to edit `/etc/hosts` and manage `/home/kporceil/data/`

### Setup

1. Clone the repository:
   ```sh
   git clone <repo_url>
   cd inception
   ```

2. Create the secrets files (never committed to git):
   ```sh
   echo "your_db_password"       > secrets/db_password.txt
   echo "your_root_password"     > secrets/db_root_password.txt
   echo "your_admin_password"    > secrets/credentials.txt
   echo "your_user_password"     > secrets/wp_user_password.txt
   ```

3. Edit `srcs/.env` to set your domain name and usernames if needed.

4. Add the domain to your `/etc/hosts`:
   ```sh
   echo "127.0.0.1 kporceil.42.fr" | sudo tee -a /etc/hosts
   ```

5. Build and start the infrastructure:
   ```sh
   make
   ```

6. Open your browser and navigate to `https://kporceil.42.fr`.
   Accept the self-signed certificate warning.

### Stop the project

```sh
make down
```

### Full reset (removes all data)

```sh
make fclean
```

---

## Project Description

### Virtual Machines vs Docker

A **Virtual Machine** emulates a full hardware stack and runs a complete OS on top of a hypervisor. It is isolated, heavy (GBs of disk, minutes to boot), and provides strong isolation.

A **Docker container** shares the host kernel and only virtualizes the process layer. It is lightweight (MBs), starts in seconds, and is designed to run a single process. A container is not a VM — it should not be managed like one.

In this project, Docker is used because each service (NGINX, WordPress, MariaDB) is an isolated process that doesn't need a full OS.

### Secrets vs Environment Variables

**Environment variables** (stored in `.env`) are injected into the container at runtime and are visible in plain text via `docker inspect`. They are suitable for non-sensitive configuration like usernames, domain names, or database names.

**Docker Secrets** are files mounted read-only inside the container at `/run/secrets/<name>`. They are not exposed via `docker inspect` and are only accessible to the process that needs them. They are used in this project for all passwords.

### Docker Network vs Host Network

With **host network** (`network: host`), the container shares the host's network stack directly — no isolation, all ports are shared. This is forbidden in this project.

With a **Docker bridge network**, containers get their own virtual network. They communicate with each other using their service name as hostname (Docker's internal DNS), and only explicitly published ports are accessible from the outside. This project uses a custom bridge network named `inception`.

### Docker Volumes vs Bind Mounts

A **bind mount** directly maps a host directory into a container. The host path must exist and Docker has no control over it.

A **named volume** is managed by Docker. It has a name, a lifecycle, and can be inspected with `docker volume inspect`. In this project, named volumes are used for both the database and WordPress files. They are configured to store their data under `/home/kporceil/data/` on the host, as required by the subject.

Bind mounts for persistent storage are explicitly forbidden by the project rules.

---

## Resources

### Documentation
- [Docker official documentation](https://docs.docker.com)
- [Docker Compose reference](https://docs.docker.com/compose/compose-file/)
- [NGINX documentation](https://nginx.org/en/docs/)
- [MariaDB documentation](https://mariadb.com/kb/en/)
- [WP-CLI documentation](https://wp-cli.org/)
- [PHP-FPM configuration](https://www.php.net/manual/en/install.fpm.configuration.php)
- [OpenSSL - generating self-signed certificates](https://www.openssl.org/docs/)

### AI Usage

Claude (claude-sonnet-4-6) was used during this project for the following tasks:
- Clarifying Docker concepts
- Reviewing shell script logic (init_db.sh, init_wp.sh)
- Understanding PHP-FPM configuration directives
- Explaining NGINX FastCGI proxy configuration

All generated content was reviewed, tested, and understood before being included in the project.

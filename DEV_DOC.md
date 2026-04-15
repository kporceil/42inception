# Developer Documentation — Inception

## Environment setup from scratch

### Prerequisites

- Docker Engine (>= 24.0)
- Docker Compose plugin (>= 2.0) — note: `docker-compose` (v1) is deprecated, use `docker compose`
- `make`
- A Linux virtual machine (required by the project)

### Repository structure

```
inception/
├── Makefile                          # entry point — wraps docker compose commands
├── README.md
├── USER_DOC.md
├── DEV_DOC.md
├── .gitignore                        # excludes secrets/ and srcs/.env
├── secrets/                          # NOT in git — create manually
│   ├── db_password.txt               # MariaDB wpuser password
│   ├── db_root_password.txt          # MariaDB root password
│   ├── credentials.txt               # WordPress admin password
│   └── wp_user_password.txt          # WordPress regular user password
└── srcs/
    ├── compose.yml                   # orchestrates all services
    ├── .env                          # NOT in git — non-sensitive config
    └── requirements/
        ├── nginx/
        │   ├── Dockerfile
        │   ├── conf/nginx.conf       # NGINX config with TLS and FastCGI
        │   └── tools/                # (reserved for future scripts)
        ├── wordpress/
        │   ├── Dockerfile
        │   ├── conf/www.conf         # PHP-FPM pool config
        │   └── tools/init_wp.sh      # downloads WP, configures, creates users
        └── mariadb/
            ├── Dockerfile
            ├── conf/my.cnf           # MariaDB config (charset, socket, port)
            └── tools/init_db.sh      # initializes DB, users, privileges
```

### Configuration files

**`srcs/.env`** — create this file if it doesn't exist. It holds non-sensitive variables:
```sh
DOMAIN_NAME=kporceil.42.fr
MYSQL_DATABASE=wordpress
MYSQL_USER=wpuser
WP_ADMIN_USER=kporceil
WP_ADMIN_EMAIL=kporceil@student.42lyon.fr
WP_USER=visitor
WP_USER_EMAIL=visitor@student.42lyon.fr
```

**`secrets/`** — create one file per secret, each containing only the password:
```sh
echo "your_db_password"    > secrets/db_password.txt
echo "your_root_password"  > secrets/db_root_password.txt
echo "your_admin_password" > secrets/credentials.txt
echo "your_user_password"  > secrets/wp_user_password.txt
```

**`/etc/hosts`** — add the domain resolution on the host machine:
```sh
echo "127.0.0.1 kporceil.42.fr" | sudo tee -a /etc/hosts
```

---

## Build and launch

### Full build and start
```sh
make
```
Equivalent to:
```sh
mkdir -p /home/kporceil/data/db /home/kporceil/data/wordpress
docker compose -f srcs/compose.yml up --build -d
```

The `--build` flag forces Docker to rebuild all images. The `-d` flag runs containers in the background.

### Startup sequence
Docker Compose starts services in this order, enforced by `depends_on`:
1. **mariadb** — initializes the database on first start, then waits to be `healthy`
2. **wordpress** — starts only after MariaDB is `healthy`, installs WordPress on first start
3. **nginx** — starts after WordPress is up, serves HTTPS on port 443

---

## Useful commands

### Container management
```sh
# List running containers with status
docker ps

# View real-time logs
docker logs -f mariadb
docker logs -f wordpress
docker logs -f nginx

# Open a shell inside a container
docker exec -it mariadb sh
docker exec -it wordpress sh
docker exec -it nginx sh
```

### Volume management
```sh
# List all Docker volumes
docker volume ls

# Inspect a volume (shows mount point and config)
docker volume inspect inception_db_data
docker volume inspect inception_wp_data

# Data location on the host
ls /home/kporceil/data/db
ls /home/kporceil/data/wordpress
```

### Makefile targets
```sh
make          # build images + start containers (creates data dirs if needed)
make down     # stop and remove containers (data preserved)
make clean    # down + remove Docker volumes
make fclean   # clean + remove built images + delete /home/kporceil/data/
make re       # fclean + make (full rebuild from scratch)
```

### Rebuild a single service
```sh
docker compose -f srcs/compose.yml build mariadb
docker compose -f srcs/compose.yml up -d --no-deps mariadb
```

---

## Data storage and persistence

### Where data lives

| Data | Docker volume | Host path |
|------|--------------|-----------|
| MariaDB database files | `inception_db_data` | `/home/kporceil/data/db` |
| WordPress files (PHP, themes, uploads) | `inception_wp_data` | `/home/kporceil/data/wordpress` |

### How persistence works

Both volumes are **named volumes** configured with `driver: local` and `o: bind`. Docker manages the volume lifecycle (name, inspect, prune) while the actual data is stored at a fixed path on the host.

When a container is stopped or removed, the data in these directories is untouched. On the next `make`, the containers find existing data and skip the initialization step:
- `init_db.sh` checks if `/var/lib/mysql/${MYSQL_DATABASE}` exists → skips init if true
- `init_wp.sh` checks if `/var/www/wordpress/wp-config.php` exists → skips install if true

To reset all data intentionally, run `make fclean`.

### Secrets at runtime

Secrets are mounted as read-only files inside containers at `/run/secrets/<name>`. They are read by the init scripts using `$(cat /run/secrets/<name>)` and never stored as environment variables. They do not appear in `docker inspect` output.

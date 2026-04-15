# User Documentation — Inception

## Services provided

This infrastructure runs three services:

| Service | Role | Access |
|---------|------|--------|
| **NGINX** | Web server, HTTPS entry point | `https://kporceil.42.fr` |
| **WordPress** | CMS — website and admin panel | `https://kporceil.42.fr/wp-admin` |
| **MariaDB** | Database — stores all WordPress content | Internal only (port 3306) |

MariaDB is not directly accessible from outside the Docker network. All traffic goes through NGINX on port 443.

---

## Start and stop the project

### Start
From the root of the repository:
```sh
make
```
This builds all Docker images and starts the containers in the background. The first build may take a few minutes.

### Stop (keep data)
```sh
make down
```
Stops and removes the containers. All data (database, WordPress files) is preserved in `/home/kporceil/data/`.

### Restart
```sh
make re
```
Full reset: stops everything, removes images and data, then rebuilds and restarts from scratch.

---

## Access the website and administration panel

### Website
Open your browser and go to:
```
https://kporceil.42.fr
```
Your browser will show a security warning because the SSL certificate is self-signed. Click "Advanced" and "Proceed" to continue.

### WordPress administration panel
```
https://kporceil.42.fr/wp-admin
```
Log in with the admin credentials defined in `secrets/credentials.txt`.

---

## Locate and manage credentials

All credentials are stored in the `secrets/` directory at the root of the repository. These files are never committed to git.

| File | Contains |
|------|----------|
| `secrets/db_password.txt` | WordPress database user password |
| `secrets/db_root_password.txt` | MariaDB root password |
| `secrets/credentials.txt` | WordPress admin password |
| `secrets/wp_user_password.txt` | WordPress regular user password |

Non-sensitive configuration (usernames, domain name, database name) is in `srcs/.env`.

To change a password:
1. Edit the corresponding file in `secrets/`
2. Run `make re` to rebuild with the new credentials

---

## Check that the services are running correctly

### View running containers
```sh
docker ps
```
All three containers (`nginx`, `wordpress`, `mariadb`) should appear with status `Up`. MariaDB also shows `(healthy)` once its healthcheck passes.

### View logs for a specific service
```sh
docker logs nginx
docker logs wordpress
docker logs mariadb
```

### Check that the website responds
```sh
curl -k https://kporceil.42.fr
```
You should receive HTML content. The `-k` flag ignores the self-signed certificate warning.

### Check MariaDB directly
```sh
docker exec -it mariadb mariadb -u wpuser -p
```
Enter the password from `secrets/db_password.txt` when prompted.

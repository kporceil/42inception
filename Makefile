COMPOSE	= docker compose -f srcs/compose.yml

# Dossiers des volumes sur l'hôte — doivent exister avant docker-compose up
DATA_DIRS = /home/kporceil/data/db /home/kporceil/data/wordpress

.PHONY: all down clean fclean re

# ─────────────────────────────────────────────
# all : crée les dossiers de données si besoin,
#       puis build et lance tous les containers
# ─────────────────────────────────────────────
all:
	mkdir -p $(DATA_DIRS)
	$(COMPOSE) up --build -d

# ─────────────────────────────────────────────
# down : arrête et supprime les containers + réseau
#        les volumes et images sont conservés
# ─────────────────────────────────────────────
down:
	$(COMPOSE) down

# ─────────────────────────────────────────────
# clean : arrête tout et supprime les volumes Docker
#         (les données dans /home/kporceil/data/ restent)
# ─────────────────────────────────────────────
clean: down
	$(COMPOSE) down -v

# ─────────────────────────────────────────────
# fclean : nettoyage total
#          containers, volumes Docker, images buildées, données sur l'hôte
# ─────────────────────────────────────────────
fclean: clean
	docker image prune -af
	sudo rm -rf /home/kporceil/data/

# ─────────────────────────────────────────────
# re : repart de zéro
# ─────────────────────────────────────────────
re: fclean all

COMPOSE	= docker compose -f srcs/compose.yml

DATA_DIRS = /home/kporceil/data/db /home/kporceil/data/wordpress

.PHONY: all down clean fclean re

all:
	mkdir -p $(DATA_DIRS)
	$(COMPOSE) up --build -d

down:
	$(COMPOSE) down

clean: down
	$(COMPOSE) down -v

fclean: clean
	docker image prune -af
	sudo rm -rf /home/kporceil/data/

re: fclean all

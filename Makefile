NAME		= inception

COMPOSE		= docker compose -f srcs/docker_compose.yml --env-file srcs/.env

DATA_DIR	= $(HOME)/data/mariadb $(HOME)/data/wordpress

all: $(DATA_DIR)
	$(COMPOSE) up -d --build

$(HOME)/data/mariadb:
	mkdir -p $@

$(HOME)/data/wordpress:
	mkdir -p $@

down:
	$(COMPOSE) down

stop:
	$(COMPOSE) stop

start:
	$(COMPOSE) start

re: fclean all

clean:
	$(COMPOSE) down --rmi all --volumes

fclean: clean
	sudo rm -rf $(HOME)/data

logs:
	$(COMPOSE) logs -f

ps:
	$(COMPOSE) ps

.PHONY: all down stop start re clean fclean logs ps

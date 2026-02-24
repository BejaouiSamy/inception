NAME		= inception

COMPOSE		= docker compose -f srcs/docker_compose.yml --env-file srcs/.env

DATA_DIR	= $(HOME)/data/mariadb $(HOME)/data/wordpress

all:
	mkdir -p $(HOME)/data/mariadb $(HOME)/data/wordpress
	$(COMPOSE) up -d --build

# stop and remove the containers, networks, volumes, and images
down:
	$(COMPOSE) down

# stop the containers without removing them, so that they can be restarted with 'start' without rebuilding
stop:
	$(COMPOSE) stop

start:
	$(COMPOSE) start 2>/dev/null || $(COMPOSE) up -d --build

re: fclean all

clean:
	$(COMPOSE) down --rmi all --volumes

fclean: clean
	sudo rm -rf $(HOME)/data

logs:
	$(COMPOSE) logs -f

ps:
	$(COMPOSE) ps

# make down for cleaning up the environment, networks, volumes, and images created by docker compose 
# make stop to stop the containers without removing them, so that they can be restarted with 'start' without rebuilding
# make re to clean up the environment and rebuild the containers
# make logs to follow the logs of the containers
# make ps to see the status of the containers
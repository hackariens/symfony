.DEFAULT_GOAL   := help
STACK           := symfony
NETWORK         := proxynetwork
PHPFPM          := $(STACK)_phpfpm
PHPFPMFULLNAME  := $(PHPFPM).1.$$(docker service ps -f 'name=$(PHPFPM)' $(PHPFPM) -q --no-trunc | head -n1)
MARIADB         := $(STACK)_mariadb
MARIADBFULLNAME := $(MARIADB).1.$$(docker service ps -f 'name=$(MARIADB)' $(MARIADB) -q --no-trunc | head -n1)
APACHE          := $(STACK)_apache
APACHEFULLNAME  := $(APACHE).1.$$(docker service ps -f 'name=$(APACHE)' $(APACHE) -q --no-trunc | head -n1)
%:
	@:

help:
	@grep -E '(^[a-zA-Z_-]+:.*?##.*$$)|(^##)' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}' | sed -e 's/\[32m##/[33m/'

apps/vendor:
	@make composer-dev -i

apps/.env: ## Install .env
	cp apps/.env.dist apps/.env

bdd-fixtures: vendor ## fixtures
	docker exec $(PHPFPMFULLNAME) make bdd-fixtures

bdd-migrate: vendor ## migrate database
	docker exec $(PHPFPMFULLNAME) make bdd-migrate

bdd-validate: vendor ## bdd validate
	docker exec $(PHPFPMFULLNAME) make bdd-validate

composer-suggests: ## suggestions package pour PHP
	docker exec $(PHPFPMFULLNAME) make composer-suggests

composer-outdated: ## Packet php outdated
	docker exec $(PHPFPMFULLNAME) make composer-outdated

composer-prod: ## Installation version de production
	docker exec $(PHPFPMFULLNAME) make composer-prod

composer-dev: ## Installation version de dev
	docker exec $(PHPFPMFULLNAME) make composer-dev

composer-update: ## COMPOSER update
	docker exec $(PHPFPMFULLNAME) make composer-update

composer-validate: ## COMPOSER validate
	docker exec $(PHPFPMFULLNAME) make composer-validatef

contributors: node_modules ## Contributors
	@npm run contributors

contributors-add: node_modules ## add Contributors
	@npm run contributors add

contributors-check: node_modules ## check Contributors
	@npm run contributors check

contributors-generate: node_modules ## generate Contributors
	@npm run contributors generate

docker-create-network: ## create network
	docker network create --driver=overlay $(NETWORK)

docker-deploy: ## deploy
	docker stack deploy -c docker-compose.yml $(STACK)

docker-image-pull: ## Get docker image
	docker image pull redis:6.0.8
	docker image pull mailhog/mailhog
	docker image pull dunglas/mercure
	docker image pull osixia/phplddapadmin
	docker image pull osixia/openldap:1.4.0
	docker image pull mariadb:10.5.1
	docker image pull httpd
	docker image pull phpmyadmin/phpmyadmin
	docker image pull koromerzhin/phpfpm:latest-symfony-without-xdebug

env-dev: apps/.env ## Installation environnement dev
	sed -i 's/APP_ENV=prod/APP_ENV=dev/g' apps/.env

env-prod: apps/.env ## Installation environnement prod
	sed -i 's/APP_ENV=dev/APP_ENV=prod/g' apps/.env
	rm -rf apps/vendor
	@make composer-prod -i

git-commit: node_modules ## Commit data
	npm run commit

git-check: node_modules ## CHECK before
	@make composer-validate -i
	@make composer-outdated -i
	@make bdd-validate
	@make contributors-check -i
	@git status

install: node_modules apps/.env ## installation
	@make docker-deploy -i
	@make sleep -i
	@make linter-launch -i

install-dev: install
	@make env-dev
	@make bdd-migrate -i
	@make bdd-features -i

linter-launch: apps/vendor node_modules ## Launch all linter
	@make linter-twigcs -i
	@make linter-phpstan -i
	@make linter-phpcpd -i
	@make linter-phpcs -i
	@make linter-phpmd -i

linter-readme: node_modules ## linter README.md
	@npm run linter-markdown README.md

linter-phpcbf: apps/vendor ## fixe le code PHP à partir d'un standard
	docker exec $(PHPFPMFULLNAME) make linter-phpcbf

linter-phpcs: apps/vendor ## indique les erreurs de code non corrigé par PHPCBF
	docker exec $(PHPFPMFULLNAME) make linter-phpcs

linter-phpcpd: apps/vendor ## verifie si il n'y a pas de copier / coller
	docker exec $(PHPFPMFULLNAME) make linter-phpcpd

linter-phpcs-onlywarning: apps/vendor ## indique les erreurs de code non corrigé par PHPCBF
	docker exec $(PHPFPMFULLNAME) make linter-phpcs-onlywarning

linter-phpcs-onlyerror: apps/vendor ## indique les erreurs de code non corrigé par PHPCBF
	docker exec $(PHPFPMFULLNAME) make linter-phpcs-onlyerror

linter-phpmd: apps/vendor ## indique quand le code PHP contient des erreurs de syntaxes ou des erreurs
	docker exec $(PHPFPMFULLNAME) make linter-phpmd

linter-phpmnd: apps/vendor ## Si des chiffres sont utilisé dans le code PHP, il est conseillé d'utiliser des constantes
	docker exec $(PHPFPMFULLNAME) make linter-phpmnd

linter-phpstan: apps/vendor ## regarde si le code PHP ne peux pas être optimisé
	docker exec $(PHPFPMFULLNAME) make linter-phpstan

linter-twigcs: apps/vendor ## indique les erreurs de code de twig
	docker exec $(PHPFPMFULLNAME) make linter-twigcs

logs: ## logs docker
	docker service logs -f --tail 100 --raw $(STACK)

logs-apache: ## logs docker APACHE
	docker service logs -f --tail 100 --raw $(APACHEFULLNAME)

logs-mariadb: ## logs docker MARIADB
	docker service logs -f --tail 100 --raw $(MARIADBFULLNAME)

logs-phpfpm: ## logs docker PHPFPM
	docker service logs -f --tail 100 --raw $(PHPFPMFULLNAME)

node_modules: ## npm install
	npm install

sleep: ## sleep
	sleep 90

ssh: ## ssh
	docker exec -ti $(PHPFPMFULLNAME) /bin/bash

tests-behat: apps/vendor ## Lance les tests behat
	docker exec $(PHPFPMFULLNAME) make tests-behat

tests-launch: apps/vendor ## Launch all tests
	@make tests-behat -i
	@make tests-phpunit -i

tests-phpunit: apps/vendor ## lance les tests phpunit
	docker exec $(PHPFPMFULLNAME) make tests-phpunit

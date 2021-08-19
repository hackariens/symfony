include make/general/Makefile
STACK         := symfony
NETWORK       := proxylampy
include make/docker/Makefile

PHPFPMFULLNAME := $(STACK)_phpfpm.1.$$(docker service ps -f 'name=$(STACK)_phpfpm' $(STACK)_phpfpm -q --no-trunc | head -n1)

DOCKER_EXECPHP := @docker exec $(STACK)_phpfpm.1.$$(docker service ps -f 'name=$(STACK)_phpfpm' $(STACK)_phpfpm -q --no-trunc | head -n1)

SUPPORTED_COMMANDS := workflow-png tests messenger linter install geocode env encore composer bdd
SUPPORTS_MAKE_ARGS := $(findstring $(firstword $(MAKECMDGOALS)), $(SUPPORTED_COMMANDS))
ifneq "$(SUPPORTS_MAKE_ARGS)" ""
  COMMAND_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  $(eval $(COMMAND_ARGS):;@:)
endif

dump:
	@mkdir dump

apps/.env: apps/.env.dist ## Install .env
	@cp apps/.env.dist apps/.env

assets: isdocker
	$(DOCKER_EXECPHP) make assets

bdd: isdocker ### Scripts for BDD
ifeq ($(COMMAND_ARGS),fixtures)
	$(DOCKER_EXECPHP) make bdd fixtures
else ifeq ($(COMMAND_ARGS),migrate)
	$(DOCKER_EXECPHP) make bdd migrate
else ifeq ($(COMMAND_ARGS),validate)
	$(DOCKER_EXECPHP) make bdd validate
else
	@echo "ARGUMENT missing"
	@echo "---"
	@echo "make bdd ARGUMENT"
	@echo "---"
	@echo "fixtures: fixtures"
	@echo "migrate: migrate database"
	@echo "validate: bdd validate"
endif

composer: isdocker ### Scripts for composer
ifeq ($(COMMAND_ARGS),suggests)
	$(DOCKER_EXECPHP) make composer suggests
else ifeq ($(COMMAND_ARGS),outdated)
	$(DOCKER_EXECPHP) make composer outdated
else ifeq ($(COMMAND_ARGS),fund)
	$(DOCKER_EXECPHP) make composer fund
else ifeq ($(COMMAND_ARGS),prod)
	$(DOCKER_EXECPHP) make composer prod
else ifeq ($(COMMAND_ARGS),dev)
	$(DOCKER_EXECPHP) make composer dev
else ifeq ($(COMMAND_ARGS),update)
	$(DOCKER_EXECPHP) make composer update
else ifeq ($(COMMAND_ARGS),validate)
	$(DOCKER_EXECPHP) make composer validate
else
	@echo "ARGUMENT missing"
	@echo "---"
	@echo "make composer ARGUMENT"
	@echo "---"
	@echo "suggests: suggestions package pour PHP"
	@echo "outdated: Packet php outdated"
	@echo "fund: Discover how to help fund the maintenance of your dependencies."
	@echo "prod: Installation version de prod"
	@echo "dev: Installation version de dev"
	@echo "update: COMPOSER update"
	@echo "validate: COMPOSER validate"
endif

encore: node_modules ##" Script for Encore
ifeq ($(COMMAND_ARGS),dev)
	@npm rebuild node-sass
	@npm run encore-dev
else ifeq ($(COMMAND_ARGS),watch)
	@npm run encore-watch
else
	@echo "ARGUMENT missing"
	@echo "---"
	@echo "make encore ARGUMENT"
	@echo "---"
	@echo "dev: créer les assets en version dev"
	@echo "watch: créer les assets en version watch"
endif

folders: dump ## Create folder

env: apps/.env ### Scripts Installation environnement
ifeq ($(COMMAND_ARGS),dev)
	@sed -i 's/APP_ENV=prod/APP_ENV=dev/g' apps/.env
else ifeq ($(COMMAND_ARGS),prod)
	@sed -i 's/APP_ENV=dev/APP_ENV=prod/g' apps/.env
	@rm -rf apps/vendor
	@make composer prod -i
else
	@echo "ARGUMENT missing"
	@echo "---"
	@echo "make env ARGUMENT"
	@echo "---"
	@echo "dev: environnement dev"
	@echo "prod: environnement prod"
endif

geocode: isdocker ### Geocode
	$(DOCKER_EXECPHP) make geocode $(COMMAND_ARGS)

install: folders apps/.env ### installation
ifeq ($(COMMAND_ARGS),all)
	@make node_modules -i
	@make docker deploy -i
	@make sleep 60 -i
	@make bdd migrate -i
	@make assets -i
	@make encore dev -i
	@make linter all -i
else ifeq ($(COMMAND_ARGS),dev)
	@make install all
	@make bdd fixtures -i
else
	@echo "ARGUMENT missing"
	@echo "---"
	@echo "make install ARGUMENT"
	@echo "---"
	@echo "all: common"
	@echo "dev: dev"
endif

linter: node_modules isdocker### Scripts Linter
ifeq ($(COMMAND_ARGS),all)
	@make linter eslint -i
	@make linter twig -i
	@make linter container -i
	@make linter yaml -i
	@make linter phpstan -i
	@make linter phpcpd -i
	@make linter phpcs -i
	@make linter phpmd -i
	@make linter readme -i
else ifeq ($(COMMAND_ARGS),readme)
	@npm run linter-markdown README.md
else ifeq ($(COMMAND_ARGS),eslint)
	@npm run eslint
else ifeq ($(COMMAND_ARGS),eslint-fix)
	@npm run eslint-fix
else ifeq ($(COMMAND_ARGS),phpcbf)
	$(DOCKER_EXECPHP) make linter phpcbf
else ifeq ($(COMMAND_ARGS),phpcpd)
	$(DOCKER_EXECPHP) make linter phpcpd
else ifeq ($(COMMAND_ARGS),phpcs)
	$(DOCKER_EXECPHP) make linter phpcs
else ifeq ($(COMMAND_ARGS),phpcs-onlywarning)
	$(DOCKER_EXECPHP) make linter phpcs-onlywarning
else ifeq ($(COMMAND_ARGS),phpcs-onlyerror)
	$(DOCKER_EXECPHP) make linter phpcs-onlyerror
else ifeq ($(COMMAND_ARGS),phploc)
	$(DOCKER_EXECPHP) make linter phploc
else ifeq ($(COMMAND_ARGS),phpmd)
	$(DOCKER_EXECPHP) make linter phpmd
else ifeq ($(COMMAND_ARGS),phpmnd)
	$(DOCKER_EXECPHP) make linter phpmnd
else ifeq ($(COMMAND_ARGS),phpstan)
	$(DOCKER_EXECPHP) make linter phpstan
else ifeq ($(COMMAND_ARGS),twig)
	$(DOCKER_EXECPHP) make linter twig
else ifeq ($(COMMAND_ARGS),container)
	$(DOCKER_EXECPHP) make linter container
else ifeq ($(COMMAND_ARGS),yaml)
	$(DOCKER_EXECPHP) make linter yaml
else
	@echo "ARGUMENT missing"
	@echo "---"
	@echo "make linter ARGUMENT"
	@echo "---"
	@echo "all: ## Launch all linter"
	@echo "readme: linter README.md"
	@echo "eslint: indique les erreurs sur le code JavaScript à partir d'un standard"
	@echo "eslint-fix: fixe le code JavaScript à partir d'un standard"
	@echo "phpcbf: fixe le code PHP à partir d'un standard"
	@echo "phpcpd: Vérifie s'il y a du code dupliqué"
	@echo "phpcs: indique les erreurs de code non corrigé par PHPCBF"
	@echo "phpcs-onlywarning: indique les erreurs de code non corrigé par PHPCBF"
	@echo "phpcs-onlyerror: indique les erreurs de code non corrigé par PHPCBF"
	@echo "phploc: phploc"
	@echo "phpmd: indique quand le code PHP contient des erreurs de syntaxes ou des erreurs"
	@echo "phpmnd: Si des chiffres sont utilisé dans le code PHP, il est conseillé d'utiliser des constantes"
	@echo "phpstan: regarde si le code PHP ne peux pas être optimisé"
	@echo "twig: indique les erreurs de code de twig"
	@echo "container: indique les erreurs de code de container"
	@echo "yaml: indique les erreurs de code de yaml"
endif

messenger: isdocker ### Scripts messenger
ifeq ($(COMMAND_ARGS),consule)
	$(DOCKER_EXECPHP) make messenger consume
else
	@echo "ARGUMENT missing"
	@echo "---"
	@echo "make messenger ARGUMENT"
	@echo "---"
	@echo "consume: Messenger Consume"
endif

tests: isdocker ### Scripts tests
ifeq ($(COMMAND_ARGS),launch)
	@docker exec $(PHPFPMFULLNAME) make tests all
else ifeq ($(COMMAND_ARGS),behat)
	@docker exec $(PHPFPMFULLNAME) make tests behat
else ifeq ($(COMMAND_ARGS),simple-phpunit-unit-integration)
	@docker exec $(PHPFPMFULLNAME) make tests simple-phpunit-unit-integration
else ifeq ($(COMMAND_ARGS),simple-phpunit)
	@docker exec $(PHPFPMFULLNAME) make tests simple-phpunit
else
	@echo "ARGUMENT missing"
	@echo "---"
	@echo "make tests ARGUMENT"
	@echo "---"
	@echo "launch: Launch all tests"
	@echo "behat: Lance les tests behat"
	@echo "simple-phpunit-unit-integration: lance les tests phpunit"
	@echo "simple-phpunit: lance les tests phpunit"
endif

translations: isdocker ## update translation
	$(DOCKER_EXECPHP) make translations

workflow-png: isdocker ### generate workflow png
	$(DOCKER_EXECPHP) make workflow-png $(COMMAND_ARGS)

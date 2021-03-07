.DEFAULT_GOAL   := help

SUPPORTED_COMMANDS   := bdd composer contributors encore env geocode git install linter logs messenger sleep ssh tests workflow-png
SUPPORTS_MAKE_ARGS   := $(findstring $(firstword $(MAKECMDGOALS)), $(SUPPORTED_COMMANDS))
ifneq "$(SUPPORTS_MAKE_ARGS)" ""
  COMMAND_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  $(eval $(COMMAND_ARGS):;@:)
endif

SYMFONY_EXEC := @symfony console

help:
	@grep -E '(^[a-zA-Z_-]+:.*?##.*$$)|(^##)' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}' | sed -e 's/\[32m##/[33m/'

composer.lock: composer.json
	composer update

vendor: composer.json
	composer install --no-progress --prefer-dist --optimize-autoloader

.env: .env.dist ## Install .env
	cp .env.dist .env

phploc.phar:
	wget https://phar.phpunit.de/phploc-7.0.1.phar -O phploc.phar

phpcpd.phar:
	wget https://phar.phpunit.de/phpcpd-6.0.2.phar -O phpcpd.phar

phpmd.phar:
	wget https://github.com/phpmd/phpmd/releases/download/2.9.1/phpmd.phar

assets: ## Ajouts assets
	${SYMFONY_EXEC} assets:install public --symlink --relative

bdd: ## Scripts for BDD
ifeq ($(COMMAND_ARGS),fixtures)
	${SYMFONY_EXEC} doctrine:fixtures:load -n
else ifeq ($(COMMAND_ARGS),migrate)
	${SYMFONY_EXEC} doctrine:migrations:migrate -n
else ifeq ($(COMMAND_ARGS),validate)
	${SYMFONY_EXEC} doctrine:schema:validate
else
	@echo "ARGUMENT missing"
	@echo "---"
	@echo "make bdd ARGUMENT"
	@echo "---"
	@echo "fixtures: fixtures"
	@echo "migrate: migrate database"
	@echo "validate: bdd validate"
endif

composer: ## Scripts for composer
ifeq ($(COMMAND_ARGS),suggests)
	@composer suggests --by-suggestion
else ifeq ($(COMMAND_ARGS),outdated)
	@composer outdated
else ifeq ($(COMMAND_ARGS),fund)
	@composer fund
else ifeq ($(COMMAND_ARGS),prod)
	@composer install --no-dev --no-progress --prefer-dist --optimize-autoloader
else ifeq ($(COMMAND_ARGS),dev)
	@composer install --no-progress --prefer-dist --optimize-autoloader
else ifeq ($(COMMAND_ARGS),update)
	@composer update
else ifeq ($(COMMAND_ARGS),validate)
	@composer validate
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

env: .env ## Scripts Installation environnement
ifeq ($(COMMAND_ARGS),dev)
	@sed -i 's/APP_ENV=prod/APP_ENV=dev/g' apps/.env
else ifeq ($(COMMAND_ARGS),prod)
	@sed -i 's/APP_ENV=dev/APP_ENV=prod/g' apps/.env
	@rm -rf vendor
	@make composer prod -i
else
	@echo "ARGUMENT missing"
	@echo "---"
	@echo "make env ARGUMENT"
	@echo "---"
	@echo "dev: environnement dev"
	@echo "prod: environnement prod"
endif

geocode: ## add geocode
	php -d memory_limit=-1 bin/console labstag:geocode:install $(COMMAND_ARGS)

linter: phpcpd.phar phploc.phar phpmd.phar ## Scripts Linter
ifeq ($(COMMAND_ARGS),all)
	@make linter twig -i
	@make linter container -i
	@make linter yaml -i
	@make linter phpstan -i
	@make linter phpcpd -i
	@make linter phpcs -i
	@make linter phpmd -i
	@make linter readme -i
else ifeq ($(COMMAND_ARGS),phpcbf)
	@COMPOSER_MEMORY_LIMIT=-1 composer run phpcbf
else ifeq ($(COMMAND_ARGS),phpcpd)
	@php phpcpd.phar src tests
else ifeq ($(COMMAND_ARGS),phpcs)
	@COMPOSER_MEMORY_LIMIT=-1 composer run phpcs
else ifeq ($(COMMAND_ARGS),phpcs-onlywarning)
	@COMPOSER_MEMORY_LIMIT=-1 composer run phpcs-onlywarning
else ifeq ($(COMMAND_ARGS),phpcs-onlyerror)
	@COMPOSER_MEMORY_LIMIT=-1 composer run phpcs-onlyerror
else ifeq ($(COMMAND_ARGS),phploc)
	@php phploc.phar src
else ifeq ($(COMMAND_ARGS),phpmd)
	@php phpmd.phar src,features/bootstrap,tests ansi phpmd.xml
else ifeq ($(COMMAND_ARGS),phpmnd)
	@COMPOSER_MEMORY_LIMIT=-1 composer run phpmnd
else ifeq ($(COMMAND_ARGS),phpstan)
	@COMPOSER_MEMORY_LIMIT=-1 composer run phpstan
else ifeq ($(COMMAND_ARGS),container)
	${SYMFONY_EXEC} lint:container
else ifeq ($(COMMAND_ARGS),twig)
	${SYMFONY_EXEC} lint:twig templates
else ifeq ($(COMMAND_ARGS),yaml)
	${SYMFONY_EXEC} lint:yaml config
else
	@echo "ARGUMENT missing"
	@echo "---"
	@echo "make linter ARGUMENT"
	@echo "---"
	@echo "all: ## Launch all linter"
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

messenger: ## Scripts messenger
ifeq ($(COMMAND_ARGS),consule)
	${SYMFONY_EXEC} messenger:consume async -vv
else
	@echo "ARGUMENT missing"
	@echo "---"
	@echo "make messenger ARGUMENT"
	@echo "---"
	@echo "consume: Messenger Consume"
endif

.PHONY: tests
tests: ## Scripts tests
ifeq ($(COMMAND_ARGS),launch)
	@make tests behat -i
	@make tests simple-phpunit -i
else ifeq ($(COMMAND_ARGS),behat)
	@COMPOSER_MEMORY_LIMIT=-1 composer run behat
else ifeq ($(COMMAND_ARGS),simple-phpunit-unit-integration)
	@COMPOSER_MEMORY_LIMIT=-1 composer run simple-phpunit-unit-integration
else ifeq ($(COMMAND_ARGS),simple-phpunit)
	@COMPOSER_MEMORY_LIMIT=-1 composer run simple-phpunit
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

.PHONY: translations
translations: ## update translation
	${SYMFONY_EXEC} translation:update --force fr

workflow-png: ## generate workflow png
	${SYMFONY_EXEC} workflow:dump $(COMMAND_ARGS) | dot -Tpng -o $(COMMAND_ARGS).png
include make/general/Makefile
STACK         := symfony
NETWORK       := proxylampy
include make/docker/Makefile

PHPFPMFULLNAME := $(STACK)_phpfpm.1.$$(docker service ps -f 'name=$(STACK)_phpfpm' $(STACK)_phpfpm -q --no-trunc | head -n1)

DOCKER_EXECPHP := @$(DOCKER_EXEC) $(PHPFPMFULLNAME)

SUPPORTED_COMMANDS := workflow-png tests messenger linter install geocode env encore composer bdd
SUPPORTS_MAKE_ARGS := $(findstring $(firstword $(MAKECMDGOALS)), $(SUPPORTED_COMMANDS))
ifneq "$(SUPPORTS_MAKE_ARGS)" ""
  COMMANDS_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  $(eval $(COMMANDS_ARGS):;@:)
endif

SYMFONY_EXEC := ${DOCKER_EXECPHP} symfony console
COMPOSER_EXEC := ${DOCKER_EXECPHP} symfony composer
PHP_EXEC := ${DOCKER_EXECPHP} php

apps/.env: apps/.env.dist ## Install .env
	@cp apps/.env.dist apps/.env

apps/phploc.phar:
	$(DOCKER_EXECPHP) wget https://phar.phpunit.de/phploc-7.0.2.phar -O phploc.phar

apps/phpmd.phar:
	$(DOCKER_EXECPHP) wget https://github.com/phpmd/phpmd/releases/download/2.10.2/phpmd.phar

assets: isdocker
	${SYMFONY_EXEC} assets:install public --symlink --relative

.PHONY: bdd
bdd: isdocker ### Scripts for BDD
ifeq ($(COMMANDS_ARGS),fixtures)
	${SYMFONY_EXEC} doctrine:fixtures:load -n
else ifeq ($(COMMANDS_ARGS),migrate)
	${SYMFONY_EXEC} doctrine:migrations:migrate -n
else ifeq ($(COMMANDS_ARGS),validate)
	${SYMFONY_EXEC} doctrine:schema:validate
else
	@printf "${MISSING_ARGUMENTS}" "bdd"
	$(call array_arguments, \
		["fixtures"]="fixtures" \
		["migrate"]="migrate database" \
		["validate"]="bdd validate" \
	)
endif

.PHONY: composer
composer: isdocker ### Scripts for composer
ifeq ($(COMMANDS_ARGS),suggests)
	${COMPOSER_EXEC} suggests --by-suggestion
else ifeq ($(COMMANDS_ARGS),outdated)
	${COMPOSER_EXEC} outdated
else ifeq ($(COMMANDS_ARGS),fund)
	${COMPOSER_EXEC} fund
else ifeq ($(COMMANDS_ARGS),prod)
	${COMPOSER_EXEC} install --no-dev --no-progress --prefer-dist --optimize-autoloader
else ifeq ($(COMMANDS_ARGS),dev)
	${COMPOSER_EXEC} install --no-progress --prefer-dist --optimize-autoloader
else ifeq ($(COMMANDS_ARGS),u)
	${COMPOSER_EXEC} update
else ifeq ($(COMMANDS_ARGS),i)
	${COMPOSER_EXEC} install
else ifeq ($(COMMANDS_ARGS),validate)
	${COMPOSER_EXEC} validate
else
	@printf "${MISSING_ARGUMENTS}" "composer"
	$(call array_arguments, \
		["suggests"]="suggestions package pour PHP" \
		["i"]="install" \
		["outdated"]="Packet php outdated" \
		["fund"]="Discover how to help fund the maintenance of your dependencies." \
		["prod"]="Installation version de prod" \
		["dev"]="Installation version de dev" \
		["u"]="COMPOSER update" \
		["validate"]="COMPOSER validate" \
	)
endif

encore: node_modules ##" Script for Encore
ifeq ($(COMMANDS_ARGS),dev)
	@npm rebuild node-sass
	@npm run encore-dev
else ifeq ($(COMMANDS_ARGS),watch)
	@npm run encore-watch
else
	@printf "${MISSING_ARGUMENTS}" "encore"
	$(call array_arguments, \
		["dev"]="créer les assets en version dev" \
		["watch"]="créer les assets en version watch" \
	)
endif

env: apps/.env ### Scripts Installation environnement
ifeq ($(COMMANDS_ARGS),dev)
	@sed -i 's/APP_ENV=prod/APP_ENV=dev/g' apps/.env
else ifeq ($(COMMANDS_ARGS),prod)
	@sed -i 's/APP_ENV=dev/APP_ENV=prod/g' apps/.env
	@rm -rf apps/vendor
	@make composer prod -i
else
	@printf "${MISSING_ARGUMENTS}" "env"
	$(call array_arguments, \
		["dev"]="environnement dev" \
		["prod"]="environnement prod" \
	)
endif

install: apps/.env ### installation
ifeq ($(COMMANDS_ARGS),all)
	@make node_modules -i
	@make docker deploy -i
	@make sleep 60 -i
	@make bdd migrate -i
	@make assets -i
	@make encore dev -i
	@make linter all -i
else ifeq ($(COMMANDS_ARGS),dev)
	@make install all
	@make bdd fixtures -i
else
	@printf "${MISSING_ARGUMENTS}" "install"
	$(call array_arguments, \
		["all"]="common" \
		["dev"]="dev" \
	)
endif

linter: node_modules isdocker apps/phploc.phar apps/phpmd.phar ### Scripts Linter
ifeq ($(COMMANDS_ARGS),all)
	@make linter eslint -i
	@make linter twig -i
	@make linter container -i
	@make linter yaml -i
	@make linter phpstan -i
	@make linter phpcs -i
	@make linter phpmd -i
	@make linter readme -i
else ifeq ($(COMMANDS_ARGS),phpaudit)
	@make linter phpcs -i
	@make linter phpmd -i
	@make linter phpmnd -i
	@make linter phpstan -i
else ifeq ($(COMMANDS_ARGS),readme)
	@npm run linter-markdown README.md
else ifeq ($(COMMANDS_ARGS),stylelint)
	@npm run stylelint
else ifeq ($(COMMANDS_ARGS),stylelint-fix)
	@npm run stylelint-fix
else ifeq ($(COMMANDS_ARGS),jscpd)
	@npm run jscpd
else ifeq ($(COMMANDS_ARGS),jscpd-report)
	@npm run jscpd-report
else ifeq ($(COMMANDS_ARGS),eslint)
	@npm run eslint
else ifeq ($(COMMANDS_ARGS),eslint-fix)
	@npm run eslint-fix
else ifeq ($(COMMANDS_ARGS),composer)
	@make composer validate -i
	@make composer outdated -i
else ifeq ($(COMMANDS_ARGS),eslint-fix)
	@npm run eslint-fix
else ifeq ($(COMMANDS_ARGS),phpcbf)
	${COMPOSER_EXEC} run phpcbf
else ifeq ($(COMMANDS_ARGS),phpcs)
	${COMPOSER_EXEC} run phpcs
else ifeq ($(COMMANDS_ARGS),phpcs-onlywarning)
	${COMPOSER_EXEC} run phpcs-onlywarning
else ifeq ($(COMMANDS_ARGS),phpcs-onlyerror)
	${COMPOSER_EXEC} run phpcs-onlyerror
else ifeq ($(COMMANDS_ARGS),phploc)
	$(PHP_EXEC) phploc.phar src
else ifeq ($(COMMANDS_ARGS),phpmd)
	$(PHP_EXEC) -d error_reporting=24575 phpmd.phar src,features/bootstrap,tests ansi phpmd.xml
else ifeq ($(COMMANDS_ARGS),phpmnd)
	${COMPOSER_EXEC} run phpmnd
else ifeq ($(COMMANDS_ARGS),phpstan)
	${PHP_EXEC} -d memory_limit=-1 -n ./bin/phpstan analyse src
else ifeq ($(COMMANDS_ARGS),twig)
	${SYMFONY_EXEC} lint:twig templates
else ifeq ($(COMMANDS_ARGS),container)
	${SYMFONY_EXEC} lint:container
else ifeq ($(COMMANDS_ARGS),yaml)
	${SYMFONY_EXEC} lint:yaml config
else
	@printf "${MISSING_ARGUMENTS}" "linter"
	$(call array_arguments, \
		["all"]="## Launch all linter" \
		["composer"]="composer" \
		["phpaudit"]="AUDIT PHP" \
		["readme"]="linter README.md" \
		["jscpd"]="Copy paste detector" \
		["jscpd-report"]="Copy paste detector report" \
		["stylelint"]="indique les erreurs dans le code SCSS" \
		["stylelint-fix"]="fix les erreurs dans le code SCSS" \
		["eslint"]="indique les erreurs sur le code JavaScript à partir d'un standard" \
		["eslint-fix"]="fixe le code JavaScript à partir d'un standard" \
		["phpcbf"]="fixe le code PHP à partir d'un standard" \
		["phpcs"]="indique les erreurs de code non corrigé par PHPCBF" \
		["phpcs-onlywarning"]="indique les erreurs de code non corrigé par PHPCBF" \
		["phpcs-onlyerror"]="indique les erreurs de code non corrigé par PHPCBF" \
		["phploc"]="phploc" \
		["phpmd"]="indique quand le code PHP contient des erreurs de syntaxes ou des erreurs" \
		["phpmnd"]="Si des chiffres sont utilisé dans le code PHP, il est conseillé d'utiliser des constantes" \
		["phpstan"]="regarde si le code PHP ne peux pas être optimisé" \
		["twig"]="indique les erreurs de code de twig" \
		["container"]="indique les erreurs de code de container" \
		["yaml"]="indique les erreurs de code de yaml" \
	)
endif

.PHONY: messenger
messenger: isdocker ### Scripts messenger
ifeq ($(COMMANDS_ARGS),consume)
	${SYMFONY_EXEC} messenger:consume async -vv
else
	@printf "${MISSING_ARGUMENTS}" "messenger"
	@printf "${NEED}" "consume" "Messenger Consume"
endif

.PHONY: tests
tests: isdocker ### Scripts tests
ifeq ($(COMMANDS_ARGS),launch)
	@make tests behat -i
	@make tests simple-phpunit -i
else ifeq ($(COMMANDS_ARGS),behat)
	${COMPOSER_EXEC} run behat
else ifeq ($(COMMANDS_ARGS),simple-phpunit-unit-integration)
	${COMPOSER_EXEC} run simple-phpunit-unit-integration
else ifeq ($(COMMANDS_ARGS),simple-phpunit)
	${COMPOSER_EXEC} run simple-phpunit
else
	@printf "${MISSING_ARGUMENTS}" "tests"
	$(call array_arguments, \
		["launch"]="Launch all tests" \
		["behat"]="Lance les tests behat" \
		["simple-phpunit-unit-integration"]="lance les tests phpunit" \
		["simple-phpunit"]="lance les tests phpunit" \
	)
endif

translations: isdocker ## update translation
	${SYMFONY_EXEC} translation:update --force --format=yml fr

workflow-png: isdocker ### generate workflow png
	${SYMFONY_EXEC} workflow:dump $(COMMANDS_ARGS) | dot -Tpng -o $(COMMANDS_ARGS).png

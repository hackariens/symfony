.DEFAULT_GOAL   := help

%:
	@:

help:
	@grep -E '(^[a-zA-Z_-]+:.*?##.*$$)|(^##)' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}' | sed -e 's/\[32m##/[33m/'

vendor:
	@make composer-dev -i

.env: ## Install .env
	cp .env.dist .env

bdd-fixtures: vendor ## fixtures
	php bin/console doctrine:fixtures:load -n

bdd-migrate: vendor ## migrate database
	php bin/console doctrine:migrations:migrate -n

bdd-validate: vendor ## bdd validate
	php bin/console doctrine:schema:validate

composer-suggests: ## suggestions package pour PHP
	composer suggests --by-suggestion

composer-outdated: ## Packet php outdated
	composer outdated

composer-prod: ## Installation version de production
	composer install --no-dev --no-progress --no-suggest --prefer-dist --optimize-autoloader

composer-dev: ## Installation version de dev
	composer install --no-progress --no-suggest --prefer-dist --optimize-autoloader

composer-update: ## COMPOSER update
	composer update

composer-validate: ## COMPOSER validate
	composer validate

env-dev: .env ## Installation environnement dev
	sed -i 's/APP_ENV=prod/APP_ENV=dev/g' .env

env-prod: .env ## Installation environnement prod
	sed -i 's/APP_ENV=dev/APP_ENV=prod/g' .env
	rm -rf vendor
	@make composer-prod -i

linter-phpcbf: vendor ## fixe le code PHP à partir d'un standard
	composer run phpcbf

linter-phpcs: vendor ## indique les erreurs de code non corrigé par PHPCBF
	composer run phpcs

linter-phpcs-onlywarning: vendor ## indique les erreurs de code non corrigé par PHPCBF
	composer run phpcs-onlywarning

linter-phpcs-onlyerror: vendor ## indique les erreurs de code non corrigé par PHPCBF
	composer run phpcs-onlyerror

linter-phpcpd: vendor ## verifie si il n'y a pas de copier / coller
	composer run phpcpd

linter-phpmd: vendor ## indique quand le code PHP contient des erreurs de syntaxes ou des erreurs
	composer run phpmd

linter-phpmnd: vendor ## Si des chiffres sont utilisé dans le code PHP, il est conseillé d'utiliser des constantes
	composer run phpmnd

linter-phpstan: vendor ## regarde si le code PHP ne peux pas être optimisé
	composer run phpstan

linter-twigcs: vendor ## indique les erreurs de code de twig
	composer run twigcs

sleep: ## sleep
	sleep 90

ssh: ## ssh
	docker exec -ti $(PHPFPMFULLNAME) /bin/bash

tests-behat: vendor ## Lance les tests behat
	composer behat

tests-launch: vendor ## Launch all tests
	@make tests-behat -i
	@make tests-phpunit -i

tests-phpunit: vendor ## lance les tests phpunit
	composer simple-phpunit
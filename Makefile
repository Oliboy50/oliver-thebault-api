#########################################################
######## VM #############################################
#########################################################

vm-download:
	test -f ansible/vars.local.yml || cp ansible/vars.local.yml.dist ansible/vars.local.yml
	ansible-galaxy install --force -p ansible --role-file=ansible/galaxy-majora.yml
	ansible-galaxy install --force -p ansible/roles --role-file=ansible/galaxy-additionals.yml

vm-ssh:
	vagrant ssh

vm-up:
	vagrant up

vm-halt:
	vagrant halt

vm-provision:
	vagrant up --no-provision
	vagrant provision

vm-destroy:
	vagrant destroy

vm-rebuild: vm-destroy vm-provision

vm-install-project: vm-download vm-provision vm-project-prepare

vm-project-prepare:
	vagrant ssh -c "cd $(WORKSPACE) && make prepare"

#########################################################
######## PROJECT ########################################
#########################################################

# First install
prepare: install
	@echo "Project is built !"

# Clean
clean:
	rm -rf app/cache/*
	rm -rf app/logs/*
	rm -rf vendor/composer/autoload*
	rm -rf app/bootstrap.php.cache
	test -d web/bundles && rm web/bundles/* || true
	test -d web/css && rm web/css/* || true
	test -d web/js && rm web/js/* || true
	bin/composer dump-autoload
	bin/composer run-script setup-bootstrap -vv
	php app/console cache:warmup
	php app/console cache:warmup --env=prod
	php app/console assets:install --symlink
	php app/console assetic:dump --force

clean-assets:
	test -d web/css && rm web/css/* || true
	test -d web/js && rm web/js/* || true
	php app/console assetic:dump --force

# Installation
install-bin:
	mkdir -p bin/
	mkdir -p wallet/
	test -f bin/composer || curl -sS https://getcomposer.org/installer | php -- --install-dir=bin --filename=composer
	bin/composer self-update
	test -f bin/php-cs-fixer || curl http://get.sensiolabs.org/php-cs-fixer.phar -o bin/php-cs-fixer
	php bin/php-cs-fixer self-update

install-git-hooks:
	test -f .git/hooks/pre-commit \
	|| (test -d .git \
		&& (curl https://raw.githubusercontent.com/LinkValue/symfony-git-hooks/master/pre-commit -o .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit) \
		|| true)

install-composer:
	bin/composer install

install: install-bin install-git-hooks install-composer clean

# Update
update: update-composer update-majora clean

update-majora:
	# php app/console majora:generate Namespace Entity -v

update-composer:
	bin/composer update --no-scripts
	bin/composer post-update

# Database
db-build:
	php app/console doctrine:database:create --if-not-exists
	php app/console doctrine:migrations:migrate -n
	php app/console doctrine:fixtures:load -n || true

db-trash:
	php app/console doctrine:database:drop --force --if-exists
	php app/console doctrine:database:create

db-rebuild: db-trash db-build

db-force: db-trash
	php app/console doctrine:schema:update --force
	php app/console doctrine:fixtures:load -n || true

db-update:
	php app/console doctrine:schema:validate || test "$$?" -gt 1
	php app/console doctrine:migrations:migrate -n
	php app/console doctrine:migrations:diff
	php app/console doctrine:migrations:migrate -n

# Tests
run-covered-tests:
	rm -rf web/tests-coverage/*
	bin/phpunit -c app --coverage-html web/tests-coverage
	@echo "\nCoverage report : \n\033[1;32m http://{{ PROJECT_URL }}/tests-coverage/index.html\033[0m\n"

run-tests:
	bin/phpunit -c app

# CI
install-ci: install-bin install-composer db-build clean

travis-install: install-ci
	curl https://scrutinizer-ci.com/ocular.phar -o bin/ocular.phar

travis-script:
	bin/phpunit -c app --coverage-clover=coverage.clover
	php bin/ocular.phar code-coverage:upload --access-token="{{ SCRUTINIZER_TOKEN }}" --format=php-clover coverage.clover

scrutinizer: install-ci

insight: install-ci

# Production
prod-install: install-bin
	bin/composer install --prefer-dist --no-dev

prod-build:
	php app/console doctrine:migration:migrate -n --env=prod

prod-clean:
	rm -rf app/cache/*
	rm -rf app/logs/*
	rm -rf vendor/composer/autoload*
	rm -rf app/bootstrap.php.cache
	test -d web/bundles && rm -rf web/bundles/* || true
	test -d web/css && rm -rf web/css/* || true
	test -d web/js && rm -rf web/js/* || true
	test -d web/fonts && rm -rf web/fonts/* || true
	test -d web/flags && rm -rf web/flags/* || true
	bin/composer dump-autoload -o
	bin/composer run-script setup-bootstrap -vv
	php app/console cache:warmup --env=prod
	php app/console assets:install --env=prod
	php app/console assetic:dump --force --env=prod

prod-deploy: prod-install prod-build prod-clean

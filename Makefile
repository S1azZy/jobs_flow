### Docker specific

ifndef VERBOSE
	MAKEFLAGS += --no-print-directory
endif

APP_USER_UID=$$($(MAKE) user_id)
APP_GROUP_GID=$$($(MAKE) user_group)

VERSION_BUILD_DATE := $$(date -u +%FT%TZ)
VERSION_BUILD_JOB_NUMBER := 0
VERSION_BRANCH := $$(git rev-parse --abbrev-ref HEAD)
VERSION_TAG := $$(git describe --exact-match --tags $(git log -n1 --pretty='%h') 2>>/dev/null  || echo 'none')
VERSION_SHA := $$(git rev-parse HEAD)

define BUILD_ARGS
--build-arg VERSION_BUILD_DATE="${VERSION_BUILD_DATE}" \
--build-arg VERSION_BUILD_JOB_NUMBER="${VERSION_BUILD_JOB_NUMBER}" \
--build-arg VERSION_BRANCH="${VERSION_BRANCH}" \
--build-arg VERSION_TAG="${VERSION_TAG}" \
--build-arg VERSION_SHA="${VERSION_SHA}"
endef

user_id:
	@echo $$(id -u)

user_group:
	@if [ $$(id -g) -lt 1000 ]; then echo 1000; else echo $$(id -g); fi

create_history_files:
	touch .bash_history
	touch .irb_history

set_envs:
	export APP_USER_UID=$(APP_USER_UID) APP_GROUP_GID=$(APP_GROUP_GID)

db_setup:
	eval $$($(MAKE) set_envs) && docker compose --rm --use-aliases -u $(APP_USER_UID) api bash -c "make db_test_reset"

build: create_history_files
	eval $$($(MAKE) set_envs) && docker compose build ${BUILD_ARGS}

up:
	eval $$($(MAKE) set_envs) && docker compose up

down:
	eval $$($(MAKE) set_envs) && docker compose down

stop:
	eval $$($(MAKE) set_envs) && docker compose stop

api_bash:
	eval $$($(MAKE) set_envs) && docker compose run --rm --use-aliases -u $(APP_USER_UID) api bash

api_exec_bash:
	eval $$($(MAKE) set_envs) && docker compose exec -u $(APP_USER_UID) api bash

### Not docker specific

db_create:
	bundle exec rails db:create

db_migrate:
	bundle exec rails db:migrate

db_test_setup:
	bundle exec rails db:test:prepare

db_test_reset:
	bundle exec rails db:create db:migrate && bundle exec rails db:test:prepare

rubocop:
	bundle exec rubocop --color

lint: rubocop

rubocop_autofix:
	bundle exec rubocop --color -a

lint_a: rubocop_autofix

rubocop_autocorrect: rubocop_autofix

rubocop_autofix_unsafe:
	bundle exec rubocop --color -A

rubocop_autocorrect_unsafe: rubocop_autofix_unsafe

lint_au: rubocop_autofix_unsafe

brakeman:
	bundle exec brakeman --color

bundler_audit:
	bundle exec bundler-audit check --update

reek:
	bundle exec reek

tests:
	RAILS_ENV=test bundle exec rspec

tests_coverage:
	RAILS_ENV=test COVERAGE='true' bundle exec rspec

tests_ci:
	RAILS_ENV=test COVERAGE='true' bundle exec rspec --color --format documentation --format RspecJunitFormatter --out tmp/rspec/tests.xml

include .env
export

export PROJECT_ROOT=$(shell pwd)

env-up:        ## Запустить окружение
	@docker compose up -d todoapp-postgres

env-down:      ## Остановить окружение
	@docker compose down todoapp-postgres port-forwarder

env-cleanup:   ## Удалить данные окружения (volume)
	@read -p "Очистить volume? Опасность утери данных. [y/N]: " ans; \
	if [ "$$ans" = "y" ]; then \
		docker compose down todoapp-postgres port-forwarder && \
		rm -rf ${PROJECT_ROOT}/out/pgdata; \
	fi

env-port-forward: ## Открыть порт к базе
	@docker compose up -d port-forwarder

env-port-close:   ## Закрыть порт
	@docker compose down port-forwarder

migrate-create:   ## Создать новую версию схемы
	@test -n "$(seq)" || (echo "seq обязателен: make migrate-create seq=name"; exit 1)
	@docker compose run --rm todoapp-postgres-migrate \
		create -ext sql -dir /migrations -seq "$(seq)"

migrate-up:       ## Накатить миграции
	@make migrate-action action=up

migrate-down:     ## Откатить миграции
	@make migrate-action action=down

migrate-action:   ## Выполнить команду миграции
	@docker compose run --rm todoapp-postgres-migrate \
		-path /migrations \
		-database postgres://$(POSTGRES_USER):$(POSTGRES_PASSWORD)@todoapp-postgres:5432/$(POSTGRES_DB)?sslmode=disable \
		"$(action)"
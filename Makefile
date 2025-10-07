COMPOSE ?= docker-compose
DUCKDB_SEED ?= ./scripts/seed_duckdb.sh
BOOTSTRAP ?= ./scripts/bootstrap_metabase_content.sh

.PHONY: seed up down restart logs bootstrap status clean

seed:
	@$(DUCKDB_SEED)

up: seed
	@$(COMPOSE) up -d

down:
	@$(COMPOSE) down

restart: down up

logs:
	@$(COMPOSE) logs -f

status:
	@$(COMPOSE) ps

bootstrap:
	@$(BOOTSTRAP)

clean:
	@$(COMPOSE) down --volumes
	@rm -f duckdb/sample.duckdb

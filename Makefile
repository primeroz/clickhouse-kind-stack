.ONESHELL: # Applies to every targets in the file!

.PHONY: help
help: # Show help for each of the Makefile recipes.
	@grep -E '^[a-zA-Z0-9 -]+:.*#'  Makefile | sort | while read -r l; do printf "\033[1;32m$$(echo $$l | cut -f 1 -d':')\033[00m:$$(echo $$l | cut -f 2- -d'#')\n"; done

.PHONY: run
run: create-kind # Run the project
	$(MAKE) check-kind-context
	$(MAKE) create-ingress
	sleep 30 # Wait for ingress webhook to be available
	$(MAKE) create-clickhouse
	$(MAKE) create-superset

.PHONY: check-kind-context
check-kind-context: # Check the current context is the kind expected ONESHELL
	exit 0

.PHONY: create-ingress
create-ingress: # Install the Nginx ingress Controller
	$(MAKE) -C nginx-ingress create

.PHONY: create-superset
create-superset: # Install the Superset Workload
	$(MAKE) -C superset create

.PHONY: create-jupyterhub
create-jupyterhub: # Install the Jupyterhub
	$(MAKE) -C jupyter create

.PHONY: create-clickhouse
create-clickhouse: # Install the clickhouse
	$(MAKE) -C clickhouse-single-server create

.PHONY: create-kind
create-kind: # Create the kind cluster
	@./kind.sh exists || ./kind.sh create

.PHONY: clean
clean: # Clean the project
	@./kind.sh delete


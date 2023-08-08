.ONESHELL: # Applies to every targets in the file!

.PHONY: help
help: # Show help for each of the Makefile recipes.
	@grep -E '^[a-zA-Z0-9 -]+:.*#'  Makefile | sort | while read -r l; do printf "\033[1;32m$$(echo $$l | cut -f 1 -d':')\033[00m:$$(echo $$l | cut -f 2- -d'#')\n"; done

.PHONY: create
create: # Install the Clickhouse-server workload
	@source ../common ;\
  e_header "Creating Clickhouse-server" ;\
	kubecfg -J ../lib show -e "(import 'main.jsonnet').resources.namespace" | kubectl --server-side=true apply -f -; \
	sleep 1
	kubecfg -J ../lib show main.jsonnet | kubectl --server-side=true apply -f -; \
	sleep 5
	kubectl rollout status --namespace clickhouse --timeout=90s statefulset/clickhouse-server; \
  e_success "Done"


.PHONY: show
show:  # Show the manifests
	kubecfg -J ../lib show main.jsonnet

#.PHONY: clean
#clean: # Clean the project


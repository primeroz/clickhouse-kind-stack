.ONESHELL: # Applies to every targets in the file!

.PHONY: help
help: # Show help for each of the Makefile recipes.
	@grep -E '^[a-zA-Z0-9 -]+:.*#'  Makefile | sort | while read -r l; do printf "\033[1;32m$$(echo $$l | cut -f 1 -d':')\033[00m:$$(echo $$l | cut -f 2- -d'#')\n"; done

.PHONY: create
create: # Install the Clickhouse-server workload
	@source ../common ;\
  e_header "Creating Clickhouse-server" ;\
	kubecfg -J ../lib update main.jsonnet
	kubectl rollout status --namespace clickhouse --timeout=90s statefulset/clickhouse-server; \
  e_success "Done"


.PHONY: show
show:  # Show the manifests
	kubecfg -J ../lib show main.jsonnet

#.PHONY: clean
#clean: # Clean the project


.ONESHELL: # Applies to every targets in the file!
JUPYTER_VERSION=0.10.5


.PHONY: help
help: # Show help for each of the Makefile recipes.
	@grep -E '^[a-zA-Z0-9 -]+:.*#'  Makefile | sort | while read -r l; do printf "\033[1;32m$$(echo $$l | cut -f 1 -d':')\033[00m:$$(echo $$l | cut -f 2- -d'#')\n"; done

.PHONY: update-helm
update-helm: # Update helm vendored version
	helm repo add superset https://apache.github.io/superset
	helm repo update superset
	helm pull superset/superset -d upstream --version ${JUPYTER_VERSION}


.PHONY: create
create: # Install the Superset Workload
	@source ../common ;\
  e_header "Creating Apache Superset" ;\
	kubecfg -J ../lib update main.jsonnet --validate=true; \
	kubectl wait --namespace superset --for=condition=available --timeout=90s deploy/superset; \
	kubectl wait --namespace superset --for=condition=available --timeout=90s deploy/superset-worker; \
	kubectl rollout status --namespace superset --timeout=90s statefulset/superset-postgresql; \
	kubectl rollout status --namespace superset --timeout=90s statefulset/superset-redis-master; \
	kubectl wait --namespace superset --timeout=90s --for=condition=complete job superset-init-db; \
  e_success "Done"


.PHONY: show
show:  # Show the manifests
	kubecfg -J ../lib show main.jsonnet

#.PHONY: clean
#clean: # Clean the project


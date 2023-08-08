.ONESHELL: # Applies to every targets in the file!

.PHONY: help
help: # Show help for each of the Makefile recipes.
	@grep -E '^[a-zA-Z0-9 -]+:.*#'  Makefile | sort | while read -r l; do printf "\033[1;32m$$(echo $$l | cut -f 1 -d':')\033[00m:$$(echo $$l | cut -f 2- -d'#')\n"; done

.PHONY: create
create: create-gateway create-nginx # Install the NGINX Gateway Controller

.PHONY: create-gateway create-nginx
create-gateway: # Create the Gateway API Resources
	@source ../common ;\
	e_header "Creating Gateway API resources" ;\
	kubecfg -J ../lib update gateway.jsonnet --validate=false; \
	kubectl wait --namespace gateway-system --for=condition=available --timeout=90s deploy/gateway-api-admission-server; \
	kubectl wait --namespace gateway-system --timeout=60s --for=condition=complete job gateway-api-admission; \
	kubectl wait --namespace gateway-system --timeout=60s --for=condition=complete job gateway-api-admission-patch; \
  e_success "Done"

create-nginx: # Create the Gateway API Resources
	@source ../common ;\
  e_header "Creating NGINX Gateway controller" ;\
	kubecfg -J ../lib update main.jsonnet --validate=false; \
	kubectl wait --namespace nginx-gateway --for=condition=available --timeout=90s deploy/nginx-gateway; \
  e_success "Done"

.PHONY: show
show:  # Show the manifests
	kubecfg -J ../lib show main.jsonnet
#.PHONY: clean
#clean: # Clean the project


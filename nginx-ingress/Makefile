.ONESHELL: # Applies to every targets in the file!

.PHONY: help
help: # Show help for each of the Makefile rec
	@grep -E '^[a-zA-Z0-9 -]+:.*#'  Makefile | sort | while read -r l; do printf "\033[1;32m$$(echo $$l | cut -f 1 -d':')\033[00m:$$(echo $$l | cut -f 2- -d'#')\n"; done

.PHONY: create
create: create-nginx # Install the NGINX Gateway Controller

create-nginx: # Create Nginx Ingress Controller
	@source ../common ;\
  e_header "Creating NGINX Ingress controller" ;\
	kubecfg -J ../lib update main.jsonnet --validate=true; \
	kubectl wait --namespace ingress-nginx --for=condition=available --timeout=90s deploy/ingress-nginx-controller; \
	kubectl wait --namespace ingress-nginx --timeout=90s --for=condition=complete job ingress-nginx-admission-create; \
	kubectl wait --namespace ingress-nginx --timeout=90s --for=condition=complete job ingress-nginx-admission-patch; \
  e_success "Done"

.PHONY: show
show:  # Show the manifests
	kubecfg -J ../lib show main.jsonnet
#.PHONY: clean
#clean: # Clean the project


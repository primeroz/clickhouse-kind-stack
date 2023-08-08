.ONESHELL: # Applies to every targets in the file!

.PHONY: help
help: # Show help for each of the Makefile recipes.
	@grep -E '^[a-zA-Z0-9 -]+:.*#'  Makefile | sort | while read -r l; do printf "\033[1;32m$$(echo $$l | cut -f 1 -d':')\033[00m:$$(echo $$l | cut -f 2- -d'#')\n"; done

.PHONY: create
create: # Install the Contour Gateway Controller
	@source ../common ;\
  e_header "Creating Contour Gateway controller" ;\
	kubecfg -J ../lib show -e "(import 'main.jsonnet').objects.phase0" | kubectl --server-side=true apply -f -; \
	sleep 2
	kubecfg -J ../lib show -e "(import 'main.jsonnet').objects.phase1" | kubectl --server-side=true apply -f -; \
	sleep 5
	kubectl wait --namespace projectcontour --for=condition=available --timeout=90s deploy/contour-gateway-provisioner; \
	kubectl wait --namespace gateway-system --for=condition=available --timeout=90s deploy/gateway-api-admission-server; \
	kubectl wait --namespace gateway-system --timeout=60s --for=condition=complete job gateway-api-admission; \
	kubectl wait --namespace gateway-system --timeout=60s --for=condition=complete job gateway-api-admission-patch; \
	kubecfg -J ../lib show -e "(import 'main.jsonnet').objects.phase2" | kubectl --server-side=true apply -f -; \
  e_success "Done"

.PHONY: show
show:  # Show the manifests
	kubecfg -J ../lib show main.jsonnet
#.PHONY: clean
#clean: # Clean the project


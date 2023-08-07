.ONESHELL: # Applies to every targets in the file!

.PHONY: help
help: # Show help for each of the Makefile recipes.
	@grep -E '^[a-zA-Z0-9 -]+:.*#'  Makefile | sort | while read -r l; do printf "\033[1;32m$$(echo $$l | cut -f 1 -d':')\033[00m:$$(echo $$l | cut -f 2- -d'#')\n"; done

.PHONY: run
run: create-kind # Run the project
	exit 0

.PHONY: create-contour-gateway
create-contour-gateway: # Install the Contour Gateway Controller
	$(MAKE) -C contour-gateway-controller create

.PHONY: create-jupyterhub
create-jupyterhub: # Install the Jupyterhub
	$(MAKE) -C jupyter create

.PHONY: create-kind
create-kind: # Create the kind cluster
	@./kind.sh exists || ./kind.sh create

.PHONY: clean
clean: # Clean the project
	@./kind.sh delete


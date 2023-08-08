.ONESHELL: # Applies to every targets in the file!
JUPYTER_VERSION=2.0.0


.PHONY: help
help: # Show help for each of the Makefile recipes.
	@grep -E '^[a-zA-Z0-9 -]+:.*#'  Makefile | sort | while read -r l; do printf "\033[1;32m$$(echo $$l | cut -f 1 -d':')\033[00m:$$(echo $$l | cut -f 2- -d'#')\n"; done

.PHONY: update-helm
update-helm: # Update helm vendored version
	helm repo add jupyterhub https://jupyterhub.github.io/helm-chart/
	helm repo update jupyterhub
	helm pull jupyterhub/jupyterhub -d upstream --version ${JUPYTER_VERSION}


.PHONY: create
create: # Install the JupyterHub workload
	@source ../common ;\
  e_header "Creating JupyterHub" ;\
	kubecfg -J ../lib show -e "(import 'main.jsonnet').objects.phase0" | kubectl --server-side=true apply -f -; \
	sleep 2
	kubecfg -J ../lib show -e "(import 'main.jsonnet').objects.phase1" | kubectl --server-side=true apply -f -; \
	sleep 5
	kubectl wait --namespace jupyterhub --for=condition=available --timeout=90s deploy/hub; \
	kubectl wait --namespace jupyterhub --for=condition=available --timeout=90s deploy/proxy; \
	kubectl wait --namespace jupyterhub --for=condition=available --timeout=90s deploy/user-scheduler; \
	kubectl rollout status --namespace jupyterhub --timeout=90s daemonset/continuous-image-puller; \
	kubectl rollout status --namespace jupyterhub --timeout=90s daemonset/hook-image-puller; \
	kubectl wait --namespace jupyterhub --timeout=90s --for=condition=complete job hook-image-awaiter; \
  e_success "Done"


.PHONY: show
show:  # Show the manifests
	kubecfg -J ../lib show main.jsonnet

#.PHONY: clean
#clean: # Clean the project


.ONESHELL: # Applies to every targets in the file!
VERSION=1.10.0


.PHONY: help
help: # Show help for each of the Makefile recipes.
	@grep -E '^[a-zA-Z0-9 -]+:.*#'  Makefile | sort | while read -r l; do printf "\033[1;32m$$(echo $$l | cut -f 1 -d':')\033[00m:$$(echo $$l | cut -f 2- -d'#')\n"; done

.PHONY: update-helm
update-helm: # Update helm vendored version
	helm repo add apache-airflow https://airflow.apache.org
	helm repo update apache-airflow
	helm pull apache-airflow/airflow -d upstream --version ${VERSION}


.PHONY: create
create: # Install the airflow Workload
	@source ../common ;\
  e_header "Creating Apache Airflow" ;\
	kubecfg -J ../lib update main.jsonnet --validate=true; \
	kubectl wait --namespace airflow --for=condition=available --timeout=90s deploy/airflow-scheduler; \
	kubectl wait --namespace airflow --for=condition=available --timeout=90s deploy/airflow-statsd; \
	kubectl wait --namespace airflow --for=condition=available --timeout=90s deploy/airflow-webserver; \
	kubectl rollout status --namespace airflow --timeout=90s statefulset/airflow-postgresql; \
	kubectl rollout status --namespace airflow --timeout=90s statefulset/airflow-redis; \
	kubectl rollout status --namespace airflow --timeout=90s statefulset/airflow-triggerer; \
	kubectl rollout status --namespace airflow --timeout=90s statefulset/airflow-worker; \
	kubectl wait --namespace airflow --timeout=90s --for=condition=complete job airflow-create-user; \
	kubectl wait --namespace airflow --timeout=90s --for=condition=complete job airflow-run-airflow-migrations; \
  e_success "Done"


.PHONY: show
show:  # Show the manifests
	kubecfg -J ../lib show main.jsonnet

#.PHONY: clean
#clean: # Clean the project


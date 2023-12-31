## Clickhouse Kind Stack

### A stack for testing Clickhouse with different tools 

* clickhouse server ( single server mode)
  * access as `http://clickhouse.127.0.0.1.nip.io` for http access
  * access as `clickhouse client -h clickhouse.127.0.0.1.nip.io` for native client access
* jupyterHub
  * access as `http://jupyter.127.0.0.1.nip.io` for http access
  * any user / password combination is valid and will spawn a dedicated hub for the user
* Apache SuperSet 
  * access as `http://superset.127.0.0.1.nip.io` for http access with `admin/admin` credentials
* Apache Airflow 
  * access as `http://airflow.127.0.0.1.nip.io` for http access with `admin/admin` credentials

### TODO

* Clickhouse
  * add readyness and liveness probes
* jupyterHub
  * Build image with clickhouse Libraries
  * Sync notebooks 
  * Authentication
* SuperSet
  * Authentication
  * Persist Database
  * CeleryBeat alerting
* AIRFLOW
  * authentication 
  * persist Database
  * git sync DAGs - Helm chart already supports it

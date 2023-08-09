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

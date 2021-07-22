# Demonstration of scanning images in Harbor using Lacework
This demonstration shows how to enable integration between Harbor and Lacework to ensure all images in Harbor automatically gets scanned by Lacework.

The demo runs on a regular Mac with Docker Desktop installed and run both Harbor and the Lacework Proxy Scanner on your desktop.

## Pre-Requisites
### Generate container registry credentials in Lacework CLI
* Log on to the Lacework UI
* Navigate to Settings
* Go to Container Registries section
* Create a new container registry of the type, Proxy Scanner
* Click on new registry and take note of the proxy scanner authorization token. Also take note of the name of your lacework account.
![Lacework Registry Configuration Section](/images/lacework-registry-screenshot.png)
### Enable Docker to trust the locally deployed registry
In order to interract with Harbor from your desktop, the registry instance will need to be added to the Docker configuration as an insecure registry.
* Open the Docker Desktop preferences UI
* Click on the `Docker Engine` section
* Add `http://kubernetes.docker.internal/` to the `insecure-registries` section
![Docker Insecure Registry Section](/images/insecure-registry.png)

## Start Demo
In a terminal window, clone the demo repository, go to the directory and start the demo. Remember to provide the lacework account name and proxy scanner authorization token, as configured in the pre-requisites.
```
$ git clone https://github.com/bvboe/lacework-harbor-demo/
$ cd lacework-harbor-demo
$ ./install.sh <lacework account name> <authorization token>
```

## Validate the demo is running
```
$ docker ps
CONTAINER ID   IMAGE                             COMMAND                  CREATED          STATUS          PORTS                                             NAMES
10f309562653   lacework/lacework-proxy-scanner   "sh ./run.sh"            10 seconds ago   Up 5 seconds    0.0.0.0:8080->8080/tcp, :::8080->8080/tcp         lacework-proxy-scanner
9522a89e5fe1   bitnami/nginx:1.21                "/opt/bitnami/script…"   14 seconds ago   Up 9 seconds    8443/tcp, 0.0.0.0:80->8080/tcp, :::80->8080/tcp   nginx
89e864f50d26   bitnami/harbor-portal:2           "/opt/bitnami/script…"   19 seconds ago   Up 14 seconds   8080/tcp, 8443/tcp                                harbor-portal
0deaae7fd8db   bitnami/harbor-jobservice:2       "/opt/bitnami/script…"   19 seconds ago   Up 13 seconds   8080/tcp, 8443/tcp                                harbor-jobservice
3653dfb7a781   bitnami/harbor-core:2             "/opt/bitnami/script…"   22 seconds ago   Up 18 seconds   8080/tcp                                          harbor-core
1686809f2527   bitnami/harbor-registryctl:2      "/opt/bitnami/script…"   32 seconds ago   Up 22 seconds   8080/tcp, 8443/tcp                                bitnami-docker-harbor-portal-master_registryctl_1
f62f67987ce5   bitnami/harbor-registry:2         "/opt/bitnami/script…"   32 seconds ago   Up 21 seconds   5000/tcp                                          bitnami-docker-harbor-portal-master_registry_1
f606ab3af38f   bitnami/redis:6.0                 "/opt/bitnami/script…"   31 hours ago     Up 22 seconds   6379/tcp                                          bitnami-docker-harbor-portal-master_redis_1
3930ba604523   bitnami/postgresql:11             "/opt/bitnami/script…"   31 hours ago     Up 22 seconds   5432/tcp                                          harbor-db
2a06b62b59f0   bitnami/chartmuseum:0             "/opt/bitnami/script…"   31 hours ago     Up 24 seconds                                                     chartmuseum
```

```
$ docker logs lacework-proxy-scanner
[DEBUG]:   2021-07-22 20:20:49 - Welcome.
[DEBUG]:   2021-07-22 20:20:50 - Starting ScanDataHandler worker
[DEBUG]:   2021-07-22 20:20:50 - Starting Scanner workers
[DEBUG]:   2021-07-22 20:20:50 - Starting Scanner worker for registry : kubernetes.docker.internal
[DEBUG]:   2021-07-22 20:20:50 - Starting Registry Tracker workers
[INFO]:   2021-07-22 20:20:50 - Starting server..
[INFO]:   2021-07-22 20:20:50 - RegistryScannerWorkers #0: Starting..
[INFO]:   2021-07-22 20:20:50 - ScanDataHandlerWorker #1: Starting..
[INFO]:   2021-07-22 20:20:50 - Listener started
[INFO]:   2021-07-22 20:20:50 - server started successfully on port 8080
```

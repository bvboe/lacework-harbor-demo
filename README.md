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
* Add `kubernetes.docker.internal` to the `insecure-registries` section
![Docker Insecure Registry Section](/images/insecure-registry.png)

### Start demo components
In a terminal window, clone the demo repository, go to the directory and start the demo. Remember to provide the lacework account name and proxy scanner authorization token, as configured in the pre-requisites.
```
$ git clone https://github.com/bvboe/lacework-harbor-demo/
$ cd lacework-harbor-demo
$ ./install.sh <lacework account name> <authorization token>
```

### Validate the demo components are running
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
### Log in to Harbor
Open a browser, open http://kubernetes.docker.internal.
![Harbor Welcome Page](/images/harbor-log-in.png)
Log on with the following username/password: `admin` / `bitnami`:
![Logged in to Harbor](/images/harbor-logged-in.png)

### Log on to Harbor using Docker CLI
Note: This operation will fail if insecure registry configuration is not setup correct.
```
$ docker login kubernetes.docker.internal -u admin -p bitnami
WARNING! Using --password via the CLI is insecure. Use --password-stdin.
Login Succeeded
```
## Demo Flow
### Submit Docker image to Harbor
Download image from Docker Hub
```
$ docker pull nginx:1.17.7
1.17.7: Pulling from library/nginx
...
Digest: sha256:8aa7f6a9585d908a63e5e418dc5d14ae7467d2e36e1ab4f0d8f9d059a3d071ce
Status: Downloaded newer image for nginx:1.17.7
docker.io/library/nginx:1.17.7
```
Tag image for Harbor
```
$ docker tag nginx:1.17.7 kubernetes.docker.internal/library/nginx:1.17.7
```
Push image into Harbor
```
docker push kubernetes.docker.internal/library/nginx:1.17.7
The push refers to repository [kubernetes.docker.internal/library/nginx]
...
1.17.7: digest: sha256:89a42c3ba15f09a3fbe39856bddacdf9e94cd03df7403cad4fc105088e268fc9 size: 948
```
Navigate to http://kubernetes.docker.internal/harbor/projects/1/repositories and see the image appear in Harbor
![Nginx in Harbor](/images/nginx-in-repo.png)
### Trigger scan of image in Harbor
The integration currently does not support an inital scan of existing images in Harbor. Support for this is coming soon, but until then, the following procedure can be run to scan all images.

For debugging purposes it's recommended to watch the log output from the proxy scanner in a separate window:
```
$ docker logs lacework-proxy-scanner
```

Run `scan-repo.sh` to use the Harbor API to build a set of REST commands to the proxy scanner to scan the images. It's recommended to review the output of that script and determine if all images need to be scanned or if older tags can be ignored.
```
$ ./scan-repo.sh
echo kubernetes.docker.internal/library/nginx:1.17.7
curl -s --data-raw '{"registry": "kubernetes.docker.internal", "image_name": "library/nginx", "tag": "1.17.7"}' --location --request POST 'localhost:8080/v1/scan' --header 'Content-Type: application/json'
```

To trigger a scan of the image we just added to Harbor, run command generated by `scan-repo.sh`:
```
curl -s --data-raw '{"registry": "kubernetes.docker.internal", "image_name": "library/nginx", "tag": "1.17.7"}' --location --request POST 'localhost:8080/v1/scan' --header 'Content-Type: application/json'
{"data":"Success.","error":"","ok":true,"status_code":200}
```
### Configure automated scan of new images added to Harbor
It's also possible to configure a webhook in Harbor that can call back to the lacework proxy scanner whenever a new image is added. This configuration has to be done on a project level in Harbor using the following procedure:

Bring up the Harbor UI:
![Logged in to Harbor](/images/harbor-logged-in.png)

Select the `library` project:
![Library Project](/images/nginx-in-repo.png)

Select `Webhooks` and click `New Webhook`, configure it as follows and click add:
* Name: `Harbor Proxy-Scanner Callback`
* Notify Type: `http`
* Event Type: `Artifact pushed` only
* Endpoint URL: `http://lacework-proxy-scanner:8080/v1/notification?registry_name=Harbor`
![Add Webhook](/images/add-webhook.png)

The new webhook then appear in the list:
![New Webhook](/images/new-webhook-created.png)

### Trigger automated scan of new image
Download new nginx image from Docker Hub
```
$ docker pull nginx:latest
latest: Pulling from library/nginx
Digest: sha256:8f335768880da6baf72b70c701002b45f4932acae8d574dedfddaf967fc3ac90
Status: Downloaded newer image for nginx:latest
docker.io/library/nginx:latest
```
Tag image for Harbor
```
$ docker tag nginx:latest kubernetes.docker.internal/library/nginx:latest
```
Push image into Harbor
```
$ docker push kubernetes.docker.internal/library/nginx:latest
The push refers to repository [kubernetes.docker.internal/library/nginx]
latest: digest: sha256:3f13b4376446cf92b0cb9a5c46ba75d57c41f627c4edb8b635fa47386ea29e20 size: 1570
```
Check the proxy scanner logs to see the scan running:
```
$ docker logs lacework-proxy-scanner
```

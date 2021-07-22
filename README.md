# Demonstration of scanning images in Harbor using Lacework
This demonstration shows how to enable integration between Harbor and Lacework to ensure all images in Harbor automatically gets scanned by Lacework.

The demo runs on a regular Mac with Docker Desktop installed and run both Harbor and the Lacework Proxy Scanner on your desktop.

## Pre-Requisites
### Generate container registry credentials in Lacework CLI
* Log on to the Lacework UI
* Navigate to Settings
* Go to Container Registries section
* Create a new container registry of the type, Proxy Scanner
* Click on new registry and download integration URL and Authorization Token.
![Lacework Registry Configuration Section](/images/lacework-registry-screenshot.png)
### Enable Docker to trust the locally deployed registry

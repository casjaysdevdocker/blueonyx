## 👋 Welcome to blueonyx 🚀  

blueonyx README  
  
  
## Install my system scripts  

```shell
 sudo bash -c "$(curl -q -LSsf "https://github.com/systemmgr/installer/raw/main/install.sh")"
 sudo systemmgr --config && sudo systemmgr install scripts  
```
  
## Automatic install/update  
  
```shell
dockermgr update blueonyx
```
  
## Install and run container
  
```shell
mkdir -p "$HOME/.local/share/srv/docker/blueonyx/rootfs"
git clone "https://github.com/dockermgr/blueonyx" "$HOME/.local/share/CasjaysDev/dockermgr/blueonyx"
cp -Rfva "$HOME/.local/share/CasjaysDev/dockermgr/blueonyx/rootfs/." "$HOME/.local/share/srv/docker/blueonyx/rootfs/"
docker run -d \
--restart always \
--privileged \
--name casjaysdevdocker-blueonyx \
--hostname blueonyx \
-e TZ=${TIMEZONE:-America/New_York} \
-v "$HOME/.local/share/srv/docker/casjaysdevdocker-blueonyx/rootfs/data:/data:z" \
-v "$HOME/.local/share/srv/docker/casjaysdevdocker-blueonyx/rootfs/config:/config:z" \
-p 80:80 \
casjaysdevdocker/blueonyx:latest
```
  
## via docker-compose  
  
```yaml
version: "2"
services:
  ProjectName:
    image: casjaysdevdocker/blueonyx
    container_name: casjaysdevdocker-blueonyx
    environment:
      - TZ=America/New_York
      - HOSTNAME=blueonyx
    volumes:
      - "$HOME/.local/share/srv/docker/casjaysdevdocker-blueonyx/rootfs/data:/data:z"
      - "$HOME/.local/share/srv/docker/casjaysdevdocker-blueonyx/rootfs/config:/config:z"
    ports:
      - 80:80
    restart: always
```
  
## Get source files  
  
```shell
dockermgr download src casjaysdevdocker/blueonyx
```
  
OR
  
```shell
git clone "https://github.com/casjaysdevdocker/blueonyx" "$HOME/Projects/github/casjaysdevdocker/blueonyx"
```
  
## Build container  
  
```shell
cd "$HOME/Projects/github/casjaysdevdocker/blueonyx"
buildx 
```
  
## Authors  
  
🤖 casjay: [Github](https://github.com/casjay) 🤖  
⛵ casjaysdevdocker: [Github](https://github.com/casjaysdevdocker) [Docker](https://hub.docker.com/u/casjaysdevdocker) ⛵  

# docker_dev
Little tool for developing with local docker environment

## Usages

### 1. Open manage.sh with editor and add this:
```
COMMANDS+=("show" "ls -l")
```
### 2. Create Dockerfile with "WORKDIR: /workspace"
```
FROM ubuntu:16.04

WORKDIR /workspace

CMD ["bash"]
```
### 3. Build development image and run it!
```
>>> ./manage.sh start

Sending build context to Docker daemon  74.75kB
Step 1/3 : FROM ubuntu:16.04
 ---> ccc7a11d65b1
Step 2/3 : WORKDIR /workspace
 ---> 783b5d3752d0
Removing intermediate container e01eea50efa2
Step 3/3 : CMD bash
 ---> Running in 685ea65f049a
 ---> 1cf3a70cdcc3
Removing intermediate container 685ea65f049a
Successfully built 1cf3a70cdcc3
Successfully tagged docker_dev:latest
Successfully build image: docker_dev:latest!
9b663b9c512cdd4e3c4325e9e1c6511f66a92daec59fd52f5cfd3b2fffca3406
The container: docker_dev is running!
```
### 4. Execute customized command: show
```
>>> ./manage.sh show

Run command: [ls -l] in container: docker_dev
total 16
-rw-rw-r-- 1 1000 1000   52 Aug 29 11:45 Dockerfile
-rw-rw-r-- 1 1000 1000  294 Aug 29 11:45 README.md
-rwxrwxr-x 1 1000 1000 7779 Aug 29 11:45 manage.sh

```

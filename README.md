# Docker-based VCLODS (Variable Configuration Locking Operation Destination Scripts `ksh` Framework)
Building off [this great project](https://github.com/cstobey/vclods), we add [Docker](https://www.docker.com/get-started/) containerization to the project for quick development and security purposes.

### To use
1. Have Docker Desktop installed on your system
2. Clone the repo with the submodule (`git clone --recursive git@github.com:joshurbain/vclods-docker.git`)
3. Place your files in the `scripts` folder
4. Build the instance and container (shown below)
5. Open a shell and use VCLODs directly (shown below)
6. Change the files in the scripts folder and it will change in your docker instance, as well


### Build an instance
```
# Only applicable if you have a prior instance of the container
docker rm -f -v vclod

# In this directory, run over the command line
docker build --tag vclods:1.0 .
```


### Build the container
```
docker container run -i -t -d -v $(realpath ./scripts):/app/scripts --name vclod vclods:1.0

# or if you have a specific network to attach to the container
docker container run -i -t -d -v $(realpath ./scripts):/app/scripts --network=mariadb-network --name vclod vclods:1.0
```


### Open a shell into the container
```
docker exec -it vclod /bin/bash
```


### Suggestions
1. Add a Docker network to share with this instance (as seen with `mariadb-network`)
2. Have aliases or scripts that do the steps above (or just use the `full_build.sh` script)
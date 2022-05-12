# Docker-based Variable Configuration Locking Operation Destination Scripts `ksh` Framework (VCLODS)
Building off [this great project](https://github.com/cstobey/vclods), we add [Docker](https://www.docker.com/get-started/) containerization to the project for quick development and security purposes.

### To use
1. Have Docker Desktop installed on your system
2. Clone the repo (`git clone ... `) with the submodule (vclods)
3. Place your files in the `vclods` folder
3. Build the instance (shown below)
4. Either open a shell and use VCLODs directly or run the container (also shown below)


### Build an instance
```
# Only applicable if you have a prior instance of the container
docker rm -f -v vclod

# In this directory, run over the command line
docker build --tag vclods:1.0 .
```


### Open a shell into the container
```
docker exec -ti vclod /bin/bash
```


### Run the container
```
docker container run -itd --name vclod vclods:1.0

# or if you have a specific network to attach to the container
docker container run -itd --network=mariadb-network --name vclod vclods:1.0
```


### Suggestions
1. Add a Docker network to share with this instance (as seen with `mariadb-network`)
2. Have aliases or scripts that do the steps above
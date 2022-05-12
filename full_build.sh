docker rm -f -v vclod
docker build --tag vclods:1.0 .
docker container run -itd --name vclod vclods:1.0
docker exec -ti vclod /bin/bash
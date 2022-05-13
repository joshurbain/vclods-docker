docker rm -f -v vclod
docker build --tag vclods:1.0 .
docker container run -i -t -d --name vclod vclods:1.0
docker exec -it vclod /bin/bash
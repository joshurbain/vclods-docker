#!/bin/bash
docker rm -f -v vclod
docker build --tag vclods:1.0 .
docker container run -i -t -d -v $(realpath ./scripts):/app/scripts --name vclod vclods:1.0
docker exec -it vclod /bin/bash
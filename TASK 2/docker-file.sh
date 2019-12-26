#!/usr/bin/env sh

time \
(echo "=> Increase memory"
sudo sysctl -w vm.max_map_count=262144

echo "=> Creating application network"
docker network create task2

echo "=> Creating volumes"
docker volume create jenkins_data
docker volume create postgres_data
docker volume create sonarqube_conf
docker volume create sonarqube_extensions
docker volume create sonarqube_logs
docker volume create sonarqube_data

echo "=> Building database image"
docker run -d --name postgres \
           --network task2 \
           -e POSTGRES_USER=sonarqube \
           -e POSTGRES_PASSWORD=sonarqube \
           -e POSTGRES_DB=sonarqube \
           -p 5432:5432 \
           -v postgres_data:/var/lib/postgresql/data \
           postgres

docker build -t romuloslv/jenkins \
             -f Docker-Jenkins .

echo "=> Building jenkins application"
docker run -d --name jenkins \
           --network task2 \
           -p 9090:8080 \
           -p 5000:5000 \
           -v jenkins_data:/var/jenkins_home \
           -v /var/run/docker.sock:/var/run/docker.sock \
	       romuloslv/jenkins

docker build -t romuloslv/sonarqube \
             -f Docker-Sonarqube .

echo "=> Building sonarqube application"
docker run -d --name sonarqube \
           --network task2 \
           -p 9000:9000 \
           -e SONARQUBE_JDBC_URL=jdbc:postgresql://postgres:5432/sonarqube \
           -e SONARQUBE_JDBC_USERNAME=sonarqube \
           -e SONARQUBE_JDBC_PASSWORD=sonarqube \
           -v sonarqube_conf:/opt/sonarqube/conf \
           -v sonarqube_extensions:/opt/sonarqube/extensions \
           -v sonarqube_logs:/opt/sonarqube/logs \
           -v sonarqube_data:/opt/sonarqube/data \
           romuloslv/sonarqube)

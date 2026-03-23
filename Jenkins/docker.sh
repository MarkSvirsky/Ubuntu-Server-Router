#create the container
docker run -d \
  --name jenkins-master \
  -p 8080:8080 \
  -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  --restart always \
  jenkins/jenkins:lts


#gives the docker container running jenkins the permissions it needs in order to run the build

sudo usermod -aG docker jenkins
sudo chmod 666 /var/run/docker.sock
docker restart jenkins-master

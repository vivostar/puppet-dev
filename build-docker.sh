# echo -e "\033[32mBuilding image ambari:2.7.5\033[0m"
# docker build -t ambari:2.7.5 .

echo -e "\033[32mCreating network bigtop\033[0m"
docker network create --driver bridge bigtop

echo -e "\033[32mCreating docker cluster master\033[0m"
docker run -d -p 50070:50070 -p 8080:8080 --name master --hostname master --network bigtop --privileged -e "container=docker" -v /sys/fs/cgroup:/sys/fs/cgroup:ro bigtop:3.1.0 /usr/sbin/init
SERVER_PUB_KEY=`docker exec master /bin/cat /root/.ssh/id_rsa.pub`
docker exec master bash -c "echo '$SERVER_PUB_KEY' > /root/.ssh/authorized_keys"
docker exec master /bin/systemctl enable sshd
docker exec master /bin/systemctl start sshd

echo -e "\033[32mStarting deploy bigtop cluster master\033[0m"
docker exec master bash -c "puppet apply --detailed-exitcodes --parser future --hiera_config=/etc/puppet/hiera.yaml --modulepath=/bigtop_home/bigtop-deploy/puppet/modules:/etc/puppet/modules:/usr/share/puppet/modules:/etc/puppetlabs/code/modules:/etc/puppet/code/modules /bigtop_home/bigtop-deploy/puppet/manifests"


echo -e "\033[32mCreating docker cluster worker01\033[0m"
docker run -d --name worker01 --hostname worker01 --network bigtop --privileged -e "container=docker" -v /sys/fs/cgroup:/sys/fs/cgroup:ro bigtop:3.1.0 /usr/sbin/init
docker exec worker01 bash -c "puppet apply --detailed-exitcodes --parser future --hiera_config=/etc/puppet/hiera.yaml --modulepath=/bigtop_home/bigtop-deploy/puppet/modules:/etc/puppet/modules:/usr/share/puppet/modules:/etc/puppetlabs/code/modules:/etc/puppet/code/modules /bigtop_home/bigtop-deploy/puppet/manifests"

echo -e "\033[32mCreating docker cluster worker02\033[0m"
docker run -d --name worker02 --hostname worker02 --network bigtop --privileged -e "container=docker" -v /sys/fs/cgroup:/sys/fs/cgroup:ro bigtop:3.1.0 /usr/sbin/init
docker exec worker02 bash -c "puppet apply --detailed-exitcodes --parser future --hiera_config=/etc/puppet/hiera.yaml --modulepath=/bigtop_home/bigtop-deploy/puppet/modules:/etc/puppet/modules:/usr/share/puppet/modules:/etc/puppetlabs/code/modules:/etc/puppet/code/modules /bigtop_home/bigtop-deploy/puppet/manifests"

echo -e "\033[32mConfiguring hosts file\033[0m"
MASTER_IP=`docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' master`
WORCKER01_IP=`docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' worker01`
WORCKER02_IP=`docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' worker02`
docker exec master bash -c "echo '$WORCKER01_IP      worker01' >> /etc/hosts"
docker exec master bash -c "echo '$WORCKER02_IP      worker02' >> /etc/hosts"
docker exec worcker01 bash -c "echo '$MASTER_IP      ambari-server' >> /etc/hosts"
docker exec worcker01 bash -c "echo '$WORCKER02_IP      worcker02' >> /etc/hosts"
docker exec worcker02 bash -c "echo '$MASTER_IP      ambari-server' >> /etc/hosts"
docker exec worcker02 bash -c "echo '$WORCKER02_IP      worcker01' >> /etc/hosts"
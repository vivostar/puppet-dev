mvn clean install -DskipTests -Drat.skip -f ../../bigtop/bigtop-packages/src/common/bigtop-ambari-mpack/bgtp-ambari-mpack/pom.xml
docker cp ../../bigtop/bigtop-packages/src/common/bigtop-ambari-mpack/bgtp-ambari-mpack/target/bgtp-ambari-mpack-1.0.0.0-SNAPSHOT-bgtp-ambari-mpack.tar.gz ambari-server:/
docker exec ambari-server bash -c "ambari-server install-mpack --mpack=/bgtp-ambari-mpack-1.0.0.0-SNAPSHOT-bgtp-ambari-mpack.tar.gz"
docker exec ambari-server bash -c "ambari-server restart --debug"
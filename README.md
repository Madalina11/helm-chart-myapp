### Openshift Local ###

$ crc setup
$ crc start

The server is accessible via web console at:
  https://console-openshift-console.apps-crc.testing

Log in as administrator:
  Username: kubeadmin
  Password: PE9Na-FNZ66-8VCk6-UdbbQ

Log in as user:
  Username: developer
  Password: developer

Use the 'oc' command line interface:
  $ eval $(crc oc-env)
  $ oc login -u developer https://api.crc.testing:6443
  $ oc login -u kubeadmin -p PE9Na-FNZ66-8VCk6-UdbbQ https://api.crc.testing:6443
  
 ### Docker ###

$ docker login

https://hub.docker.com/r/madalinna/myapp/tags

$ docker build -t madalinna/myapp:latest .
$ docker push madalinna/myapp:latest

### Creare Route pentru acces aplicație ###

$ oc expose svc myapp -n myproject
$ oc get route -n myproject 

Creare network comun pentru teamcity-server, teamcity-postgres si teamcity-agent:
$ docker network create teamcity-net

###  PostgreSQL Local ###

Completezi formularul PostgreSQL in TeamCity

Database type	PostgreSQL
Host:	host.docker.internal (dacă TeamCity și PostgreSQL sunt în containere separate)
Port:	5432
Database name:	teamcity
User name:	tcuser
Password:	tcpass

$ docker run -d \
           --name teamcity-postgres \
           --network teamcity-net \
           -p 5432:5432 \
           -e POSTGRES_USER=tcuser \
           -e POSTGRES_PASSWORD=tcpass \
           -e POSTGRES_DB=teamcity \
           postgres:15

### TeamCity Local ###


$ docker run -d \
  --name teamcity-server \
  --network teamcity-net \
  -p 8111:8111 \
  -v teamcity_data:/data/teamcity_server/datadir \
  -v teamcity_logs:/opt/teamcity/logs \
  jetbrains/teamcity-server
  
  http://localhost:8111
  
### TeamCity Agent ###

Dockerfile (pentru a configura un container de TeamCity Agent pe imagine de Ubuntu/Debian - imaginea jetbrains/teamcity-agent nu are runtime-ul necesar pentru a rula 'oc' - care sa contina binarele oc/kubectl si helm)

$ docker build -t teamcity-agent-full .

$ docker run -d \
             --name teamcity-agent \
             --network teamcity-net \
             --user=root \
             -v /var/run/docker.sock:/var/run/docker.sock \
             teamcity-agent-full
#            -e SERVER_URL=http://host.docker.internal:8111 \
           

In containerul teamcity-agent-full, apare eroarea WARN - buildServer.AGENT.registration - Error registering on the server via URL http://localhost:8111.⁠ Will continue repeating connection attempts.

variabila de mediu -e SERVER_URL=http://host.docker.internal:8111, nu a suprascris valoarea http://localhost:8111 din conf/buildAgent.properties

$ docker exec 3dcf870bd921 sed -i 's|serverUrl=.*|serverUrl=http://host.docker.internal:8111|' conf/buildAgent.properties

$ docker exec -it 91fdd6cd4e4f cat conf/buildAgent.properties | grep serverUrl
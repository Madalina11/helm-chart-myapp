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

$ docker build --platform=linux/amd64 -t teamcity-agent-full .

$ docker run --platform=linux/amd64 -d \
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

### Connection between TeamCity Agent and Openshift ###

Pe sistemul tău host, rulează:

$ oc whoami --show-server

$ docker exec -it teamcity-agent curl -k https://api.crc.testing:6443

Pe host, redirectionam portul 6443 al Openshift catre exterior, folosind socat. Asta face ca traficul către host.docker.internal:6443 din container să ajungă la CRC:

$ sudo socat TCP-LISTEN:6443,fork TCP:127.0.0.1:6443

$ ipconfig getifaddr en0  # sau en1, în funcție de rețea

172.20.10.12

/# cat /etc/hosts
 Copy:
# Added by CRC
127.0.0.1        myapp-default.apps-crc.testing myapp-myproject.apps-crc.testing api.crc.testing canary-openshift-ingress-canary.apps-crc.testing console-openshift-console.apps-crc.testing default-route-openshift-image-registry.apps-crc.testing downloads-openshift-console.apps-crc.testing host.crc.testing oauth-openshift.apps-crc.testing
# End of CRC section

Then, on teamcity-agent container:

/# echo "172.20.10.12 myapp-default.apps-crc.testing myapp-myproject.apps-crc.testing api.crc.testing canary-openshift-ingress-canary.apps-crc.testing console-openshift-console.apps-crc.testing default-route-openshift-image-registry.apps-crc.testing downloads-openshift-console.apps-crc.testing host.crc.testing oauth-openshift.apps-crc.testing" >> /etc/hosts

It will look like this:
/# cat /etc/hosts
127.0.0.1	localhost
::1	localhost ip6-localhost ip6-loopback
fe00::	ip6-localnet
ff00::	ip6-mcastprefix
ff02::1	ip6-allnodes
ff02::2	ip6-allrouters
172.18.0.2	ab51d43de05b
172.20.10.12 oauth-openshift.apps.crc.testing
172.20.10.12 myapp-default.apps-crc.testing myapp-myproject.apps-crc.testing api.crc.testing canary-openshift-ingress-canary.apps-crc.testing console-openshift-console.apps-crc.testing default-route-openshift-image-registry.apps-crc.testing downloads-openshift-console.apps-crc.testing host.crc.testing oauth-openshift.apps-crc.testing

Now, oc login should work:

oc login -u kubeadmin -p PE9Na-FNZ66-8VCk6-UdbbQ https://api.crc.testing:6443

The server uses a certificate signed by an unknown authority.
You can bypass the certificate check, but any data you send to the server could be intercepted by others.
Use insecure connections? (y/n): y

WARNING: Using insecure TLS client config. Setting this option is not supported!

Login successful.

You have access to 66 projects, the list has been suppressed. You can list all projects with 'oc projects'

Using project "default".
Welcome! See 'oc help' to get started.

### Important NOTE ###

Before running the TeamCity job, make sure the Openshift API Token hasn't expired. If so, make sure to replace it with the latest one in the 1. Openshift Login and 6. Helm Upgrade Build steps.
Openshift Local

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
  
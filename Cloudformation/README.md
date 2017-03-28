# Sypnosis

This CF template spins up a Centos7 EC2 instance and installs openshift origin cli to spins up a single cluster node.  
Persistent volumes and installation configuration will be persisted under `/opt` directory.  

oc cluster reference: https://github.com/openshift/origin/blob/master/docs/cluster_up_down.md

# General Usage

Once the CF Stack creation of the template is completed, view the CF **Outputs** and access your Openshift webconsole at https://PUBLIC_IP:8443/console. 

Username: `admin`
Password: `admin`

Accessing your cluster from the commandline: `oc login https://PUBLIC_IP:8443 -u admin -p admin`

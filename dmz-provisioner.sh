#!/bin/bash

LOCAL_REPO_PATH="/opt/repos"

# This script enables the needed RHEL, OpenShift, Gluster, Ansible, HA, and additional repos needed to mirror them locally.
# The locally created mirror can then be used to deploy OCP into a disconnected environment.

#===== PRE-RUN NOTES:
# This assumes you've already registered and subscribed to the needed OpenShift, Gluster, Ansible, and RHEL subscriptions.

echo "====== To ensure that the packages are not deleted after you sync the repository, import the GPG key:"
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release
echo "====== Disable all repos..."
subscription-manager repos --disable="*"
echo "====== Enable needed repos..."
subscription-manager repos --enable="rhel-7-server-rpms" \
    --enable="rhel-7-server-extras-rpms" \
    --enable="rhel-7-server-optional-rpms" \
    --enable="rhel-7-server-ose-3.10-rpms" \
    --enable="rhel-7-server-ansible-2.7-rpms" \
    --enable="rhel-ha-for-rhel-7-server-rpms" \
    --enable="rh-gluster-3-for-rhel-7-server-rpms" \
    --enable="rh-gluster-3-samba-for-rhel-7-server-rpms" \
    --enable="rh-gluster-3-nfs-for-rhel-7-server-rpms" \
    --enable="rh-gluster-3-web-admin-server-for-rhel-7-server-rpms" \
    --enable="rh-gluster-3-web-admin-agent-for-rhel-7-server-rpms"

echo "====== Update repository listings and local packages..."
yum update -y

echo "====== Install needed packages to mirror RPMs and Container Images..."
yum -y install yum-utils createrepo docker git nano

echo "====== Create needed local repo path..."
mkdir -p $LOCAL_REPO_PATH/{rpms,docker}

echo "====== Sync packages and create repository for each mirrored repo..."
for repo in \
rhel-7-server-rpms \
rhel-7-server-extras-rpms \
rhel-7-server-optional-rpms \
rhel-7-server-ose-3.10-rpms \
rhel-7-server-ansible-2.7-rpms \
rhel-ha-for-rhel-7-server-rpms \
rh-gluster-3-for-rhel-7-server-rpms \
rh-gluster-3-samba-for-rhel-7-server-rpms \
rh-gluster-3-nfs-for-rhel-7-server-rpms \
rh-gluster-3-web-admin-server-for-rhel-7-server-rpms \
rh-gluster-3-web-admin-agent-for-rhel-7-server-rpms
do
  reposync --gpgcheck -lm --repoid=${repo} --download_path=$LOCAL_REPO_PATH/rpms
  createrepo -v $LOCAL_REPO_PATH/rpms/${repo} -o $LOCAL_REPO_PATH/rpms/${repo}
done

echo "===== RPM REPO SYNC COMPLETE! ====="
echo "===== RPM Repo Local Size..."
du -h $LOCAL_REPO_PATH

echo "===== Starting Docker..."
systemctl start docker

echo "===== Pull OpenShift Container Platform infrastructure component images..."
docker pull registry.access.redhat.com/openshift3/csi-attacher:v3.10.45
docker pull registry.access.redhat.com/openshift3/csi-driver-registrar:v3.10.45
docker pull registry.access.redhat.com/openshift3/csi-livenessprobe:v3.10.45
docker pull registry.access.redhat.com/openshift3/csi-provisioner:v3.10.45
docker pull registry.access.redhat.com/openshift3/image-inspector:v3.10.45
docker pull registry.access.redhat.com/openshift3/local-storage-provisioner:v3.10.45
docker pull registry.access.redhat.com/openshift3/manila-provisioner:v3.10.45
docker pull registry.access.redhat.com/openshift3/ose-ansible:v3.10.45
docker pull registry.access.redhat.com/openshift3/ose-cli:v3.10.45
docker pull registry.access.redhat.com/openshift3/ose-cluster-capacity:v3.10.45
docker pull registry.access.redhat.com/openshift3/ose-deployer:v3.10.45
docker pull registry.access.redhat.com/openshift3/ose-descheduler:v3.10.45
docker pull registry.access.redhat.com/openshift3/ose-docker-builder:v3.10.45
docker pull registry.access.redhat.com/openshift3/ose-docker-registry:v3.10.45
docker pull registry.access.redhat.com/openshift3/ose-egress-dns-proxy:v3.10.45
docker pull registry.access.redhat.com/openshift3/ose-egress-http-proxy:v3.10.45
docker pull registry.access.redhat.com/openshift3/ose-egress-router:v3.10.45
docker pull registry.access.redhat.com/openshift3/ose-f5-router:v3.10.45
docker pull registry.access.redhat.com/openshift3/ose-haproxy-router:v3.10.45
docker pull registry.access.redhat.com/openshift3/ose-hyperkube:v3.10.45
docker pull registry.access.redhat.com/openshift3/ose-hypershift:v3.10.45
docker pull registry.access.redhat.com/openshift3/ose-keepalived-ipfailover:v3.10.45
docker pull registry.access.redhat.com/openshift3/ose-pod:v3.10.45
docker pull registry.access.redhat.com/openshift3/ose-node-problem-detector:v3.10.45
docker pull registry.access.redhat.com/openshift3/ose-recycler:v3.10.45
docker pull registry.access.redhat.com/openshift3/ose-web-console:v3.10.45
docker pull registry.access.redhat.com/openshift3/ose-node:v3.10.45
docker pull registry.access.redhat.com/openshift3/ose-control-plane:v3.10.45
docker pull registry.access.redhat.com/openshift3/registry-console:v3.10.45
docker pull registry.access.redhat.com/openshift3/snapshot-controller:v3.10.45
docker pull registry.access.redhat.com/openshift3/snapshot-provisioner:v3.10.45
docker pull registry.access.redhat.com/openshift3/apb-base:v3.10.45
docker pull registry.access.redhat.com/openshift3/apb-tools:v3.10.45
docker pull registry.access.redhat.com/openshift3/ose-service-catalog:v3.10.45
docker pull registry.access.redhat.com/openshift3/ose-ansible-service-broker:v3.10.45
docker pull registry.access.redhat.com/openshift3/mariadb-apb:v3.10.45
docker pull registry.access.redhat.com/openshift3/mediawiki-apb:v3.10.45
docker pull registry.access.redhat.com/openshift3/mysql-apb:v3.10.45
docker pull registry.access.redhat.com/openshift3/ose-template-service-broker:v3.10.45
docker pull registry.access.redhat.com/openshift3/postgresql-apb:v3.10.45
docker pull registry.access.redhat.com/openshift3/efs-provisioner:v3.10.45
docker pull registry.access.redhat.com/rhel7/etcd:3.2.22

echo "===== Pull required OpenShift Container Platform component images for the optional components..."
docker pull registry.access.redhat.com/openshift3/logging-auth-proxy:v3.10.45
docker pull registry.access.redhat.com/openshift3/logging-curator:v3.10.45
docker pull registry.access.redhat.com/openshift3/logging-elasticsearch:v3.10.45
docker pull registry.access.redhat.com/openshift3/logging-eventrouter:v3.10.45
docker pull registry.access.redhat.com/openshift3/logging-fluentd:v3.10.45
docker pull registry.access.redhat.com/openshift3/logging-kibana:v3.10.45
docker pull registry.access.redhat.com/openshift3/oauth-proxy:v3.10.45
docker pull registry.access.redhat.com/openshift3/metrics-cassandra:v3.10.45
docker pull registry.access.redhat.com/openshift3/metrics-hawkular-metrics:v3.10.45
docker pull registry.access.redhat.com/openshift3/metrics-hawkular-openshift-agent:v3.10.45
docker pull registry.access.redhat.com/openshift3/metrics-heapster:v3.10.45
docker pull registry.access.redhat.com/openshift3/metrics-schema-installer:v3.10.45
docker pull registry.access.redhat.com/openshift3/prometheus:v3.10.45
docker pull registry.access.redhat.com/openshift3/prometheus-alert-buffer:v3.10.45
docker pull registry.access.redhat.com/openshift3/prometheus-alertmanager:v3.10.45
docker pull registry.access.redhat.com/openshift3/prometheus-node-exporter:v3.10.45
docker pull registry.access.redhat.com/cloudforms46/cfme-openshift-postgresql
docker pull registry.access.redhat.com/cloudforms46/cfme-openshift-memcached
docker pull registry.access.redhat.com/cloudforms46/cfme-openshift-app-ui
docker pull registry.access.redhat.com/cloudforms46/cfme-openshift-app
docker pull registry.access.redhat.com/cloudforms46/cfme-openshift-embedded-ansible
docker pull registry.access.redhat.com/cloudforms46/cfme-openshift-httpd
docker pull registry.access.redhat.com/cloudforms46/cfme-httpd-configmap-generator
docker pull registry.access.redhat.com/rhgs3/rhgs-server-rhel7
docker pull registry.access.redhat.com/rhgs3/rhgs-volmanager-rhel7
docker pull registry.access.redhat.com/rhgs3/rhgs-gluster-block-prov-rhel7
docker pull registry.access.redhat.com/rhgs3/rhgs-s3-server-rhel7

echo "===== Pull in the Red Hat-certified Source-to-Image (S2I) builder images..."
docker pull registry.access.redhat.com/jboss-amq-6/amq63-openshift
docker pull registry.access.redhat.com/jboss-datagrid-7/datagrid71-openshift
docker pull registry.access.redhat.com/jboss-datagrid-7/datagrid71-client-openshift
docker pull registry.access.redhat.com/jboss-datavirt-6/datavirt63-openshift
docker pull registry.access.redhat.com/jboss-datavirt-6/datavirt63-driver-openshift
docker pull registry.access.redhat.com/jboss-decisionserver-6/decisionserver64-openshift
docker pull registry.access.redhat.com/jboss-processserver-6/processserver64-openshift
docker pull registry.access.redhat.com/jboss-eap-6/eap64-openshift
docker pull registry.access.redhat.com/jboss-eap-7/eap70-openshift
docker pull registry.access.redhat.com/jboss-webserver-3/webserver31-tomcat7-openshift
docker pull registry.access.redhat.com/jboss-webserver-3/webserver31-tomcat8-openshift
docker pull registry.access.redhat.com/openshift3/jenkins-1-rhel7
docker pull registry.access.redhat.com/openshift3/jenkins-2-rhel7
docker pull registry.access.redhat.com/openshift3/jenkins-agent-maven-35-rhel7
docker pull registry.access.redhat.com/openshift3/jenkins-agent-nodejs-8-rhel7
docker pull registry.access.redhat.com/openshift3/jenkins-slave-base-rhel7
docker pull registry.access.redhat.com/openshift3/jenkins-slave-maven-rhel7
docker pull registry.access.redhat.com/openshift3/jenkins-slave-nodejs-rhel7
docker pull registry.access.redhat.com/rhscl/mongodb-32-rhel7
docker pull registry.access.redhat.com/rhscl/mysql-57-rhel7
docker pull registry.access.redhat.com/rhscl/perl-524-rhel7
docker pull registry.access.redhat.com/rhscl/php-56-rhel7
docker pull registry.access.redhat.com/rhscl/postgresql-95-rhel7
docker pull registry.access.redhat.com/rhscl/python-35-rhel7
docker pull registry.access.redhat.com/redhat-sso-7/sso70-openshift
docker pull registry.access.redhat.com/rhscl/ruby-24-rhel7
docker pull registry.access.redhat.com/redhat-openjdk-18/openjdk18-openshift
docker pull registry.access.redhat.com/redhat-sso-7/sso71-openshift
docker pull registry.access.redhat.com/rhscl/nodejs-6-rhel7
docker pull registry.access.redhat.com/rhscl/mariadb-101-rhel7

echo "===== Create packaged tars of docker images..."
echo "===== Create OpenShift Container Platform Infrastructure image package..."
docker save -o $LOCAL_REPO_PATH/docker/ose3-images.tar \
    registry.access.redhat.com/openshift3/csi-attacher \
    registry.access.redhat.com/openshift3/csi-driver-registrar \
    registry.access.redhat.com/openshift3/csi-livenessprobe \
    registry.access.redhat.com/openshift3/csi-provisioner \
    registry.access.redhat.com/openshift3/efs-provisioner \
    registry.access.redhat.com/openshift3/image-inspector \
    registry.access.redhat.com/openshift3/local-storage-provisioner \
    registry.access.redhat.com/openshift3/manila-provisioner \
    registry.access.redhat.com/openshift3/ose-ansible \
    registry.access.redhat.com/openshift3/ose-cli \
    registry.access.redhat.com/openshift3/ose-cluster-capacity \
    registry.access.redhat.com/openshift3/ose-deployer \
    registry.access.redhat.com/openshift3/ose-descheduler \
    registry.access.redhat.com/openshift3/ose-docker-builder \
    registry.access.redhat.com/openshift3/ose-docker-registry \
    registry.access.redhat.com/openshift3/ose-egress-dns-proxy \
    registry.access.redhat.com/openshift3/ose-egress-http-proxy \
    registry.access.redhat.com/openshift3/ose-egress-router \
    registry.access.redhat.com/openshift3/ose-f5-router \
    registry.access.redhat.com/openshift3/ose-haproxy-router \
    registry.access.redhat.com/openshift3/ose-hyperkube \
    registry.access.redhat.com/openshift3/ose-hypershift \
    registry.access.redhat.com/openshift3/ose-keepalived-ipfailover \
    registry.access.redhat.com/openshift3/ose-pod \
    registry.access.redhat.com/openshift3/ose-node-problem-detector \
    registry.access.redhat.com/openshift3/ose-recycler \
    registry.access.redhat.com/openshift3/ose-web-console \
    registry.access.redhat.com/openshift3/ose-node \
    registry.access.redhat.com/openshift3/ose-control-plane \
    registry.access.redhat.com/openshift3/registry-console \
    registry.access.redhat.com/openshift3/snapshot-controller \
    registry.access.redhat.com/openshift3/snapshot-provisioner \
    registry.access.redhat.com/openshift3/apb-base \
    registry.access.redhat.com/openshift3/apb-tools \
    registry.access.redhat.com/openshift3/ose-service-catalog \
    registry.access.redhat.com/openshift3/ose-ansible-service-broker \
    registry.access.redhat.com/openshift3/mariadb-apb \
    registry.access.redhat.com/openshift3/mediawiki-apb \
    registry.access.redhat.com/openshift3/mysql-apb \
    registry.access.redhat.com/openshift3/ose-template-service-broker \
    registry.access.redhat.com/openshift3/postgresql-apb \
    registry.access.redhat.com/openshift3/efs-provisioner \
    registry.access.redhat.com/rhel7/etcd:3.2.22

echo "===== Create OpenShift Container Platform Optional image package..."
docker save -o $LOCAL_REPO_PATH/docker/ose3-optional-images.tar \
    registry.access.redhat.com/openshift3/logging-curator \
    registry.access.redhat.com/openshift3/logging-elasticsearch \
    registry.access.redhat.com/openshift3/logging-eventrouter \
    registry.access.redhat.com/openshift3/logging-fluentd \
    registry.access.redhat.com/openshift3/logging-kibana \
    registry.access.redhat.com/openshift3/oauth-proxy \
    registry.access.redhat.com/openshift3/metrics-cassandra \
    registry.access.redhat.com/openshift3/metrics-hawkular-metrics \
    registry.access.redhat.com/openshift3/metrics-hawkular-openshift-agent \
    registry.access.redhat.com/openshift3/metrics-heapster \
    registry.access.redhat.com/openshift3/metrics-schema-installer \
    registry.access.redhat.com/openshift3/prometheus \
    registry.access.redhat.com/openshift3/prometheus-alert-buffer \
    registry.access.redhat.com/openshift3/prometheus-alertmanager \
    registry.access.redhat.com/openshift3/prometheus-node-exporter \
    registry.access.redhat.com/cloudforms46/cfme-openshift-postgresql \
    registry.access.redhat.com/cloudforms46/cfme-openshift-memcached \
    registry.access.redhat.com/cloudforms46/cfme-openshift-app-ui \
    registry.access.redhat.com/cloudforms46/cfme-openshift-app \
    registry.access.redhat.com/cloudforms46/cfme-openshift-embedded-ansible \
    registry.access.redhat.com/cloudforms46/cfme-openshift-httpd \
    registry.access.redhat.com/cloudforms46/cfme-httpd-configmap-generator \
    registry.access.redhat.com/rhgs3/rhgs-server-rhel7 \
    registry.access.redhat.com/rhgs3/rhgs-volmanager-rhel7 \
    registry.access.redhat.com/rhgs3/rhgs-gluster-block-prov-rhel7 \
    registry.access.redhat.com/rhgs3/rhgs-s3-server-rhel7

echo "===== Create OpenShift Container Platform builder image package..."
docker save -o $LOCAL_REPO_PATH/docker/ose3-builder-images.tar \
    registry.access.redhat.com/jboss-amq-6/amq63-openshift \
    registry.access.redhat.com/jboss-datagrid-7/datagrid71-openshift \
    registry.access.redhat.com/jboss-datagrid-7/datagrid71-client-openshift \
    registry.access.redhat.com/jboss-datavirt-6/datavirt63-openshift \
    registry.access.redhat.com/jboss-datavirt-6/datavirt63-driver-openshift \
    registry.access.redhat.com/jboss-decisionserver-6/decisionserver64-openshift \
    registry.access.redhat.com/jboss-processserver-6/processserver64-openshift \
    registry.access.redhat.com/jboss-eap-6/eap64-openshift \
    registry.access.redhat.com/jboss-eap-7/eap70-openshift \
    registry.access.redhat.com/jboss-webserver-3/webserver31-tomcat7-openshift \
    registry.access.redhat.com/jboss-webserver-3/webserver31-tomcat8-openshift \
    registry.access.redhat.com/openshift3/jenkins-1-rhel7 \
    registry.access.redhat.com/openshift3/jenkins-2-rhel7 \
    registry.access.redhat.com/openshift3/jenkins-agent-maven-35-rhel7 \
    registry.access.redhat.com/openshift3/jenkins-agent-nodejs-8-rhel7 \
    registry.access.redhat.com/openshift3/jenkins-slave-base-rhel7 \
    registry.access.redhat.com/openshift3/jenkins-slave-maven-rhel7 \
    registry.access.redhat.com/openshift3/jenkins-slave-nodejs-rhel7 \
    registry.access.redhat.com/rhscl/mongodb-32-rhel7 \
    registry.access.redhat.com/rhscl/mysql-57-rhel7 \
    registry.access.redhat.com/rhscl/perl-524-rhel7 \
    registry.access.redhat.com/rhscl/php-56-rhel7 \
    registry.access.redhat.com/rhscl/postgresql-95-rhel7 \
    registry.access.redhat.com/rhscl/python-35-rhel7 \
    registry.access.redhat.com/redhat-sso-7/sso70-openshift \
    registry.access.redhat.com/rhscl/ruby-24-rhel7 \
    registry.access.redhat.com/redhat-openjdk-18/openjdk18-openshift \
    registry.access.redhat.com/redhat-sso-7/sso71-openshift \
    registry.access.redhat.com/rhscl/nodejs-6-rhel7 \
    registry.access.redhat.com/rhscl/mariadb-101-rhel7

echo "===== DOCKER IMAGES SYNCED! ====="

echo "===== Total Local Repo Size..."
du -h $LOCAL_REPO_PATH

echo ""
echo ""
echo "===== COMPLETED! ====="
echo ""
echo ""
echo "Now simply copy the contents of $LOCAL_REPO_PATH to an external drive or burn it to a disc."
echo "Make sure to include a copy of the RHEL 7.5 Server install ISO, or have a way to install it."
echo "Then sneakernet it across to the environment and follow the next steps in the README file."

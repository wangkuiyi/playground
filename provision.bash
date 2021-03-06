#!/bin/bash

set -e  # Exit script if any error

# The shared folder is specified in Vagrantfile.
VAGRANT_SHARED_FOLDER=/home/vagrant/desktop

source $VAGRANT_SHARED_FOLDER/sqlflow/docker/dev/find_fastest_resources.sh

echo "Setting apt-get mirror..."
find_fastest_apt_source >/etc/apt/sources.list
apt-get update

echo "Installing Docker ..."
# c.f. https://dockr.ly/3cExcay
if ! which docker > /dev/null; then
    echo "Docker had been installed. Skip."
else
    best_install_url=$(find_fastest_docker_url)
    docker_ce_mirror=$(find_fastest_docker_ce_mirror)
    echo "Using ${best_install_url}..."
    curl -sSL "${best_install_url}" | DOWNLOAD_URL=$docker_ce_mirror bash -
    best_docker_mirror=$(find_fastest_docker_registry)
    if [[ -n "${best_docker_mirror}" ]]; then
        mkdir -p /etc/docker
        cat <<-EOF >/etc/docker/daemon.json
	{ 
	  "graph": "/mnt/docker-data",
	  "storage-driver": "overlay",
	  "registry-mirrors":[ "${best_docker_mirror}" ]
	}
	EOF
    fi
    usermod -aG docker vagrant
fi
echo "Done."

echo "Install axel ..."
if which axel > /dev/null; then
    echo "axel installed. Skip."
else
    $VAGRANT_SHARED_FOLDER/sqlflow/scripts/travis/install_axel.sh
fi

echo "Export Kubernetes environment variables ..."
# NOTE: According to https://stackoverflow.com/a/16619261/724872,
# source is very necessary here.
source $VAGRANT_SHARED_FOLDER/sqlflow/scripts/travis/export_k8s_vars.sh

echo "Installing kubectl ..."
if which kubectl > /dev/null; then
    echo "kubectl installed. Skip."
else
    $VAGRANT_SHARED_FOLDER/sqlflow/scripts/travis/install_kubectl.sh
fi
echo "Done."

echo "Installing minikube ..."
if which minikube > /dev/null; then
    echo "minikube installed. Skip."
else
    $VAGRANT_SHARED_FOLDER/sqlflow/scripts/travis/install_minikube.sh
fi
echo "Done."

echo "Configure minikube ..."
mkdir -p /home/vagrant/.kube /home/vagrant/.minikube
touch /home/vagrant/.kube/config
chown -R vagrant /home/vagrant/.bashrc
echo "Done."


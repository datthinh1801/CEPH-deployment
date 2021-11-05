#! /bin/bash

sudo useradd --create-home -s /bin/bash ceph-user
echo "ceph-user:ceph-user" | sudo chpasswd
echo "ceph-user ALL = (root) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/ceph-user
sudo chmod 0440 /etc/sudoers.d/ceph-user

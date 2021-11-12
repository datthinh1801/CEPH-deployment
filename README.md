# CEPH storage cluster deployment
> Reference: https://computingforgeeks.com/how-to-deploy-ceph-storage-cluster-on-ubuntu-18-04-lts/

## Host Installation
- Nodes should have differentiable hostname because the aliases in `/etc/hosts` must be the same as the hostname. Therefore, same hostnames might cause conflict aliases.  
- In this guide, we used `ceph-admin`, `ceph-mon1`, `ceph-mon2`, `ceph-mon3`, `ceph-osd1`, `ceph-osd2`, `ceph-osd3`, `ceph-rgw`.

## Preparation (on all nodes)
- System update.
```sh
sudo apt update && sudo apt upgrade -y && sudo reboot
```

- Install `ntp` on all nodes.
```sh
sudo apt install ntp -y
```

- Install `python-minimal` and `python3-minimal`.
```sh
sudo apt install python-minimal python3-minimal -y
```

- Install `python-routes` on manager nodes.
```sh
sudo apt install python-routes -y
```

- Add alias to the hosts file. This `hosts` file should contain all nodes in the cluster, including the `admin` node, `mon` nodes, `mgr` nodes, `osd` nodes.
> `client` node will be setup later.

```
# /etc/hosts
10.1.1.130 ceph-admin
10.1.1.131 ceph-mon1
10.1.1.132 ceph-mon2
10.1.1.133 ceph-mon3
10.1.1.141 ceph-osd1
10.1.1.142 ceph-osd2
10.1.1.143 ceph-osd3
10.1.1.150 ceph-rgw
```

- Create a `ceph-user` user with passwordless sudo privileges.
```sh
sudo useradd --create-home -s /bin/bash ceph-user
echo "ceph-user:ceph-user" | sudo chpasswd
echo "ceph-user ALL = (root) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/ceph-user
sudo chmod 0440 /etc/sudoers.d/ceph-user
```

### On the `admin` node
> In following sections, `ceph-user` is in used.  

- Install `ceph-deploy`
```sh
wget -q -O- 'https://download.ceph.com/keys/release.asc' | sudo apt-key add -
echo deb https://download.ceph.com/debian-nautilus/ $(lsb_release -sc) main | sudo tee /etc/apt/sources.list.d/ceph.list
sudo apt update && sudo apt install -y ceph-deploy
```

- Generate SSH keys
```sh
ssh-keygen
```

- Configure `.ssh/config`
```sh
Host ceph-admin
    Hostname ceph-admin
    User ceph-user

Host ceph-mon1
    Hostname ceph-mon1
    User ceph-user
    
Host ceph-mon2
    Hostname ceph-mon2
    User ceph-user
    
Host ceph-mon3
    Hostname ceph-mon3
    User ceph-user
    
Host ceph-osd1
    Hostname ceph-osd1
    User ceph-user

Host ceph-osd2
    Hostname ceph-osd2
    User ceph-user

Host ceph-osd3
    Hostname ceph-osd3
    User ceph-user

Host ceph-rgw
    Hostname ceph-rgw
    User ceph-user
```

- Distribute ssh public key.
```sh
for i in ceph-mon1 ceph-mon2 ceph-mon3 ceph-osd1 ceph-osd2 ceph-osd3 ceph-rgw; do
    ssh-copy-id $i
done
```

- Make a `ceph-deploy` directory to store `ceph-deploy` logs and configuration files.
```sh
mkdir ceph-deploy
cd ceph-deploy
```

## Deploy the cluster
> Commands executed in this section are taken place in `ceph-admin` node, unless specified.  

### Deploy `mon`, `mgr`, `mds` nodes
- Add `mon` nodes to the cluster. These nodes are called *initial members* and will run `ceph-mon` when ceph is installed.
```sh
ceph-deploy new ceph-mon1 ceph-mon2 ceph-mon3
```

- Install Ceph packages on all nodes.
```sh
ceph-deploy ceph-mon1 ceph-mon2 ceph-mon3 ceph-osd1 ceph-osd2 ceph-osd3 ceph-rgw
```

- Create initial monitors in the cluster.
```sh
ceph-deploy mon create-initial
```

- Deploy `mgr` daemons.
```sh
ceph-deploy mgr create ceph-mon1 ceph-mon2 ceph-mon3
```

- Deploy metadata servers.
```sh
ceph-deploy mds create ceph-mon1 ceph-mon2 ceph-mon3
```

### Deploy `osd` nodes
- SSH to `osd` nodes and inspect available hard disks.
```sh
lsblk
```

- Copy the configuration file and admin key to all nodes, including the `ceph-admin`.
```sh
ceph-deploy ceph-admin ceph-mon1 ceph-mon2 ceph-mon3 ceph-osd1 ceph-osd2 ceph-osd3 ceph-rgw
```

- Deploy `osd` daemons on these disks.
```sh
# ceph-deploy osd create --data {device} {ceph-node}
for i in sdb sdc sdd; do
    for j in ceph-osd1 ceph-osd2 ceph-osd3; do
        ceph-deploy osd create --data /dev/$i $j
    done
done
```

- Use `lsblk` to inspect if previous available disks are attached to ceph osd daemons. Example:
```sh
lsblk 
NAME                                                                                                  MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                                                                                                     8:0    0   32G  0 disk 
|-sda1                                                                                                  8:1    0  487M  0 part /boot
|-sda2                                                                                                  8:2    0  1.9G  0 part [SWAP]
`-sda3                                                                                                  8:3    0 29.6G  0 part /
vdb                                                                                                   252:0    0    5G  0 disk 
`-ceph--908c8792--04e8--414f--8430--faa78e9b18eb-osd--block--275c9d8b--3825--4898--9b3b--5ea080fd7137 253:0    0    5G  0 lvm  
vdc                                                                                                   252:16   0    5G  0 disk 
`-ceph--c79a5159--3980--47e8--b649--ed0c44d32d51-osd--block--a50c2ebc--8d65--4d16--9196--6f741606b3a2 253:1    0    5G  0 lvm  
vdd                                                                                                   252:32   0    5G  0 disk 
`-ceph--594ff477--943e--49d8--8e08--addf5dbccca3-osd--block--5b71bad9--7fa8--41af--a3af--48af1219aafd 253:2    0    5G  0 lvm
```

- Check cluster health on a `mon` node.
```sh
sudo ceph health
# for more details
sudo ceph status
```

### Enable Ceph dashboard
> Following commands are executed on a `mon` node.  

- Enable the Ceph Dashboard module.
```sh
sudo ceph mgr module enable dashboard
sudo ceph mgr module ls
```

- Generate a self signed certificates for the dashboard.
```sh
sudo ceph dashboard create-self-signed-cert
```

- Create a user for the dashboard. This user will be used to login the dashboard.
```sh
# sudo ceph dashboard set-login-credentials <username> <password>
sudo ceph dashboard set-login-credentials ceph-admin ceph-admin
```

- Enable the Object Gateway Management Frontend:
```sh
sudo radosgw-admin user create --uid=ceph-admin --display-name='Ceph Admin' --system
```

- Provide the credentials of `ceph-admin` to the dashboard.
```sh
sudo ceph dashboard set-rgw-api-access-key <api-access-key>
sudo ceph dashboard set-rgw-api-secret-key <api-secret-key>
```

- Disable certificate verification because we're using a self-signed certificate in our Object Gateway.  
```sh
sudo ceph dashboard set-rgw-api-ssl-verify False
```

### Deploy the RADOS Gateway
- Add the `rgw` node to cluster.
```sh
ceph-deploy rgw create ceph-rgw
```

- The default port of the gateway will be `7480`. If we want to change it, Add following lines to `ceph.conf` on the `ceph-rgw` node:
```sh
[client]
rgw frontends = civetweb port=80
```

### Reset the cluster
- If we have any problem, we can reset the cluster.
```sh
ceph-deploy purge {ceph-node} [{ceph-node}]
ceph-deploy purgedata {ceph-node} [{ceph-node}]
ceph-deploy forgetkeys
rm ceph.*
```

## Confugure AWS S3 CLI for Ceph Object Gateway Storage
### Install AWS S3 CLI on the client
- Install `pip`.
```sh
# Ubuntu 20.04
sudo apt update
sudo apt -y install python3-pip

# Other Ubuntu / Debian
sudo apt-get update
sudo apt-get -y install python-pip
```
- Upgrade `pip`.
```sh
# Ubuntu 20.04 
sudo pip3 install --upgrade pip

# Other Ubuntu / Debian 
sudo pip install --upgrade pip
```
- Install and Upgrade AWS CLI.
```sh
# Ubuntu 20.04
sudo pip3 install awscli
sudo pip3 install awscli --upgrade

# Other Ubuntu / Debian
sudo pip install awscli
sudo pip install awscli --upgrade
```

- Check the installation
```
aws --version
```

### Configure Object Storage User for S3 access
- Create a new Object Storage user.
```sh
# on a mon node
sudo radosgw-admin user create --uid="S3user" --display-name="S3User"
```

- Take note the `access_key` and `secret_key`. If we forget, use command below to show:
```sh
# on a mon node
sudo radosgw-admin user info --uid=S3user
```

## Configure the client for accessing Ceph Object Storage
```sh
aws configure --profile=ceph 
AWS Access Key ID [None]: access_key
AWS Secret Access Key [None]: secret_key
Default region name [None]:
Default output format [None]: json
```

- Make a new bucket for a data object: 
```sh
# aws --profile=ceph --endpoint=http://{rgw-node-ip}:{gateway-port} s3 mb s3://{path-on-ceph}
aws --profile=ceph --endpoint=http://10.1.1.150:7480 s3 mb s3://test
```
- Check the bucket on a `mon` node:
```sh
sudo radosgw-admin bucket list
[
    "test"
]
```
- If we are on the `client` node, use the following command to list all buckets:
```sh
aws --profile=ceph --endpoint=http://{rgw-node-ip}:{gateway-port} s3 ls
```

- Copy a file to a bucket in the Object Storage cluster:
```sh
aws --profile=ceph --endpoint=http://192.168.226.137:7480 s3 cp {file_to_upload} s3://{bucket-name}
```

- list file in bucket:
```sh
aws --profile=ceph --endpoint=http://192.168.226.137:7480 s3 ls s3://test/
```

## Check bucket on the Ceph Dashboard
On a `mgr` node:
- To show the dashboard url
```sh
sudo ceph mgr services
```

# Deploy Ceph Block Device

## Client node
- System update.
```sh
sudo apt update
sudo apt upgrade -y
sudo reboot
```

- Install dependencies.
```sh
sudo apt install ntp python-minimal python-routes -y
# install python3-minimal and python3-routes if using ubuntu >= 20.04
```

- Install `python2` if is hasn't been installed on the client.
```sh
sudo apt install python2 -y
```

## Admin node

- Add an entry to the SSH config.
```sh
Host {client-host}
    Hostname {client-hostname}
    User {client-ceph-user}
```

- Add an entry to the `hosts` file.
```sh
{client-ip} {client-hostname}
```

- Add the client to the cluster.
```bash
ssh-copy-id ceph-client
ceph-deploy install ceph-client
ceph-deploy admin ceph-client
```

- Create a new pool for storing block devices.
```sh
sudo ceph osd pool create {pool-name} {pg-num} {pgp-num}
```

- Create a block device image.
```sh
sudo rbd create --size {image-size} --pool {pool-name} {image-name}
```

- Disable features not supported by the kernel before mapping block device.
```sh
sudo rbd feature disable datastore/vol01 object-map fast-diff deep-flatten
```

- On the client, map the image to the system.
> This is similar to attaching a hard drive/USB to the computer.  

```
sudo rbd map vol01 --pool datastore
```

- Format the block device.
```
mkfs.ext4 -m0 /dev/rbd/datastore/vol01
```

- Mount the block device to the filesystem.
```
mkdir /var/vol01
mount /dev/rbd/datastore/vol01 /var/vol01
```

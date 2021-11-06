# CEPH storage cluster deployment
> Reference: https://computingforgeeks.com/how-to-deploy-ceph-storage-cluster-on-ubuntu-18-04-lts/






## Preparation
- Install `ntp` on all nodes.
```sh
sudo apt install ntp -y
```
- Install `python-minimal` and `python3-minimal` on all nodes.
```sh
sudo apt install python-minimal python3-minimal -y
```

- Install `python-routes` on manager nodes.
```sh
sudo apt install python-routes -y
```

- Replace `sudo ceph dashboard ac-user-create <username> <password> <role>` with
```sh
sudo ceph dashboard set-login-credentials <username> <password>
```

# Confugure AWS S3 CLI for Ceph cluster storage

## Install AWS S3 on Ubuntu/Debian

Install Pip

```bash
--- Ubuntu 20.04 ---
sudo apt update
sudo apt -y install python3-pip

--- Other Ubuntu / Debian --- (ubuntu 18.04)
sudo apt-get update
sudo apt-get -y install python-pip
```
Upgrade Pip

```bash
--- Ubuntu 20.04 ---
sudo pip3 install --upgrade pip

--- Other Ubuntu / Debian ---
sudo pip install --upgrade pip
```

Install and Upgrade AWS CLI

```bash
--- Ubuntu 20.04 ---
sudo pip3 install awscli
sudo pip3 install awscli --upgrade

--- Other Ubuntu / Debian ---
sudo pip install awscli
sudo pip install awscli --upgrade
```

```
aws --version
```

## Configure Ceph aws s3 client

### On mon node

```bash
sudo radosgw-admin user create --uid="S3user" --display-name="S3User"
```

Take note `access_key` and `secret_key`

## AWS CLI for Accessing Ceph Object Storage


```bash
aws configure --profile=ceph 
AWS Access Key ID [None]: access_key
AWS Secret Access Key [None]: secret_key
Default region name [None]:
Default output format [None]: json
```
Connect to Radosgw:

rgw: 192.168.226.137 and running on port 7480 (if default)

Make bucket: 

```bash
aws --profile=ceph --endpoint=http://192.168.226.137:7480 s3 mb s3://test
```

Check bucket on mgr node:

```bash
sudo radosgw-admin bucket list
[
    "jkmutai-bucket",
    "test"
]
```

List bucket created with command:

```bash
aws --profile=ceph --endpoint=http://192.168.226.137:7480 s3 ls
```

Copy file local to bucket in cluster:

```bash
aws --profile=ceph --endpoint=http://192.168.226.137:7480 s3 cp upload_file.txt s3://test/
```

list file in bucket:

```bash
aws --profile=ceph --endpoint=http://192.168.226.137:7480 s3 ls s3://test/
```

## Check bucket on Dashboard

On mgr node:

To show dashboard url

```bash
sudo ceph mgr services
```
# Deploy Ceph Block Device

# Config ceph-block devices

## Client node

```bash
sudo apt update
sudo apt upgrade -y
sudo reboot 
sudo apt install ntp -y
sudo apt install python-minimal
sudo apt install python-routes
```

## Admin node

add ssh config

![image](https://user-images.githubusercontent.com/31529599/140593536-21c53090-11f9-4ba2-bd6b-69c7eb9a4a95.png)

add alias

![Untitled](https://s3-us-west-2.amazonaws.com/secure.notion-static.com/6fc103e9-f437-42ef-bd27-8387bb6b22c9/Untitled.png)

```bash
ssh-copy-id ceph-client
ceph-deploy install ceph-client
ceph-deploy admin ceph-client # in ceph-deploy directory
```

```bash
ceph osd pool create datastore 150 150 
rbd create --size 4096 --pool datastore vol01
sudo rbd feature disable datastore/vol01 object-map fast-diff deep-flatten # disable any features that are unsupported by the kernel before map
rbd map vol01 --pool datastore
mkfs.ext4 -m0 /dev/rbd/datastore/vol01
mkdir /var/vol01
mount /dev/rbd/datastore/vol01 /var/vol01
```

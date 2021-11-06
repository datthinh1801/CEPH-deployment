# CEPH Storage Cluster Deployment

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
- Update and upgrade, reboot
```sh
sudo apt update
sudo apt -y upgrade
sudo reboot
```

- Add alias to `/etc/hosts`
```sh
192.168.226.137 rgw.example.com rgw
192.168.226.141 osd01.example.com osd01
192.168.226.143 osd02.example.com osd02
192.168.226.144 mon01.example.com mon01
192.168.226.145 mon02.example.com mon02
192.168.226.140 ceph-admin.example.com ceph-admin
```
> Note: when install ceph node cluster, the hostname must be equal to alias 

- The admin node must have password-less SSH access to Ceph nodes. When ceph-deploy logs in to a Ceph node as a user, that particular user must have passwordless sudo privileges on all nodes.
```sh
export USER_NAME="ceph-admin"
export USER_PASS="ok"
sudo useradd --create-home -s /bin/bash ${USER_NAME}
echo "${USER_NAME}:${USER_PASS}"|sudo chpasswd
echo "${USER_NAME} ALL = (root) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/${USER_NAME}
sudo chmod 0440 /etc/sudoers.d/${USER_NAME}
```
- Verify passwordless set up:
```sh
jmutai@osd01:~$ su - ceph-admin
Password: 
ceph-admin@osd01:~$ sudo su -
root@ceph-admin:~#
```

## Preparation on ceph-admin node

- Import ceph repository key:
```sh
wget -q -O- 'https://download.ceph.com/keys/release.asc' | sudo apt-key add -
```
- Add the Ceph repository to your system. This installation will do Ceph `nautilus`:
```sh
echo deb https://download.ceph.com/debian-nautilus/ $(lsb_release -sc) main | sudo tee /etc/apt/sources.list.d/ceph.list
```

- Update and install ceph-deploy:
```sh
sudo apt update
sudo apt -y install ceph-deploy
```
- Generate and share ssh key to ceph node
```sh
# su - ceph-admin
$ ssh-keygen 
```
- Configure your ~/.ssh/config
```sh
$ vi /home/ceph-admin/.ssh/config 
Host osd01
  Hostname osd01
  User ceph-admin
Host osd02
  Hostname osd02
  User ceph-admin
Host osd01
  Hostname osd01
  User ceph-admin
Host mon01
  Hostname mon01
  User ceph-admin
Host mon02
  Hostname mon02
  User ceph-admin
Host rgw
  Hostname rgw
  User ceph-admin
```

- Copy the key to each Ceph Node ( Do this from Ceph Admin Node as the `ceph-admin` user)
```sh
for i in rgw mon01 mon02 mon03 osd01 osd02 osd03; do
 ssh-copy-id $i
done
```

## Deploy Ceph Storage Cluster 

- Let’s start by creating a directory on our `admin node` for maintaining the configuration files and keys that ceph-deploy generates for the cluster.
```sh
mkdir ceph-deploy
cd ceph-deploy
```

> Note: The `ceph-deploy` utility will output files to the current directory. Ensure you are in this directory when executing ceph-deploy.

### Initialize ceph monitor nodes
- Run the following commands on your admin node from the ceph-deploy directory you created for holding your configuration details
```sh
ceph-deploy new mon01 mon02 
```
### Install Ceph packages

- Install Ceph Packages on all nodes.

```sh
ceph-deploy install mon01 mon02 osd01 osd02 rgw
```

### Deploy the initial monitor(s) and gather the keys:

```sh
ceph-deploy mon create-initial
```
After the previous command, A number of keyrings will be placed in your working directory

- Deploy a manager deamon:
```sh
ceph-deploy mgr create mon01 mon02
```

- Add a Metadata Servers:
```sh
ceph-deploy mds create mon01 mon02
```

### Copy Ceph Admin Key To All Nodes

- Copy the configuration file and admin key to your admin node and your Ceph Nodes:
```sh
ceph-deploy admin mon01 mon02 osd01 osd02
```

### Add three OSDs

- I assume you have an unused disk in each node called `/dev/device`. Mine look like below:

```sh
root@osd01:~# lsblk 
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda      8:0    0   32G  0 disk 
|-sda1   8:1    0  487M  0 part /boot
|-sda2   8:2    0  1.9G  0 part [SWAP]
`-sda3   8:3    0 29.6G  0 part /
sdb    252:0    0    5G  0 disk 
sdc    252:16   0    5G  0 disk 
sdd    252:32   0    5G  0 disk
```
I have three devices to use:
  - /dev/sdb
  - /dev/sdc
  - /dev/sdd

- Be sure that the device is not currently in use and does not contain any important data.
```sh
for i in sdb sdc sdd; do
  for j in osd01 osd02 osd03; do
    ceph-deploy osd create --data /dev/$i $j
done
done
```

- Verify result

```sh
# lsblk 
NAME                                                                                                  MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                                                                                                     8:0    0   32G  0 disk 
|-sda1                                                                                                  8:1    0  487M  0 part /boot
|-sda2                                                                                                  8:2    0  1.9G  0 part [SWAP]
`-sda3                                                                                                  8:3    0 29.6G  0 part /
sdb                                                                                                   252:0    0    5G  0 disk 
`-ceph--908c8792--04e8--414f--8430--faa78e9b18eb-osd--block--275c9d8b--3825--4898--9b3b--5ea080fd7137 253:0    0    5G  0 lvm  
sdc                                                                                                   252:16   0    5G  0 disk 
`-ceph--c79a5159--3980--47e8--b649--ed0c44d32d51-osd--block--a50c2ebc--8d65--4d16--9196--6f741606b3a2 253:1    0    5G  0 lvm  
sdd                                                                                                   252:32   0    5G  0 disk 
`-ceph--594ff477--943e--49d8--8e08--addf5dbccca3-osd--block--5b71bad9--7fa8--41af--a3af--48af1219aafd 253:2    0    5G  0 lvm
```



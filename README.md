# CEPH-deployment
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

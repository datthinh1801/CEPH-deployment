#! /bin/bash

for i in ceph-mon1 ceph-mon2 ceph-mon3 ceph-osd1 ceph-osd2 ceph-osd3 ceph-rgw; do
    ssh $i 'bash -s' < ./config_ssh.sh
    ssh $i 'bash -s' < ./config_hosts_file.sh
done

#! /bin/bash

echo "Host ceph-mon1
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
    User ceph-user" | tee ~/.ssh/config

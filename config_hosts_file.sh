#! /bin/bash

echo "10.1.1.131 ceph-mon1
10.1.1.132 ceph-mon2
10.1.1.133 ceph-mon3
10.1.1.141 ceph-osd1
10.1.1.142 ceph-osd2
10.1.1.143 ceph-osd3
10.1.1.150 ceph-rgw" | sudo tee -a /etc/hosts

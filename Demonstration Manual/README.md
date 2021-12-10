# Demonstration

## Replicate
Configuration: 1 admin host, 2 monitor hosts, 2 osd host (each contain 3 osd node)
> set `min_size` replicate required to 1 (number of osd hosts not meet the default configuration)
> 
- Create a Pool
    - `ceph osd pool create <pool-name> {pg-num} {pgp-num}`
    - `ceph osd pool get <POOL> size/min_size`
    
    ```
    osd_pool_default_pg_num = 128
    osd_pool_default_pgp_num = 128
    
    pgnum == pgp = (OSDs*100)/size_replicate
    
    size_replicate_default : 3
    min_size : 2
    ```
    
- Upload and download a file object to pool
    - `rados -p <pool-name> put <objectname> <file>` → upload
    - `rados -p <pool-name> get <objectname> <file>` → download
- Show info replicate of object in Placement Groups
    - `ceph osd lspools` → list all existed pools
    - `ceph pg ls-by-pool <pool-name>`  → show pg info can read replicate osd nodes (`ceph pg map 3.0` → info replicate map)
    - [3,5,1] → 3 primary osd, 5 secondary osd, 1 tertiary osd
- Stop a primary osd (one osd host)
    - `systemctl | grep ceph`  →show osd services
    - `systemctl stop <service-name>` (`systemctl stop ceph-osd@1`) → stop osd services node
- Try to download file again then start osd node

## Demo automate map/unmap on boot/shutdown
- Root privilege on client
    - config `/etc/ceph/rbdmap` to access cluster
        - `<pool-name>/<image> id=admin,keyring=/etc/ceph/ceph.client.admin.keyring`
- Enable rbdmap service to automate map/unmap
    - `systemctl enable rbdmap`
- `/dev/rbd/<pool-name>/<image>` → to check result
- `mount` → to inspect block content


## Erasure coding
```bash
ceph osd erasure-code-profile set myprofile \
   k=2 \
   m=1 \
   crush-failure-domain=rack
```

Error EINVAL: k=1 must be >= 2

where `k +m <= osd hosts`

[References here for more detail](https://docs.ceph.com/en/latest/rados/operations/erasure-code/?highlight=erasure)

- Check default erasure code profile and set to fix with number of osd hosts
    - `ceph osd erasure-code-profile get default` → k+m ≤ num of osd hosts (k ≥2)
- Create a erasure coding pool
    - `ceph osd pool create <pool-name> <pg-num> <pgp-num> erasure`
- Put object to pool
    - `echo <data> | rados --pool <pool-name> put <object-name> -`
    - Check objects is exist on created pool: `rados --pool <pool-name> get <object-name> -`
- Show osd node storage data of object
    - `ceph osd lspools` → list all existed pools
    - `ceph pg ls-by-pool <pool-name>`  → show pg info store data
- Stop osd node on osd Host
    - `systemctl | grep ceph`  →show osd services
    - `systemctl stop <service-name>` (`systemctl stop ceph-osd@1`) → stop osd services node

Because `m=1` so if a node is down then placement group store object data will work normally

If more than one osd node is down then placement group will down too

## Adding/Removing an OSD

> For adding/removing an osd: See [this](https://docs.ceph.com/en/latest/rados/operations/add-or-rm-osds/#removing-osds-manual) and [my note](https://best-dream-976.notion.site/Add-and-Remove-Osd-host-c66b87c3430e49f58d619fb546be6970).  

## Inspecting its migration process
- List all objects of a pool.
```sh
rados -p {pool-name} ls
```
> [More about how this command works.](https://stackoverflow.com/questions/62725757/how-listing-objects-in-ceph-works)  

- List all PGs of a pool.
```sh
ceph ps ls-by-pool {pool-name}
```

- Get the mapping of a PG.
```sh
ceph ps map {PG-ID}
```


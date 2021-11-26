# Demonstration
## Adding/Removing an OSD
> For adding/removing an osd: See [this](https://docs.ceph.com/en/latest/rados/operations/add-or-rm-osds/#removing-osds-manual).  

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


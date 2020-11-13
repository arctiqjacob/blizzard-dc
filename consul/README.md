## Run Consul Snapshot Agent

```bash
# create a file containing the ACL token attached to the snapshot ACL policy
$ cat <<EOF > snapshot-agent/acl_token
0d3cc34b-ac01-a982-435c-9330531d5f39
EOF

# run the snapshot agent
$ consul snapshot agent -config-file config.json -token-file=acl_token
==> Consul snapshot agent running!
             Version: 1.8.5+ent
          Datacenter: "blizzard"
            Interval: "20m0s"
              Retain: 30
               Stale: false
...
```
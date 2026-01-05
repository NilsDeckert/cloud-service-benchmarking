bind 0.0.0.0
cluster-announce-ip {{ ansible_host }}
port 7000
protected-mode no
cluster-enabled yes
cluster-config-file nodes.conf
cluster-node-timeout 5000
io-threads 3
io-threads-do-reads yes
appendonly no
save ""
dir /home/nils/cluster

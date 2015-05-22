# Cluster Monitor Tool

This tool provides real-time visualization of the cluster member roles for all
shards in the config datastore. It is useful for understanding cluster behavior
in when controllers are isolated, downed, or rebooted.

A file named `cluster.json` containing a list of the IP addresses of the
controllers is required. This resides in the same directory as `monitor.py`.
"user" and "pass" are not required for `monitor.py`, but they may be
needed for other apps in this folder. Because this configuration
information unique to your environment, it may be more convenient to
copy the contents of this folder out of git to prevent these settings
from being overwritten by updates.


The file should look like this:

```
    {
        "cluster": {
            "controllers": [
                "172.17.10.93",
                "172.17.10.94",
                "172.17.10.95"
            ],
            "user": "username",
            "pass": "password"
        }
    }
```

## Usage: `monitor.py`

### Starting `monitor.py`

Before using, start and configure all controllers in the cluster. Use of the
cluster deployment script is recommended. All controllers must initially be
running so the tool can retrieve the controller and shard names. Once
the tool is started and the controller and cluster shard names are retrieved,
controllers can be isolated, downed, rebooted, etc.

### The `monitor.py` UI

Controller member names (not host names) are displayed across the top. Shard
names are displayed to the left.

In the upper left is a heart emoticon "<3" which toggles between yellow and
black backgrounds with each update. If a controller is down, the HTTP timeout
comes in to play and updating becomes much slower.

The central matrix displays controller roles. When REST queries fail, the
error type is displayed. Leader, Follower, and Candidate roles are color-
coded.

## Other Scripts

### `isolate.py`

Isolates an indicated controller from the cluster.

### `rejoin.py`

Rejoins any isolated controllers to the cluster.

### `timed_isolation.py`

Isolates an indicated controller for a specified duration

## Future Enhancements

Add operational shards.

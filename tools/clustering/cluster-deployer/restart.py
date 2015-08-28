# #!/usr/local/bin/python
#
# This script restarts the cluster nodes. It can optionally cleanup the persistent data.
# --------------------------------------------------------------------------------------
#
# This script takes a list of hosts as parameter
#
#
# -------------------------------------------------------------------------------------------------------------

import argparse
from remote_host import RemoteHost

parser = argparse.ArgumentParser(description='Cluster Restart')
parser.add_argument("--rootdir", default="/root",
                    help="the root directory on the remote host where the distribution is deployed", required=True)
parser.add_argument("--hosts", default="",
                    help="a comma separated list of host names or ip addresses", required=True)
parser.add_argument("--clean", action="store_true", default=False,
                    help="clean the persistent data for the current deployment")
parser.add_argument("--user", default="root", help="the SSH username for the remote host(s)")
parser.add_argument("--password", default="Ecp123", help="the SSH password for the remote host(s)")
args = parser.parse_args()


def main():
    hosts = args.hosts.split(",")
    for x in range(0, len(hosts)):
        # Connect to the remote host and start doing operations
        remote = RemoteHost(hosts[x], args.user, args.password, args.rootdir)
        remote.kill_controller()
        if(args.clean):
            remote.exec_cmd("rm -rf " + args.rootdir + "/deploy/current/odl/journal")
            remote.exec_cmd("rm -rf " + args.rootdir + "/deploy/current/odl/snapshots")
        remote.start_controller(args.rootdir + "/deploy/current")

main()

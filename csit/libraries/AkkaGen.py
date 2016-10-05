"""
Library to generate akka.conf content

This library will be potentially used in suites and tests where new seednodes
may be added into the cluster.
"""

from string import Template

def generate_akka_content(index, ip_list=[]):
    """Generates the ocntent of akka,conf file

    Args:
        :param index: cluster node index, starts with 1, the ip_list[index-1] is a valid ip address
                      for the cluster node
        :param ip_list: list of ip addresses, e.g. ["1.1.1.1", "2.2.2.2", "3.3.3.3"]

    Returns:
        :returns str: akka.conf content

    """
    tmpl = '''odl-cluster-data {
  akka {
    remote {
      netty.tcp {
        hostname = "$hostname"
        port = 2550
      }
    }

    cluster {
      seed-nodes = [ $seednodes ]

      roles = [ $roles ]

    }
    
    persistence {
      # By default the snapshots/journal directories live in KARAF_HOME. You can choose to put it somewhere else by
      # modifying the following two properties. The directory location specified may be a relative or absolute path. 
      # The relative path is always relative to KARAF_HOME.

      # snapshot-store.local.dir = "target/snapshots"
      # journal.leveldb.dir = "target/journal"

      journal {
        leveldb {
          # Set native = off to use a Java-only implementation of leveldb.
          # Note that the Java-only version is not currently considered by Akka to be production quality.

          # native = off
        }
      }
    }
  }
}
'''
    akkatempl = Template(tmpl)
    seed_nodes = ""
    for ip in ip_list:
        seed_nodes += '{}"akka.tcp://opendaylight-cluster-data@{}:2550"'.format("" if seed_nodes=="" else ' ,', ip)
    roles = '"member-{}"'.format(index)
    hostname = '{}'.format(ip_list[index-1])
    d = {'hostname': hostname, 'seednodes': seed_nodes, 'roles': roles}
    return akkatempl.safe_substitute(d)

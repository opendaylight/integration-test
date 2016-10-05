"""
Library generating configuration/initial files.


The purpose of this library is about to customize conf file creation.
"""


import pyhocon


def _parse_input(file_name):
    """Parses given file and returns it's pyhocon object.

    Args:
        :param file_name: path to the filename

    Returns:
        :returns pyhocon_obj: parsed content of the given file
    """
    return pyhocon.ConfigFactory.parse_file(file_name)


def generate_akka(original_file, node_idx=1, nodes_ip_list=['127.0.0.1']):
    """Generates akka.conf content.

    Args:
        :param file_name: path to the filename, normally expecting file from system/org/opendaylight...
                          sal-clustering-config-<version>-akkaconf.xml
    Returns:
        :returns str: akka.conf content
    """

    conf = _parse_input(original_file)
    conf['odl-cluster-data']['akka']['remote']['netty']['tcp']['hostname'] = nodes_ip_list[node_idx-1]
    seed_nodes = [ u'akka.tcp://opendaylight-cluster-data@{}:2550'.format(ip) for ip in nodes_ip_list]
    conf['odl-cluster-data']['akka']['cluster']['seed-nodes'] = seed_nodes
    conf['odl-cluster-data']['akka']['cluster']['roles'] = ["member-{}".format(node_idx)]
    return pyhocon.tool.HOCONConverter.to_hocon(conf)

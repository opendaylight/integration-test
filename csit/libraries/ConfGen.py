"""
Library generating configuration/initial files.

The purpose of this library is about to customize conf file creation for special
use cases while testing, e.g. non replicated shards.
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
        :param original_file: path to the filename, normally expecting file from system/org/opendaylight...
                          sal-clustering-config-<version>-akkaconf.xml
        :param node_idx: cluster node index for which the file is generated
        :param nodes_ip_list: list of luster nodes ip addresses

    Returns:
        :returns str: akka.conf content
    """

    conf = _parse_input(original_file)
    conf['odl-cluster-data']['akka']['remote']['netty']['tcp']['hostname'] = nodes_ip_list[node_idx-1]
    seed_nodes = [u'akka.tcp://opendaylight-cluster-data@{}:2550'.format(ip) for ip in nodes_ip_list]
    conf['odl-cluster-data']['akka']['cluster']['seed-nodes'] = seed_nodes
    conf['odl-cluster-data']['akka']['cluster']['roles'] = ["member-{}".format(node_idx)]
    return pyhocon.tool.HOCONConverter.to_hocon(conf)


def generate_modules(original_file, name='', namespace=''):
    """Generates modules.conf content.

    If name and namespace parameters are filled, exactly one module item is added to the content of orginal file.
    If more modules needed, then use this keyword more times with storing temp file after each addition and use
    it as <original_file> in the next step.

    Args:
        :param original_files: path to the filename, normally expecting file from system/org/opendaylight...
                          sal-clustering-config-<version>-moduleconf.xml
        :param name: name of the new, addional shard
        :param namespace: namespace of the new, addional shard

    Returns:
        :returns str: modules.conf content
    """
    conf = _parse_input(original_file)
    if name != '' and namespace != '':
        conf['modules'].append(
            pyhocon.ConfigTree([("name", name), ("namespace", namespace), ("shard-strategy", "module")]))
    return pyhocon.tool.HOCONConverter.to_hocon(conf)


def generate_module_shards(original_file, nodes=1, shard_name='', replicas=[]):
    """Generates module-shards.conf content.

    If shard_name and replicas parameters are filled, exactly one shard item is added to the content of orginal file.
    If more shards needed, then use this keyword more times with storing temp file after each addition and use it as
    <original_file> in the next step.

    Args:
        :param file_name: path to the filename, normally expecting file from system/org/opendaylight...
                          sal-clustering-config-<version>-moduleshardconf.xml
        :param: nodes: number of nodes in the cluster
        :param shard_name: new name of the additional shard
        :param replicas: list of member indexes which should keep shard replicas

    Returns:
        :returns str: module-shards.conf content
    """
    conf = _parse_input(original_file)
    for module_shard in conf['module-shards']:
        module_shard["shards"][0]["replicas"] = ["member-{}".format(i+1) for i in range(int(nodes))]
    if shard_name != '' and replicas != []:
        conf['module-shards'].append(
            pyhocon.ConfigTree([("name", shard_name),
                                ("shards", [pyhocon.ConfigTree(
                                    [("name", shard_name),
                                     ("replicas", ["member-{}".format(i) for i in replicas])])])]))
    return pyhocon.tool.HOCONConverter.to_hocon(conf)

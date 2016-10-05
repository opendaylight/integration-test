"""
Library to generate configuration/initial/module-shards.conf content
"""

import copy
from string import Template


def generate_module_shards_content(shard_list=[]):
    """Generates the content of module-shards.conf file.

    Shard detail is a dict containing name and replicas keys.
    {"name": "myname", "replicas":[""member-1""]}
    The replica item must contain "" as a part of the name, becuase
    it is just used as a string and no further manipulation is done.

    Args:
        :param shard_list: list of particular shards details

    Returns:
        :returns str: module-shards.conf content

    """
    mstmpl = """module-shards = [
$module_shards
]
"""
    stmpl = """        {
                name = "$name"
                shards = [
                        {
                                name = "$name"
                                replicas = [$replicas]
                        }
                ]
        }"""

    module_shards_templ = Template(mstmpl)
    shard_templ = Template(stmpl)

    module_shards_cnt = ""
    for scnt in shard_list:
        replicas_str = ""
        for repl in scnt["replicas"]:
            replicas_str += "{}{}".format("" if replicas_str == "" else ",", repl)
        nscnt = copy.deepcopy(scnt)
        nscnt["replicas"] = replicas_str
        module_shards_cnt += "{}{}".format("" if module_shards_cnt == "" else ",\n", shard_templ.safe_substitute(nscnt))

    return module_shards_templ.safe_substitute({"module_shards": module_shards_cnt})


def get_default_shard_list(nodes=1, shards=["default", "inventory", "topology", "toaster"]):
    """Geneartes shard list with the default items.

    Args:
        :param nodes: number of nodes in the cluster, default shards are repicated on all nodes

    Returns:
        :returns shard_list: list of modules details(dictionaries) suitable for template

    """

    shard_list = []
    for shard in shards:
        sdict = {"name": shard, "replicas": []}
        for i in range(nodes):
            sdict["replicas"].append('"member-{}"'.format(i+1))
        shard_list.append(sdict)
    return shard_list


def get_not_replicated_bgp_rib_shard_with_defaults(
        node_idx=1, default_shards=["default", "inventory", "topology", "toaster"], nodes=3):
    """Geneartes shard list with the default items and one additional shard.

    Args:
        :param node_idx: id the the cluster node member, replicas will be done only here
        :param default_shards: list of shards to be included
        :param nodes: number of nodes in the cluster
    Returns:
        :returns shard_list: list of module shard details(dictionaries) suitable for template
    """

    shard_list = []
    shard_list.extend(get_default_shard_list(shards=default_shards, nodes=nodes))
    shard_list.append({"name": "bgp_rib", "replicas": ['"member-{}"'.format(node_idx)]})
    return shard_list

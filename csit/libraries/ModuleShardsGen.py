"""
Library to generate configuration/initial/module-shards.conf content
"""

import copy
from string import Template


def generate_module_shards_content(content_list=[]):
    """Generates the content of module-shards.conf file

    Args:
        :param content_list: list od shards details

    Returns:
        :returns str: module-shards.conf content

    """
    mstmpl = '''module-shards = [
    $module_shards
]
'''
    stmpl = '''	{
		name = "$name"
		shards = [
			{
				name = "$name"
				replicas = [$replicas]
			}
		]
	}'''

    print content_list
    module_shards_templ = Template(mstmpl)
    shard_templ = Template(stmpl)

    module_shards_cnt = ""
    for scnt in content_list:
        replicas_str = ""
        for repl in scnt['replicas']:
            replicas_str += "{}{}".format( "" if replicas_str == "" else ",", repl)
        nscnt = copy.deepcopy(scnt)
        nscnt['replicas'] = replicas_str
        print nscnt
        module_shards_cnt += "{}{}".format( "" if module_shards_cnt == "" else ",\n" , shard_templ.safe_substitute(nscnt))

    return module_shards_templ.safe_substitute({'module_shards': module_shards_cnt})

def get_default_content_list( nodes = 1, shards=['default', 'inventory', 'topology', 'toaster']):
    """blabla"""
    content_list = []
    for shard in shards:
        sdict = { 'name': shard, 'replicas':[]}
        for i in range(nodes):
            sdict['replicas'].append('"member-{}"'.format(i+1))
        content_list.append(sdict)
    return content_list



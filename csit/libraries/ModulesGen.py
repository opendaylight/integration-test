"""
Library to generate configuration/initial/modules.conf content
"""

from string import Template


def generate_modules_content(modules_list=[]):
    """Generates the content of modules.conf file.

    Module detail is a dict containing name, namespace and strategy.
    {"name": "myname", "namespace": "mynamespace", "strategy;: "module"}
    This dict is then used with the template to generate the file content.

    Args:
        :param modules_list: list of modules' details

    Returns:
        :returns str: modules.conf content

    """
    modules_tmpl = """modules = [
$modules
]
"""
    module_tmpl = """        {
                name = "$name"
                namespace = "$namespace"
                shard-strategy = "$strategy"
        }"""

    modules_templ = Template(modules_tmpl)
    module_templ = Template(module_tmpl)

    modules_cnt = ""
    for module in modules_list:
        modules_cnt += "{}{}".format("" if modules_cnt == "" else ",\n", module_templ.safe_substitute(module))

    return modules_templ.safe_substitute({"modules": modules_cnt})


def get_default_modules_list(modules=["inventory", "topology", "toaster"]):
    """Geneartes modules list with the default items.

    Args:
        :param modules: list of modules which should be included

    Returns:
        :returns modules_list: list of modules details(dictionaries) suiteable for template

    """
    def_modules_list = {
        "inventory": {
            "name": "inventory",
            "namespace": "urn:opendaylight:inventory",
            "strategy": "module",
        },
        "topology": {
            "name": "topology",
            "namespace": "urn:TBD:params:xml:ns:yang:network-topology",
            "strategy": "module",
        },
        "toaster": {
            "name": "toaster",
            "namespace": "http://netconfcentral.org/ns/toaster",
            "strategy": "module",
        }
    }
    modules_list = []
    for module in modules:
        modules_list.append(def_modules_list[module])
    return modules_list


def get_default_modules_with_new_module(name, namespace, strategy='module',
                                        include_default=["inventory", "topology", "toaster"]):
    """Generates modules list with one additional module details.

    Args:
        :param name: additional module name
        :param namespace: additional module's namespace
        :param strategy: should be "module"
        :param include_default: which of default modules should be included

    Returns:
        :returns modules_list: list of modules details(dictionaries) suiteable for template

    """
    modules_list = get_default_modules_list(include_default)
    modules_list.append({"name": name, "namespace": namespace, "strategy": strategy})
    return modules_list

from changes import Changes

# assumes that the new/current and older distributions are unzipped in /tmp/distro_new and
# /tmp_distro_old respectively

def get_project_names():
    # TODO: when autorelease starts publishing the dependencies.log artifact, this function (or the consumer
    # of this tool) can take the latest dependencies.log from jenkins lastSuccessfulArtifacts and put it
    # in /tmp/ For now the functionality to read the projects from that file are commented.

    '''
    projects = []
    with open("/tmp/dependencies.log") as dep_file:
        for line in dep_file:
            if line != "\n":
                projects.append(line.split(":")[0])

    return projects
    '''

    # this hard coded list of projects was taken from a Carbon dependencies.log - late January 2017
    return ['eman', 'integration/distribution', 'snbi', 'mdsal', 'alto', 'sfc', 'sdninterfaceapp', 'topoprocessing',
            'usc', 'ovsdb', 'lispflowmapping', 'groupbasedpolicy', 'usecplugin', 'snmp4sdn', 'capwap', 'aaa',
            'honeycomb/vbd', 'atrium', 'next', 'nic', 'vtn', 'lacp', 'openflowplugin', 'faas', 'ttp', 'of-config',
            'packetcable', 'genius', 'yangtools', 'natapp', 'didm', 'infrautils', 'netide', 'netvirt', 'neutron',
            'cardinal', 'snmp', 'bgpcep', 'nemo', 'netconf', 'yang-push', 'iotdm', 'tsdr', 'sxp', 'centinel',
            'odlparent', 'l2switch', 'unimgr', 'openflowjava', 'ocpplugin', 'dlux', 'controller']

query_limit = 100
num_to_display = 50
branch = 'master'
project_names = get_project_names()
extracted_distro_location = {'new': '/tmp/distro_new', 'old': '/tmp/distro_old'}

change_sets = {}
includes = {'new': {}, 'old': {}}

for distro in ['new', 'old']:
    change_sets[distro] = Changes()
    change_sets[distro].distro_path = extracted_distro_location[distro]
    change_sets[distro].project_names = project_names
    change_sets[distro].branch = branch
    change_sets[distro].limit = num_to_display
    change_sets[distro].qlimit = query_limit

    change_sets[distro].run_cmd()
    change_sets[distro].pretty_print_projects(change_sets[distro].projects)

    for idx, project in enumerate(project_names):
        includes[distro][project] = change_sets[distro].projects[project_names[idx]]['includes']

    # TODO: there is something not working when trying to create two Changes() objects at the same
    # time. Seems they are sharing things and it was not possible to have both objects alive at the
    # same time. so that's why I'm going each change set in order and del on the object. would like
    # to figure out the problem which I suspect is in changes.py
    del change_sets[distro]

patchset_diff = []
num_differences = 0

print("\nPatch differences:\n------------------")
for project in includes['new']:
    for patchset in includes['new'][project]:
        if patchset not in includes['old'][project]:
            num_differences += 1
            patchset_diff.append(patchset)
            print('{:<15}{}\t{}'.format(project, patchset['url'], patchset['subject']))

print("\n%s different patches between the two distros." % num_differences)

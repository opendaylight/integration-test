from changes import Changes

# need to add command line args here. at the least, so we can pass in the two distro urls

def get_project_names():
    # this will eventually grab dependencies.log from jenkins autorelease and generate projects based on that
    projects = []
    with open("/tmp/dependencies.log") as dep_file:
        for line in dep_file:
            if line != "\n":
                projects.append(line.split(":")[0])

    # return projects
    return ["yangtools", "netvirt", 'genius']

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

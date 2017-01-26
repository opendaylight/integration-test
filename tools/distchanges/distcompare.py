from changes import Changes

# need to add command line args here. at the least, so we can pass in the two distro urls

def get_project_names():
    # this will eventually grab dependencies.log from jenkins autorelease and generate projects based on that
    projects = []
    with open("/tmp/dependencies.log") as dep_file:
        for line in dep_file:
            if line != "\n":
                projects.append(line.split(":")[0])

    return projects
    # return ["yangtools", "netvirt", 'genius']

query_limit = 100
num_to_display = 50
branch = 'master'
project_names = get_project_names()

change_set_1 = Changes()
change_set_1.distro_path = '/tmp/distro_new'
change_set_1.project_names = project_names
change_set_1.branch = branch
change_set_1.limit = num_to_display
change_set_1.qlimit = query_limit

change_set_1_result = change_set_1.run_cmd()
change_set_1.pretty_print_projects(change_set_1.projects)

change_set_1_includes = {}
for idx, project in enumerate(project_names):
    change_set_1_includes[project] = change_set_1.projects[project_names[idx]]['includes']

# TODO: there is something not working when trying to create two Changes() objects at the same
# time. Seems they are sharing things and it was not possible to have both objects alive at the
# same time. so that's why I'm going each change set in order and del on the object. would like
# to figure out the problem which I suspect is in changes.py
del change_set_1

change_set_2 = Changes()
change_set_2.distro_path = '/tmp/distro_old'
change_set_2.project_names = project_names
change_set_2.branch = branch
change_set_2.limit = num_to_display
change_set_2.qlimit = query_limit

change_set_2_result = change_set_2.run_cmd()
change_set_2.pretty_print_projects(change_set_2.projects)

change_set_2_includes = {}
for idx, project in enumerate(project_names):
    change_set_2_includes[project] = change_set_2.projects[project_names[idx]]['includes']

# TODO: see above TODO near "del change_set_1"
del change_set_2

patchset_diff = []

num_differences = 0

print("\nPatch differences:\n------------------")
for project in change_set_1_includes:
    for patchset in change_set_1_includes[project]:
        if patchset not in change_set_2_includes[project]:
            num_differences += 1
            patchset_diff.append(patchset)
            print('{:<15}{}\t{}'.format(project, patchset['url'], patchset['subject']))

print("\n%s different patches between the two distros." % num_differences)

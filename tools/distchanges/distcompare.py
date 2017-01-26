from tools.distchanges.changes import Changes

# TODO: there is something not working when trying to create two Changes() objects at the same
# time. Seems they are sharing things and it was not possible to have both objects alive at the
# same time. so that's why I'm going each change set in order and del on the object. would like
# to figure out the problem which I suspect is in changes.py

# notes:
# this is currently just a hack to get it working.
# need to work across multiple projects, only one hardcoded here now
# need to pretty print the diffs
# probably should do full outputs of both distros change sets before the above pretty print
# need to add command line args here. at the least, so we can pass in the two distro urls
# need to run this with remote_urls for change_set_2 as that is the likely case

query_limit = 50
num_to_display = 10
branch = 'master'
project_names = ['yangtools']

change_set_1 = Changes()
change_set_1.distro_path = '/tmp/distro_1'
change_set_1.project_names = project_names
change_set_1.branch = branch
change_set_1.limit = num_to_display
change_set_1.qlimit = query_limit
change_set_1.pretty_print_projects(change_set_1.projects)

change_set_1_result = change_set_1.run_cmd()
change_set_1_includes = change_set_1.projects[project_names[0]]['includes']

del change_set_1

change_set_2 = Changes()
change_set_2.distro_path = '/tmp/distro_2'
change_set_2.project_names = project_names
change_set_2.branch = branch
change_set_2.limit = num_to_display
change_set_2.qlimit = query_limit
change_set_2.pretty_print_projects(change_set_2.projects)

change_set_2_result = change_set_2.run_cmd()
change_set_2_includes = change_set_2.projects[project_names[0]]['includes']

del change_set_2

patchset_diff = []

for patchset in change_set_1_includes:
    if patchset not in change_set_2_includes:
        patchset_diff.append(patchset)
        print("this is a diff methinks %s" % patchset)


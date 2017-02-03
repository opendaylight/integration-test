from changes import Changes

# assumes that the new/current and older distributions are unzipped in /tmp/distro_new and
# /tmp_distro_old respectively


class DistCompare(object):

    @staticmethod
    def get_project_names():
        # TODO: when autorelease starts publishing the dependencies.log artifact, this function (or the consumer
        # of this tool) can take the latest dependencies.log from jenkins lastSuccessfulArtifacts and put it
        # in /tmp/ For now the functionality to read the projects from that file are commented.

        """
        projects = []
        with open("/tmp/dependencies.log") as dep_file:
            for line in dep_file:
                if line != "\n":
                    projects.append(line.split(":")[0])

        return projects
        """

        # this hard coded list of projects was taken from a Carbon dependencies.log - late January 2017
        return ['eman', 'integration/distribution', 'snbi', 'mdsal', 'alto', 'sfc', 'sdninterfaceapp', 'topoprocessing',
                'usc', 'ovsdb', 'lispflowmapping', 'groupbasedpolicy', 'usecplugin', 'snmp4sdn', 'capwap', 'aaa',
                'honeycomb/vbd', 'atrium', 'next', 'nic', 'vtn', 'lacp', 'openflowplugin', 'faas', 'ttp', 'of-config',
                'packetcable', 'genius', 'yangtools', 'natapp', 'didm', 'infrautils', 'netide', 'netvirt', 'neutron',
                'cardinal', 'snmp', 'bgpcep', 'nemo', 'netconf', 'yang-push', 'iotdm', 'tsdr', 'sxp', 'centinel',
                'odlparent', 'l2switch', 'unimgr', 'openflowjava', 'ocpplugin', 'dlux', 'controller']

    def run_cmd(self):
        query_limit = 100
        num_to_display = 50
        branch = 'master'
        project_names = self.get_project_names()
        extracted_distro_locations = {'new': '/tmp/distro_new', 'old': '/tmp/distro_old'}

        new_changes = Changes(branch, extracted_distro_locations['new'], num_to_display,
                              query_limit, project_names)
        new_projects = new_changes.run_cmd()
        new_changes.pretty_print_projects(new_projects)

        old_changes = Changes(branch, extracted_distro_locations['old'], num_to_display,
                              query_limit, project_names)
        old_projects = old_changes.run_cmd()
        old_changes.pretty_print_projects(old_projects)

        patchset_diff = []
        print("\nPatch differences:\n------------------")
        for project_name, values in new_projects.items():
            new_gerrits = values['includes']
            for gerrit in new_gerrits:
                if gerrit not in old_projects[project_name]['includes']:
                    patchset_diff.append(gerrit)
                    print('{:<20}{}\t{}'.format(project_name, gerrit['url'], gerrit['subject']))

        print("\n%s different patches between the two distros." % len(patchset_diff))


def main():
    distc = DistCompare()
    distc.run_cmd()


if __name__ == "__main__":
    main()

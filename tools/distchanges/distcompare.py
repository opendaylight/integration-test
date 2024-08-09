import argparse
from changes import Changes

# assumes that the new/current and older distributions are unzipped in /tmp/distro_new and
# /tmp_distro_old respectively


class DistCompare(object):
    def __init__(self, remote_url):

        self.remote_url = remote_url

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
        # this hard coded list of projects was taken from Oxygen dependencies.log - late January 2018
        return [
            "integration/distribution",
            "mdsal",
            "serviceutils",
            "ovsdb",
            "lispflowmapping",
            "snmp4sdn",
            "aaa",
            "honeycomb/vbd",
            "openflowplugin",
            "of-config",
            "daexim",
            "dluxapps",
            "packetcable",
            "yangtools",
            "infrautils",
            "snmp",
            "bgpcep",
            "nemo",
            "netconf",
            "sxp",
            "jsonrpc",
            "p4plugin",
            "odlparent",
            "l2switch",
            "dlux",
            "controller",
        ]

    def run_cmd(self):
        query_limit = 100
        num_to_display = 50
        branch = "master"
        project_names = self.get_project_names()
        extracted_distro_locations = {
            "new": "/tmp/distro_new",
            "old": "/tmp/distro_old",
        }

        new_changes = Changes(
            branch,
            extracted_distro_locations["new"],
            num_to_display,
            query_limit,
            project_names,
            self.remote_url,
        )

        new_projects = new_changes.run_cmd()
        new_changes.pretty_print_projects(new_projects)

        old_changes = Changes(
            branch,
            extracted_distro_locations["old"],
            num_to_display,
            query_limit,
            project_names,
            self.remote_url,
        )

        old_projects = old_changes.run_cmd()
        old_changes.pretty_print_projects(old_projects)

        patchset_diff = []
        print("\nPatch differences:\n------------------")
        for project_name, values in new_projects.items():
            new_gerrits = values["includes"]
            for gerrit in new_gerrits:
                if gerrit not in old_projects[project_name]["includes"]:
                    patchset_diff.append(gerrit)
                    print(
                        "{:<20}{}\t{}".format(
                            project_name, gerrit["url"], gerrit["subject"]
                        )
                    )

        print("\n%s different patches between the two distros." % len(patchset_diff))


def main():

    parser = argparse.ArgumentParser(
        description="Returns the list of patches found in the unzipped distribution at "
        "/tmp/distro_new that are not found in the distribution at "
        "/tmp/distro_old. This should result in a listing of what new changes "
        "were made between the two distributions."
    )
    parser.add_argument(
        "-r",
        "--remote",
        dest="remote_url",
        default=Changes.REMOTE_URL,
        help="git remote url to use for gerrit",
    )
    options = parser.parse_args()

    distc = DistCompare(options.remote_url)
    distc.run_cmd()


if __name__ == "__main__":
    main()

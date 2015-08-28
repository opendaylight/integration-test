# remote_host.py
#
#
# The RemoteHost class provides methods to do operations on a remote host
#

from SSHLibrary import SSHLibrary

import os


class RemoteHost:
    def __init__(self, host, user, password, rootdir):
        self.host = host
        self.user = user
        self.password = password
        self.rootdir = rootdir
        self.lib = SSHLibrary()
        self.lib.open_connection(self.host)
        self.lib.login(username=self.user, password=self.password)

    def __del__(self):
        self.lib.close_connection()

    def exec_cmd(self, command):
        print "Executing command " + command + " on host " + self.host
        rc = self.lib.execute_command(command, return_rc=True)
        if rc[1] != 0:
            raise Exception('remote command failed [{0}] with exit code {1}.'
                            'For linux-based vms, Please make sure requiretty is disabled in the /etc/sudoers file'
                            .format(command, rc))

    def mkdir(self, dir_name):
        self.exec_cmd("mkdir -p " + dir_name)

    def copy_file(self, src, dest):
        if src is None:
            print "src is None not copy anything to " + dest
            return

        if os.path.exists(src) is False:
            print "Src file " + src + " was not found"
            return

        print "Copying " + src + " to " + dest + " on " + self.host
        self.lib.put_file(src, dest)

    def kill_controller(self):
        self.exec_cmd("sudo ps axf | grep karaf | grep -v grep "
                      "| awk '{print \"kill -9 \" $1}' | sudo sh")

    def start_controller(self, dir_name):
        self.exec_cmd(dir_name + "/odl/bin/start")

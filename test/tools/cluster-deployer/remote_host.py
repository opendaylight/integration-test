# remote_host.py

# 
# The RemoteHost class provides methods to do operations on a remote host
#

from SSHLibrary import SSHLibrary

class RemoteHost:
	def __init__(self, host, user, password, rootdir):
		self.host = host
		self.user = user
		self.password = password
		self.rootdir = rootdir

	def exec_cmd(self, command):
		print "Executing command " + command + " on host " + self.host
		lib = SSHLibrary()
		lib.open_connection(self.host)
		lib.login(username=self.user,password=self.password)
		lib.execute_command(command)
		lib.close_connection()


	def mkdir(self, dir_name):
		self.exec_cmd("mkdir -p " + dir_name)

	def copy_file(self, src, dest):
	    lib = SSHLibrary()
	    lib.open_connection(self.host)
	    lib.login(username=self.user, password=self.password)
	    print "Copying " + src + " to " + dest + " on " + self.host
	    lib.put_file(src, dest)
	    lib.close_connection()

	def kill_controller(self):
	    self.exec_cmd("ps axf | grep karaf | grep -v grep | awk '{print \"kill -9 \" $1}' | sh")

	def start_controller(self, dir_name):
		self.exec_cmd(dir_name + "/odl/bin/start")
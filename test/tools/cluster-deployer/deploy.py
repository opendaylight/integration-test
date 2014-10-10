#!/usr/local/bin/python
#
# This script deploys a cluster
# -------------------------------------------
#
# Pre-requisites
# - Python 2.7
# - SSHLibrary (pip install robotframework-sshlibrary)
# - pystache (pip install pystache)
# - argparse (pip install argparse)
#
# The input that this script will take is as follows,
# 
# - A comma separated list of ip addresses/hostnames for each host on which the distribution needs to be deployed
# - The replication factor to be used
# - The ssh username/password of the remote host(s). Note that this should be the same for each host
# - The name of the template to be used. 
#   Note that this template name should match the name of a template folder in the templates directory.
#   The templates directory can be found in the same directory as this script.
#
# Here are the things it will do,
#
# - Copy over a distribution of opendaylight to the remote host
# - Create a timestamped directory on the remote host
# - Unzip the distribution to the timestamped directory
# - Copy over the template substituted configuration files to the appropriate location on the remote host
# - Create a symlink to the timestamped directory
# - Start karaf
#
# -------------------------------------------------------------------------------------------------------------

import argparse
from SSHLibrary import SSHLibrary
import time
import pystache
import os
import sys
import random

parser = argparse.ArgumentParser(description='Cluster Deployer')
parser.add_argument("--distribution", default="", help="the absolute path of the distribution on the local host that needs to be deployed", required=True)
parser.add_argument("--rootdir", default="/root", help="the root directory on the remote host where the distribution is to be deployed", required=True)
parser.add_argument("--hosts", default="", help="a comma separated list of host names or ip addresses", required=True)
parser.add_argument("--clean", action="store_true", default=False, help="clean the deployment on the remote host")
parser.add_argument("--template", default="openflow", help="the name of the template to be used. This name should match a folder in the templates directory.")
parser.add_argument("--rf", default=3, type=int, help="replication factor. This is the number of replicas that should be created for each shard.")
parser.add_argument("--user", default="root", help="the SSH username for the remote host(s)")
parser.add_argument("--password", default="Ecp123", help="the SSH password for the remote host(s)")
args = parser.parse_args()

# 
# The RemoteHost class provides methods to do operations on a remote host
#
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

#
# The TemplateRenderer provides methods to render a template
#
class TemplateRenderer:
    def __init__(self, template):
	    self.cwd = os.getcwd()
	    self.template_root = self.cwd + "/templates/" + template + "/"

    def render(self, template_path, output_path, variables={}):
        with open (self.template_root + template_path, "r") as myfile:
            data=myfile.read()

        parsed = pystache.parse(u"%(data)s" % locals())
        renderer = pystache.Renderer()

        output = renderer.render(parsed, variables)

        with open (os.getcwd() + "/temp/" + output_path, "w") as myfile:
	        myfile.write(output)
        return os.getcwd() + "/temp/" + output_path

#
# The array_str method takes an array of strings and formats it into a string such that
# it can be used in an akka configuration file
#
def array_str(arr):
    s = "["
    for x in range(0, len(arr)):
        s = s + '"' + arr[x] + '"'
        if x < (len(arr) - 1):
            s = s + ","
    s = s + "]"
    return s

#
# The Deployer deploys the controller to one host and configures it 
#
class Deployer:
    def __init__(self, host, member_no, template, user, password, rootdir, distribution, 
                dir_name, hosts, ds_seed_nodes, rpc_seed_nodes, replicas, clean=False):
        self.host = host
        self.member_no = member_no
        self.template = template
        self.user = user
        self.password = password
        self.rootdir = rootdir
        self.clean = clean
        self.distribution = distribution
        self.dir_name = dir_name
        self.hosts = hosts
        self.ds_seed_nodes = ds_seed_nodes
        self.rpc_seed_nodes = rpc_seed_nodes
        self.replicas = replicas

    def deploy(self):
        # Render all the templates
        renderer = TemplateRenderer(self.template)
        akka_conf = renderer.render("akka.conf.template", "akka.conf", 
        {
        "HOST" : self.host, 
        "MEMBER_NAME" : "member-" + str(self.member_no), 
        "DS_SEED_NODES" : array_str(self.ds_seed_nodes),
        "RPC_SEED_NODES" : array_str(self.rpc_seed_nodes)
        }
        )
        module_shards_conf = renderer.render("module-shards.conf.template", "module-shards.conf", self.replicas)
        modules_conf = renderer.render("modules.conf.template", "modules.conf")
        features_cfg = renderer.render("org.apache.karaf.features.cfg.template", "org.apache.karaf.features.cfg")
        jolokia_xml = renderer.render("jolokia.xml.template", "jolokia.xml")
        management_cfg = renderer.render("org.apache.karaf.management.cfg.template", "org.apache.karaf.management.cfg", {"HOST" : self.host})

        # Connect to the remote host and start doing operations
        remote = RemoteHost(self.host, self.user, self.password, self.rootdir)
        remote.mkdir(self.dir_name)

        # Delete all the sub-directories under the deploy directory if the --clean flag is used
        if(self.clean == True):
            remote.exec_cmd("rm -rf " + self.rootdir + "/deploy/*")
        
        # Clean the m2 repository
        remote.exec_cmd("rm -rf " + self.rootdir + "/.m2/repository")

        # Kill the controller if it's running
        remote.kill_controller()

        # Copy the distribution to the host and unzip it
        odl_file_path = self.dir_name + "/odl.zip"
        remote.copy_file(self.distribution, odl_file_path)
        remote.exec_cmd("unzip " + odl_file_path + " -d " + self.dir_name + "/")

        # Rename the distribution directory to odl
        distribution_name = os.path.splitext(os.path.basename(self.distribution))[0]
        remote.exec_cmd("mv " + self.dir_name + "/" + distribution_name + " " + self.dir_name + "/odl")

        # Copy all the generated files to the server
        remote.mkdir(self.dir_name + "/odl/configuration/initial")
        remote.copy_file(akka_conf, self.dir_name + "/odl/configuration/initial/")
        remote.copy_file(module_shards_conf, self.dir_name + "/odl/configuration/initial/")
        remote.copy_file(modules_conf, self.dir_name + "/odl/configuration/initial/")
        remote.copy_file(features_cfg, self.dir_name + "/odl/etc/")
        remote.copy_file(jolokia_xml, self.dir_name + "/odl/deploy/")
        remote.copy_file(management_cfg, self.dir_name + "/odl/etc/")

        # Add symlink
        remote.exec_cmd("ln -s " + self.dir_name + " " + args.rootdir + "/deploy/current")

        # Run karaf
        remote.start_controller(self.dir_name)      


def main():    
    # Validate some input
    if os.path.exists(args.distribution) == False:
        print args.distribution + " is not a valid file"
        sys.exit(1)

    if os.path.exists(os.getcwd() + "/templates/" + args.template) == False:
        print args.template + " is not a valid template"

    # Prepare some 'global' variables
    hosts = args.hosts.split(",")
    time_stamp = time.time()
    dir_name = args.rootdir + "/deploy/" + str(time_stamp)
    distribution_name = os.path.splitext(os.path.basename(args.distribution))[0]

    ds_seed_nodes = []
    rpc_seed_nodes = []
    all_replicas = []
    replicas = {}

    for x in range(0, len(hosts)):
        ds_seed_nodes.append("akka.tcp://opendaylight-cluster-data@" + hosts[x] + ":2550")
        rpc_seed_nodes.append("akka.tcp://odl-cluster-rpc@" + hosts[x] + ":2551")
        all_replicas.append("member-" + str(x+1))


    for x in range(0, 10):
        if len(all_replicas) > args.rf:
            replicas["REPLICAS_" + str(x+1)] = array_str(random.sample(all_replicas, args.rf))
        else:
            replicas["REPLICAS_" + str(x+1)] = array_str(all_replicas)

    for x in range(0, len(hosts)):
        Deployer(hosts[x], x+1, args.template, args.user, args.password, args.rootdir, args.distribution, dir_name, hosts, ds_seed_nodes, rpc_seed_nodes, replicas, args.clean).deploy()

# Run the script
main()

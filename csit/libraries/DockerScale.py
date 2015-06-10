#!/usr/bin/env python
"""
DockerScale library for OpenDaylight project
robot system test framework.

Authors: Marcus Williams mgkwill - Intel Inc.
Updated: 2015-08-22

*Copyright (c) 2015 Intel Corp. and others.  All rights reserved.
*
* This program and the accompanying materials are made available under the
* terms of the Eclipse Public License v1.0 which accompanies this distribution,
* and is available at http://www.eclipse.org/legal/epl-v10.html
"""
import Docker
from robot.api import logger
import sys
import argparse
import pickle
import os.path
from subprocess import call, Popen, PIPE


class DockerScale(object):
    """Docker Scale Library object to ease use with robot

    Attributes:
        dockervm: An object, docker vm library used to
            perform docker magic.
    """

    def __init__(self, ipadress, port):
        method_name = "DockerScale.__init__"
        logger.info("Creating object %s" % method_name)
        logger.info("Using ipaddress: %s and port: %s" % (ipadress, port))
        self.dockervm = DockerVm(ipadress, port)

    def setup_test_switches(self,
                            switches,
                            ipaddress_start,
                            controller):
        """Setup test switches, wrapper
            for DockerVm object

        Parameters:
            :param switches: An integer describing the
                number of switches to setup

            :param ipaddress_start: A string describing
                the IP to use as the starting range.

            :param controller: ip address of the controller
        """
        self.dockervm.setup_test_switches(switches, ipaddress_start, controller)

    def scalability_docker_suite_teardown(self):
        """Tear down scalability docker suite. Wrapper
            to ease use with robot.

        """
        self.dockervm.scalability_docker_suite_teardown()


class DockerVm(object):
    """Represents a docker VM that can spawn docker instances.

    Attributes:
        docker_lib: An object, docker client library used to
            perform docker magic.
        ipaddress: A string ipaddress of docker vm.
        port: A string port docker vm uses to listen.
        pickle_location: A string used as filename
            and location for serialized data.
        docker_instance_dict: A dict storing
            running instances of docker
            containers. {<docker_id>: <docker_container_obj>}
    """

    def __init__(self, ipaddress, port, pickle_location="docker.pickle"):
        self.docker_lib = Docker.DockerClientWrapper(ipaddress, port)
        self.ipaddress = ipaddress
        self.port = port
        self.pickle_location = pickle_location
        self.docker_instance_dict = {}

    def create_docker_container(self,
                                docker_ip,
                                docker_image_name,
                                docker_name_suffix="docker",
                                passed_args_dict=dict()):
        """Create docker container

        Parameters:
            :param docker_ip: A string that describes the
                IPAddress to use
                    example '10.0.0.1'

            :param docker_image_name: The name representing
                the docker image used

            :param docker_name_suffix: The suffice to add
                to all docker container names

            :param passed_args_dict: A dictionary with
                arguments to pass on to docker lib while
                creating a container

        Returns:
            :returns tuple of docker_id_str and docker_dict:
                docker_id string is unique docker ID and
                docker_dict contains information about the
                created docker container in dict form

            Example docker_dict:
            {u'State':
                {u'Pid': 0,
                 u'OOMKilled': False,
                 u'Dead': False,
                 u'Paused': False,
                 u'Running': False,
                 u'FinishedAt': u'0001-01-01T00:00:00Z',
                 u'Restarting': False,
                 u'Error': u'',
                 u'StartedAt': u'0001-01-01T00:00:00Z',
                 u'ExitCode': 0
                 },

            u'VolumesRelabel': {},
            u'Config': {
                u'Env': [u'PATH=/usr/local/sbin:
                            /usr/local/bin:/usr/sbin:
                            /usr/bin:/sbin:/bin',
                         u'OVS_VERSION=2.3.1',
                         u'SUPERVISOR_STDOUT_VERSION=
                            0.1.1'
                           ],
                u'Hostname': u'e9961c442cc7',
                u'Entrypoint': None,
                u'PortSpecs': None,
                u'Memory': 0,
                u'OnBuild': None,
                u'OpenStdin': False,
                u'MacAddress': u'',
                u'Cpuset': u'',
                u'User': u'',
                u'CpuShares': 0,
                u'AttachStdout': True,
                u'NetworkDisabled': False,
                u'WorkingDir': u'/',
                u'Cmd': [u'/usr/bin/supervisord'],
                u'StdinOnce': False,
                u'AttachStdin': False,
                u'MemorySwap': 0,
                u'Volumes': None,
                u'Tty': False,
                u'AttachStderr': True,
                u'Domainname': u'',
                u'Image': u'socketplane/openvswitch',
                u'Labels': {},
                u'ExposedPorts': None},
            u'HostsPath': u'',
            u'Args': [],
            u'Driver': u'devicemapper',
            u'ExecDriver': u'native-0.2',
            u'Path': u'/usr/bin/supervisord',
            u'HostnamePath': u'',
            u'VolumesRW': {},
            u'RestartCount': 0,
            u'Name': u'/evil_turing',
            u'Created': u'2015-07-20T22:07:43.068959167Z',
            u'ResolvConfPath': u'',
            u'Volumes': {},
            u'ExecIDs': None,
            u'ProcessLabel': u'system_u:system_r:svirt_lxc_net_t:s0:c744,c920',
            u'NetworkSettings': {
                u'Bridge': u'',
                u'GlobalIPv6PrefixLen': 0,
                u'LinkLocalIPv6Address': u'',
                u'GlobalIPv6Address': u'',
                u'IPv6Gateway': u'',
                u'PortMapping': None,
                u'IPPrefixLen': 0,
                u'LinkLocalIPv6PrefixLen': 0,
                u'MacAddress': u'',
                u'IPAddress': u'',
                u'Gateway': u'',
                u'Ports': None},
            u'AppArmorProfile': u'',
            u'Image': u'1c821847d513bd32421b2ac67c683
                        eadc62150537e6c69e3aa4f4b0145e1cde0',
            u'LogPath': u'',
            u'HostConfig': {
                u'ContainerIDFile': u'',
                u'Dns': None,
                u'Memory': 0,
                u'DnsSearch': None,
                u'Privileged': False,
                u'Ulimits': None,
                u'CpusetCpus': u'',
                u'CgroupParent': u'',
                u'RestartPolicy': {
                                   u'MaximumRetryCount': 0,
                                   u'Name': u''},
                u'PublishAllPorts': False,
                u'ReadonlyRootfs': False,
                u'CpuShares': 0,
                u'MountRun': False,
                u'NetworkMode': u'',
                u'LxcConf': None,
                u'Devices': None,
                u'VolumesFrom': None,
                u'Binds': None,
                u'MemorySwap': 0,
                u'PidMode': u'',
                u'ExtraHosts': None,
                u'CapDrop': None,
                u'Links': None,
                u'IpcMode': u'',
                u'PortBindings': None,
                u'SecurityOpt': None,
                u'CapAdd': None,
                u'LogConfig': {
                               u'Type': u'json-file',
                               u'Config': None}
                               },
                u'Id': u'e9961c442cc7b45ed05d5d8bf9a
                         97c3b4f0da5d232783213cb167a
                         6c59d42679',
                u'MountLabel': u'system_u:object_r:
                  svirt_sandbox_file_t:s0:c744,c920'}

        This method is similar to running this command:
        'sudo docker run -p 6640:6640 -p 9001:9001 --privileged=true -d -i
            -t socketplane/docker-ovs:2.1.2
        /usr/bin/supervisord'
        """
        docker_name = "%s-%s" % (docker_ip, docker_name_suffix)
        method_name = "DockerVM.create_docker_container"
        logger.info("Starting method %s" % method_name)
        logger.info("Creating OVS Docker Container with IP: %s Name: %s " %
                    (docker_ip, docker_name))

        default_args_dict = dict(command="tail -f /dev/null",
                                 hostname=docker_name,
                                 name=docker_name,
                                 detach=True)
        args_dict = Docker.DockerClientWrapper.docker_process_args(passed_args_dict, default_args_dict, method_name)

        docker_dict = self.docker_lib.docker_create(
            docker_image_name,
            args_dict
        )
        docker_id_str = str(docker_dict.get("Id"))
        logger.info("Created OVS Docker Container with IP: %s Name: "
                    "%s with docker ID of %s" % (docker_ip,
                                                 docker_name,
                                                 docker_id_str))
        self.docker_instance_dict = \
            {docker_id_str: DockerContainerInstance(self, docker_dict)}
        return docker_id_str, docker_dict

    def add_ovs_switch(self,
                       docker_ip,
                       switch_dict,
                       passed_args_dict=dict(),
                       command="/usr/bin/supervisord"):
        """Add OVS docker Switch.

        Parameters:
            :param docker_ip: A string that describes the IPAddress to use
                example '10.0.0.1'

            :param switch_dict: A dictionary holding the switches in docker
            :param passed_args_dict: A dictionary with
                arguments to pass on to docker lib while
                creating a container
            :param command: string to run as initial command

        Returns:
            :returns dict: switch_dict - A dictionary holding the
            switches in docker Each Key is the Switch ID, each
            Value the docker_info_dict
        """
        method_name = "DockerVM.add_ovs_switch"
        logger.info("Starting method %s" % method_name)
        logger.info("Adding switch with IP %s" % docker_ip)

        docker_ovsdb_port = 6640
        docker_openflow_port = 6653
        docker_xml_rpc_port = 9001
        host_bindings_config = self.docker_lib \
            .docker_create_host_config(dict(port_bindings={
            '%d/tcp' % docker_ovsdb_port: [{
                'HostIp': '%s' % docker_ip,
                'HostPort': docker_ovsdb_port}],
            '%d/tcp' % docker_openflow_port: [{
                'HostIp': '%s' % docker_ip,
                'HostPort': docker_openflow_port}],
            '%d/tcp' % docker_xml_rpc_port: [{
                'HostIp': '%s' % docker_ip,
                'HostPort': docker_xml_rpc_port}]
        }))
        docker_ports = [docker_ovsdb_port,
                        docker_openflow_port,
                        docker_xml_rpc_port]

        docker_id_str, docker_dict = self \
            .create_docker_container(docker_ip,
                                     "socketplane/openvswitch",
                                     "ovs",
                                     dict(host_config=host_bindings_config,
                                          ports=docker_ports,
                                          command=command))

        passed_args_dict["network_mode"] = "bridge"
        passed_args_dict["privileged"] = True

        status = self.docker_lib.docker_start(docker_id_str, passed_args_dict)
        if status is True:
            switch_dict[docker_id_str] = docker_dict

        return switch_dict

    def add_controller(self,
                       docker_inst_dict,
                       controller_ip,
                       command="./bin/karaf server",
                       start_passed_args_dict=dict()):
        """Add ODL docker controller.

        Params:

            :param docker_inst_dict: A dictionary holding the
                docker instances
            :param controller_ip: A string representing
                controller ip
            :param command: initial command to run in container
            :param start_passed_args_dict: A dictionary with
                arguments to pass on to docker lib while
                creating a container

        Returns:
            :returns dict: docker_dict - A dictionary holding
                the switches in docker. Each Key is the
                Switch ID, each Value the docker_info_dict
        """
        method_name = "DockerVM.add_controller"
        logger.info("Starting method %s" % method_name)
        logger.info("Adding controller with IP %s" % controller_ip)
        docker_id_str, docker_dict = \
            self.create_docker_container(controller_ip,
                                         "mgkwill/odl:0.3.0-debian",
                                         "odl",
                                         passed_args_dict=dict())

        start_passed_args_dict["network_mode"] = "bridge"

        status = self.docker_lib.docker_start(
            docker_id_str,
            start_passed_args_dict)
        if status:
            docker_inst_dict[docker_id_str] = docker_dict

        exec_output = self.docker_lib.docker_execute(
            docker_id_str,
            command)
        print exec_output
        logger.info(exec_output)

        return docker_inst_dict

    def remove_ovs_switch(self, docker_id, switch_dict, force=False):
        """Remove OVS docker Switch.

        Parameters:
            :param docker_id: A string that describes the
                docker id of the container to remove

            :param switch_dict: A dictionary holding the
                switches in docker
            :param force: Boolean - force or not

        Returns:
            :returns dict: switch_dict - A dictionary holding
                the switches in docker. Each Key is the Switch
                ID, each Value the docker_info_dict
        """
        method_name = "DockerVM.remove_switch"
        logger.info("Starting method %s" % method_name)
        logger.info("Removing switch with name %s" % docker_id)
        stop_status = self.docker_lib.docker_stop(docker_id)

        remove_status = self.docker_lib.docker_remove(
            docker_id,
            dict(force=force))
        if stop_status and remove_status is True:
            if docker_id in switch_dict.keys():
                del switch_dict[docker_id]

        return switch_dict

    def setup_test_switches(self,
                            switches,
                            ipaddress_start="192.168.200.1",
                            controller="127.0.0.1"):
        """Setup test switches.

        Parameters:
            :param switches: An integer describing the
                number of switches to setup

            :param ipaddress_start: A string describing
                the IP to use as the starting range.

            :param controller: ip address of the controller
        """
        method_name = "DockerVM.setup_test_switches"
        logger.info("Starting method %s" % method_name)
        switch_dict = dict()

        # setup br-docker-ovs bridge
        ip_output = DockerVm \
            .run_commmand_on_remote(self.ipaddress, "ip a")
        if "br-docker-ovs" not in ip_output:
            DockerVm.run_commmand_on_remote(self.ipaddress,
                                            "brctl addbr "
                                            "br-docker-ovs")
            DockerVm.run_commmand_on_remote(self.ipaddress,
                                            "sudo ip addr "
                                            "add 172.0.100.1/16"
                                            " dev br-docker-ovs")
            DockerVm.run_commmand_on_remote(self.ipaddress,
                                            "sudo ip link set"
                                            "dev br-docker-ovs up")

        # external_route = self.return_processed_ip(controller, 3, 1)

        for switch in range(0, int(switches)):
            subnet_iteration = ipaddress_start.split(".")[2]
            if int(switches) > 252 and int(
                    self.return_processed_ip(ipaddress_start, 3, switch + 2)
                    .split(".")[3]) > 253:
                subnet_iteration += 1
                ipaddress = self.return_processed_ip(
                    ipaddress_start,
                    2, subnet_iteration)
                ipaddress = self.return_processed_ip(
                    ipaddress,
                    3,
                    switch - 251)
            else:
                ipaddress = self.return_processed_ip(
                    ipaddress_start,
                    3, switch + 2)
            switch_dict = self.add_ovs_switch(ipaddress,
                                              switch_dict)

            # DockerVm.run_commmand_on_remote(self.ipaddress,
            #                                "/usr/local"
            #                                "/bin/pipework "
            #                                "--wait -i "
            #                                "br-docker-ovs")
            # DockerVm.run_commmand_on_remote(self.ipaddress,
            #                                "/usr/local/bin/pipework"
            #                                " br-docker-ovs %s-ovs"
            #                                " %s/16@%s"
            #                                % (ipaddress,
            #                                   ipaddress,
            #                                   external_route))

        self.serialize_data(switch_dict)

    @staticmethod
    def return_processed_ip(ipaddress, octet, digit):
        """Return processed IP.

        Parameters:
            :param ipaddress: A string that describes
                the IPAddress - example '10.0.0.1'
            :param octet: The ip octet to change 0-4
            :param digit: An integer used to replace the
                IP octet.

        Returns:
            :returns string: A string representing the processed IP
        """
        method_name = "DockerVM.return_processed_ip"
        logger.info("Starting method %s" % method_name)

        ipaddress_octets = ipaddress.split(".")
        ipaddress_octets[octet] = digit
        return "%s.%s.%s.%s" % (ipaddress_octets[0],
                                ipaddress_octets[1],
                                ipaddress_octets[2],
                                ipaddress_octets[3])

    @staticmethod
    def run_commmand_on_remote(ipaddress, cmd):
        """Run command on remote system.

        Parameters:
            :param ipaddress: A string that describes
                the IPAddress - example '10.0.0.1'
            :param cmd: The command to run

        Returns:
            :returns string: A string representing the output
        """

        ssh = Popen(["ssh", "%s" % ipaddress, cmd],
                    shell=False,
                    stdout=PIPE,
                    stderr=PIPE)
        output = ssh.stdout.readlines()
        if output is []:
            error = ssh.stderr.readlines()
            print >> sys.stderr, "Error: %s" % error
        else:
            print output
            return output

    def scalability_docker_suite_teardown(self):
        """Tear down scalability docker suite.

        """
        method_name = "DockerVM" \
                      ".scalability_docker_suite_teardown"
        logger.info("Starting method %s" % method_name)
        logger.info("Tearing down scalability test suite...")
        for docker in self.docker_lib.docker_list_containers():
            docker_id = str(docker.get("Id"))
            self.remove_ovs_switch(docker_id,
                                   switch_dict=dict(),
                                   force=True)

        process = Popen(["docker", "ps", "-a", "-q"],
                        stdin=PIPE,
                        stdout=PIPE,
                        stderr=PIPE)
        docker_ps_output, err = process.communicate()

        if docker_ps_output:
            for docker_instance in docker_ps_output.split():
                call(["docker", "stop", "%s" % docker_instance])
                call(["docker", "rm", "%s" % docker_instance])

        call(["ip", "link", "set", "dev", "br-docker-ovs", "down"])
        call(["brctl", "delbr", "br-docker-ovs"])

        try:
            os.remove(self.pickle_location)
        except OSError:
            pass
        try:
            os.remove("switches.pickle")
        except OSError:
            pass

    def serialize_data(self, dictionary):
        """Serialize Data.

        Parameters:
            :param dictionary: A dictionary to serialize
        """
        method_name = "DockerVM.serialize_data"
        logger.info("Starting method %s" % method_name)

        with open(self.pickle_location, 'wb') as file_write:
            pickle.dump(dictionary, file_write)

    def load_serialized_data(self):
        """Load Serialized Data.

        Returns:
            :returns dict: A dictionary representing the loaded data
        """
        method_name = "DockerVM.load_serialized_data"
        logger.info("Starting method %s" % method_name)

        with open(self.pickle_location, 'r') as file_read:
            return pickle.load(file_read)

    def return_container_names(self):
        """Return a list of container names.

        Returns:
            :returns list: a list of container names
        """
        method_name = "DockerVM.return_container_names"
        logger.info("Starting method %s" % method_name)
        docker_name_list = []
        for docker in self.docker_lib.docker_list_containers():
            docker_name_list.append(docker.get("Name"))

        return docker_name_list


class DockerContainerInstance(object):
    def __init__(self, docker_vm, docker_dict):
        self.private_ipaddress = docker_dict \
            .get("NetworkSettings").get("IpAddress")
        self.test_ipaddress = None
        self.docker_id = docker_dict.get("Id")
        self.docker_name = docker_dict.get("Name")
        self.image = docker_dict.get("Config").get("Image")
        self.docker_dict = docker_dict
        self.parent_docker_vm = docker_vm

    def ping(self, ipaddress, count):
        method_name = "DockerContainerInstance.ping"
        logger.info("Starting method %s" % method_name)
        self.parent_docker_vm.docker_ping(
            self,
            self.docker_name,
            ipaddress,
            count)

    def start(self):
        self.parent_docker_vm.docker_lib.start(self.docker_name)

    def stop(self):
        self.parent_docker_vm.docker_lib.stop(self.docker_name)


def main():
    method_name = "DockerScale.main"
    logger.info("Starting method %s" % method_name)

    parser = argparse.ArgumentParser()

    one_arg_group = parser.add_argument_group()
    one_arg_group.add_argument("-t", "--teardown",
                               help="Teardown testing containers and setup")

    setup_switches_group = parser.add_argument_group()
    setup_switches_group.add_argument("-s", "--switches",
                                      help="Takes integer - The number of "
                                           "Switches to add", type=int)
    setup_switches_group.add_argument("-a", "--addswitch",
                                      help="Takes string - The switch ip "
                                           "to add",
                                      type=str)
    setup_switches_group.add_argument("-r", "--removeswitch",
                                      help="Takes string - The switch ip "
                                           "to remove",
                                      type=str)
    setup_switches_group.add_argument("-i", "--ipadressstart",
                                      help="Takes string - The start of "
                                           "IPAddress range",
                                      type=str,
                                      default="172.0.0.5")
    setup_switches_group.add_argument("-c", "--controller",
                                      help="Takes string - The IPAddress "
                                           "of the controller",
                                      type=str,
                                      required=True)
    setup_switches_group.add_argument("-l", "--locationpickle",
                                      help="name/path of pickle data "
                                           "serialization file to use",
                                      type=str,
                                      default="switches.pickle")

    parser.add_argument("-v", "--dockervmip",
                        help="Takes string - The IPAddress "
                             "of the dockervmip", type=str, required=True)
    parser.add_argument("-p", "--dockervmport",
                        help="Takes string - The port "
                             "of the dockervm", type=str, required=True)
    args = parser.parse_args()

    docker_vm = DockerVm(args.dockervmip,
                         args.dockervmport,
                         args.locationpickle)

    if os.path.isfile(args.locationpickle):
        switch_dict = docker_vm.load_serialized_data()
    else:
        switch_dict = dict()

    if args.teardown:
        docker_vm.scalability_docker_suite_teardown()
        sys.exit(0)

    if args.switches:
        docker_vm.setup_test_switches(switches=args.switches,
                                      ipaddress_start=args.ipaddressstart,
                                      controller=args.controller)
        sys.exit(0)

    if args.addswitch:
        docker_vm.serialize_data(
            docker_vm.add_ovs_switch(args.addswitch,
                                     switch_dict))

    if args.removeswitch:
        docker_vm.serialize_data(
            docker_vm.remove_ovs_switch(args.removeswitch,
                                        switch_dict))
        sys.exit(0)


if __name__ == "__main__":
    main()

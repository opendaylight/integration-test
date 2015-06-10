"""
Docker library for OpenDaylight project robot system test framework.
Authors: Marcus Williams - irc @ mgkwill - Intel Inc.
Updated: 2015-05-05

*Copyright (c) 2015 Intel Corp. and others.  All rights reserved.
*
* This program and the accompanying materials are made available under the
* terms of the Eclipse Public License v1.0 which accompanies this distribution,
* and is available at http://www.eclipse.org/legal/epl-v10.html
"""

import docker
import json
from robot.api import logger


class DockerClientWrapper(object):

    def __init__(self, ipaddress=None, port=None):
        logger.info("Creating DockerClientWrapper with "
                    "ipaddress: %s and port: %s" % (ipaddress, port))
        if ipaddress and port:
            base_url = "http://%s:%s" % (ipaddress, port)
            logger.info("Using base URL: %s " % base_url)
            self.docker_client = DockerClientWrapper.docker_get_client(
                dict(base_url=base_url))
        else:
            self.docker_client = DockerClientWrapper.docker_get_client()

    def docker_create(self,
                      docker_image_name,
                      passed_args_dict=None,
                      tag=None):
        """Create docker container.

        Args:
            :param docker_image_name: A string that describes the docker
                image to use
                example 'socketplane/openvswitch'

            :param passed_args_dict: keyword docker-py create container args.
                defaults to command=None, hostname=None, user=None,
                detach=False, stdin_open=False, tty=False, mem_limit=0,
                ports=None, environment=None, dns=None, volumes=None,
                volumes_from=None, network_disabled=False, name=None,
                entrypoint=None, cpu_shares=None, working_dir=None,
                domainname=None, memswap_limit=0, cpuset=None,
                host_config=None

        Returns:
            :returns dict: docker-info - identifying info about docker
                container created
        """
        logger.info("Creating docker %s" % docker_image_name)
        logger.info(passed_args_dict)

        default_args_dict = dict(command=None,
                                 hostname=None,
                                 user=None,
                                 detach=False,
                                 stdin_open=False,
                                 tty=False,
                                 mem_limit=0,
                                 ports=None,
                                 environment=None,
                                 dns=None,
                                 volumes=None,
                                 volumes_from=None,
                                 network_disabled=False,
                                 name=None,
                                 entrypoint=None,
                                 cpu_shares=None,
                                 working_dir=None,
                                 domainname=None,
                                 memswap_limit=0,
                                 cpuset=None,
                                 host_config=None,
                                 # mac_address=None
                                 )
        args_dict = DockerClientWrapper.\
            docker_process_args(passed_args_dict,
                                default_args_dict,
                                "docker_create")

        for line in self.docker_client.pull(
                docker_image_name, tag=tag, stream=True):
            logger.info("    %s" % json.dumps(json.loads(line)))

        docker_uid_dict = self.docker_client\
            .create_container(docker_image_name, **args_dict)
        docker_info = self.docker_client.inspect_container(
            docker_uid_dict.get("Id"))
        return docker_info

    def docker_start(self, docker_name, passed_args_dict=None):
        """Start docker container.

        Args:
            :param docker_name: A string that describes the docker image
                to use. Either the uid or docker container name must be
                used.

            :param passed_args_dict: keyword docker-py start container args.
                defaults to binds=None, port_bindings=None, lxc_conf=None,
                publish_all_ports=False, links=None, privileged=False,
                dns=None, dns_search=None, volumes_from=None,
                network_mode=None, restart_policy=None, cap_add=None,
                cap_drop=None, devices=None, extra_hosts=None
        Returns:
            :returns bool: returns false if container fails to start
                and true otherwise
        """
        logger.info("Starting docker %s" % docker_name)
        logger.info(passed_args_dict)

        default_args_dict = dict(binds=None,
                                 port_bindings=None,
                                 lxc_conf=None,
                                 publish_all_ports=False,
                                 links=None,
                                 privileged=False,
                                 dns=None,
                                 dns_search=None,
                                 volumes_from=None,
                                 network_mode=None,
                                 restart_policy=None,
                                 cap_add=None,
                                 cap_drop=None,
                                 devices=None,
                                 extra_hosts=None
                                 )
        args_dict = DockerClientWrapper.docker_process_args(passed_args_dict,
                                                            default_args_dict,
                                                            "docker_start")

        self.docker_client.start(docker_name, **args_dict)

        if "True" in str(self.docker_client.inspect_container(docker_name)
                         .get("State").get("Running")):
            logger.info("Started docker %s successfully" % docker_name)
            return True
        else:
            logger.info("Starting docker %s failed" % docker_name)
            return False

    def docker_remove(self, docker_name, passed_args_dict=None):
        """Remove docker container.

        Args:
            :param docker_name: A string that describes the docker image
                to use - example 'socketplane/openvswitch'

            :param passed_args_dict: keyword docker-py remove container
            args. defaults to v=False, link=False, force=False

        Returns:
            :returns bool: True if container was removed false otherwise
        """
        logger.info("Removing docker %s" % docker_name)
        logger.info(passed_args_dict)

        default_args_dict = dict(v=False,
                                 link=False,
                                 force=False
                                 )
        args_dict = DockerClientWrapper.docker_process_args(passed_args_dict,
                                                            default_args_dict,
                                                            "docker_remove")

        self.docker_client.remove_container(docker_name, **args_dict)
        docker_containers = self.docker_client.containers(all=True)
        for container in docker_containers:
            if docker_name in container.get("Id") or \
                    docker_name in container.get("Names"):
                logger.info("Removing docker %s failed" % docker_name)
                return False
        logger.info("Removed docker %s successfully" % docker_name)
        return True

    def docker_stop(self, docker_name, timeout=10):
        """Stop docker container.

        Args:
            :param docker_name: A string that describes the
                docker image to use. Either the uid or docker
                container name must be used.

            :param timeout: docker-py stop container args. defaults
                to timeout=10
        Returns:
            :returns bool: returns false if container fails to stop
                and true otherwise
        """
        logger.info("Stopping docker %s with timeout %d" %
                    (docker_name, timeout))

        self.docker_client.stop(docker_name, timeout)

        if "False" in str(self.docker_client
                              .inspect_container(docker_name)
                              .get("State").get("Running")):
            logger.info("Stopped docker %s successfully" % docker_name)
            return True
        else:
            logger.debug("Stopping docker %s failed" % docker_name)
            return False

    def docker_return_logs(self, docker_name, passed_args_dict=None):
        """Return docker container logs.

        Args:
            :param docker_name: A string that describes the docker
                image to use. Either the uid or docker container
                name must be used.

            :param passed_args_dict: keyword docker-py logs
                container args. defaults to stdout=True,
                stderr=True, stream=False, timestamps=False,
                tail='all'
        Returns:
            :returns string: returns a string containing docker
                logs
        """
        logger.info("Returning logs for docker %s" % docker_name)
        logger.info(passed_args_dict)

        default_args_dict = dict(stdout=True,
                                 stderr=True,
                                 stream=False,
                                 timestamps=False,
                                 tail='all'
                                 )
        args_dict = DockerClientWrapper\
            .docker_process_args(passed_args_dict,
                                 default_args_dict, "docker_return_logs")

        return self.docker_client.logs(docker_name, **args_dict)

    def docker_execute(self, docker_name, cmd, passed_args_dict=None):
        """Run a command on a docker container.

        Args:
            :param docker_name: A string that describes the docker
                image to use. Either the uid or docker container
                name must be used.

            :param cmd: A string of the command to run
                Example 'ip a'

            :param passed_args_dict: dictionary of key word
                docker-py exec container args. defaults to
                detach=False, stdout=True, stderr=True, stream=False,
                tty=False
        Returns:
            :returns string: returns string representing
                the results of the command

        NOTE: In docker-py version >=1.2 execute will be deprecated in
            favor of exec_create and exec_start
        """
        logger.info("Executing command %s on docker %s" % (cmd, docker_name))
        logger.info(passed_args_dict)

        default_args_dict = dict(detach=False,
                                 stdout=True,
                                 stderr=True,
                                 stream=False,
                                 tty=False
                                 )
        args_dict = DockerClientWrapper\
            .docker_process_args(passed_args_dict,
                                 default_args_dict, "docker_execute")

        return self.docker_client.execute(docker_name, cmd, **args_dict)

    def docker_get_ip4(self, docker_name):
        """Inspects a docker container and returns its IP address.

        Args:
            :param docker_name: A string that describes the docker
                image to use. Either the uid or docker container
                name must be used.

        Returns:
            :returns string: returns string of IP address
        """
        logger.info("Getting IP of docker %s" % docker_name)
        return str(self.docker_client.inspect_container(docker_name)
                   .get("NetworkSettings")
                   .get("IPAddress"))

    def docker_ping(self, docker_name, ip, count=3):
        """Pings from a docker container and returns results.

        Args:
            :param docker_name: A string that describes the docker
                image to use. Either the uid or docker container
                name must be used.

            :param ip: A string of the IP address to ping

            :param count: An integer of the count to ping

        Returns:
            :returns string: returns string of results
        """
        logger.info("Pinging from docker %s to %s %d times" %
                    (docker_name, ip, count))
        ping_cmd = str(ip) + "ping -c " + str(count)
        return self.docker_execute(docker_name, ping_cmd)

    def docker_list_containers(self, passed_args_dict=None):
        """Return a list of docker containers.

           Returns:
            :returns list: returns list of docker
                containers in following format:
                [{'Id': u'069a56ec06f965f98efa752467737fa
                          a58431ebb471bc51e9b2bd485fcc4916c'},
                {'Id': u'769aff6170eec78e7c502fea4770cfbb
                          7b7e53a2dc44070566d01e18b6d57c14'}]
        """
        logger.info("Listing docker containers")
        logger.info(passed_args_dict)

        default_args_dict = dict(quiet=True,
                                 all=True,
                                 trunc=True,
                                 latest=False,
                                 since=None,
                                 before=None,
                                 limit=-1,
                                 size=False,
                                 filters=None
                                 )
        args_dict = DockerClientWrapper\
            .docker_process_args(passed_args_dict,
                                 default_args_dict, "docker_list_containers")

        return self.docker_client.containers(**args_dict)

    def docker_create_host_config(self, passed_args_dict):
        """Return a list of docker create host config
            for port bindings.

           Parameters:
            :param passed_args_dict: dictionary of the keyword
                values to use.

           Returns:
            :returns list: returns host config for a container
                create command in following format:
                {'PortBindings': {'6640/tcp': [{'HostIp':
                                  '', 'HostPort': '6640'}],
                '6653/tcp': [{'HostIp': '', 'HostPort': '6653'}],
                '9001/tcp': [{'HostIp': '', 'HostPort': '9001'}]}}
        """
        logger.info("Creating host config.")

        default_args_dict = dict(binds=None,
                                 port_bindings=None,
                                 lxc_conf=None,
                                 publish_all_ports=False,
                                 links=None,
                                 privileged=False,
                                 dns=None,
                                 dns_search=None,
                                 volumes_from=None,
                                 network_mode=None,
                                 restart_policy=None,
                                 cap_add=None,
                                 cap_drop=None,
                                 devices=None,
                                 extra_hosts=None
                                 )
        args_dict = DockerClientWrapper\
            .docker_process_args(passed_args_dict,
                                 default_args_dict,
                                 "docker_create_host_config")

        return self.docker_client.create_host_config(**args_dict)

    @staticmethod
    def docker_process_args(passed_args_dict,
                            default_args_dict, method_name):
        """Accepts two dicts and combines them
                preferring passed args while filling unspecified
                args with default values.

        Parameters:
            :param passed_args_dict: A dict of the passed
                keyword args for the method.

            :param default_args_dict: A dict of the default
                keyword args for the method.

        Returns:
            :returns dict: returns dict containing passed args, with
            defaults for all other keyword args.
        """
        logger.info("Processing args for %s method" % method_name)
        logger.info(passed_args_dict)
        logger.info(default_args_dict)
        processed_args_dict = {}

        if passed_args_dict is None:
            passed_args_dict = {}

        try:
            for key in default_args_dict:
                if key in passed_args_dict:
                    processed_args_dict[key] = passed_args_dict[key]
                else:
                    processed_args_dict[key] = default_args_dict[key]
        except TypeError:
            logger.debug("Error: One or both of the passed "
                         "arguments is not a dictionary")

        logger.info("Returning processed args for %s method" % method_name)
        logger.info(processed_args_dict)
        return processed_args_dict

    @staticmethod
    def docker_get_client(*passed_args_dict):
        """Returns docker-py client.

        Parameters:
            :param passed_args_dict: dictionary of
                the keyword values to use.

        Returns:
            :returns obj: returns docker-py client object.
        """
        logger.info("Returning docker client")
        logger.info(passed_args_dict)
        default_args_dict = dict(base_url="unix://var/run/docker.sock",
                                 version='1.19',
                                 timeout=60,
                                 tls=False)
        args_dict = DockerClientWrapper\
            .docker_process_args(passed_args_dict,
                                 default_args_dict,
                                 "docker_get_client")

        return docker.Client(**args_dict)

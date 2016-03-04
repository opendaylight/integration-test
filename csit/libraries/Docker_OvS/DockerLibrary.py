from docker import Client

class DockerLibrary(object):

    client = Client(base_url='unix://var/run/docker.sock')

    CONST_URL_PREFIX = 'https://'
    CONST_DOCKER_CONTAINER_NAME = "ovs_container_"
    CONST_DOCKER_IMAGE_NAME = ''
    CONST_DOCKER_PORTS = [22, 2022]
    CONST_DOCKER_CAPABILITIES = ["ALL"]
    CONST_DOCKER_COMMANDS = ["/etc/init.d/openvswitch-switch start",
                             "ovs-vsctl add-br br0"]
    CONST_OF_PORT = ":6633"
    CONST_CONTROLLER_IP = ''
    CONST_SET_OVS_CONTOLLER = "ovs-vsctl set-controller br0 tcp:"
    

    def __init__(self, controller_ip, image_name):
        self.CONST_CONTROLLER_IP = controller_ip
        self.CONST_DOCKER_IMAGE_NAME = image_name

    def add_containers(self, ammount):
        containers = self.client.containers()
        container_list = list()
        for dictionary in containers:
            for item in dictionary.get('Names'):
                container_list.append(item)

        for x in range(ammount):
            container_name = self.CONST_DOCKER_CONTAINER_NAME+repr(x)
            if '/' + container_name not in container_list:
                # Set the capabilities
                capabilities = self.client.create_host_config(privileged=True,
                                                              network_mode='isolated_nw',
                                                              cap_add=self.CONST_DOCKER_CAPABILITIES)
                # Create the container
                container = self.client.create_container(image=self.CONST_DOCKER_IMAGE_NAME,
                                                         hostname=container_name,
                                                         name=container_name,
                                                         host_config=capabilities)
                # Start the container (it is not started automatically)
                _ = self.client.start(container=container.get('Id'))
                # Execute the commands
                for cmd in self.CONST_DOCKER_COMMANDS:
                    command = self.client.exec_create(container=container_name,
                                                      cmd=cmd)
                    self.client.exec_start(exec_id=command.get('Id'))
                # Set br0 contoller
                setc = self.client.exec_create(container=container_name,
                                               cmd=self.CONST_SET_OVS_CONTOLLER + repr(self.CONST_CONTROLLER_IP) + repr(self.CONST_OF_PORT))
                self.client.exec_start(exec_id=setc.get('Id'))
                print "Container %s created" % (container_name)
            else:
                print "Container %s already exist" % (container_name)
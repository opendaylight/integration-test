# Deploy Openstack Using the Deploy in ODL Integration/CSIT Code

##  Setup Info
### 1node  Setup (1 Openstack Control Node)
Requires 4 VM instances
* 1 for robot execution
* 1 for Control Node 
* 2 Compute Nodes

#### 1node setup Platform Requirements
* All Nodes should have this hardware support as minimum
     - 4 VCPU
     - 8192 MB RAM
  
### 3node Setup (3 Openstack Control Nodes for HA)
Requires 7 VM instances
* 1 for robot execution
* 3 Openstack Control Nodes 
* 1 HAProxy Node
* 2 Compute Nodes

#### 3node setup Platform Requirements
* All Control Nodes to have 
     - 4 VCPU
     - 12288 MB RAM
     
* All Other Nodes should have this hardware support as minimum
     - 4 VCPU
     - 8192 MB RAM

### Common Settings for all VM
* All VM's will run the latest CentOS (7) distro
  At the time of creating this text, latest can be found here
  [CentOS 7.4](http://mirrors.kernel.org/centos/7.4.1708/)
  
* Ensure that one common sudo capable username/password can login to all VM's. i.e login with the same username/password combination
  is possible in all VM's, preferrably have the same root password in all VM's
  
* Ensure that SELINUX is disabled in all nodes.
   ```
   Edit the file /etc/selinux/config and ensure the line
   SELINUX=disabled 
   ```
* Ensure the instances can reach internet to download and install packages

* If you have Proxy for internet, please configure the proxy details to yum.conf
   [Ref:Add proxy settings to yum.conf](https://www.centos.org/docs/5/html/yum/sn-yum-proxy-server.html)


##  Topology

### 1node Topology

	-------------
	|	     |---------------------|		|
	|  Robot VM  |---------|           |            |
	|            |---------|-----------|------------|
	-------------          |           |		|
	-------------          |           |  		|
	|	     |---------|-----------|		|
	| Controller |---------|           |		|
	|            |---------|-----------|------------|
	-------------         |           |		|
	-------------          |           |		|
	|	     |---------|-----------|		|
	|  Compute1  |---------|           |		|
	|            |---------|-----------|------------|
	-------------          |           |		|
	-------------          |           |		|
	|	     |---------|-----------|		|
	|  Compute2  |---------|           |		|
	|            |---------|-----------|------------|
	-------------          |           |		|
	                       |           |		|
	                       |           |		|
      			     Data      External      External
                                      Network1	   Network2
                                      
                                 
 ### 3node Topology


	-------------
	|	     |---------------------|	        |
	|  Robot VM  |---------|           |            |
	|            |---------|-----------|------------|
	-------------          |           |		|
	-------------          |           |  		|
	|	     |---------|-----------|		|
	|Controller1 |---------|           |		|
	|            |---------|-----------|------------|
	-------------          |           |		|
	-------------          |           |		|
	|	     |---------|-----------|		|
	|Controller2 |---------|           |		|
	|            |---------|-----------|------------|
	-------------          |           |		|
	-------------          |           |		|
	|	     |---------|-----------|	        |
	|Controller3 |---------|           |		|
	|            |---------|-----------|------------|
	-------------          |           |		|
	-------------          |           |		|
	|	     |         |           |		|
	|  haproxy   |---------|           |		|
	|            |         |           |            |
	-------------          |           |	        |  
	-------------          |           |		|
	|	     |---------|-----------|		|
	|  Compute1  |---------|           |		|
	|            |---------|-----------|------------|
	-------------          |           |		|  
	-------------          |           |		|
	|	     |---------|-----------|		|
	|  Compute2  |---------|           |		|
	|            |---------|-----------|------------|
	-------------          |           |		|  
			       |           |		|   
			       |           |		|  
			       Data      External      External
			       		 Network1	Network2
 
 
 ## Steps to Execute from Robot VM
 
 ### Get Deployer
 
 * Install robotframework pre-requisites
 ```
 	sudo yum install python-pip git -y
 	pip install robotframework robotframework-sshlibrary 
 	pip install robotframework-requests
 	pip install robotframework-httplibrary
 ```
 
 * Get the Deployer
 ```
 	git clone https://git.opendaylight.org/gerrit/p/integration/test
 	cd test
 	git fetch https://<user-id>@git.opendaylight.org/gerrit/a/integration/test refs/changes/68/63168/41 && git cherry-pick FETCH_HEAD
 ```
 ```
 Note: The deployer is not merged yet
 ```
 
 ### Test 1node Openstack with ODL
 
 #### Deploy 1node Openstack with ODL
 
 * Run the deployer with pybot
 ```
 	pybot --debug ~/debug_1node.log \
	-v OS_CONTROL_1_IP:<CONTROL_NODE_IP> \
	-v OS_CONTROL_NODE_IP:<CONTROL_NODE_IP> \
	-v OS_CONTROL_1_HOSTNAME:<CONTROL_NODE_HOSTNAME> \
	-v OS_IP:<CONTROL_NODE_IP> \
	-v NUM_CONTROL_NODES:1 \
	-v NUM_COMPUTE_NODES:2 \
	-v OS_COMPUTE_1_IP:<COMPUTE_1_IP> \
	-v OS_COMPUTE_1_HOSTNAME:<COMPUTE_1_HOSTNAME> \
	-v OS_COMPUTE_2_IP:<COMUTE_2_IP> \
	-v OS_COMPUTE_2_HOSTNAME:<COMPUTE_2_HOSTNAME> \
	-v OPENSTACK_VERSION:pike \
	-v EXT_BRIDGE:datacenter \
	-v OS_USER:root \
	-v OS_USER_PASSWORD:<root_password> \
	-v OS_NODE_PROMPT:# \
	-v ODL_RPM:http://cbs.centos.org/repos/nfv7-opendaylight-70-release/x86_64/os/Packages/opendaylight-7.0.0-1.el7.noarch.rpm \
	~/test/csit/suites/openstack/deploy/00_initial_setup.robot \
	~/test/csit/suites/openstack/deploy/01_mysql_setup.robot \
	~/test/csit/suites/openstack/deploy/02_rabbitmq_setup.robot \
	~/test/csit/suites/openstack/deploy/03_keystone_setup.robot \
	~/test/csit/suites/openstack/deploy/04_glance_setup.robot \
	~/test/csit/suites/openstack/deploy/05_nova_setup.robot \
	~/test/csit/suites/openstack/deploy/06_neutron_setup.robot \
	~/test/csit/suites/openstack/deploy/07_csit_setup.robot
```

* After execution, Check the log.html to understand the status of execution

* If the status is "PASS", there will be an Openstack Installation with
  one control node and 2 compute nodes.
  
* All the settings for executing CSIT will be configured.

#### Execute CSIT

* Once the deployer command mentioned above is successful, you are ready to launch the CSIT Tests

* Run the below pybot command to launch any test

```
	source /tmp/stackrc
	pybot --debug debug_csit.log \
	--log log_csit.html --output output_csit.xml \
	-v CONTROLLER_USER:jenkins \
	-v NUM_ODL_SYSTEM:1 \
	-v NUM_OS_SYSTEM:3 \
	-v ODL_SYSTEM_IP:<CONTROL_NODE_IP> \
	-v ODL_SYSTEM_1_IP:<CONTROL_NODE_IP> \
	-v OS_CONTROL_NODE_IP:<CONTROL_NODE_IP> \
	-v OS_CONTROL_NODE_1_IP:<CONTROL_NODE_IP> \
	-v OS_COMPUTE_1_IP:<COMPUTE_1_IP> \
	-v OS_COMPUTE_2_IP:<COMPUTE_2_IP> \
	-v OS_USER:jenkins \
	-v USER_HOME:${HOME} \
	-v OPENSTACK_BRANCH:stable/pike \
	~/test/csit/suites/openstack/connectivity/01_l2_tests.robot \
	~/test/csit/suites/openstack/connectivity/02_l3_tests.robot \
```

### Test 3node Openstack  with ODL

#### Deploy 3node Openstack with ODL

* Run the below pybot command
```
	pybot --debug ~/debug_3node.log \
	-l log_3node_install.html \
	-v OS_CONTROL_1_IP:<CONTROL_1_IP> \
	-v OS_CONTROL_1_HOSTNAME:<CONTROL_1_HOSTNAME> \
	-v OS_CONTROL_2_IP:<CONTROL_2_IP> \
	-v OS_CONTROL_2_HOSTNAME:<CONTROL_2_HOSTNAME> \
	-v OS_CONTROL_3_IP:<CONTROL_3_IP> \
	-v OS_CONTROL_3_HOSTNAME:<CONTROL_3_HOSTNAME> \
	-v NUM_CONTROL_NODES:3 \
	-v NUM_COMPUTE_NODES:2 \
	-v OS_COMPUTE_1_IP:<COMPUTE_1_IP> \
	-v OS_COMPUTE_1_HOSTNAME:<COMPUTE_1_HOSTNAME> \
	-v OS_COMPUTE_2_IP:<COMPUTE_2_IP> \
	-v OS_COMPUTE_2_HOSTNAME:<COMPUTE_2_HOSTNAME> \
	-v HAPROXY_IP:<HAPROXY_IP> \
	-v HAPROXY_HOSTNAME:<HAPROXY_HOSTNAME> \
	-v OPENSTACK_VERSION:pike \
	-v EXT_BRIDGE:datacenter \
	-v OS_USER:root \
	-v OS_USER_PASSWORD:<root_password> \
	-v OS_NODE_PROMPT:# \
	-v ODL_RPM:http://cbs.centos.org/repos/nfv7-opendaylight-70-release/x86_64/os/Packages/opendaylight-7.0.0-1.el7.noarch.rpm \
	~/test/csit/suites/openstack/deploy/00_initial_setup.robot \
	~/test/csit/suites/openstack/deploy/01_mysql_setup.robot \
	~/test/csit/suites/openstack/deploy/02_rabbitmq_setup.robot \
	~/test/csit/suites/openstack/deploy/03_keystone_setup.robot \
	~/test/csit/suites/openstack/deploy/04_glance_setup.robot \
	~/test/csit/suites/openstack/deploy/05_nova_setup.robot \
	~/test/csit/suites/openstack/deploy/06_neutron_setup.robot \
	~/test/csit/suites/openstack/deploy/07_csit_setup.robot
```
* After execution, Check the log.html to understand the status of execution

* If the status is "PASS", there will be an Openstack Installation with
  three control nodes as HA and 2 compute nodes along with HAProxy node 
  configured to load balance and ensure HA.

* All the settings for executing CSIT will be configured.

#### Execute CSIT

* Run the below pybot command to execute CSIT

```     source /tmp/stackrc
	pybot --debug debug_csit.log \
	--log log_csit.html --output output_csit.xml \
	-v CONTROLLER_USER:jenkins \
	-v HA_PROXY_IP:<HAPROXY_IP> \
	-v NUM_ODL_SYSTEM:3 \
	-v NUM_OS_SYSTEM:5 \
	-v ODL_SYSTEM_IP:<CONTROL_1_IP> \
	-v ODL_SYSTEM_1_IP:<CONTROL_1_IP> \
	-v ODL_SYSTEM_2_IP:<CONTROL_2_IP> \
	-v ODL_SYSTEM_3_IP:<CONTROL_3_IP> \
	-v OS_CONTROL_NODE_IP:<CONTROL_1_IP> \
	-v OS_CONTROL_NODE_1_IP:<CONTROL_1_IP> \
	-v OS_CONTROL_NODE_2_IP:<CONTROL_2_IP> \
	-v OS_CONTROL_NODE_3_IP:<CONTROL_3_IP> \
	-v OS_COMPUTE_1_IP:<COMPUTE_1_IP> \
	-v OS_COMPUTE_2_IP:<COMPUTE_2_IP> \
	-v OS_USER:jenkins \
	-v USER_HOME:${HOME} \
	-v OPENSTACK_BRANCH:stable/pike \
	/home/evaluatech01/test/csit/suites/openstack/connectivity/01_l2_tests.robot
```

### Uninstall Openstack

* Sometimes, the deployer might fail and may warrant a rerun. At this time the below pybot command can be executed
  to clear the setup for rerun

#### 1node Openstack

```
	pybot --debug ~/debug_1node.log \
	-v OS_CONTROL_1_IP:<CONTROL_NODE_IP> \
	-v OS_CONTROL_NODE_IP:<CONTROL_NODE_IP> \
	-v OS_CONTROL_1_HOSTNAME:<CONTROL_NODE_HOSTNAME> \
	-v OS_IP:<CONTROL_NODE_IP> \
	-v NUM_CONTROL_NODES:1 \
	-v NUM_COMPUTE_NODES:2 \
	-v OS_COMPUTE_1_IP:<COMPUTE_1_IP> \
	-v OS_COMPUTE_1_HOSTNAME:<COMPUTE_1_HOSTNAME> \
	-v OS_COMPUTE_2_IP:<COMUTE_2_IP> \
	-v OS_COMPUTE_2_HOSTNAME:<COMPUTE_2_HOSTNAME> \
	-v OPENSTACK_VERSION:pike \
	-v EXT_BRIDGE:datacenter \
	-v OS_USER:root \
	-v OS_USER_PASSWORD:<root_password> \
	-v OS_NODE_PROMPT:# \
	-v ODL_RPM:http://cbs.centos.org/repos/nfv7-opendaylight-70-release/x86_64/os/Packages/opendaylight-7.0.0-1.el7.noarch.rpm \
	~/test/csit/suites/openstack/deploy/000_destroy_setup.robot
```

#### 3node Openstack

```
	pybot --debug ~/debug_3node.log \
	-l log_3node_install.html \
	-v OS_CONTROL_1_IP:<CONTROL_1_IP> \
	-v OS_CONTROL_1_HOSTNAME:<CONTROL_1_HOSTNAME> \
	-v OS_CONTROL_2_IP:<CONTROL_2_IP> \
	-v OS_CONTROL_2_HOSTNAME:<CONTROL_2_HOSTNAME> \
	-v OS_CONTROL_3_IP:<CONTROL_3_IP> \
	-v OS_CONTROL_3_HOSTNAME:<CONTROL_3_HOSTNAME> \
	-v NUM_CONTROL_NODES:3 \
	-v NUM_COMPUTE_NODES:2 \
	-v OS_COMPUTE_1_IP:<COMPUTE_1_IP> \
	-v OS_COMPUTE_1_HOSTNAME:<COMPUTE_1_HOSTNAME> \
	-v OS_COMPUTE_2_IP:<COMPUTE_2_IP> \
	-v OS_COMPUTE_2_HOSTNAME:<COMPUTE_2_HOSTNAME> \
	-v HAPROXY_IP:<HAPROXY_IP> \
	-v HAPROXY_HOSTNAME:<HAPROXY_HOSTNAME> \
	-v OPENSTACK_VERSION:pike \
	-v EXT_BRIDGE:datacenter \
	-v OS_USER:root \
	-v OS_USER_PASSWORD:<root_password> \
	-v OS_NODE_PROMPT:# \
	-v ODL_RPM:http://cbs.centos.org/repos/nfv7-opendaylight-70-release/x86_64/os/Packages/opendaylight-7.0.0-1.el7.noarch.rpm \
	~/test/csit/suites/openstack/deploy/000_destroy_setup.robot
```

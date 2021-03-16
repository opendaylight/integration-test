Run Integration Test on local machine
=====================================

Overview
========
Sometimes you might want to run some CSIT integration tests on your VM 
instead of the sandbox, this guide contains information about pre-requisites 
that need to be installed.

Operating System
----------------
To run the integration tests you will need a Linux-type OS, like Ubuntu or 
CentOS. Setup can be done manually, or you can download a VM image with the 
pre-installed OS.

Set up the integration test framework
-------------------------------------

Install Python
______________

For Debian-based distributions

.. code-block::

    sudo apt-get install python
    sudo apt-get install python-pip

Install Robot Framework
_______________________

.. note::
  RobotFramework installation guide can be found `here <https://robotframework.org/robotframework/latest/RobotFrameworkUserGuide.html>`_
  Releng/Builder CI/CD installation options can be found `here <https://github.com/opendaylight/releng-builder/blob/master/jjb/integration/integration-install-robotframework.sh>`_

.. code-block::

  pip install robotframework

Install libs if need
____________________

.. code-block::

  pip install alabaster Babel docutils imagesize Jinja2 lfdocs-conf

Install Additional Robot libraries
__________________________________

.. code-block::

  pip install robotframework-extendedrequestslibrary
  pip install robotframework-requests

Setup SSH access.
_________________
Add new user with name `jenkins` to the linux, setup home directory for this user.
Create and add pair of ssh keys. Put them to /home/jenkins/.ssh

Test ssh connection:

.. code-block::

  ssh jenkins@localhost -i /home/jenkins/.ssh/id-rsa

.. warning::
  If *Robot* can not connect through SSH, but manually connection works ok - update paramiko library:

  .. code-block::

    pip3 install --upgrade robotframework-sshlibrary
    pip3 install --upgrade paramiko

Run single integration test
---------------------------

Start `Karaf` and install required features.

Run test:

.. code-block::

  robot -L debug --variable KARAF_HOME:/home/user/workspace/netconf/karaf/target/assembly/bin --variable USER_HOME:/home/jenkins --variable DEFAULT_LINUX_PROMPT:\$ --variable ODL_SYSTEM_IP:127.0.0.1 --variable ODL_SYSTEM_1_IP:127.0.0.1 --variable RESTCONFPORT:8181 --variable IS_KARAF_APPL:True ./test.robot

Where
	* *KARAF_HOME* - path to karaf directory
	* *USER_HOME* - path to jenkins home directotry. Used by `Robot` to read id-rsa key for ssh connection. Can be set to any directory where .ssh folder with id-rsa key located
	* *ODL_SYSTEM_IP* - IP of ODL restconf server.
	* *ODL_SYSTEM_1_IP* (*ODL_SYSTEM_2_IP*, *ODL_SYSTEM_3_IP*) - IP`s of ODL cluster.
	* *RESTCONFPORT* - Restconf server port. 8181 by default.

.. note::
  Every suite can have different options. Please check Jenkins configuration for the specific test.

Getting result
--------------

On test finish, test result will be in the same folder as `Robot` test file:
  - report.html
  - log.html
  - output.xml

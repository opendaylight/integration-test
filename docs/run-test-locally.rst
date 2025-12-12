Run Integration Test Locally
============================

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

.. code-block:: bash

    sudo apt-get install python3
    sudo apt-get install python3-pip

Install Robot Framework and Extended Requests Library
_____________________________________________________

.. note::
  RobotFramework installation guide can be found `here <https://robotframework.org/robotframework/latest/RobotFrameworkUserGuide.html>`_

  Releng/Builder CI/CD installation options can be checked inside the `integration-install-robotframework.sh <https://github.com/opendaylight/releng-builder/blob/master/jjb/integration/integration-install-robotframework.sh>`_

.. code-block:: bash

  pip3 install robotframework
  pip3 install robotframework-extendedrequestslibrary

Install Libraries needed for test suites
________________________________________

.. code-block:: bash

  pip3 install alabaster Babel docutils imagesize Jinja2 lfdocs-conf

Setup SSH access
________________
Add new user with name `jenkins` to the linux, setup home directory for this
user. Create and add pair of ssh keys. Put them to /home/jenkins/.ssh

.. note::
  This is only applicable if you don't change a ${DEFAULT_USER} variable.

Test ssh connection:

.. code-block:: bash

  ssh jenkins@localhost -i /home/jenkins/.ssh/id-rsa

.. warning::
  If *Robot* can not connect through SSH, but manually connection works ok - update paramiko library:

  .. code-block:: bash

    pip3 install --upgrade robotframework-sshlibrary
    pip3 install --upgrade paramiko

Run single integration test
---------------------------

Start `Karaf` and install required features.

Run test:

.. code-block:: bash

  robot -L debug --variable KARAF_HOME:/home/user/workspace/netconf/karaf/target/assembly/bin --variable USER_HOME:/home/jenkins --variable DEFAULT_LINUX_PROMPT:\$ --variable ODL_SYSTEM_IP:127.0.0.1 --variable ODL_SYSTEM_1_IP:127.0.0.1 --variable RESTCONFPORT:8181 --variable IS_KARAF_APPL:True ./test.robot

Where
  * *KARAF_HOME* - path to karaf directory
  * *USER_HOME* - path to jenkins home directotry. Used by `Robot` to read id-rsa key for ssh connection. Can be set to any directory where .ssh folder with id-rsa key located
  * *ODL_SYSTEM_IP* - IP of ODL restconf server.
  * *ODL_SYSTEM_1_IP* (*ODL_SYSTEM_2_IP*, *ODL_SYSTEM_3_IP*) - IP`s of ODL cluster.
  * *RESTCONFPORT* - Restconf server port. 8181 by default.

Current list of parameters used by jenkins job can be found at `integration-run-test.sh <https://github.com/opendaylight/releng-builder/blob/174e01d61a9472b0b25da8d05d7c56bfb5589809/jjb/integration/integration-run-test.sh#L40>`_ script.

Full list of variables available from the CSIT is configured under the `Variables.robot <https://github.com/opendaylight/integration-test/blob/master/csit/variables/Variables.robot>`_

.. note::
  Every suite can have different options. Please check Jenkins configuration for the specific test.

Getting result
--------------

On test finish, test result will be in the same folder as `Robot` test file:
  - report.html
  - log.html
  - output.xml

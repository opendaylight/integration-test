robot_tool
==========
*robot test tool for OpenDaylight Project.*

* Version: 0.1
* Authors: [Baohua Yang](mailto:yangbaohua@gmail.com), [Denghui Huang](mailto:huangdenghui@gmail.com)
* Homepage: <https://github.com/yeasy/robot_tool>

##Get Code

`git clone https://github.com/yeasy/robot_tool.git`


##Usage
###Prerequisites
* Python 2.6/2.7
* Python [Roboframework-requests library](https://github.com/bulkan/robotframework-requests/)
 
  pip install -U robotframework-requests

* [OpenDaylight Controller](https://wiki.opendaylight.org/view/GettingStarted:Developer_Main)
   ```
   # Download and build OpenDaylight Controller
   git clone https://git.opendaylight.org/gerrit/p/controller.git
   cd controller/opendaylight/distribution/opendaylight
   mvn clean install -DskipTests -Dmaven.compile.fork=true -U
   ```
* [Mininet](http://mininet.org/walkthrough/)
* [Robotframework](http://robotframework.org/)

###Run Test
* Start the [OpenDaylight Controller](https://wiki.opendaylight.org/view/GettingStarted:Developer_Main)

 ```
  cd controller/target/distribution.opendaylight-0.1.0-SNAPSHOT-osgipackage/opendaylight/
  ./run.sh
  ```
* Start mininet, and make sure mininet has all switches connected to the controller, for example, 
      `sudo mn --controller=remote,ip=your_controller_ip --topo tree,2`
*  Go to the suites directory, executing the suite such as `pybot --variable topo_tree_level:2 base` which will run all tests in the base edition or `pybot --variable topo_tree_level:2 switch_manager.txt` to test the switch manager module.
  
##Code Structure

    robot_tool
    \---------suites       # all robot test suites
    |         \-----base                # all test suites for the base edition
    |         |
    |         \-----service_provider    # all test suites for the service provider edition
    |         |
    |         \-----virtualization      # all test suites for the service provider edition
    |
    \---------libraries    # all keywords
    |
    \---------resources    # resources related files
    |
    \---------variables    # all variables


##Development Plan
* Finish test suites for the base edition.

##About OpenDaylight
OpenDaylight is the first production-quality open-source SDN management platform sponsored by Linux Foundation. 
Lead SDN enterprises (Ericsson, IBM, Microsoft, Redhat, Cisco, Juniper, NEC, VMWare etc.) are involved to develop and support the project.
Please go to the official [homepage](http://www.opendaylight.org) page to find more information.


##Robot framework user guide.
   http://robotframework.googlecode.com/hg/doc/userguide/RobotFrameworkUserGuide.html?r=2.8.1

##Testlibraries references.
   3.1 A list of available test libraries for Robot Framework 
   http://code.google.com/p/robotframework/wiki/TestLibraries

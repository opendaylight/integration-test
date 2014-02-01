
OpenDaylight test VM
--------------------
Prepared by Luis Gomez (luis.gomez@ericsson.com)

This VM contains the following:

1) OpenDaylight release editions:

~/controller-base/ -> Base edition folder
~/controller-virt/ -> Virtualization edition folder
~/controller-sp/ -> Service Provider edition folder

Note: to run controller just go to opendaylight folder and type run.sh

2) Mininet 2.1.0 with OVS 2.0.0 and CPqD:

~/integration/vm/scripts/start_mininet_of10.sh -> starts mininet OVS OF10 on local controller
~/integration/vm/scripts/start_mininet_of13.sh -> starts mininet OVS OF13 on local controller
~/integration/vm/scripts/start_mininet_cpqd.sh -> starts mininet CPqD on local controller

3) Integration tests (Robot Framework):

~/integration/test/csit/suites/ -> Robot test folder
~/integration/vm/scripts/run_test_base_self.sh -> run base edition test on local controller
~/integration/vm/scripts/run_test_base.sh <IP> -> run base edition test on external controller

Note: Robot test results (saved at ~/) can be opened with a browser

4) VTN Coordinator:

~/integration/vm/scripts/start_vtn_coordinator.sh
~/integration/vm/scripts/stop_vtn_coordinator.sh


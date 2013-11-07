#!/usr/bin/env python
"""
CSIT test tools.
Authors: Baohua Yang@IBM, Denghui Huang@IBM
Updated: 2013-11-07

Usage: Before running the test tool, should
 1. Start 2-layer tree topology network. e.g., in Mininet, run  'sudo mn --controller=remote,ip=127.0.0.1 --mac --topo tree,2'.
 2. Configure gateway in the controller web GUI, name = 'gateway', subnet = '10.0.0.254/24'.
 3. In Mininet, run 'h1 ping h2' to make sure the network is connected.
"""
import doctest
import os
from restlib import *


def test_case(module_name):
    '''
    Run single test on given module.
    '''
    print "#Test case: " + module_name.replace('_', ' ')
    cmd = 'python -m doctest ' + module_name + '.py'
    os.system(cmd)

def run(modules=None):
    '''
    Run test cases according to the given modules.
    If no parameter is given, then will scan the case directory,
     and try to run all cases.
    '''
    backup_dir = os.getcwd()
    if not modules:
        modules = [e[:-3] for e in os.listdir(CASES_DIR) if e.endswith('.py')]
    os.chdir(backup_dir + '/' + CASES_DIR)
    for name in modules:
        test_case(name)
    os.chdir(backup_dir)


if __name__ == '__main__':
    doctest.testmod()
    test_modules = ['switch_manager', 'topology_manager', 'forwarding_rule_manager', 'statistics_manager',
                    'host_tracker', 'arp_handler', 'forwarding_manager', 'container_manager']
    #test_modules = ['topology_manager']
    run(test_modules)
    #run()

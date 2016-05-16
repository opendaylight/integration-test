"""This module contains implementation of monkey test for openflow cluster."""
# Copyright (c) 2016 Cisco Systems, Inc. and others.  All rights reserved.
#
# This program and the accompanying materials are made available under the
# terms of the Eclipse Public License v1.0 which accompanies this distribution,
# and is available at http://www.eclipse.org/legal/epl-v10.html

__author__ = "Juraj Sebin"
__copyright__ = "Copyright(c) 2016, Cisco Systems, Inc."
__license__ = "Eclipse Public License v1.0"
__email__ = "jsebin@cisco.com"


import threading
import random
import time
import logging
import signal
import re
import subprocess
import sys
import os
import json
import requests
import argparse

import VsctlListParser

_auth = ('admin', 'admin')
_stop = False
_cluster_data = [('10.25.2.12', 'member-1'), ('10.25.2.13', 'member-2'), ('10.25.2.14', 'member-3')]
_root_logger = logging.getLogger('Monkey')


# logging.getLogger("requests").setLevel(logging.WARNING)


def _dump_data():
    _root_logger.info('DUMPING DATA')
    _root_logger.info('SWITCH DATA - BRIDGE-CONTROLLER')
    _root_logger.info('-'*60)
    _root_logger.info(json.dumps(OVSData.data, indent=4, separators=(',', ': ')))
    _root_logger.info('-'*60)
    _root_logger.info('SWITCH DATA - CONTROLLER')
    _root_logger.info('-'*60)
    _root_logger.info(json.dumps(OVSData.bridges, indent=4, separators=(',', ': ')))
    _root_logger.info('-'*60)
    _root_logger.info('SWITCH DATA - BRIDGE')
    _root_logger.info('-'*60)
    _root_logger.info(json.dumps(OVSData.ctrls, indent=4, separators=(',', ': ')))
    _root_logger.info('-'*60)
    _root_logger.info('CLUSTER DATA')
    _root_logger.info('-'*60)
    _root_logger.info(json.dumps(ClusterData.data, indent=4, separators=(',', ': ')))
    _root_logger.info('-'*60)


def _blank_check_callback(*args, **kwargs):
    """blank function to be used as default argument for check callback in functions 
       decorated by _repeat_until_succeess
    """
    _root_logger.warn('Using blank check callback')
    return True


def _ovs_switch_odl_name(ovs_sw_name):
    return 'openflow:'+ovs_sw_name[1:]


def _repeat_until_succeess(f):
    """Decorator to run target function mutliple times, with interval between each run
       against expected result

       If all runs fail, invalid state is found and test execution is stopped with data dump
    """
    def wrapper(self, expected_result, backoff_time, count, *args, **kwargs):
        act_cnt = 0

        while act_cnt < count:
            result = f(self, *args, **kwargs)
            if result == expected_result:
                return True
            time.sleep(backoff_time)
            act_cnt = act_cnt + 1

        _root_logger.info('Found invalid state - sending exit signal')
        _dump_data()
        global _stop
        _stop = True

        return False
    return wrapper


class Army(object):
    """Army of monkeys.
    
    It should be used to group monkeys together. 
    """

    _logger = logging.getLogger('Army')

    def __init__(self):
        self._running = False
        self._monkeys = []

    @property
    def running(self):
        return self._running

    def add_monkey(self, monkey):
        if self._running:
            monkey.start()
        self._monkeys.append(monkey)
    
    @property
    def monkeys(self):
        return tuple(self._monkeys)

    #TODO: remove monkey
    def start(self):
        self._running = True
        for monkey in self._monkeys:
            monkey.start()

    def stop(self):
        self._running = False
        self._logger.info('Stoping all monkeys..')
        for monkey in self._monkeys:
            monkey.stop()

        for monkey in self._monkeys:
            monkey.join()


class ClusterData(object):
    """Object wrapping cluster data gathering and parsing
    """

    cluster_nodes = []
    _data_lock = threading.Lock()
    _logger = logging.getLogger('ClusterData')
    data = {}

    _OPENFLOW_ENTITIES_URL = 'http://{ctrl}:8181/restconf/operational/entity-owners:entity-owners/entity-type/openflow/'
    _SWITCH_ID_TEMPLATE = '/general-entity:entity[general-entity:name=\'{sw_name}\']'
    _OPERATIONAL_STORE_JOLOKIA = 'http://{ctrl}:8181/jolokia/read/org.opendaylight.controller:Category=ShardManager,name=shard-manager-operational,type=DistributedOperationalDatastore'
    _OPERATIONAL_STORE_SHARD_STATUS_JOLOKIA = 'http://{ctrl}:8181/jolokia/read/org.opendaylight.controller:Category=Shards,name={member}-shard-inventory-operational,type=DistributedOperationalDatastore'

    @classmethod
    def lock(cls):
        cls._logger.debug('Locking')
        cls._data_lock.acquire()

    @classmethod
    def unlock(cls):
        cls._logger.debug('Unlocking')
        cls._data_lock.release()

    @classmethod
    def init(cls, *cluster_node_ips):
        """Init method for cluster data, needs to be called before any other methods will be used. It populates dictionary
           of cluster nodes which is used for requesting REST data
        """
        cls.cluster_nodes = {}
        for node_ip in cluster_node_ips:
            cls.cluster_nodes[node_ip] = {}

        cls._get_operational_ds_members()
        cls.get_leadership_status()

        cls.reload_data()

        result = cls.check_data_integrity(True, 5, 5)
        cls._logger.info('Data ingerity on cluster nodes during init... %s', 'ok' if result else 'notok')
        cls._logger.info('ClusterData init done...')

    @classmethod
    def _get_operational_ds_members(cls):
        for node_ip in cls.cluster_nodes.keys():
            url = cls._OPERATIONAL_STORE_JOLOKIA.format(ctrl=node_ip)
            response_json = requests.get(url).json()
            try:
                cls.cluster_nodes[node_ip]['member'] = response_json['value']['MemberName']
                cls._logger.info('Assigned %s to %s',cls.cluster_nodes[node_ip]['member'], node_ip)
            except KeyError:
                cls._logger.info('Cannot get operational ds member info for node %s', node_ip)
    
    @classmethod
    def get_leadership_status(cls):
        for node_ip, node in cls.cluster_nodes.items():
            url = cls._OPERATIONAL_STORE_SHARD_STATUS_JOLOKIA.format(ctrl=node_ip, member=node['member'])
            response_json = requests.get(url).json()
            try:
                cls.cluster_nodes[node_ip]['leader'] = (response_json['value']['RaftState'] == 'Leader')
            except KeyError:
                cls.cluster_nodes[node_ip]['leader'] = None
                cls._logger.info('Cannot get leadership status for node %s', node_ip)

    @classmethod
    def _get_entity_switch_id(cls, switch_name):
        return cls._SWITCH_ID_TEMPLATE.format(sw_name=switch_name)

    @classmethod
    def _get_single_node_data_json(cls, node_ip):
        url = cls._OPENFLOW_ENTITIES_URL.format(ctrl=node_ip)
        r = requests.get(url, auth=_auth)
        return r.json()

    @classmethod
    def get_master(cls, switch_name):
        switch_id = cls._get_entity_switch_id(switch_name)
        all_switches = cls.data['entity-type'][0]['entity']
        target_switch = [sw for sw in all_switches if switch_id == sw['id']][0]

        return target_switch['owner']

    @classmethod
    def reload_data(cls):
        cls.data = cls._get_single_node_data_json(cls.cluster_nodes.keys()[0])

    @classmethod
    @_repeat_until_succeess
    def check_data_integrity(cls):
        final_result = True

        for node_ip in cls.cluster_nodes.keys():
            response_json = cls._get_single_node_data_json(node_ip)
            final_result = final_result and (response_json == cls.data)

            if not final_result:
                return final_result

        return final_result

    @classmethod
    def _get_owner_and_candidates(cls, switch_id):
        all_switches = cls.data['entity-type'][0]['entity']
        target_switch = [sw for sw in all_switches if switch_id == sw['id']][0]

        try:
            candidates = [candidate['name'] for candidate in target_switch['candidate']]
        except KeyError:
            candidates = []
        owner = target_switch['owner']

        return owner, candidates

    @classmethod
    @_repeat_until_succeess
    def check_member(cls, switch_name, controller_ip, callback=_blank_check_callback):
        member = cls.cluster_nodes[controller_ip]['member']
        switch_id = cls._get_entity_switch_id(switch_name)

        cls.reload_data()
        cls._logger.debug('Got cluster data... \n%s', json.dumps(cls.data, indent=4, separators=(',', ': ')))
        
        owner, candidates = cls._get_owner_and_candidates(switch_id)
        cls._logger.debug('Member: %s, Switch Id: %s, Candidate names: %s, Owner: %s', member, switch_id, candidates, owner)

        return callback(member, candidates, owner)


class OVSData(object):
    """Object wrapping OVS data gathering and parsing
    """

    _data_lock = threading.Lock()
    data = {}
    bridges = {}
    ctrls = {}
    _free_controllers = []

    _logger = logging.getLogger('OVSData')
    _invalid = True

    @classmethod
    def lock(cls):
        cls._logger.debug('Locking')
        cls._data_lock.acquire()

    @classmethod
    def unlock(cls):
        cls._logger.debug('Unlocking')
        cls._data_lock.release()

    @classmethod
    def invalidate(cls):
        cls._invalid = True

    @classmethod
    def _is_free_controller(cls, ctrl):
        return len(ctrl['target'].split(':')) == 3 and  ctrl['is_connected'] == 'true' # and ctrl['role'] == 'master'

    @classmethod
    def init(cls):
        """Method to populate controller, bridge, bridge-controller and free controllers data
    
        It needs to be called before a monkey will try to take some controller
        """

        cls.reload_data()
        cls._logger.debug('Got bridge-controller data \n%s', json.dumps(cls.data, indent=4, separators=(',', ': ')))
        cls._logger.debug('Got controller data \n%s', json.dumps(cls.ctrls, indent=4, separators=(',', ': ')))
        cls._logger.debug('Got bridge data \n%s', json.dumps(cls.bridges, indent=4, separators=(',', ': ')))

        cls._logger.debug('Getting free controllers from \n%s', json.dumps(cls.ctrls.values(), indent=4, separators=(',', ': ')))
        cls._free_controllers = [ctrl for ctrl in cls.ctrls.values() if cls._is_free_controller(ctrl)]

        cls._logger.debug('Free controllers \n%s', json.dumps(cls._free_controllers, indent=4, separators=(',', ': ')))
        cls._logger.info('OVSData init done...')

    @classmethod
    def reload_data(cls):
        if cls._invalid:
            cls._logger.debug('Getting Bridges and Controller data')

            bridges_raw = subprocess.check_output(['ovs-vsctl', 'list', 'Bridge'])
            ctrls_raw = subprocess.check_output(['ovs-vsctl', 'list', 'Controller'])

            cls.data, cls.bridges, cls.ctrls  = VsctlListParser.parse(bridges_raw, ctrls_raw)
            cls._invalid = False


    @classmethod
    def get_controller_switch(cls, controller_ip, controller_uuid):
        cls._logger.debug('Gettings switch from... \n%s\nby IP: %s and UUID: %s', json.dumps(cls.data.values(), indent=4, separators=(',', ': ')), controller_ip, controller_uuid)
        switch = [k for k, v in cls.data.items() if v['controller'][controller_ip]['_uuid'] == controller_uuid][0]

        return switch

    @classmethod
    def take_controller(cls):
        try:
            controller = random.choice(cls._free_controllers)
            cls._free_controllers.remove(controller)
        except IndexError:
            controller = None

        return controller

    @classmethod
    def return_controller(cls, controller):
        cls._free_controllers.append(controller)

        return None


class Monkey(threading.Thread):
    """Baseclass for all monkeys.
    
    Do NOT use this class directly.
    """

    def __init__(self, interval):
        super(Monkey, self).__init__()

        self._interval = interval
        self._running = False
        self._logger = logging.getLogger('Monkey.%s' % self.__class__.__name__)

    def run(self):
        self._logger.info('Starting with interval %s', self._interval)
        self._running = True
        while self._running:
            self._make_chaos()
            time.sleep(self._interval)
            self._clean_up()

        self._logger.info('Monkey stopped')

    def stop(self):
        self._running = False

    def _make_chaos(self):
        pass

    def _clean_up(self):
        pass



class CtrlSwitchLinkDisconnectingMonkey(Monkey):
    """Monkey for disconnecting and reconnecting switch connections to cluster nodes
    """

    def __init__(self, interval):
        super(CtrlSwitchLinkDisconnectingMonkey, self).__init__(interval)
        self._controller = None

    def _execute_disconnect_command(self):
        new_target = 'target="tcp:'+self._get_controller_ip(self._controller)+':6654"'

        self._logger.info('Disconnecting link to controller with UUID %s to target %s', self._controller['_uuid'], self._controller['target'])
        self._logger.debug('Changing target to %s', new_target)

        subprocess.call(['ovs-vsctl', 'set', 'Controller', self._controller['_uuid'], new_target])

    def _execute_reconnect_command(self):
        new_target = 'target="tcp:'+self._get_controller_ip(self._controller)+':6633"'

        self._logger.info('Reconnecting link to controller with UUID %s to target %s', self._controller['_uuid'], self._controller['target'])
        self._logger.debug('Changing target to %s', new_target)

        subprocess.call(['ovs-vsctl', 'set', 'Controller', self._controller['_uuid'], new_target])

    @classmethod
    def _get_link_state(cls, controller_uuid):
        return OVSData.ctrls[controller_uuid]['is_connected']

    @classmethod
    def _get_controller_ip(cls, controller):
        return controller['target'].split(':')[1]

    def _disconnect(self):
        self._execute_disconnect_command()
        OVSData.invalidate()

    def _reconnect(self):
        self._execute_reconnect_command()
        OVSData.invalidate()

    def _make_chaos(self):
        OVSData.lock()

        self._controller = OVSData.take_controller()

        if self._controller is not None:
            controller_uuid = self._controller['_uuid']
            controller_ip = self._get_controller_ip(self._controller)
            ovs_sw = OVSData.get_controller_switch(controller_ip, controller_uuid)
            odl_sw = _ovs_switch_odl_name(ovs_sw)
            master_member = ClusterData.get_master(odl_sw)

            def member_not_in_candidates_or_owner(member, candidates, owner):
                # verify election of new master, if we'd chosen master switch
                election_check = master_member != owner if ClusterData.cluster_nodes[controller_ip]['member'] == master_member else True
                member_not_present_check = member not in candidates and member != owner
                
                return election_check and member_not_present_check

            self._logger.info('Taking controller uuid: %s, at %s, linked to switch %s (odl: %s)', controller_uuid, controller_ip, ovs_sw, odl_sw)
            self._disconnect()

            result = self._test_connection_status('false', 5, 5)
            self._logger.info('Controller connection status after disconnect... %s', 'ok' if result else 'notok')

            self._logger.debug('Checking Cluster data with ovs_sw %s and odl_sw %s', ovs_sw, odl_sw)
            result = ClusterData.check_member(True, 5, 5, odl_sw, controller_ip, member_not_in_candidates_or_owner)
            self._logger.info('Disconnected controller is not present as candidate or owner... %s', 'ok' if result else 'notok')

            result = ClusterData.check_data_integrity(True, 5, 5)
            self._logger.info('Data ingerity on cluster nodes after chaos is made... %s', 'ok' if result else 'notok')
        else:
            self._logger.info('Cannot get free connection, waiting...')

        OVSData.unlock()


    def _clean_up(self):
        if self._controller is not None:
            OVSData.lock()

            def member_in_candidates(member, candidates, owner):
                return member in candidates

            controller_uuid = self._controller['_uuid']
            controller_ip = self._get_controller_ip(self._controller)
            ovs_sw = OVSData.get_controller_switch(controller_ip, controller_uuid)
            odl_sw = _ovs_switch_odl_name(ovs_sw)

            self._reconnect()

            result = self._test_connection_status('true', 5, 5)
            self._logger.info('Controller connection status after reconnect... %s', 'ok' if result else 'notok')

            self._logger.debug('Checking Cluster data with ovs_sw %s and odl_sw %s', ovs_sw, odl_sw)
            result = ClusterData.check_member(True, 5, 5, odl_sw, controller_ip, member_in_candidates)
            self._logger.info('Reconnected controller is present as candidate... %s', 'ok' if result else 'notok')

            result = ClusterData.check_data_integrity(True, 5, 5)
            self._logger.info('Data ingerity on cluster nodes after chaos is made... %s', 'ok' if result else 'notok')

            self._controller = OVSData.return_controller(self._controller)

            OVSData.unlock()
        else:
            self._logger.info('No connection taken, nothing to cleanup...')

    @_repeat_until_succeess
    def _test_connection_status(self):
        OVSData.invalidate()
        OVSData.reload_data()
        return self._get_link_state(self._controller['_uuid'])


def _handler(signum, frame):
    global _stop
    _stop = True


def start_monkey(monkey_count, interval, run_time, logfile, loglevel, cluster_nodes):
    global _stop

    signal.signal(signal.SIGINT, _handler)
    logging.basicConfig(format='[%(asctime)s] %(levelname)7s %(name)22s %(threadName)10s: %(message)s',
                    datefmt='%Y/%m/%d %H:%M:%S', level=loglevel,
                    filename=logfile)

    OVSData.init()
    ClusterData.init(*cluster_nodes)

    a = Army()
    act_time = 0
    inc_time = 1

    for i in range(monkey_count):
        a.add_monkey(CtrlSwitchLinkDisconnectingMonkey(interval))

    a.start()

    while True:
        if _stop:
            a.stop()
            break
        act_time += inc_time
        
        if act_time > run_time:
            _root_logger.info("Test time has passed, stopping...")
            _stop = True
        time.sleep(inc_time)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Automated monkey test script for Openflow Cluster")
    parser.add_argument("--monkey-count", type=int, default=10, help="Number of monkeys created.")
    parser.add_argument("--interval", type=int, default=20, help="Number of seconds each monkey will wait before performing action")
    parser.add_argument("--run-time", type=int, default=300, help="Number of seconds the test will run")
    parser.add_argument('--cluster-nodes', metavar='IP', nargs='+', help='Cluster Node IPs')
    parser.add_argument("--error", dest="loglevel", action="store_const",
                        const=logging.ERROR, default=logging.INFO,
                        help="Set log level to error (default is info)")
    parser.add_argument("--warning", dest="loglevel", action="store_const",
                        const=logging.WARNING, default=logging.INFO,
                        help="Set log level to warning (default is info)")
    parser.add_argument("--info", dest="loglevel", action="store_const",
                        const=logging.INFO, default=logging.INFO,
                        help="Set log level to info (default is info)")
    parser.add_argument("--debug", dest="loglevel", action="store_const",
                        const=logging.DEBUG, default=logging.INFO,
                        help="Set log level to debug (default is info)")
    parser.add_argument("--logfile", default="result-monkey.log", help="Log file name")

    args = parser.parse_args()

    start_monkey(**vars(args))

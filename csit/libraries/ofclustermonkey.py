"""This module contains implementation of monkey test for openflow cluster.

Monkeys are processes used to disturb cluster and verify that it can recover
from these disruptions and that during these recovery phases it's behaving as
inteded.

Usage if script itself is described by in help. Currently, two types of monkeys
are implemented:

1. Monkey to disturb connection between switch and cluster node: Monkey takes random
connection to controller from ovsctl bridge list, and disconnects it by changing port
to invalid value (6654). During recovery it reconnects connection by changing port
value to correct one (6633)

2. Monkey for isolating cluster node: Monkey takes random cluster node and disconnects
it from cluster by altering iptable rules on other cluster nodes. Recovery phase consists
of deleting theses rules on other nodes.

Number of monkeys which disturbs connection between switch and node (1.) is specified by
arguments. As the current test environments consists only from 3-node cluster, only single
monkey for isolating cluster nodes is used.

Cluster state checks are performed based on cluster data (currently only entity-ownership and
jolokia operational inventory leader and followers data) and OVS data. Separate classes
for collecting theses kinds of data are implemented in ClusterData and OVSData. These
classes are also resposible for maintaning list of available connections and cluster nodes
to be taken and disturbed by some monkey.
"""
# Copyright (c) 2016 Cisco Systems, Inc. and others.  All rights reserved.
#
# This program and the accompanying materials are made available under the
# terms of the Eclipse Public License v1.0 which accompanies this distribution,
# and is available at http://www.eclipse.org/legal/epl-v10.html


import threading
import random
import time
import logging
import signal
import subprocess
import sys
import json
import requests
import argparse
import traceback

import VsctlListParser
from SSHLibrary import SSHLibrary


__author__ = "Juraj Sebin"
__copyright__ = "Copyright(c) 2016, Cisco Systems, Inc."
__license__ = "Eclipse Public License v1.0"
__email__ = "jsebin@cisco.com"

_auth = ('admin', 'admin')
_stop = False
_root_logger = logging.getLogger('Monkey')
_data_dump_logger = logging.getLogger('DataDump')
general_lock = threading.Lock()


# logging.getLogger("requests").setLevel(logging.WARNING)
# logging.getLogger("RobotFramework").setLevel(logging.WARNING)
# logging.getLogger("paramiko.transport").setLevel(logging.WARNING)


def _dump_data():
    """Function to dump OVS and Cluster data into separate file
    """
    _root_logger.info('DUMPING DATA')
    _data_dump_logger.info('SWITCH DATA - BRIDGE-CONTROLLER')
    _data_dump_logger.info('-' * 60)
    _data_dump_logger.info(json.dumps(OVSData.data, indent=4, separators=(',', ': ')))
    _data_dump_logger.info('-' * 60)
    _data_dump_logger.info('CLUSTER DATA')
    _data_dump_logger.info('-' * 60)
    _data_dump_logger.info(json.dumps(ClusterData.data, indent=4, separators=(',', ': ')))
    _data_dump_logger.info('-' * 60)


def _blank_check_callback(*args, **kwargs):
    """Blank function to be used as default argument for check callback in functions
       decorated by _repeat_until_succeess
    """
    _root_logger.warn('Using blank check callback')
    return True


def _ovs_switch_odl_name(ovs_sw_name):
    return 'openflow:' + ovs_sw_name[1:]


def _repeat_until_succeess(f):
    """Decorator to run target function mutliple times, with interval between each run
       against expected result. Decorator is to be used in object method.

       If all runs fail, invalid state is found and test execution is stopped with data dump

    Args:
        :param self: Object instance of decorated function
        :param expected_result: an expected result that will be compared with result of
        decorated function
        :param backoff_time: how long time should elapse between retries
        :param count: retries count

    Returns:
        :returns wrapper: decoratred function
    """
    def wrapper(self, expected_result, backoff_time, count, *args, **kwargs):
        global _stop
        act_cnt = 0

        while act_cnt < count:
            result = f(self, *args, **kwargs)
            _root_logger.debug('%s attempt: %s == %s', act_cnt, result, expected_result)
            if result == expected_result:
                return True
            _root_logger.debug('Result is not equals to expected value, backing off for %s seconds', backoff_time)
            time.sleep(backoff_time)
            act_cnt = act_cnt + 1

        if not _stop:
            _root_logger.info('Found invalid state - sending exit signal')
            _dump_data()
            _stop = True
            TestResults.fail()

        return False
    return wrapper


class Army(object):
    """Army of monkeys.

    It should be used to group monkeys together.
    """

    _logger = logging.getLogger('Monkey.Army')

    def __init__(self):
        self._running = False
        self._monkeys = []

    @property
    def running(self):
        return self._running

    def add_monkey(self, monkey):
        """Function to add monkey to army. If army is already stared, start
        new monkey as well.

        Args:
            :param monkey: Instance of Monkey object
        """
        if self._running:
            monkey.start()
        self._monkeys.append(monkey)

    @property
    def monkeys(self):
        return tuple(self._monkeys)

    def start(self):
        """Starts all monkeys in army and set running flag to True
        """
        self._running = True
        for monkey in self._monkeys:
            monkey.start()

    def stop(self):
        """Stops all monkeys in army and set running flag to False. Waits for all
        Monkey threads to finish and then return
        """
        self._running = False
        self._logger.info('Stoping all monkeys..')

        for monkey in self._monkeys:
            monkey.stop()

        for monkey in self._monkeys:
            monkey.join()


class TestResults(object):
    """Class to aggregate test results
    """
    _isolate_run_count = 0
    _disconnect_run_count = 0
    _pass = True
    _logger = logging.getLogger('Monkey.TestResults')
    _time_start = 0
    _last_time_tracked = 0

    @classmethod
    def log_results(cls):
        cls._logger.info('Cluster Node Isolated %s times', cls._isolate_run_count)
        cls._logger.info('Controller-Switch connection distrubed %s times', cls._disconnect_run_count)
        cls._logger.info('Test duration: %s, passed: %s', cls._last_time_tracked, cls._pass)

    @classmethod
    def fail(cls):
        cls._pass = False

    @classmethod
    def has_failed(cls):
        return not cls._pass

    @classmethod
    def start_time_tracking(cls):
        cls._time_start = time.time()

    @classmethod
    def get_elapsed_time(cls):
        """Checks if node is leader of operational DS

        Returns:
            :returns elapsed time in seconds
        """
        cls._last_time_tracked = time.time() - cls._time_start
        return cls._last_time_tracked

    @classmethod
    def save_plot_data(cls):
        """Saves statistical data to be later used in a plot
        """
        cls._logger.info('Saving plot data')
        with open('plot-data.csv', 'w') as f:
            f.write('{et},{status}\r\n'.format(et=cls._last_time_tracked, status=cls._pass))
            f.write('{mtype},{cnt}\r\n'.format(
                    mtype=CtrlSwitchLinkDisconnectingMonkey.__class__.__name__,
                    cnt=cls._disconnect_run_count))
            f.write('{mtype},{cnt}\r\n'.format(
                    mtype=ClusterNodeIsolatingMonkey.__class__.__name__,
                    cnt=cls._isolate_run_count))


class ClusterData(object):
    """Object wrapping cluster data gathering and parsing
    """

    cluster_nodes = {}
    _isolated_nodes = []
    _logger = logging.getLogger('Monkey.ClusterData')
    data = {}

    _OPENFLOW_ENTITIES_URL = 'http://{ctrl}:8181/restconf/operational/entity-owners:entity-owners/entity-type/openflow/'
    _SWITCH_ID_TEMPLATE = '/general-entity:entity[general-entity:name=\'{sw_name}\']'
    _OPERATIONAL_STORE_JOLOKIA = 'http://{ctrl}:8181/jolokia/read/org.opendaylight.controller:Category=ShardManager,name\
=shard-manager-operational,type=DistributedOperationalDatastore'
    _OPERATIONAL_STORE_SHARD_STATUS_JOLOKIA = 'http://{ctrl}:8181/jolokia/read/org.opendaylight.controller:Category=\
Shards,name={member}-shard-inventory-operational,type=DistributedOperationalDatastore'

    @classmethod
    def init(cls, *cluster_node_ips):
        """Init method for cluster data, needs to be called before any other methods will be used. It populates dictionary
           of cluster nodes which is used for requesting REST data and checking operational DS leadership. During init
           method, dictionary of cluser nodes is created with cluster node ip as key. Value is another dictionary with
           key member and leader.

        Args:
            :param cluster_node_ips: list of cluster nodes IP addresses as strings
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
        """Iterates over cluster nodes dictionary and assings membership to each one
        """
        for node_ip in cls.cluster_nodes.keys():
            url = cls._OPERATIONAL_STORE_JOLOKIA.format(ctrl=node_ip)
            response_json = requests.get(url, auth=_auth, verify=False).json()
            try:
                cls.cluster_nodes[node_ip]['member'] = response_json['value']['MemberName']
            except KeyError:
                cls._logger.info('Cannot get operational ds member info for node %s', node_ip)
                cls._logger.debug('Api: %s data dump %s',
                                  url, json.dumps(response_json, indent=4, separators=(',', ': ')))

    @classmethod
    def get_leadership_status(cls):
        """Iterates over cluster nodes dictionary and assings leadership status of opearational DS to each one
        """
        for node_ip, node in cls.cluster_nodes.items():
            url = cls._OPERATIONAL_STORE_SHARD_STATUS_JOLOKIA.format(ctrl=node_ip, member=node['member'])
            response_json = requests.get(url, auth=_auth, verify=False).json()
            try:
                cls.cluster_nodes[node_ip]['leader'] = (response_json['value']['RaftState'] == 'Leader')
            except KeyError:
                cls.cluster_nodes[node_ip]['leader'] = None
                cls._logger.info('Cannot get leadership status for node %s', node_ip)
                cls._logger.debug('Api: %s data dump %s',
                                  url, json.dumps(response_json, indent=4, separators=(',', ': ')))

    @classmethod
    def is_node_leader(cls, node_ip):
        """Checks if node is leader of operational DS

        Args:
            :param node_ip: ip as string

        Returns:
            :returns value of leader key (True/False/None)
        """
        return cls.cluster_nodes[node_ip]['leader']

    @classmethod
    def _get_entity_switch_id(cls, switch_name):
        """Formats entity id template to correspond with id of /entity-owners:entity-owners/entity-type/openflow/
        entites

        Args:
            :param switch_name: name of switch

        Returns:
            :returns formatted string
        """
        return cls._SWITCH_ID_TEMPLATE.format(sw_name=switch_name)

    @classmethod
    def _get_single_node_data_json(cls, node_ip):
        """Gets entity ownership data from single cluster node

        Args:
            :param node_ip: ip of cluster node as string

        Returns:
            :returns json response
        """
        url = cls._OPENFLOW_ENTITIES_URL.format(ctrl=node_ip)
        r = requests.get(url, auth=_auth, verify=False)
        return r.json()

    @classmethod
    def get_master(cls, switch_name):
        """Gets owner of the switch

        Args:
            :param switch_name: name of switch

        Returns:
            :returns switch owner member
        """
        switch_id = cls._get_entity_switch_id(switch_name)
        all_switches = cls.data['entity-type'][0]['entity']
        target_switch = [sw for sw in all_switches if switch_id == sw['id']][0]

        return target_switch['owner']

    @classmethod
    def get_operational_leader(cls, timeout=10):
        """Gets leader of operational DS. Method has timeout during which leadership status
        must be assigned in cluster

        Args:
            :param timeout: timeout to wait until leadership status is assigned

        Returns:
            :returns ip of leader or None if leader is not known and timeout has elapsed
        """
        act_time = 0
        free_nodes = cls.get_free_nodes()

        while act_time < timeout:
            cls.get_leadership_status()
            for node_ip in free_nodes:
                if cls.cluster_nodes[node_ip]['leader']:
                    return node_ip
            time.sleep(1)
            act_time += 1

        return None

    @classmethod
    def get_free_nodes(cls):
        """Gets free nodes, that are not assigned to Monkey

        Returns:
            :returns set of free nodes ip addresses
        """
        return set(cls.cluster_nodes.keys()) - set(cls._isolated_nodes)

    @classmethod
    def reload_data(cls):
        """Reloads data from cluster
        """
        leader = cls.get_operational_leader()
        cls.data = cls._get_single_node_data_json(leader)

    @classmethod
    @_repeat_until_succeess
    def check_data_integrity(cls):
        """Checks for data integrity. Data from all cluster nodes must be same

        Returns:
            :returns True if integrity check passed, otherwise False
        """
        cls._logger.debug('Checking data integrity on cluster nodes')
        final_result = True
        free_nodes = cls.get_free_nodes()

        for node_ip in free_nodes:
            response_json = cls._get_single_node_data_json(node_ip)
            final_result = final_result and (response_json == cls.data)

            if not final_result:
                return final_result

        return final_result

    @classmethod
    def _get_owner_and_candidates(cls, switch_id):
        """Gets owner and candidates for switch

        Args:
            :param switch_id: id of switch returned from _get_entity_switch_id

        Returns:
            :returns tuple of owner member and list of candidate members
        """
        all_switches = cls.data['entity-type'][0]['entity']
        target_switch = [sw for sw in all_switches if switch_id == sw['id']][0]

        try:
            candidates = [candidate['name'] for candidate in target_switch['candidate']]
        except KeyError:
            candidates = []
        owner = target_switch['owner']

        return owner, candidates

    @classmethod
    def get_node_membership(cls, node_ip):
        """Gets cluster member by ip

        Args:
            :param node_ip: ip of cluster node

        Returns:
            :returns cluster member
        """
        return cls.cluster_nodes[node_ip]['member']

    @classmethod
    @_repeat_until_succeess
    def check_member(cls, switch_name, callback=_blank_check_callback):
        """Gets owner and candidates of switch and return result of callback method

        Args:
            :param switch_name: name of switch
            :param callback: callback method ran with owner and candidates as parameters

        Returns:
            :returns results of callback method
        """
        cls._logger.debug('Checking switch members and owner data')
        switch_id = cls._get_entity_switch_id(switch_name)

        cls.reload_data()

        owner, candidates = cls._get_owner_and_candidates(switch_id)
        cls._logger.debug('Switch Id: %s, Candidate names: %s, Owner: %s', switch_id, candidates, owner)

        return callback(candidates, owner)

    @classmethod
    def take_node(cls):
        """Takes a random free cluster node and add it to pool of isolated nodes

        Returns:
            :returns Cluster node ip
        """
        free_nodes = cls.get_free_nodes()

        try:
            if len(free_nodes) <= 2:  # need to have at least 2 nodes to make a cluster
                raise IndexError

            # node_ip = [n for n in list(free_nodes) if cls.cluster_nodes[n]['leader']][0]
            node_ip = random.choice(list(free_nodes))
            cls._isolated_nodes.append(node_ip)
        except IndexError:
            node_ip = None

        return node_ip

    @classmethod
    def return_node(cls, node):
        """Remove node from pool of isolated nodes

        Args:
            :param node: node ip address

        Returns:
            :returns None
        """
        cls._isolated_nodes.remove(node)
        return None

    @classmethod
    def is_node_isolated(cls, node):
        """Remove node from pool of isolated nodes

        Args:
            :param node: node ip address

        Returns:
            :returns True/False based on whether node is present in pool of isolated nodes
        """
        return node in cls._isolated_nodes


class OVSData(object):
    """Object wrapping OVS data gathering and parsing
    """

    data = {}
    bridges = {}
    ctrls = {}
    _occupied_controllers = []

    _logger = logging.getLogger('Monkey.OVSData')
    _invalid = True

    @classmethod
    def invalidate(cls):
        """Invalidate data, sets invalid flag to True
        """
        cls._invalid = True

    @classmethod
    def _is_free_controller(cls, ctrl):
        """Determine if controller is free

        Args:
            :param ctrl: from controllers data structure parsed by VsctlListParser

        Returns:
            :returns True/False
        """
        target_parts = ctrl['target'].split(':')

        return ctrl not in cls._occupied_controllers and \
            len(target_parts) == 3 and \
            ctrl['is_connected'] == 'true' and \
            not ClusterData.is_node_isolated(target_parts[1])  # and ctrl['role'] == 'master'

    @classmethod
    def init(cls):
        """Method to populate controller, bridge, bridge-controller and free controllers data

        It needs to be called before a monkey will try to take some controller
        """

        cls.reload_data()
        cls._logger.debug('Got bridge-controller data \n%s', json.dumps(cls.data, indent=4, separators=(',', ': ')))
        cls._logger.debug('Got controller data \n%s', json.dumps(cls.ctrls, indent=4, separators=(',', ': ')))
        cls._logger.debug('Got bridge data \n%s', json.dumps(cls.bridges, indent=4, separators=(',', ': ')))
        cls._logger.info('OVSData init done...')

    @classmethod
    def reload_data(cls):
        """Reloads data - only if invalid flag is set to True
        """
        if cls._invalid:
            cls._logger.debug('Getting Bridges and Controller data')

            bridges_raw = subprocess.check_output(['ovs-vsctl', 'list', 'Bridge'])
            ctrls_raw = subprocess.check_output(['ovs-vsctl', 'list', 'Controller'])

            cls.data, cls.bridges, cls.ctrls = VsctlListParser.parse(bridges_raw, ctrls_raw)
            cls._invalid = False

    @classmethod
    def get_controller_switch(cls, controller_ip, controller_uuid):
        """Gets switch that has associated connection to controller, specified by parameters

        Args:
            :param controller_ip: ip of controller
            :param controller_uuid: uuid of controller connection

        Returns:
            :returns name of OVS switch
        """
        cls._logger.debug('Gettings switch from... %s, by IP: %s and UUID: %s',
                          cls.data.keys(), controller_ip, controller_uuid)
        switch = [k for k, v in cls.data.items() if v['controller'][controller_ip]['_uuid'] == controller_uuid][0]

        return switch

    @classmethod
    def take_controller(cls):
        """Takes a random free controller connection and add it to pool of occupied ones

        Returns:
            :returns controller data structrue parsed by VsctlListParser
        """
        cls._logger.debug('Getting free controllers from %s', cls.ctrls.keys())
        free_controllers = [ctrl for ctrl in cls.ctrls.values() if cls._is_free_controller(ctrl)]

        try:
            controller = random.choice(free_controllers)
            cls._occupied_controllers.append(controller)
        except IndexError:
            controller = None

        return controller

    @classmethod
    def return_controller(cls, controller):
        """Remove controller connection from pool of occupied connections

        Args:
            :param controller: controller data structrue parsed by VsctlListParser

        Returns:
            :returns None
        """
        cls._occupied_controllers.remove(controller)

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
            self._logger.debug('Making chaos')
            self._make_chaos()
            self._logger.debug('Sleeping for %s', self._interval)
            time.sleep(self._interval)
            self._logger.debug('Cleaning up')
            self._clean_up()

        self._logger.info('Monkey stopped')

    def stop(self):
        self._logger.info('Stopping monkey')
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
        """Executes ovs-vsctl command to set invalid port 6654 to contoller connection, which simulates disconnect
        """
        new_target = 'target="tcp:' + self._get_controller_ip(self._controller) + ':6654"'

        self._logger.info('Disconnecting link to controller with UUID %s to target %s',
                          self._controller['_uuid'], self._controller['target'])
        self._logger.debug('Changing target to %s', new_target)

        cmd_list = ['ovs-vsctl', 'set', 'Controller', self._controller['_uuid'], new_target]
        retval = subprocess.call(cmd_list)
        self._logger.debug('Call %s returns %s', ' '.join(cmd_list), retval)

    def _execute_reconnect_command(self):
        """Executes ovs-vsctl command to set valid port 6633 to contoller connection, which simulates reconnection
        """
        new_target = 'target="tcp:' + self._get_controller_ip(self._controller) + ':6633"'

        self._logger.info('Reconnecting link to controller with UUID %s to target %s',
                          self._controller['_uuid'], self._controller['target'])
        self._logger.debug('Changing target to %s', new_target)

        cmd_list = ['ovs-vsctl', 'set', 'Controller', self._controller['_uuid'], new_target]
        retval = subprocess.call(cmd_list)
        self._logger.debug('Call %s returns %s', ' '.join(cmd_list), retval)

    @classmethod
    def _get_link_state(cls, controller_uuid):
        """Get connection state of link
        """
        return OVSData.ctrls[controller_uuid]['is_connected']

    @classmethod
    def _get_controller_ip(cls, controller):
        """Get IP of connected controller
        """
        return controller['target'].split(':')[1]

    def _disconnect(self):
        """Disconnects controller from switch and invalidate OVS data
        """
        self._execute_disconnect_command()
        OVSData.invalidate()

    def _reconnect(self):
        """Reconnects controller from switch and invalidate OVS data
        """
        self._execute_reconnect_command()
        OVSData.invalidate()

    def _make_chaos(self):
        """Disturbs controller connection by doing following:

        1. Get free connection
        2. Disconnects connection
        3. Check connection status
        4. Check entity ownership data
        5. Check cluster data integrity
        """
        self._logger.debug('Trying to acquire lock')
        general_lock.acquire()
        self._logger.debug('Lock acquired - locking')

        self._controller = OVSData.take_controller()

        if self._controller is not None:
            TestResults._disconnect_run_count += 1
            controller_uuid = self._controller['_uuid']
            controller_ip = self._get_controller_ip(self._controller)
            member = ClusterData.get_node_membership(controller_ip)
            ovs_sw = OVSData.get_controller_switch(controller_ip, controller_uuid)
            odl_sw = _ovs_switch_odl_name(ovs_sw)
            master_member = ClusterData.get_master(odl_sw)

            def member_not_in_candidates_or_owner(candidates, owner):
                # verify election of new master, if we'd chosen master switch
                election_check = master_member != owner \
                    if ClusterData.get_node_membership(controller_ip) == master_member \
                    else True

                member_not_present_check = member not in candidates and member != owner

                return election_check and member_not_present_check

            self._logger.info('Taking controller uuid: %s, at %s (membership %s), linked to switch %s (odl: %s)',
                              controller_uuid, controller_ip, member, ovs_sw, odl_sw)
            self._disconnect()

            self._logger.info('Checking connection status after disconnecting switch %s', controller_uuid)
            result = self._test_connection_status('false', 5, 10)
            self._logger.info('Controller connection status after disconnect... %s', 'ok' if result else 'notok')

            self._logger.info('Checking Cluster data with if member %s is not present as candidate in %s',
                              member, odl_sw)
            result = ClusterData.check_member(True, 5, 5, odl_sw, member_not_in_candidates_or_owner)
            self._logger.info('Disconnected controller %s is not present as candidate or owner in %s... %s',
                              member, odl_sw, 'ok' if result else 'notok')

            result = ClusterData.check_data_integrity(True, 5, 5)
            self._logger.info('Data ingerity on cluster nodes after chaos is made... %s', 'ok' if result else 'notok')
        else:
            self._logger.info('Cannot get free connection, waiting...')

        self._logger.debug('Unlocking')
        general_lock.release()

    def _clean_up(self):
        """Reestablish controller connection by doing following:

        1. Reconnects connection
        2. Check connection status
        3. Check entity ownership data
        4. Check cluster data integrity
        5. Return controller connection
        """
        if self._controller is not None:
            self._logger.debug('Trying to acquire lock')
            general_lock.acquire()
            self._logger.debug('Lock acquired - locking')

            controller_uuid = self._controller['_uuid']
            controller_ip = self._get_controller_ip(self._controller)
            member = ClusterData.get_node_membership(controller_ip)
            ovs_sw = OVSData.get_controller_switch(controller_ip, controller_uuid)
            odl_sw = _ovs_switch_odl_name(ovs_sw)

            def member_in_candidates(candidates, owner):
                free_nodes = ClusterData.get_free_nodes()

                member_present = member in candidates
                is_member_free = member in free_nodes

                # if the node is taken and isolated by cluster isolating monkey, skip check
                return member_present if is_member_free else True

            self._reconnect()

            self._logger.info('Checking connection status after reconnecting switch %s', controller_uuid)
            result = self._test_connection_status('true', 5, 10)
            self._logger.info('Controller connection status after reconnect... %s', 'ok' if result else 'notok')

            self._logger.info('Checking Cluster data with if member %s is present as candidate in %s', member, odl_sw)
            result = ClusterData.check_member(True, 5, 5, odl_sw, member_in_candidates)
            self._logger.info('Reconnected controller %s is present as candidate in %s... %s',
                              member, odl_sw, 'ok' if result else 'notok')

            result = ClusterData.check_data_integrity(True, 5, 5)
            self._logger.info('Data ingerity on cluster nodes after chaos is made... %s', 'ok' if result else 'notok')

            self._controller = OVSData.return_controller(self._controller)

            self._logger.debug('Unlocking')
            general_lock.release()
        else:
            self._logger.info('No connection taken, nothing to cleanup...')

    @_repeat_until_succeess
    def _test_connection_status(self):
        """Checks if controller connection is in expected state
        """
        self._logger.debug('Testing connection status, invalidating and reloading data')
        OVSData.invalidate()
        OVSData.reload_data()
        return self._get_link_state(self._controller['_uuid'])


class ClusterNodeIsolatingMonkey(Monkey):
    """Monkey for isolating cluster node
    """

    _CMD_TEMPLATE = 'sudo /sbin/iptables {cmd} OUTPUT -p all --source {src} --destination {dst} -j DROP'
    _USER = 'odl'
    _PASSWORD = 'cisco'

    def __init__(self, interval):
        super(ClusterNodeIsolatingMonkey, self).__init__(interval)
        self._cluster_node = None
        self._other_nodes = []

    def _get_other_controllers(self):
        """Get other nodes that currently selected one

        Returns:
            :returns list of cluster nodes
        """
        return [dict(ip=node, conn=None) for node in ClusterData.cluster_nodes.keys() if node != self._cluster_node]

    def _isolate_nodes(self):
        """Isolates cluster node by alering IPtables on other nodes in cluster
        """
        member = ClusterData.get_node_membership(self._cluster_node)
        self._logger.info('Isolating node %s (member %s)...', self._cluster_node, member)

        for node in self._other_nodes:
            self._logger.debug('Isolating node %s from %s...', self._cluster_node, node['ip'])

            node['conn'] = self._connect_to_node(node['ip'], self._USER, self._PASSWORD)
            self._modify_iptables_single_node(node['conn'], '-I', self._cluster_node, node['ip'])

    def _reconnect_nodes(self):
        """Reconnects cluster node by alering IPtables on other nodes in cluster
        """
        member = ClusterData.get_node_membership(self._cluster_node)
        self._logger.info('Reconnecting node %s (member %s)...', self._cluster_node, member)

        for node in self._other_nodes:
            self._logger.debug('Reconnecting node %s to %s...', self._cluster_node, node['ip'])

            self._modify_iptables_single_node(node['conn'], '-D', self._cluster_node, node['ip'])
            node['conn'].close_connection()

    def _connect_to_node(self, node, user, password):
        """Establishes ssh connection to node and returns it

        Args:
            :param node: ip of cluster node
            :param user: username
            :param password: password

        Returns:
            :returns ssh connection
        """
        connection = SSHLibrary()
        connection.open_connection(node)
        connection.login(username=user, password=password)

        return connection

    def _modify_iptables_single_node(self, connection, cmd, target_node, other_node):
        """Executes commands to alter IPtables

        Args:
            :param cmd: command to execute
            :param target_node: taken cluster node
            :param other_node: other node in cluster
        """
        command = self._CMD_TEMPLATE.format(cmd=cmd, src=target_node, dst=other_node)
        _, rc = connection.execute_command(command, return_rc=True)
        self._logger.debug('Command to isolate node %s returned %s', command, rc)

        command = self._CMD_TEMPLATE.format(cmd=cmd, src=other_node, dst=target_node)
        _, rc = connection.execute_command(command, return_rc=True)
        self._logger.debug('Command to isolate node %s returned %s', command, rc)

    @_repeat_until_succeess
    def _check_new_leader_elected(self):
        """Checks if new leader has been elected
        """
        self._logger.debug('Testing if new leader is elected')
        leader = ClusterData.get_operational_leader()
        return leader is not None

    def _make_chaos(self):
        """Isolate cluster node by doing following actions:

        1. Take free cluster node
        2. Get other nodes in cluster
        3. Isolate taken node from other cluster nodes
        4. If the isolated node was leader, check if new leader is elected
        """
        self._logger.debug('Trying to acquire lock')
        general_lock.acquire()
        self._logger.debug('Lock acquired - locking')

        self._cluster_node = ClusterData.take_node()

        if self._cluster_node is not None:
            TestResults._isolate_run_count += 1

            self._other_nodes = self._get_other_controllers()
            self._isolate_nodes()

            if ClusterData.is_node_leader(self._cluster_node):
                result = self._check_new_leader_elected(True, 3, 3)
                self._logger.info('New leader elected... %s', 'ok' if result else 'notok')
            ClusterData.reload_data()
        else:
            self._logger.info('No free cluster node available...')

        self._logger.debug('Unlocking')
        general_lock.release()

    def _clean_up(self):
        """Rejoin cluster node by doing following actions:

        1. Reconnects other nodes in cluster to selected node
        2. Return taken node
        3. Wait until node is rejoined
        """
        if self._cluster_node is not None:
            self._logger.debug('Trying to acquire lock')
            general_lock.acquire()
            self._logger.debug('Lock acquired - locking')

            self._reconnect_nodes()
            self._other_nodes = []
            self._cluster_node = ClusterData.return_node(self._cluster_node)

            time.sleep(5)  # Wait until node reconnects

            self._logger.debug('Unlocking')
            general_lock.release()
        else:
            self._logger.info('No cluster node taken, nothing to clean up...')


def _handler(signum, frame):
    global _stop
    _stop = True


def start_monkey(monkey_count, interval, run_time, logfile, dumpfile, loglevel, cluster_nodes):
    """Start monkey test

    Args:
        :param monkey_count: count of CtrlSwitchLinkDisconnectingMonkey monkeys
        :param interval: duration of time between making chaos and cleaning up
        :param run_time: total duration of test
        :param logfile: filename for logs
        :param dumpfile: filename for data dump
        :param loglevel: log level
        :param cluster_nodes: IP addresses of cluster nodes
    """
    global _stop
    mgsfmt = '[%(asctime)s] %(levelname)7s %(name)50s %(threadName)10s %(funcName)30s: %(lineno)s: %(message)s'
    datefmt = '%Y/%m/%d %H:%M:%S'
    formatter = logging.Formatter(mgsfmt, datefmt=datefmt)
    logging.basicConfig(format=mgsfmt, datefmt=datefmt, level=loglevel, filename=logfile)
    signal.signal(signal.SIGINT, _handler)

    data_dump_handler = logging.FileHandler(dumpfile)
    data_dump_handler.setFormatter(formatter)
    _data_dump_logger.addHandler(data_dump_handler)

    OVSData.init()
    ClusterData.init(*cluster_nodes)

    a = Army()

    for i in range(monkey_count):
        a.add_monkey(CtrlSwitchLinkDisconnectingMonkey(interval))

    # Cluster Node Isolating monkey is temporary disabled, because it breaks ssh connection
    # m = ClusterNodeIsolatingMonkey(10)
    # a.add_monkey(m)

    TestResults.start_time_tracking()

    a.start()
    while True:
        if _stop:
            print('Exiting...')
            a.stop()
            break

        if TestResults.get_elapsed_time() > run_time:
            _root_logger.info('Test time has passed, stopping...')
            _stop = True
        time.sleep(1)

    TestResults.log_results()
    TestResults.save_plot_data()

    if TestResults.has_failed():
        sys.exit(1)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Automated monkey test script for Openflow Cluster")
    parser.add_argument("--monkey-count", type=int, default=3, help="Number of monkeys created.")
    parser.add_argument("--interval", type=int, default=15,
                        help="Number of seconds each monkey will wait before performing action")
    parser.add_argument("--run-time", type=int, default=100, help="Number of seconds the test will run")
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
    parser.add_argument("--dumpfile", default="dump-monkey.log", help="Data dump file name in case of invalid state")

    args = parser.parse_args()

    try:
        start_monkey(**vars(args))
    except StandardError as e:
        stack_trace = traceback.format_exc()
        _root_logger.error(stack_trace)
        _dump_data()
        TestResults.save_plot_data()
        sys.exit(1)

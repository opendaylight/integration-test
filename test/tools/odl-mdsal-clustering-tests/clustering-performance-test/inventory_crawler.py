#!/usr/bin/python
__author__ = "Jan Medved"
__copyright__ = "Copyright(c) 2014, Cisco Systems, Inc."
__license__ = "New-style BSD"
__email__ = "jmedved@cisco.com"

import argparse
import requests
import re
import json


class InventoryCrawler(object):
    reported_flows = 0
    found_flows = 0
    nodes = 0

    INVENTORY_URL = 'restconf/%s/opendaylight-inventory:nodes'
    hdr = {'Accept': 'application/json'}
    OK, ERROR = range(2)
    table_stats_unavailable = 0
    table_stats_fails = []

    def __init__(self, host, port, plevel, datastore, auth, debug):
        self.url = 'http://' + host + ":" + port + '/' + self.INVENTORY_URL % datastore
        self.plevel = plevel
        self.auth = auth
        self.debug = debug


    def crawl_flows(self, flows):
        """
        Collects and prints summary information for all flows in a table
        """
        self.found_flows += len(flows)
        if self.plevel > 1:
            print '             Flows found: %d\n' % len(flows)
            if self.plevel > 2:
                for f in flows:
                    s = json.dumps(f, sort_keys=True, indent=4, separators=(',', ': '))
                    # s = s.replace('{\n', '')
                    # s = s.replace('}', '')
                    s = s.strip()
                    s = s.lstrip('{')
                    s = s.rstrip('}')
                    s = s.replace('\n', '\n            ')
                    s = s.lstrip('\n')
                    print "             Flow %s:" % f['id']
                    print s


    def crawl_table(self, table):
        """
        Collects and prints summary statistics information about a single table. Depending on the print level
        (plevel), it also invokes the crawl_flows
        """
        try:
            stats = table['opendaylight-flow-table-statistics:flow-table-statistics']
            active_flows = int(stats['active-flows'])

            if active_flows > 0:
                self.reported_flows += active_flows
                if self.plevel > 1:
                    print '        Table %s:' % table['id']
                    s = json.dumps(stats, sort_keys=True, indent=12, separators=(',', ': '))
                    s = s.replace('{\n', '')
                    s = s.replace('}', '')
                    print s
        except KeyError:
            if self.plevel > 1:
                print "        Stats for Table '%s' not available." % table['id']
            self.table_stats_unavailable += 1
            pass

        try:
            flows_in_table = table['flow']
            self.crawl_flows(flows_in_table)
        except KeyError:
            pass


    def crawl_node(self, node):
        """
        Collects and prints summary information about a single node
        """
        self.table_stats_unavailable = 0
        self.nodes += 1

        if self.plevel > 1:
            print "\nNode '%s':" % (node['id'])
        elif self.plevel > 0:
            print "%s" % (node['id'])

        try:
            tables = node['flow-node-inventory:table']
            if self.plevel > 1:
                print '    Tables: %d' % len(tables)

            for t in tables:
                self.crawl_table(t)

            if self.table_stats_unavailable > 0:
                self.table_stats_fails.append(node['id'])

        except KeyError:
            if self.plevel > 1:
                print '    Data for tables not available.'


    def crawl_inventory(self):
        """
        Collects and prints summary information about all openflow nodes in a data store (either operational or config)
        """
        self.found_flows = 0
        self.reported_flows = 0
        self.table_stats_unavailable = 0
        self.table_stats_fails = []

        s = requests.Session()
        if not self.auth:
            r = s.get(self.url, headers=self.hdr, stream=False)
        else:
            r = s.get(self.url, headers=self.hdr, stream=False, auth=('admin', 'admin'))

        if r.status_code == 200:
            try:
                inv = json.loads(r.content)['nodes']['node']
                sinv = []
                for n in range(len(inv)):
                    if re.search('openflow', inv[n]['id']) is not None:
                        sinv.append(inv[n])

                sinv = sorted(sinv, key=lambda k: int(re.findall('\d+', k['id'])[0]))

                for n in range(len(sinv)):
                    try:
                        self.crawl_node(sinv[n])
                    except:
                        print 'Can not crawl %s' % sinv[n]['id']

            except KeyError:
                print 'Could not retrieve inventory, response not in JSON format'
        else:
            print 'Could not retrieve inventory, HTTP error %d' % r.status_code

        s.close()


    def set_plevel(self, plevel):
        self.plevel = plevel




if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Restconf test program')
    parser.add_argument('--host', default='127.0.0.1', help='host where '
                                                               'odl controller is running (default is 127.0.0.1)')
    parser.add_argument('--port', default='8181', help='port on '
                                                          'which odl\'s RESTCONF is listening (default is 8181)')
    parser.add_argument('--plevel', type=int, default=0,
                        help='Print Level: 0 - Summary (stats only); 1 - Node names; 2 - Node details;'
                             '3 - Flow details')
    parser.add_argument('--datastore', choices=['operational', 'config'],
                        default='operational', help='Which data store to crawl; '
                                                    'default operational')
    parser.add_argument('--no-auth', dest='auth', action='store_false', default=False,
                        help="Do not use authenticated access to REST (default)")
    parser.add_argument('--auth', dest='auth', action='store_true',
                        help="Use authenticated access to REST (username: 'admin', password: 'admin').")
    parser.add_argument('--debug', dest='debug', action='store_true', default=False,
                        help="List nodes that have not provided proper statistics data")

    in_args = parser.parse_args()

    ic = InventoryCrawler(in_args.host, in_args.port, in_args.plevel, in_args.datastore, in_args.auth,
                          in_args.debug)

    print "Crawling '%s'" % ic.url
    ic.crawl_inventory()

    print '\nTotals:'
    print '    Nodes:          %d' % ic.nodes
    print '    Reported flows: %d' % ic.reported_flows
    print '    Found flows:    %d' % ic.found_flows

    if in_args.debug:
        n_missing = len(ic.table_stats_fails)
        if n_missing > 0:
            print '\nMissing table stats (%d nodes):' % n_missing
            print "%s\n" % ", ".join([x for x in ic.table_stats_fails])



__author__ = "Jan Medved"
__copyright__ = "Copyright(c) 2014, Cisco Systems, Inc."
__license__ = "New-style BSD"
__email__ = "jmedved@cisco.com"

from operator import itemgetter, attrgetter
import argparse
import requests
# import time
# import threading
import re
import json

INVENTORY_URL = 'restconf/%s/opendaylight-inventory:nodes'
hdr = {'Accept': 'application/json'}

# Inventory totals
reported_flows = 0
found_flows = 0
nodes = 0

def crawl_flows(flows):
    global found_flows

    found_flows += len(flows)
    if in_args.plevel > 1:
        print '             Flows found: %d' % len(flows)
        if in_args.plevel > 2:
            for f in flows:
                s = json.dumps(f, sort_keys=True, indent=4, separators=(',', ': '))
                # s = s.replace('{\n', '')
                # s = s.replace('}', '')
                s = s.strip()
                s = s.lstrip('{')
                s = s.rstrip('}')
                s = s.replace('\n', '\n            ')
                s = s.lstrip('\n')
                print "             Flow %s:" % f['flow-node-inventory:id']
                print s



def crawl_table(table):
    global reported_flows

    try:
        stats = table['opendaylight-flow-table-statistics:flow-table-statistics']
        active_flows = stats['opendaylight-flow-table-statistics:active-flows']

        if active_flows > 0:
            reported_flows += active_flows
            if in_args.plevel > 1:
                print '        Table %s:' % table['flow-node-inventory:id']
                s = json.dumps(stats, sort_keys=True, indent=12, separators=(',', ': '))
                s = s.replace('{\n', '')
                s = s.replace('}', '')
                print s
    except:
        print "        Stats for Table '%s' not available." %  \
              table['flow-node-inventory:id']

    try:
        flows_in_table = table['flow-node-inventory:flow']
        crawl_flows(flows_in_table)
    except(KeyError):
        pass



def crawl_node(node):
    global nodes
    nodes = nodes + 1
    if in_args.plevel > 1:
        print "\nNode '%s':" %(node['id'])
    elif in_args.plevel > 0:
        print "%s" %(node['id'])

    try:
        tables = node['flow-node-inventory:table']
        if in_args.plevel > 1:
            print '    Tables: %d' % len(tables)

        for t in tables:
            crawl_table(t)
    except:
        print '    Data for tables not available.'

#    print json.dumps(tables, sort_keys=True, indent=4, separators=(',', ': '))

def crawl_inventory(url):
    s = requests.Session()
    r = s.get(url, headers=hdr, stream=False)

    if (r.status_code == 200):
        try:
            inv = json.loads(r.content)['nodes']['node']
            sinv = []
            for n in range(len(inv)):
                if re.search('openflow', inv[n]['id']) != None:
                    sinv.append(inv[n])

#            sinv = sorted(sinv, key=lambda k: int(k['id'].split(':')[-1]))
            try:
                sinv = sorted(sinv, key=lambda k: int(re.findall('\d+', k['id'])[0]))
                for n in range(len(sinv)):
                    crawl_node(sinv[n])
            except:
                print 'Fuck! %s' % sinv[n]['id']

        except(KeyError):
            print 'Could not retrieve inventory, response not in JSON format'
    else:
        print 'Could not retrieve inventory, HTTP error %d' % r.status_code



if __name__ == "__main__":

    parser = argparse.ArgumentParser(description='Restconf test program')
    parser.add_argument('--odlhost', default='127.0.0.1', help='host where '
                        'odl controller is running (default is 127.0.0.1)')
    parser.add_argument('--odlport', default='8080', help='port on '
                        'which odl\'s RESTCONF is listening (default is 8080)')
    parser.add_argument('--plevel', type=int, default=0, help='Print level: '
                        '0 - Summary (just stats); 1 - Node names; 2 - Node details; '
                         '3 - Flow details')
    parser.add_argument('--datastore', choices=['operational', 'config'], \
                        default='operational', help='Which data store to crawl; '
                        'default operational')

    in_args = parser.parse_args()

    url = 'http://' + in_args.odlhost + ":" + in_args.odlport + '/' + \
          INVENTORY_URL % in_args.datastore

    print "Crawling '%s'" % url

    crawl_inventory(url)

    print '\nTotals:'
    print '    Nodes:          %d' % nodes
    print '    Reported flows: %d' % reported_flows
    print '    Found flows:    %d' % found_flows



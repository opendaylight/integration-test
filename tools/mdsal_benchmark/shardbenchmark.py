#!/usr/bin/python

import argparse
import requests
import json
import csv
import time
import re
import string

__author__ = "Peter Gubka"
__copyright__ = "Copyright(c) 2016, Cisco Systems, Inc."
__license__ = "New-style BSD"
__email__ = "pgubka@cisco.com"


parser = argparse.ArgumentParser(description='Sharding Simple Benchmarking'
                                             ''
                                             'See documentation @:'
                                             'https://wiki.opendaylight.org/view/Controller_Core_Functionality_Tutorials:Tutorials:Data_Store_Benchmarking_and_Data_Access_Patterns'  # noqa
                                             '')

# Host Config
parser.add_argument("--host", default="localhost", help="the IP of the target host to initiate benchmark testing on.")
parser.add_argument("--port", type=int, default=8181, help="the port number of target host.")

# Test Parameters
parser.add_argument("--test-type", choices=["ROUND-ROBIN", "MULTI-THREADED", "SOAK-TEST", "RANDOM-SHARD"], nargs='+', default=["ROUND-ROBIN"], dest="test_type",
                    help="List of the test types to execute.")
parser.add_argument("--datastore", choices=["CONFIG", "OPERATIONAL"], nargs='+',
                    default=["OPERATIONAL", "CONFIG"], help="data-store type (config/operational) to use")
parser.add_argument("--shard-type", choices=["INMEMORY", "CDS"], nargs='+', default=["INMEMORY"], dest="shard_type",
                    help="List of the shard types to execute.")
parser.add_argument("--dataitems", type=int, default=100, help="Number of per-shard data items.")
parser.add_argument("--shards", type=int, default=1, help="Total number of created shards.")
parser.add_argument("--operations", type=int, default=100, help="Number of operations durinf SOAK-TEST.")
parser.add_argument("--putspertx", type=int, default=1, help="Number of write operations before submit.")
parser.add_argument("--listeners", type=int, default=0, help="Number of data tree change listeners listening for changes on the test exec tree.")
parser.add_argument("--precreate-data", action='store_true', default=False, help="Specifies whether test data should be pre-created before pushing it into the data store.")
parser.add_argument("--validate-data", action='store_true', default=False, help="Specifies whether the written data should be validated.")

# Test repetitions
parser.add_argument("--warmups", type=int, default=3, help="number of warmup runs before official test runs")
parser.add_argument("--runs", type=int, default=10, help="number of official test runs. Note: Reported results are based on these runs.")

# Output
parser.add_argument("--output", choices=["STDOUT-JSON", "FILE-JSON", ], nargs='+', default=["STDOUT-JSON"], help="Requested output")
args = parser.parse_args()

#def run_test(test_type, datastore, shard_type):
def run_test(mapping):
    """
    Sends a request to the dsbenchmark app to start a data store benchmark test run.
    The dsbenchmark app will perform the requested benchmark test and return measured
    transaction times
    :param operation: PUT, MERGE, DELETE or READ
    :param data_fmt: BINDING-AWARE or BINDING-INDEPENDENT
    :param datastore: OPERATIONAL, CONFIG or BOTH
    :param outer_elem: Number of elements in the outer list
    :param inner_elem: Number of elements in the inner list
    :param ops_per_tx: Number of operations (PUTs, MERGEs or DELETEs) on each transaction
    :return:
    """
    url = "http://{}:{}/restconf/operations/shardingsimple:shard-test".format(args.host, args.port)
    postheaders = {'content-type': 'application/json', 'Accept': 'application/json'}

    test_request_template = '''{
        "input": {
            "test-type": "%s",
            "data-store": "%s",
            "shards": "%s",
            "shard-type": "%s",
            "dataItems": %d,
            "operations": %d,
            "putsPerTx": %d,
            "listeners": %d,
            "precreate-data": %s,
            "validate-data": %s
        }
    }'''
    test_request_template2 = '''{
        "input": {
            "test-type": "$TEST_TYPE",
            "data-store": "$DATASTORE",
            "shards": "$SHARDS",
            "shard-type": "$SHARDTYPE",
            "dataItems": $DATAITEMS,
            "operations": $OPERATIONS,
            "putsPerTx": $PUTSPERTX,
            "listeners": $LISTENERS,
            "precreate-data": $PRECREATEDATA,
            "validate-data": $VALIDATEDATA
        }
    }'''

    data = string.Template(test_request_template2.rstrip()).safe_substitute(mapping)
    #data = test_request_template % (test_type, datastore, args.shards, shard_type, args.dataitems, args.operations, args.putspertx, args.listeners, args.precreate_data, args.validate_data)
    r = requests.post(url, data, headers=postheaders, stream=False, auth=('admin', 'admin'))
    result = {u'http-status': r.status_code}
    if r.status_code == 200:
        result = dict(result.items() + json.loads(r.content)['output'].items())
    else:
        print 'Error %s, %s' % (r.status_code, r.content)
    return result


def store_result(values, tx_type, operation, data_fmt, datastore,
                 outer_elem, inner_elem, ops_per_tx, value_name, value):
    """
    Stores a record to the list (dictionary) of values to be written into a csv file for plotting purposes.
    :param values: The list (dictionary) to be used for storing the result
    :param operation: PUT, MERGE or DELETE
    :param data_fmt: BINDING-AWARE or BINDING-INDEPENDENT
    :param datastore: OPERATIONAL, CONFIG or BOTH
    :param outer_elem: Number of elements in the outer list
    :param inner_elem: Number of elements in the inner list
    :param ops_per_tx: Number of operations (PUTs, MERGEs or DELETEs) on each transaction
    :param value_name: Value name (name for the measured value)
    :param value: The (measured) value
    :return: none
    """
    plot_key = (datastore + '-' + data_fmt + '-' + tx_type + '-' + operation + '-' + str(outer_elem) + '/' +
                str(inner_elem) + 'OUTER/INNER-' + str(ops_per_tx) + 'OP-' + value_name)
    values[plot_key] = value


def write_results_to_file(values, file_name, key_filter):
    """
    Writes specified results (values) into the file (file_name). Results are filtered according to key_filter value.
    Produces a csv file consumable by Jnekins integration environment.
    :param file_name: Name of the (csv) file to be created
    :param values: The list (dictionary) to be written into the file
    :param key_filter: A regexp string to filter the results to be finally put into the file
    :return: none
    """
    first_line = ''
    second_line = ''
    f = open(file_name, 'wt')
    try:
        for key in sorted(values):
            if (key_filter != 'none') & ((key_filter == 'all') | (re.search(key_filter, key) is not None)):
                first_line += key + ','
                second_line += str(values[key]) + ','
        first_line = first_line[:-1]
        second_line = second_line[:-1]
        f.write(first_line + '\n')
        f.write(second_line + '\n')
    finally:
        f.close()


if __name__ == "__main__":

    for i in range(args.warmups):
        for test_type in args.test_type:
           for ds in args.datastore:
               for sht in args.shard_type:
                   request_args = { "TEST_TYPE":test_type, "DATASTORE": ds, "SHARDS": args.shards, "SHARDTYPE": sht, "DATAITEMS": args.dataitems, "OPERATIONS": args.operations,
                               "PUTSPERTX": args.putspertx, "LISTENERS": args.listeners, "PRECREATEDATA": args.precreate_data, "VALIDATEDATA": args.validate_data }
                   test_result = run_test(request_args)
                   #test_result = run_test(test_type, ds, sht)
                   print request_args
                   print test_result

#    for i in range(args.runs):
#        for test_type in args.test_type:
#            for ds in args.datastore:
#
#                test_result = run_test(test_type)
#        store_and_print(test_result)


    
        

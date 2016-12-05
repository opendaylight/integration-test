#!/usr/bin/python

import argparse
import requests
import json
import csv
import string

__author__ = "Peter Gubka"
__copyright__ = "Copyright(c) 2016, Cisco Systems, Inc."
__license__ = "New-style BSD"
__email__ = "pgubka@cisco.com"

import sys
print "Arguments {}.".format(sys.argv)

parser = argparse.ArgumentParser(description='Sharding Simple Benchmarking')

# Host Config
parser.add_argument("--hosts", default="127.0.0.1", help="Comma separated list of controller's ip addresses")
parser.add_argument("--port", type=int, default=8181, help="the port number of target host.")

# Test Parameters
parser.add_argument("--test-type", choices=["ROUND-ROBIN", "MULTI-THREADED", "SOAK-TEST", "RANDOM-SHARD"], nargs='+', default=["ROUND-ROBIN"], dest="test_type",
                    help="List of the test types to execute.")
parser.add_argument("--datastore", choices=["CONFIG", "OPERATIONAL"], nargs='+',
                    default=["CONFIG"], help="data-store type (config/operational) to use")
parser.add_argument("--shard-type", choices=["INMEMORY", "CDS"], nargs='+', default=["INMEMORY"], dest="shard_type",
                    help="List of the shard types to execute.")
parser.add_argument("--totaldataitems", default=[100], nargs='+', help="Total number data items in all shards.")
parser.add_argument("--shards", default=[1], nargs='+', help="Total number of created shards.")
parser.add_argument("--operations", default=[1], nargs='+', help="Number of operations durinf SOAK-TEST.")
parser.add_argument("--putspertx", default=[1], help="Number of write operations before submit.")
parser.add_argument("--listeners", default=[0], nargs='+', help="Number of data tree change listeners listening for changes on the test exec tree.")
parser.add_argument("--precreate-data", action='store_true', default=False, help="Specifies whether test data should be pre-created before pushing it into the data store.")
parser.add_argument("--validate-data", action='store_true', default=False, help="Specifies whether the written data should be validated.")


# Test repetitions
parser.add_argument("--warmups", type=int, default=3, help="number of warmup runs before official test runs")
parser.add_argument("--runs", type=int, default=10, help="number of official test runs. Note: Reported results are based on these runs.")

# Output
parser.add_argument("--csv", default=None, help="Csv file name to store overall results.")
parser.add_argument("--fulldata", default=None, help="Json file with all requests and responce data.")

args = parser.parse_args()

#def run_test(test_type, datastore, shard_type):
def run_test(mapping, warmup=False):
    """
    Sends a request to the dsbenchmark app to start a data store benchmark test run.
    The dsbenchmark app will perform the requested benchmark test and return measured
    transaction times
    :param mapping: a dict with data to fill the input template
    :param warmup: boolean to indicate warmup vs. regular test
    :return result: a dict with data received
    """
    url = "http://{}:{}/restconf/operations/shardingsimple:shard-test".format(mapping['host'], args.port)
    postheaders = {'content-type': 'application/json', 'Accept': 'application/json'}

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

    note_prefix = "Warmup test" if warmup else "Test"
    print "{} starting with details: {}".format(note_prefix, mapping)
    data = string.Template(test_request_template2.rstrip()).safe_substitute(mapping)
    r = requests.post(url, data, headers=postheaders, stream=False, auth=('admin', 'admin'))
    result = {u'http-status': r.status_code}
    if r.status_code == 200:
        result.update(r.json())
        print "{} finished OK with: {}".format(note_prefix, result)
    else:
        print "{} finished with ERROR {}, {}".format(note_prefix, r.status_code, r.content)
    return result


if __name__ == "__main__":
    all_results = []

    nodes = args.hosts.split(",")
    for node in nodes:
        for test_type in args.test_type:
           for ds in args.datastore:
               for sht in args.shard_type:
                   for lis in args.listeners:
                       for nrshards in args.shards:
                           for items in args.totaldataitems:
                               persharditems = int(items)/int(nrshards)
                               for opers in args.operations:
                                   for puts in args.putspertx:
                                       request_args = { "TEST_TYPE":test_type, "DATASTORE": ds, "SHARDS": nrshards, "SHARDTYPE": sht, "DATAITEMS": persharditems, "OPERATIONS": opers,
                                                        "PUTSPERTX": puts, "LISTENERS": lis, "PRECREATEDATA": args.precreate_data, "VALIDATEDATA": args.validate_data, "host":node,
                                                        "TOTALITEMS": items}
                                       partial_results = { "request": request_args, "warmups": [], "runs": []}
                                       for i in range(args.warmups):
                                           test_result = run_test(request_args, warmup=True)
                                           partial_results["warmups"].append(test_result)
                                       for i in range(args.runs):
                                           test_result = run_test(request_args, warmup=False)
                                           partial_results["runs"].append(test_result)
                                       all_results.append(partial_results)

    if args.fulldata is not None:
        with open(args.fulldata, 'wt') as fd:
            json.dump(all_results, fd)

    if args.csv is not None:
        for test in all_results:
            rdet = test["request"]
            column_name='{}_{}DS_{}_SHARDS{}_TOTITEMS{}_IPS{}_LISTEN{}_OPER{}_PUTSPERTX{}'.format(rdet["SHARDTYPE"], rdet["DATASTORE"], rdet["TEST_TYPE"], rdet["SHARDS"], rdet["TOTALITEMS"], rdet["DATAITEMS"], rdet["LISTENERS"], rdet["OPERATIONS"], rdet["PUTSPERTX"] )
            durations = [ trun["output"]["totalExecTime"]    for trun in test["runs"]]
            avdur = sum(durations) / len(durations)
            print "TEST RES: {} {}".format(column_name, avdur)
        with open(args.csv, 'wt') as fd:
            pass

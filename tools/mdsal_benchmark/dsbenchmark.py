#!/usr/bin/python
__author__ = "Jan Medved"
__copyright__ = "Copyright(c) 2015, Cisco Systems, Inc."
__license__ = "New-style BSD"
__email__ = "jmedved@cisco.com"

import argparse
import requests
import json
import csv
import time

parser = argparse.ArgumentParser(description='Datastore Benchmarking'
                                             ''
                                             'See documentation @:'
                                             'https://wiki.opendaylight.org/view/Controller_Core_Functionality_Tutorials:Tutorials:Data_Store_Benchmarking_and_Data_Access_Patterns'  # noqa
                                             '')

# Host Config
parser.add_argument("--host", default="localhost", help="the IP of the target host to initiate benchmark testing on.")
parser.add_argument("--port", type=int, default=8181, help="the port number of target host.")

# Test Parameters
parser.add_argument("--txtype", choices=["TX-CHAINING", "SIMPLE-TX"], nargs='+', default=["TX-CHAINING", "SIMPLE-TX"],
                    help="list of the transaction types to execute.")
parser.add_argument("--total", type=int, default=100000, help="total number of elements to process.")
parser.add_argument("--inner", type=int, default=[1, 10, 100, 1000, 10000, 100000], nargs='+',
                    help="number of inner elements to process.")
parser.add_argument("--ops", type=int, default=[1, 10, 100, 1000, 10000, 100000], nargs='+',
                    help="number of operations per transaction.")
parser.add_argument("--optype", choices=["PUT", "MERGE", "DELETE", "READ"], nargs='+',
                    default=["PUT", "MERGE", "DELETE", "READ"], help="list of the types operations to execute.")
parser.add_argument("--format", choices=["BINDING-AWARE", "BINDING-INDEPENDENT"], nargs='+',
                    default=["BINDING-AWARE", "BINDING-INDEPENDENT"], help="list of data formats to execute.")
parser.add_argument("--warmup", type=int, default=10, help="number of warmup runs before official test runs")
parser.add_argument("--runs", type=int, default=10,
                    help="number of official test runs. Note: Reported results are based on these runs.")
args = parser.parse_args()


BASE_URL = "http://%s:%d/restconf/" % (args.host, args.port)


def send_clear_request():
    """
    Sends a clear request to the dsbenchmark app. A clear will clear the test-exec data store
    and clear the 'test-executing' flag.
    :return: None
    """
    url = BASE_URL + "operations/dsbenchmark:cleanup-store"

    r = requests.post(url, stream=False, auth=('admin', 'admin'))
    print r.status_code


def send_test_request(tx_type, operation, data_fmt, outer_elem, inner_elem, ops_per_tx):
    """
    Sends a request to the dsbenchmark app to start a data store benchmark test run.
    The dsbenchmark app will perform the requested benchmark test and return measured
    transaction times
    :param operation: PUT, MERGE, DELETE or READ
    :param data_fmt: BINDING-AWARE or BINDING-INDEPENDENT
    :param outer_elem: Number of elements in the outer list
    :param inner_elem: Number of elements in the inner list
    :param ops_per_tx: Number of operations (PUTs, MERGEs or DELETEs) on each transaction
    :return:
    """
    url = BASE_URL + "operations/dsbenchmark:start-test"
    postheaders = {'content-type': 'application/json', 'Accept': 'application/json'}

    test_request_template = '''{
        "input": {
            "transaction-type": "%s",
            "operation": "%s",
            "data-format": "%s",
            "outerElements": %d,
            "innerElements": %d,
            "putsPerTx": %d
        }
    }'''
    data = test_request_template % (tx_type, operation, data_fmt, outer_elem, inner_elem, ops_per_tx)
    r = requests.post(url, data, headers=postheaders, stream=False, auth=('admin', 'admin'))
    result = {u'http-status': r.status_code}
    if r.status_code == 200:
        result = dict(result.items() + json.loads(r.content)['output'].items())
    else:
        print 'Error %s, %s' % (r.status_code, r.content)
    return result


def print_results(run_type, idx, res):
    """
    Prints results from a dsbenchmakr test run to console
    :param run_type: String parameter that can be used to identify the type of the
                     test run (e.g. WARMUP or TEST)
    :param idx: Index of the test run
    :param res: Parsed json (disctionary) that was returned from a dsbenchmark
                test run
    :return: None
    """
    print '%s #%d: status: %s, listBuildTime %d, testExecTime %d, txOk %d, txError %d' % \
          (run_type, idx, res[u'status'], res[u'listBuildTime'], res[u'execTime'], res[u'txOk'], res[u'txError'])


def run_test(warmup_runs, test_runs, tx_type, operation, data_fmt, outer_elem, inner_elem, ops_per_tx):
    """
    Execute a benchmark test. Performs the JVM 'wamrup' before the test, runs
    the specified number of dsbenchmark test runs and computes the average time
    for building the test data (a list of lists) and the average time for the
    execution of the test.
    :param warmup_runs: # of warmup runs
    :param test_runs: # of test runs
    :param operation: PUT, MERGE or DELETE
    :param data_fmt: BINDING-AWARE or BINDING-INDEPENDENT
    :param outer_elem: Number of elements in the outer list
    :param inner_elem: Number of elements in the inner list
    :param ops_per_tx: Number of operations (PUTs, MERGEs or DELETEs) on each transaction
    :return: average build time AND average test execution time
    """
    total_build_time = 0.0
    total_exec_time = 0.0

    print 'Tx Type: {0:s}, Operation: {1:s}, Data Format: {2:s}, Outer/Inner Elements: {3:d}/{4:d}, PutsPerTx {5:d}' \
        .format(tx_type, operation, data_fmt, outer_elem, inner_elem, ops_per_tx)
    for idx in range(warmup_runs):
        res = send_test_request(tx_type, operation, data_fmt, outer_elem, inner_elem, ops_per_tx)
        print_results('WARMUP', idx, res)

    for idx in range(test_runs):
        res = send_test_request(tx_type, operation, data_fmt, outer_elem, inner_elem, ops_per_tx)
        print_results('TEST', idx, res)
        total_build_time += res['listBuildTime']
        total_exec_time += res['execTime']

    return total_build_time / test_runs, total_exec_time / test_runs


if __name__ == "__main__":
    # Test Parameters
    TX_TYPES = args.txtype
    TOTAL_ELEMENTS = args.total
    INNER_ELEMENTS = args.inner
    OPS_PER_TX = args.ops
    OPERATIONS = args.optype
    DATA_FORMATS = args.format

    # Iterations
    WARMUP_RUNS = args.warmup
    TEST_RUNS = args.runs

    # Clean up any data that may be present in the data store
    send_clear_request()

    # Run the benchmark tests and collect data in a csv file for import into a graphing software
    f = open('test.csv', 'wt')
    try:
        start_time = time.time()
        print "Start time: %f " % start_time

        writer = csv.writer(f)

        # Determine the impact of transaction type, data format and data structure on performance.
        # Iterate over all transaction types, data formats, operation types, and different
        # list-of-lists layouts; always use a single operation in each transaction
        print '\n#######################################'
        print 'Tx type, data format & data structure'
        print '#######################################'
        for tx_type in TX_TYPES:
            print '***************************************'
            print 'Transaction Type: %s' % tx_type
            print '***************************************'
            writer.writerow((('%s:' % tx_type), '', ''))

            for fmt in DATA_FORMATS:
                print '---------------------------------------'
                print 'Data format: %s' % fmt
                print '---------------------------------------'
                writer.writerow(('', ('%s:' % fmt), ''))

                for oper in OPERATIONS:
                    print 'Operation: %s' % oper
                    writer.writerow(('', '', '%s:' % oper))

                    for elem in INNER_ELEMENTS:
                        avg_build_time, avg_exec_time = \
                            run_test(WARMUP_RUNS, TEST_RUNS, tx_type, oper, fmt, TOTAL_ELEMENTS / elem, elem, 1)
                        e_label = '%d/%d' % (TOTAL_ELEMENTS / elem, elem)
                        writer.writerow(('', '', '', e_label, avg_build_time, avg_exec_time,
                                         (avg_build_time + avg_exec_time)))

        # Determine the impact of number of writes per transaction on performance.
        # Iterate over all transaction types, data formats, operation types, and
        # operations-per-transaction; always use a list of lists where the inner list has one parameter
        print '\n#######################################'
        print 'Puts per tx'
        print '#######################################'
        for tx_type in TX_TYPES:
            print '***************************************'
            print 'Transaction Type: %s' % tx_type
            print '***************************************'
            writer.writerow((('%s:' % tx_type), '', ''))

            for fmt in DATA_FORMATS:
                print '---------------------------------------'
                print 'Data format: %s' % fmt
                print '---------------------------------------'
                writer.writerow(('', ('%s:' % fmt), ''))

                for oper in OPERATIONS:
                    print 'Operation: %s' % oper
                    writer.writerow(('', '', '%s:' % oper))

                    for wtx in OPS_PER_TX:
                        avg_build_time, avg_exec_time = \
                            run_test(WARMUP_RUNS, TEST_RUNS, tx_type, oper, fmt, TOTAL_ELEMENTS, 1, wtx)
                        writer.writerow(('', '', '', wtx, avg_build_time, avg_exec_time,
                                         (avg_build_time + avg_exec_time)))

        end_time = time.time()
        print "End time: %f " % end_time
        print "Total execution time: %f" % (end_time - start_time)

    finally:
        f.close()

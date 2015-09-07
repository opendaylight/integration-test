#!/usr/bin/python
##############################################################################
# Copyright (c) 2015 Cisco Systems  All rights reserved.
#
# This program and the accompanying materials are made available under the
# terms of the Eclipse Public License v1.0 which accompanies this distribution,
# and is available at http://www.eclipse.org/legal/epl-v10.html
##############################################################################

__author__ = "Jan Medved"
__copyright__ = "Copyright(c) 2015, Cisco Systems, Inc."
__license__ = "Eclipse Public License v1.0"
__email__ = "jmedved@cisco.com"

import argparse
import requests
import json
import csv

global BASE_URL


def send_test_request(operation, clients, servers, payload_size, iterations):
    """
    Sends a request to the rpcbenchmark app to start a data store benchmark test run.
    The rpcbenchmark app will perform the requested benchmark test and return measured
    test execution time and RPC throughput

    :param operation: operation type
    :param clients: number of simulated RPC clients
    :param servers: Number of simulated RPC servers if operation type is ROUTED-***
    :param payload_size: Payload size for the test RPCs
    :param iterations: Number of iterations to run
    :return: Result from the test request REST call (json)
    """
    url = BASE_URL + "operations/rpcbenchmark:start-test"
    postheaders = {'content-type': 'application/json', 'Accept': 'application/json'}

    test_request_template = '''{
        "input": {
            "operation": "%s",
            "num-clients": "%s",
            "num-servers": "%s",
            "payload-size": "%s",
            "iterations": "%s"
        }
    }'''
    data = test_request_template % (operation, clients, servers, payload_size, iterations)
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
    print '%s #%d: Ok: %d, Error: %d, Rate: %d, Exec time: %d' % \
          (run_type, idx,
           res[u'global-rtc-client-ok'], res[u'global-rtc-client-error'], res[u'rate'], res[u'exec-time'])


def run_test(warmup_runs, test_runs, operation, clients, servers, payload_size, iterations):
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
    total_exec_time = 0.0
    total_rate = 0.0

    for idx in range(warmup_runs):
        res = send_test_request(operation, clients, servers, payload_size, iterations)
        print_results('WARM-UP', idx, res)

    for idx in range(test_runs):
        res = send_test_request(operation, clients, servers, payload_size, iterations)
        print_results('TEST', idx, res)
        total_exec_time += res['exec-time']
        total_rate += res['rate']

    return total_exec_time / test_runs, total_rate / test_runs


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='RPC Benchmarking')

    # Host Config
    parser.add_argument("--host", default="localhost", help="IP of the target host where benchmarks will be run.")
    parser.add_argument("--port", type=int, default=8181, help="The port number of target host.")

    # Test Parameters
    parser.add_argument("--operation", choices=["GLOBAL-RTC", "ROUTED-RTC"], default='GLOBAL-RTC',
                        help='RPC and client type. RPC can be global or routcan be run-to-completion (RTC).'
                             '(default: GLOBAL-RTC - Global RPC, Run-to-completion client)')
    parser.add_argument("--warm", type=int, default=10, help='The number of warm-up runs before the measured test runs'
                                                             '(Default 10)')
    parser.add_argument("--run", type=int, default=10,
                        help='The number of measured test runs. Reported results are based on these average of all'
                             " measured runs. (Default 10)")
    parser.add_argument("--clients", type=int, nargs='+', default=[1, 2, 4, 8, 16, 32, 64],
                        help='The number of test RPC clients to start. (Default 10)')
    parser.add_argument("--servers", type=int, nargs='+', default=[1, 2, 4, 8, 16, 32, 64],
                        help='The number of routed RPC servers to start in the routed RPC test. Ignored in the global '
                             'RPC test. (Default 10)')
    parser.add_argument("--iterations", type=int, default=10, help='The number requests that each RPC client issues '
                                                                   'during the test run. (Default 10)')
    parser.add_argument("--payload", type=int, default=10, help='Payload size for the RPC - number of elements in a '
                                                                'simple integer list. (Default 10)')

    args = parser.parse_args()
    BASE_URL = "http://%s:%d/restconf/" % (args.host, args.port)

    if args.operation == 'GLOBAL-RTC':
        servers = [1]
    else:
        servers = args.servers

    # Run the benchmark tests and collect data in a csv file for import into a graphing software
    f = open('test.csv', 'wt')
    try:
        writer = csv.writer(f)
        rate_matrix = []

        for svr in servers:
            rate_row = ['']
            for client in args.clients:
                exec_time, rate = \
                    run_test(args.warm, args.run, args.operation, client, svr, args.payload, args.iterations)
                rate_row.append(rate)
            rate_matrix.append(rate_row)
        print rate_matrix

        writer.writerow(('RPC Rates:', ''))
        writer.writerows(rate_matrix)
    finally:
        f.close()

#!/usr/bin/env python
"""Compute basic stats about CBench data."""

import csv
import numpy
import pprint
import matplotlib.pyplot as pyplot
import argparse
import sys


class Stats(object):

    """Compute stats and/or graph data.

    I know I could convert these fns that simply punt to a helper
    to a dict/list data structure, but that would remove some of the
    flexabilty I get by simply calling a graph/stat fn for each
    graph/stat arg. All current fns just punt to helpers, but future
    ones might not.

    """

    results_file = "results.csv"
    log_file = "cbench.log"
    precision = 3
    run_index = 0
    min_flow_index = 1
    max_flow_index = 2
    avg_flow_index = 3
    start_time_index = 4
    end_time_index = 5
    start_steal_time_index = 12
    end_steal_time_index = 13
    used_ram_index = 15
    one_load_index = 18
    five_load_index = 19
    fifteen_load_index = 20
    start_iowait_index = 22
    end_iowait_index = 23

    def __init__(self):
        """Setup some flags and data structures, kick off build_cols call."""
        self.build_cols()
        self.results = {}
        self.results["sample_size"] = len(self.run_col)

    def build_cols(self):
        """Parse results file into lists of values, one per column."""
        self.run_col = []
        self.min_flows_col = []
        self.max_flows_col = []
        self.avg_flows_col = []
        self.runtime_col = []
        self.used_ram_col = []
        self.iowait_col = []
        self.steal_time_col = []
        self.one_load_col = []
        self.five_load_col = []
        self.fifteen_load_col = []

        with open(self.results_file, "rb") as results_fd:
            results_reader = csv.reader(results_fd)
            for row in results_reader:
                try:
                    self.run_col.append(float(row[self.run_index]))
                    self.min_flows_col.append(float(row[self.min_flow_index]))
                    self.max_flows_col.append(float(row[self.max_flow_index]))
                    self.avg_flows_col.append(float(row[self.avg_flow_index]))
                    self.runtime_col.append(float(row[self.end_time_index]) -
                                            float(row[self.start_time_index]))
                    self.used_ram_col.append(float(row[self.used_ram_index]))
                    self.iowait_col.append(float(row[self.end_iowait_index]) -
                                           float(row[self.start_iowait_index]))
                    self.steal_time_col.append(
                        float(row[self.end_steal_time_index]) -
                        float(row[self.start_steal_time_index]))
                    self.one_load_col.append(float(row[self.one_load_index]))
                    self.five_load_col.append(float(row[self.five_load_index]))
                    self.fifteen_load_col.append(
                        float(row[self.fifteen_load_index]))
                except ValueError:
                    # Skips header
                    continue

    def compute_avg_flow_stats(self):
        """Compute CBench average flows/second stats."""
        self.compute_generic_stats("flows", self.avg_flows_col)

    def build_avg_flow_graph(self, total_gcount, graph_num):
        """Plot average flows/sec data.

        :param total_gcount: Total number of graphs to render.
        :type total_gcount: int
        :param graph_num: Number for this graph, <= total_gcount.
        :type graph_num: int

        """
        self.build_generic_graph(total_gcount, graph_num,
                                 "Average Flows per Second", self.avg_flows_col)

    def compute_min_flow_stats(self):
        """Compute CBench min flows/second stats."""
        self.compute_generic_stats("min_flows", self.min_flows_col)

    def build_min_flow_graph(self, total_gcount, graph_num):
        """Plot min flows/sec data.

        :param total_gcount: Total number of graphs to render.
        :type total_gcount: int
        :param graph_num: Number for this graph, <= total_gcount.
        :type graph_num: int

        """
        self.build_generic_graph(total_gcount, graph_num,
                                 "Minimum Flows per Second", self.min_flows_col)

    def compute_max_flow_stats(self):
        """Compute CBench max flows/second stats."""
        self.compute_generic_stats("max_flows", self.max_flows_col)

    def build_max_flow_graph(self, total_gcount, graph_num):
        """Plot max flows/sec data.

        :param total_gcount: Total number of graphs to render.
        :type total_gcount: int
        :param graph_num: Number for this graph, <= total_gcount.
        :type graph_num: int

        """
        self.build_generic_graph(total_gcount, graph_num,
                                 "Maximum Flows per Second", self.max_flows_col)

    def compute_ram_stats(self):
        """Compute used RAM stats."""
        self.compute_generic_stats("used_ram", self.used_ram_col)

    def build_ram_graph(self, total_gcount, graph_num):
        """Plot used RAM data.

        :param total_gcount: Total number of graphs to render.
        :type total_gcount: int
        :param graph_num: Number for this graph, <= total_gcount.
        :type graph_num: int

        """
        self.build_generic_graph(total_gcount, graph_num,
                                 "Used RAM (MB)", self.used_ram_col)

    def compute_runtime_stats(self):
        """Compute CBench runtime length stats."""
        self.compute_generic_stats("runtime", self.runtime_col)

    def build_runtime_graph(self, total_gcount, graph_num):
        """Plot CBench runtime length data.

        :param total_gcount: Total number of graphs to render.
        :type total_gcount: int
        :param graph_num: Number for this graph, <= total_gcount.
        :type graph_num: int

        """
        self.build_generic_graph(total_gcount, graph_num,
                                 "CBench Runtime (sec)", self.runtime_col)

    def compute_iowait_stats(self):
        """Compute iowait stats."""
        self.compute_generic_stats("iowait", self.iowait_col)

    def build_iowait_graph(self, total_gcount, graph_num):
        """Plot iowait data.

        :param total_gcount: Total number of graphs to render.
        :type total_gcount: int
        :param graph_num: Number for this graph, <= total_gcount.
        :type graph_num: int

        """
        self.build_generic_graph(total_gcount, graph_num,
                                 "IOWait Time (sec)", self.iowait_col)

    def compute_steal_time_stats(self):
        """Compute steal time stats."""
        self.compute_generic_stats("steal_time", self.steal_time_col)

    def build_steal_time_graph(self, total_gcount, graph_num):
        """Plot steal time data.

        :param total_gcount: Total number of graphs to render.
        :type total_gcount: int
        :param graph_num: Number for this graph, <= total_gcount.
        :type graph_num: int

        """
        self.build_generic_graph(total_gcount, graph_num,
                                 "Steal Time (sec)", self.steal_time_col)

    def compute_one_load_stats(self):
        """Compute one minute load stats."""
        self.compute_generic_stats("one_load", self.one_load_col)

    def build_one_load_graph(self, total_gcount, graph_num):
        """Plot one minute load data.

        :param total_gcount: Total number of graphs to render.
        :type total_gcount: int
        :param graph_num: Number for this graph, <= total_gcount.
        :type graph_num: int

        """
        self.build_generic_graph(total_gcount, graph_num,
                                 "One Minute Load", self.one_load_col)

    def compute_five_load_stats(self):
        """Compute five minute load stats."""
        self.compute_generic_stats("five_load", self.five_load_col)

    def build_five_load_graph(self, total_gcount, graph_num):
        """Plot five minute load data.

        :param total_gcount: Total number of graphs to render.
        :type total_gcount: int
        :param graph_num: Number for this graph, <= total_gcount.
        :type graph_num: int

        """
        self.build_generic_graph(total_gcount, graph_num,
                                 "Five Minute Load", self.five_load_col)

    def compute_fifteen_load_stats(self):
        """Compute fifteen minute load stats."""
        self.compute_generic_stats("fifteen_load", self.fifteen_load_col)

    def build_fifteen_load_graph(self, total_gcount, graph_num):
        """Plot fifteen minute load data.

        :param total_gcount: Total number of graphs to render.
        :type total_gcount: int
        :param graph_num: Number for this graph, <= total_gcount.
        :type graph_num: int

        """
        self.build_generic_graph(total_gcount, graph_num,
                                 "Fifteen Minute Load", self.fifteen_load_col)

    def compute_generic_stats(self, stats_name, stats_col):
        """Helper for computing generic stats."""
        generic_stats = {}
        generic_stats["min"] = int(numpy.amin(stats_col))
        generic_stats["max"] = int(numpy.amax(stats_col))
        generic_stats["mean"] = round(numpy.mean(stats_col), self.precision)
        generic_stats["stddev"] = round(numpy.std(stats_col), self.precision)
        try:
            generic_stats["relstddev"] = round(generic_stats["stddev"] /
                                               generic_stats["mean"] *
                                               100, self.precision)
        except ZeroDivisionError:
            generic_stats["relstddev"] = 0.
        self.results[stats_name] = generic_stats

    def build_generic_graph(self, total_gcount, graph_num, y_label, data_col):
        """Helper for plotting generic data.

        :param total_gcount: Total number of graphs to render.
        :type total_gcount: int
        :param graph_num: Number for this graph, <= total_gcount.
        :type graph_num: int
        :param y_label: Lable of Y axis.
        :type y_label: string
        :param data_col: Data to graph.
        :type data_col: list

        """
        # Pagenerics are numrows, numcols, fignum
        pyplot.subplot(total_gcount, 1, graph_num)
        # "go" means green O's
        pyplot.plot(self.run_col, data_col, "go")
        pyplot.xlabel("Run Number")
        pyplot.ylabel(y_label)


# Build stats object
stats = Stats()

# Map of graph names to the Stats.fns that build them
graph_map = {"min_flows": stats.build_min_flow_graph,
             "max_flows": stats.build_max_flow_graph,
             "flows": stats.build_avg_flow_graph,
             "runtime": stats.build_runtime_graph,
             "iowait": stats.build_iowait_graph,
             "steal_time": stats.build_steal_time_graph,
             "one_load": stats.build_one_load_graph,
             "five_load": stats.build_five_load_graph,
             "fifteen_load": stats.build_fifteen_load_graph,
             "ram": stats.build_ram_graph}
stats_map = {"min_flows": stats.compute_min_flow_stats,
             "max_flows": stats.compute_max_flow_stats,
             "flows": stats.compute_avg_flow_stats,
             "runtime": stats.compute_runtime_stats,
             "iowait": stats.compute_iowait_stats,
             "steal_time": stats.compute_steal_time_stats,
             "one_load": stats.compute_one_load_stats,
             "five_load": stats.compute_five_load_stats,
             "fifteen_load": stats.compute_fifteen_load_stats,
             "ram": stats.compute_ram_stats}

# Build argument parser
parser = argparse.ArgumentParser(description="Compute stats about CBench data")
parser.add_argument("-S", "--all-stats", action="store_true",
                    help="compute all stats")
parser.add_argument("-s", "--stats", choices=stats_map.keys(),
                    help="compute stats on specified data", nargs="+")
parser.add_argument("-G", "--all-graphs", action="store_true",
                    help="graph all data")
parser.add_argument("-g", "--graphs", choices=graph_map.keys(),
                    help="graph specified data", nargs="+")


# Print help if no arguments are given
if len(sys.argv) == 1:
    parser.print_help()
    sys.exit(1)

# Parse the given args
args = parser.parse_args()

# Build graphs
if args.all_graphs:
    graphs_to_build = graph_map.keys()
elif args.graphs:
    graphs_to_build = args.graphs
else:
    graphs_to_build = []
for graph, graph_num in zip(graphs_to_build, range(len(graphs_to_build))):
    graph_map[graph](len(graphs_to_build), graph_num+1)

# Compute stats
if args.all_stats:
    stats_to_compute = stats_map.keys()
elif args.stats:
    stats_to_compute = args.stats
else:
    stats_to_compute = []
for stat in stats_to_compute:
    stats_map[stat]()

# Render graphs
if args.graphs or args.all_graphs:
    # Attempt to adjust plot spacing, just a simple heuristic
    if len(graphs_to_build) <= 3:
        pyplot.subplots_adjust(hspace=.2)
    elif len(graphs_to_build) <= 6:
        pyplot.subplots_adjust(hspace=.4)
    elif len(graphs_to_build) <= 9:
        pyplot.subplots_adjust(hspace=.7)
    else:
        pyplot.subplots_adjust(hspace=.7)
        print "WARNING: That's a lot of graphs. Add a second column?"
    pyplot.show()

# Print stats
if args.stats or args.all_stats:
    pprint.pprint(stats.results)

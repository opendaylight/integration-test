"""
    Appenders Object Definition to be used with karaf-decanter
    Used to collect resource usage metrics

    Currently implements ElasticsearchAppender

    Usage
            declare foo = ElasticsearchAppender()
            get connection object conn = foo.get_connection(host=host,
                                                            port=port)
            call
                    foo.get_jvm_memory(conn), foo.get_jvm_classloading(conn),
                    foo.get_jvm_threadingconn(),
                    foo.get_jvm_garbageCollector(conn),
                    foo.get_jvm_operatingsystem(conn)
            returns
                    the latest resource usage statistics dictionary object
                    (latest based on the @timestamp)
            call
                    foo.plot_points(conn, title, filename, metric,
                                    submetric, submetrickey)

                    for example
                    foo.plot_points(conn, 'JVM Started Threads',
                                    'threadcount.png', 'Threading',
                                    'TotalStartedThreadCount')
                    submetrickey is optional
                    for more usage and examples see https://goo.gl/dT1RqT

"""

from datetime import datetime
from operator import itemgetter
from elasticsearch import Elasticsearch
from elasticsearch_dsl import Search
import re
import matplotlib as mpl
mpl.use('Agg')


class MBeanNotFoundError(Exception):
    def __init__(self, message, errors):
        super(MBeanNotFoundError, self).__init__(message)


class BaseAppender(object):
    '''
        Base Appender from which all appenders should inherit
    '''

    def _get_index(self, need_all):
        raise NotImplementedError

    def _get_connection(self):
        raise NotImplementedError


class ElasticsearchAppender(BaseAppender):
    '''
        ElasticsearchAppender Class
        Metrics supported : Memory, ClassLoading, Threading, GarbageCollector
        Individual resource attributes as defined in attr dictionary object
    '''

    attr = {'Memory': ['HeapMemoryUsage', 'NonHeapMemoryUsage',
                       '@timestamp'],
            'ClassLoading': ['TotalLoadedClassCount', 'UnloadedClassCount',
                             '@timestamp'],
            'OperatingSystem': ['FreeSwapSpaceSize', 'TotalSwapSpaceSize',
                                'FreePhysicalMemorySize',
                                'TotalPhysicalMemorySize',
                                'CommittedVirtualMemorySize', 'ProcessCpuLoad',
                                'ProcessCpuTime', 'SystemCpuLoad',
                                '@timestamp'],
            'Threading': ['DaemonThreadCount', 'PeakThreadCount',
                          'ThreadCount', 'TotalStartedThreadCount',
                          '@timestamp'],
            'GarbageCollector': ['LastGcInfo', 'CollectionCount',
                                 '@timestamp', 'CollectionTime']}
    label = {'Memory': 'Memory', 'ClassLoading': 'Class Loading',
             'Threading': 'Threads', 'GarbageCollector': 'Garbage Collector'}

    def get_connection(self, host='localhost', port=9200):
        host = self.cleanse_string(host)
        port = self.cleanse_string(port)
        return self._get_connection(host, port)

    def get_jvm_memory(self, connection):
        return self._get_mbean_attr(connection, 'Memory')

    def get_jvm_classloading(self, connection):
        return self._get_mbean_attr(connection, 'ClassLoading',)

    def get_jvm_threading(self, connection):
        return self._get_mbean_attr(connection, 'Threading')

    def get_jvm_garbagecollector(self, connection):
        return self._get_mbean_attr(connection, 'GarbageCollector')

    def get_jvm_operatingsystem(self, connection):
        return self._get_mbean_attr(connection, 'OperatingSystem')

    def cleanse_string(self, s):
        return str(s).replace("'", "")

    def plot_points(self, connection, title, filename, metric, submetric,
                    submetrickey=None):

        from matplotlib import dates, pyplot as plt, ticker as tkr

        metric = self.cleanse_string(metric)
        submetric = self.cleanse_string(submetric)
        if submetrickey is not None:
            submetrickey = self.cleanse_string(submetrickey)

        points = self._get_plot_points(connection, metric, submetric,
                                       submetrickey)
        points[0] = [p.replace(microsecond=0) for p in points[0]]
        myFmt = dates.DateFormatter('%m-%d %H:%M:%S')
        fig, ax = plt.subplots()

        ax.plot_date(points[0], points[1], 'c-')
        ax.grid(color='grey')
        ax.patch.set_facecolor('black')
        ax.xaxis.set_major_formatter(myFmt)

        axes = plt.gca()
        axes.get_yaxis().get_major_formatter().set_scientific(False)
        axes.get_yaxis().get_major_formatter().set_useOffset(False)

        ax.set_xlabel('Time')
        xlabel = self._convert(submetric).title()
        if submetrickey is not None:
            xlabel = xlabel + ' : ' + str(submetrickey).title()
        ax.set_ylabel(xlabel)

        mx = max(points[1]) + max(points[1]) * 0.00001
        mn = min(points[1]) - min(points[1]) * 0.00001
        ax.set_ylim(mn, mx)

        ax.set_title(title)
        if isinstance(points[1][0], int):
            axes.yaxis.set_major_formatter(tkr.FuncFormatter(lambda x, _:
                                                             int(x)))
        else:
            axes.yaxis.set_major_formatter(tkr.FuncFormatter(lambda x, _:
                                                             float(x)))
        plt.gcf().autofmt_xdate()
        plt.savefig(filename, bbox_inches='tight')

    def _convert(self, name):
        s1 = re.sub('(.)([A-Z][a-z]+)', r'\1 \2', name)
        return re.sub('([a-z0-9])([A-Z])', r'\1 \2', s1).lower()

    def _get_y_val(self, response, metric, submetric=None):
        if isinstance(response[metric], dict):
            return response[metric][submetric]
        else:
            return response[metric]

    def _get_plot_points(self, connection, metric, submetric,
                         submetrickey=None):
        indices = self._get_index(connection, need_all=True)
        points = []
        for index in indices:
            responses = self._get_all_mbean_attr(connection, metric, index)
            for response in responses:
                point = (self._get_datetime_object(response['@timestamp']),
                         self._get_y_val(response, submetric, submetrickey))
                points.append(point)
        points.sort(key=itemgetter(0))
        return zip(*points)

    def _get_index(self, connection, need_all=False):
        indices = sorted([i for i in
                          connection.indices.get_mapping().keys()
                          if i.startswith('karaf')])
        if need_all:
            return indices
        else:
            return sorted(indices, reverse=True)[0]

    def _get_connection(self, host, port):
        con_obj = {'host': host, 'port': port}
        es = Elasticsearch([con_obj])
        return es

    def _get_all_mbean_attr(self, connection, mbean, index, dsl_class='match'):
        s = Search(using=connection, index=index).\
            query(dsl_class, ObjectName=mbean).\
            sort({"@timestamp": {"order": 'desc'}})
        response = []
        for hit in s.scan():
            response.append(self._get_attr_obj([hit], mbean))
        return response

    def _get_mbean_attr(self, connection, mbean, dsl_class='match'):
        index = self._get_index(connection)

        try:
            s = Search(using=connection, index=index).\
                query(dsl_class, ObjectName=mbean).\
                sort({"@timestamp": {"order": 'desc'}})[0].execute()
        except Exception:
            raise MBeanNotFoundError('Could Not Fetch %s mbean' % mbean)

        mem_attr = self._get_attr_obj(s, mbean)
        return mem_attr

    def _get_attr_obj(self, response, mbean):
        mbean_attr = {}
        for r in response:
            for k in self.attr[mbean]:
                is_to_dict = getattr(r[k], "to_dict", None)
                if callable(is_to_dict):
                    mbean_attr[k] = r[k].to_dict()
                else:
                    mbean_attr[k] = r[k]
        return mbean_attr

    def _get_datetime_object(self, timestamp):
        return datetime.strptime(timestamp, '%Y-%m-%dT%H:%M:%S,%fZ')

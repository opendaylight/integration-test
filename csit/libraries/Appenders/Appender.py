"""
    Appenders Object Definition to be used with karaf-decanter
    Used to collect resource usage metrics

    Currently implements ElasticsearchAppender

    Usage
            declare foo = ElasticsearchAppender(hostname, port)
            call
                    foo.get_jvm_memory(), foo.get_jvm_classloading,
                    foo.get_jvm_threading, foo.get_jvm_garbageCollector
            returns
                    the latest resource usage statistics dictionary object
                    (latest based on the @timestamp)
            call
                    foo.plot_points(duration, metric, submetric, submetrickey)

                    for example
                    foo.plot_points(200, 'Threading',
                                    'TotalStartedThreadCount')
                    submetrickey is optional
                    for more usage and examples see https://goo.gl/dT1RqT

"""

from datetime import datetime
from functools import partial
import re
import time

from elasticsearch import Elasticsearch
from elasticsearch_dsl import Search
from matplotlib import dates, pyplot as plt, ticker as tkr


class MBeanNotFoundError(Exception):
        def __init__(self, message, errors):
            super(MBeanNotFoundError, self).__init__(message)


class BaseAppender(object):
    '''
        Base Appender from which all appenders should inherit
    '''

    host = ''
    port = ''

    def __init__(self, host='localhost', port=9200):
        self.host = host
        self.port = port

    def _get_latest_index(self):
        raise NotImplementedError

    def _get_connection(self):
        raise NotImplementedError


class ElasticsearchAppender(BaseAppender):
    '''
        ElasticsearchAppender Class
        Metrics supported : Memory, ClassLoading, Threading, GarbageCollector
        Individual resource attributes as defined in attr dictionary object
    '''

    connection = ''
    attr = {'Memory': ['HeapMemoryUsage', 'NonHeapMemoryUsage',
                       '@timestamp'],
            'ClassLoading': ['TotalLoadedClassCount', 'UnloadedClassCount',
                             '@timestamp'],
            'Threading': ['DaemonThreadCount', 'PeakThreadCount',
                          'ThreadCount', 'TotalStartedThreadCount',
                          '@timestamp'],
            'GarbageCollector': ['LastGcInfo', 'CollectionCount',
                                 '@timestamp', 'CollectionTime']}
    label = {'Memory': 'Memory', 'ClassLoading': 'Class Loading',
             'Threading': 'Threads', 'GarbageCollector': 'Garbage Collector'}

    def __init__(self, host='localhost', port=9200):
        super(ElasticsearchAppender, self).__init__(host, port)
        self.connection = self._get_connection()
        for key in self.attr:
            setattr(self, 'get_jvm_' + key.lower(), partial(self.func, key))

    def func(self, attribute):
        return self._get_mbean_attr(attribute)

    def plot_points(self, duration, metric, submetric, submetrickey=None):
        points = self._get_plot_points(duration, metric, submetric,
                                       submetrickey)
        points[0] = [p.replace(microsecond=0) for p in points[0]]

        myFmt = dates.DateFormatter('%H:%M:%S')
        fig, ax = plt.subplots()

        ax.plot(points[0], points[1], 'co-')
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

        ax.set_title(str(self.label[metric]))
        if isinstance(points[1][0], int):
            axes.yaxis.set_major_formatter(tkr.FuncFormatter(lambda x, _:
                                                             int(x)))
        else:
            axes.yaxis.set_major_formatter(tkr.FuncFormatter(lambda x, _:
                                                             float(x)))
        plt.gcf().autofmt_xdate()
        plt.show()

    def _convert(self, name):
        s1 = re.sub('(.)([A-Z][a-z]+)', r'\1 \2', name)
        return re.sub('([a-z0-9])([A-Z])', r'\1 \2', s1).lower()

    def _get_y_val(self, response, metric, submetric=None):
        if isinstance(response[metric], dict):
            return response[metric][submetric]
        else:
            return response[metric]

    def _get_plot_points(self, duration, metric, submetric, submetrickey=None):
        plot_points = (duration / 5)
        resource = getattr(self, 'get_jvm_' + metric.lower())
        points = []
        for i in range(0, plot_points):
            response = resource()
            point = (self._get_datetime_object(response['@timestamp']),
                     self._get_y_val(response, submetric, submetrickey))
            points.append(point)
            time.sleep(5)
        return zip(*points)

    def _get_latest_index(self):
        indices = [i for i in self.connection.indices.get_mapping().keys()
                   if i.startswith('karaf')]
        index = sorted(indices, reverse=True)[0]
        return index

    def _get_connection(self):
        con_obj = {'host': self.host, 'port': self.port}
        es = Elasticsearch([con_obj])
        return es

    def _get_mbean_attr(self, mbean, dsl_class='match'):
        index = self._get_latest_index()

        try:
            s = Search(using=self.connection, index=index).\
                filter(dsl_class, ObjectName=mbean).\
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

"""
    Appenders Object Definition to be used with karaf-decanter
    Used to collect resource usage metrics

    Currently implements ElasticsearchAppender

    Usage
            declare foo = ElasticsearchAppender(hostname, port)
            call
                    foo.Memory, foo.ClassLoading, foo.Threading,
                    foo.GarbageCollector
            returns
                    the latest resource usage statistics dictionary object
                    (latest based on the @timestamp)
"""

from elasticsearch import Elasticsearch
from elasticsearch_dsl import Search


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
    attr = {'Memory': ['HeapMemoryUsage', 'NonHeapMemoryUsage'],
            'ClassLoading': ['TotalLoadedClassCount', 'UnloadedClassCount'],
            'Threading': ['DaemonThreadCount', 'PeakThreadCount',
                          'ThreadCount', 'TotalStartedThreadCount'],
            'GarbageCollector': ['LastGcInfo', 'CollectionCount',
                                 'CollectionTime']}

    def __init__(self, host='localhost', port=9200):
        super(ElasticsearchAppender, self).__init__(host, port)
        self.connection = self._get_connection()

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
                mbean_attr[k] = r[k]
        return mbean_attr

    def __getattr__(self, attr):
        return self._get_mbean_attr(attr)

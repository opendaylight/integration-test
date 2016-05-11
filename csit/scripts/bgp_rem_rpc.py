#!/usr/bin/env python

import sys
import logging
from SimpleXMLRPCServer import SimpleXMLRPCServer
import select
import threading
import os
import re
import binascii
from exabgp.bgp.message import Message
import argparse

class ExaStorage(dict):
    def __init__(self, * p_arg, ** n_arg) :
        super(ExaStorage, self).__init__()
        self._lock = threading.Lock()

    def __enter__(self) :
        self._lock.acquire()
        return self

    def __exit__(self, type, value, traceback) :
        self._lock.release()


class Rpcs:
    def __init__(self, storage):
        self.storage = storage

    def _write(self, text):
        logging.debug('Command towards exabgp: {}'.format(text))
        sys.stdout.write(text)
        sys.stdout.write("\n")
        sys.stdout.flush()
        logging.debug('Connand flushed: {}.'.format(text))

    def get_something(self):
        logging.info('get_something')
        return 'get return'

    def get_counter(self, msg_type):
        logging.debug('get_counter rpc called, storage {}'.format(self.storage))
        with self.storage as s:
            cnt = s['counters'][msg_type]
        return cnt

    def clean_counter(self, msg_type):
        logging.debug('clean_counter rpc called, storage {}'.format(self.storage))
        with self.storage as s:
            if msg_type in s['counters']:
                del s['counters'][msg_type]
        return

    def execute(self, exabgp_cmd):
        logging.info('executing: {}.'.format(exabgp_cmd))
        self._write(exabgp_cmd)
        return

        
def decode_message(header, body):
    headbin = binascii.unhexlify(header)
    bodybin = None if body is None else binascii.unhexlify(body)

    msg_type = ord(headbin[18])
    msg = None

    if msg_type == Message.CODE.KEEPALIVE:
        pass
    elif msg_type == Message.CODE.OPEN:
        pass
    elif msg_type == Message.CODE.UPDATE:
        pass
    elif msg_type == Message.CODE.ROUTE_REFRESH:
        pass
    else:
        pass

    return msg_type, msg


def _increment_counter(storage, key):
    with storage as s:
        if 'counters' not in s:
            s['counters'] = {}
        if key not in s['counters']:
            s['counters'][key] = 1
        else:
            s['counters'][key] += 1

def handle_open(storage, msg):
    logging.debug('Handling Open with storage {}'.format(storage))
    _increment_counter(storage, 'open')

def handle_keepalive(storage, msg):
    logging.debug('Handling KeepAlive with storage {}'.format(storage))
    _increment_counter(storage, 'keepalive')

def handle_update(storage, update):
    logging.debug('Handling Update with storage {}'.format(storage))
    _increment_counter(storage, 'update')

def handle_route_refresh(storage, msg):
    logging.debug('Handling Route Refresh with storage {}'.format(storage))
    _increment_counter(storage, 'route_refresh')

def exa_msg_handler(storage, data):
    if not ('neighbor' in data and 'header' in data and 'body' in data):
        logging.debug('Ignoring received notification from exabgp: {}'.format(data))
        return
    logging.info('Message from exabgp received: {}.'.format(data))
    pat = re.compile('neighbor (?P<ip>[0-9,\.]+) received (?P<mid>[0-9]+) header (?P<header>[0-9,A-F]+) body.?(?P<body>[0-9,A-F]+)?')
    match = re.search(pat, data)
    if match is None:
        logging.warn('Unexpected data in this part, only bgp message expected. Received: {}.'.format(data))
    msg_type, msg = decode_message( match.groupdict()['header'], match.groupdict()['body'])
    if msg_type == Message.CODE.KEEPALIVE:
        handle_keepalive(storage, msg)
    elif msg_type == Message.CODE.OPEN:
        handle_open(storage, msg)
    elif msg_type == Message.CODE.UPDATE:
        handle_update(storage, msg)
    elif msg_type == Message.CODE.ROUTE_REFRESH:
        handle_route_refresh(storage, msg)
    else:
        logging.warn('Not handler function for msg_type: {}'.format(msg_type))

    

def main(*argv):

    parser = argparse.ArgumentParser(description='ExaBgp rpc server script')
    parser.add_argument('--host', default='127.0.0.1', help='Host where exabgp is running (default is 127.0.0.1)')
    parser.add_argument('--loglevel', default=logging.DEBUG, help='Log level')
    parser.add_argument('--logfile', default= '{}/bgp_rem_rpc.log'.format(os.path.dirname(os.path.abspath(__file__))),
                        help='Log file name.')
    in_args = parser.parse_args(*argv)

    logging.basicConfig(filename=in_args.logfile, level=in_args.loglevel)

    storage = ExaStorage()
    rpcserver = SimpleXMLRPCServer((in_args.host, 8000), allow_none=True)
    rpcserver.register_instance(Rpcs(storage))
    t = threading.Thread(target=rpcserver.serve_forever)
    t.start()

    epoll = select.epoll()

    epoll.register(sys.__stdin__, select.EPOLLIN | select.EPOLLERR | select.EPOLLHUP )

    try:
        while True:
            logging.debug('Epoll loop')
            events = epoll.poll(10)
            for fd, event_type in events:
                logging.debug('Epoll returned: {},{}'.format(fd, event_type))
                if event_type != select.EPOLLIN:
                    raise Exception('Unexpected epoll event')
                else:
                    data = sys.stdin.readline()
                    logging.debug('Data recevied from exabgp: {}.'.format(data))
                    exa_msg_handler(storage, data)
    except Exception as e:
        logging.debug('Exacption occured: {}'.format(e))
    finally:
        rpcserver.shutdown()
        t.join()

if __name__ == '__main__':
    main()

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
import json


class ExaStorage(dict):
    '''Thread save dictionary

    The object will serve as thread save data storage.
    It should be used with "with" statement.

    The content of thet dict may be changed dynamically, but i'll use it as
    {
      "counters": { <msg type>: count, ...}
      "messages": { <msg type>: [hex_string1, ]
    '''
    def __init__(self, * p_arg, ** n_arg):
        super(ExaStorage, self).__init__()
        self._lock = threading.Lock()

    def __enter__(self):
        self._lock.acquire()
        return self

    def __exit__(self, type, value, traceback):
        self._lock.release()


class Rpcs:
    '''Handler for SimpleXMLRPCServer'''

    def __init__(self, storage):
        '''Init method

        Arguments:
            :storage: thread safe dict
        '''
        self.storage = storage

    def _write(self, text):
        '''Method for passing commands from rpc server towards exabgp

        Arguments:
            :text: exabgp command
        '''
        logging.debug('Command towards exabgp: {}'.format(text))
        sys.stdout.write(text)
        sys.stdout.write("\n")
        sys.stdout.flush()
        logging.debug('Connand flushed: {}.'.format(text))

    def get_counter(self, msg_type):
        '''Gets counter value

        Arguments:
            :msg_type: message type which counter should be returned
        Returns:
            :cnt: counter value
        '''
        logging.debug('get_counter rpc called, storage {}'.format(self.storage))
        with self.storage as s:
            cnt = s['counters'][msg_type]
        return cnt

    def clean_counter(self, msg_type):
        '''Cleans counter

        Arguments:
            :msg_type: message type which counter should be cleaned
        '''

        logging.debug('clean_counter rpc called, storage {}'.format(self.storage))
        with self.storage as s:
            if msg_type in s['counters']:
                del s['counters'][msg_type]
        return

    def execute(self, exabgp_cmd):
        '''Execite given command on exabgp

        Arguments:
            :exabgp_cmd: command
        ''''
        logging.info('executing: {}.'.format(exabgp_cmd))
        self._write(exabgp_cmd)
        return


def decode_message(header, body):
    '''Decodes message

    Arguments:
        :header: hexstring of the header
        :body: hexstring of the body
    Returns:
        :msg_type: message type
        :msg: None (in the future some decoded data)
    '''
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
    '''Increments the counter for a message

    Arguments:
        :key: message type
    '''
    with storage as s:
        if 'counters' not in s:
            s['counters'] = {}
        if key not in s['counters']:
            s['counters'][key] = 1
        else:
            s['counters'][key] += 1


def handle_open(storage, msg):
    '''Handles received bgp open message

    - incements open counter

    Arguments:
        :msg: hex string of open body
    '''
    logging.debug('Handling Open with storage {}'.format(storage))
    _increment_counter(storage, 'open')


def handle_keepalive(storage, msg):
    '''Handles received bgp keepalive message

    - incements keepalive counter

    Arguments:
        :msg: hex string of message body (in fact it is None)
    '''
    logging.debug('Handling KeepAlive with storage {}'.format(storage))
    _increment_counter(storage, 'keepalive')


def handle_update(storage, msg):
    '''Handles received bgp update message

    - incements update counter

    Arguments:
        :msg: hex string of update body
    '''
    logging.debug('Handling Update with storage {}'.format(storage))
    _increment_counter(storage, 'update')


def handle_route_refresh(storage, msg):
    '''Handles received bgp route refresh message

    - incements route refresh counter

    Arguments:
        :msg: hex string of route refresh body
    '''
    logging.debug('Handling Route Refresh with storage {}'.format(storage))
    _increment_counter(storage, 'route_refresh')


def handle_json_update(storage, jdata):
    '''Handles received json parsed bgp update message

    - incements update counter

    Arguments:
        :jdata: json formated data of update message
    '''
    logging.debug('Handling Json Update with storage {}'.format(storage))
    _increment_counter(storage, 'update')


def handle_json_state(storage, jdata):
    '''Handles received json state message

    This is for future use. This information is not used/required/needed
    at the moment.

    Arguments:
        :jdata: json formated data about connection/peer state
    '''
    logging.debug('Handling Json State with storage {}'.format(storage))


def exa_msg_handler(storage, data, encoder):

    if encoder == 'text':
        if not ('neighbor' in data and 'header' in data and 'body' in data):
            logging.debug('Ignoring received notification from exabgp: {}'.format(data))
            return
        logging.info('Message from exabgp received: {}.'.format(data))
        restr = 'neighbor (?P<ip>[0-9,\.]+) received (?P<mid>[0-9]+) header\
 (?P<header>[0-9,A-F]+) body.?(?P<body>[0-9,A-F]+)?'
        pat = re.compile(restr)
        match = re.search(pat, data)
        if match is None:
            logging.warn('Unexpected data in this part, only bgp message expected. Received: {}.'.format(data))
            return
        msg_type, msg = decode_message(match.groupdict()['header'], match.groupdict()['body'])
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
    elif encoder == 'json':
        jdata = json.loads(data)
        if jdata['type'] == 'state':
            logging.debug('State info received: {}.'.format(data))
        elif jdata['type'] == 'update':
            logging.debug('Update info received: {}.'.format(data))
        elif jdata['type'] == 'notification':
            logging.debug('Notification info received: {}.'.format(data))
        else:
            raise Exception('Unexpected type for data: {}'.format(data))
    else:
        logging.error('Ignoring received data, unknown encoder: {}'.format(encoder))


def main(*argv):
    '''This script is used as i/o api for communication with exabgp

    Arguments:
        :*argv: unparsed cli arguments

    In a separate thread an rpc server is started. This server will be used as an api towards the user.
    Stdin and stdout are used for communication with exabgp.
    '''

    parser = argparse.ArgumentParser(description='ExaBgp rpc server script')
    parser.add_argument('--host', default='127.0.0.1', help='Host where exabgp is running (default is 127.0.0.1)')
    parser.add_argument('--loglevel', default=logging.DEBUG, help='Log level')
    parser.add_argument('--logfile', default='{}/bgp_rem_rpc.log'.format(os.path.dirname(os.path.abspath(__file__))),
                        help='Log file name.')
    parser.add_argument('--encoder', default='json', help='Exabgp encoder type')
    in_args = parser.parse_args(*argv)

    logging.basicConfig(filename=in_args.logfile, level=in_args.loglevel)

    storage = ExaStorage()
    rpcserver = SimpleXMLRPCServer((in_args.host, 8000), allow_none=True)
    rpcserver.register_instance(Rpcs(storage))
    t = threading.Thread(target=rpcserver.serve_forever)
    t.start()

    epoll = select.epoll()

    epoll.register(sys.__stdin__, select.EPOLLIN | select.EPOLLERR | select.EPOLLHUP)

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
                    exa_msg_handler(storage, data, in_args.encoder)
    except Exception as e:
        logging.debug('Exacption occured: {}'.format(e))
    finally:
        rpcserver.shutdown()
        t.join()

if __name__ == '__main__':
    main()

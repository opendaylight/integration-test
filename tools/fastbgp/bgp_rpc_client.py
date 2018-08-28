#!/usr/bin/env python

import xmlrpclib

proxy = xmlrpclib.ServerProxy("http://{}:{}".format("127.0.0.2", 8002))

proxy.clean("update")

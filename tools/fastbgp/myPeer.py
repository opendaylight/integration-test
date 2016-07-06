# Copyright (c) 2015 Cisco Systems, Inc. and others.  All rights reserved.
#
# This program and the accompanying materials are made available under the
# terms of the Eclipse Public License v1.0 which accompanies this distribution,
# and is available at http://www.eclipse.org/legal/epl-v10.html

import xmlrpclib
###############################################################################################
proxy = xmlrpclib.ServerProxy("http://{}:8000".format('127.0.0.2'))
proxy.send('ffffffffffffffffffffffffffffffff0050020000003940010100400200800e2400194604c714a629000119000219999999000101f20cdd809ff70016000000000a05dc10c010080602f20cdd809ff8')

# Copyright (c) 2018 Red Hat, Inc. and others.  All rights reserved.
#
# This program and the accompanying materials are made available under the
# terms of the Eclipse Public License v1.0 which accompanies this distribution,
# and is available at http://www.eclipse.org/legal/epl-v10.html

import logging

logger = None
ch = None
fh = None


def debug():
    ch.setLevel(logging.DEBUG)
    # logger.setLevel(min([ch.level, fh.level]))


class Logger:
    def __init__(self, console_level=logging.INFO, file_level=logging.DEBUG):
        global logger
        global ch
        global fh

        logger = logging.getLogger()
        formatter = logging.Formatter('%(asctime)s | %(levelname).3s | %(name)-20s | %(lineno)04d | %(message)s')
        ch = logging.StreamHandler()
        ch.setLevel(console_level)
        ch.setFormatter(formatter)
        logger.addHandler(ch)
        fh = logging.FileHandler("/tmp/odltools.txt", "w")
        fh.setLevel(file_level)
        fh.setFormatter(formatter)
        logger.addHandler(fh)
        logger.setLevel(min([ch.level, fh.level]))

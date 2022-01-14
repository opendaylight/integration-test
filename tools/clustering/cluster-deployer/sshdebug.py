from SSHLibrary import SSHLibrary

import os
import code


def init(host, user, password):
    host = host
    user = user
    password = password
    lib = SSHLibrary()
    lib.open_connection(host)
    lib.login(username=user, password=password)

    code.interact(local=locals())


init("172.17.0.2", "root", "pass")

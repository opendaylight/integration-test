import logging
import os

import pytest
from src.variables import (
    ODL_SYSTEM_IP,
    ODL_SYSTEM_PASSWORD,
    ODL_SYSTEM_USER,
    TOOLS_SYSTEM_IP,
)


def pytest_itemcollected(item):
    par = item.parent.obj
    node = item.obj
    pref = par.__doc__.strip() if par.__doc__ else par.__class__.__name__
    suf = node.__doc__.strip() if node.__doc__ else node.__name__
    if pref or suf:
        item._nodeid = " ".join((pref, suf))


def pytest_addoption(parser):
    parser.addoption(
        "--private_key",
        action="store",
        default="{}/.ssh/id_rsa".format(os.getenv("HOME")),
    )
    parser.addoption("--user", action="store", default=ODL_SYSTEM_USER)
    parser.addoption("--password", action="store", default=ODL_SYSTEM_PASSWORD)
    parser.addoption("--odl_ip", action="store", default=ODL_SYSTEM_IP)
    parser.addoption("--tools_ip", action="store", default=TOOLS_SYSTEM_IP)


@pytest.hookimpl()
def pytest_configure(config):
    logging.getLogger("requests").setLevel(logging.WARNING)
    logging.getLogger("paramiko").setLevel(logging.WARNING)

    pytest.private_key = config.getoption("--private_key")
    pytest.user = config.getoption("--user")
    pytest.password = config.getoption("--password")
    pytest.odl_ip = config.getoption("--odl_ip")
    pytest.tools_ip = config.getoption("--tools_ip")

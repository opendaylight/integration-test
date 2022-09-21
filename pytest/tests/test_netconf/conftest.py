import os
import pytest
from ...src.variables import ODL_SYSTEM_IP, ODL_SYSTEM_USER, RESTCONFPORT, REST_API, AUTH
from ...src.rest import create_default_session
from ...src.ssh import open_connection_to_tools_system, execute_command, make_dir, upload_files_from_dir
# Variables

session = None
url = "http://{}:{}{}".format(ODL_SYSTEM_IP, RESTCONFPORT, REST_API)


def pytest_itemcollected(item):
    par = item.parent.obj
    node = item.obj
    pref = par.__doc__.strip() if par.__doc__ else par.__class__.__name__
    suf = node.__doc__.strip() if node.__doc__ else node.__name__
    if pref or suf:
        item._nodeid = " ".join((pref, suf))


def pytest_addoption(parser):
    parser.addoption("--user", action="store", default=ODL_SYSTEM_USER)
    parser.addoption("--userhome", action="store", default="/home/{}".format(ODL_SYSTEM_USER))


# Setup before running test suite

@pytest.fixture(scope="module")
def create_session():
    session = create_default_session(auth=AUTH)
    yield session


@pytest.fixture(scope="function")
def connect_to_tools_system(request, create_session):
    user = request.config.getoption("--user")
    userhome = request.config.getoption("--userhome")
    client = open_connection_to_tools_system(user, userhome)

    # Setup before executing the test
    # Deploy Artifact
    command = "wget -q -N 'https://nexus.opendaylight.org/content/repositories/opendaylight.release/org/opendaylight/netconf/netconf-testtool/4.0.0/netconf-testtool-4.0.0-executable.jar' 2>&1"
    stdin, stdout, stderr = execute_command(client, command)

    assert stdout.channel.recv_exit_status() == 0, "Deployment of Artifact failed"

    # NetconfKeywords Deploy Additional Schemas
    remote_dir = "schemas"
    remotedir_creation_status = make_dir(client, remote_dir)
    assert remotedir_creation_status is True, "Creation of directory named {} on remote server failed".format(
        remote_dir)

    source_dir = os.path.join(os.getcwd(), "schemas")
    upload_files_status = upload_files_from_dir(client, source_dir, remote_dir)
    assert upload_files_status is True, "Upload of schema files to remote server {} directory failed".format(remote_dir)

    # Start Testtool
    command = "nohup /usr/bin/java -Xmx1G -Djava.security.egd=file:/dev/./urandom -jar netconf-testtool-4.0.0-executable.jar --device-count 1 --debug true --schemas-dir ./schemas  --md-sal true > testtool.log 2>&1 &"
    stdin, stdout, stderr = execute_command(client, command)

    assert stdout.channel.recv_exit_status() == 0, "Starting of testtool failed"

    yield (session, client)

    # Teardown of the test
    stdin, stdout, stderr = client.exec_command("kill -15 `pidof java`")
    assert stdout.channel.recv_exit_status() == 0, "Test tool couldnot be stopped"

    stdin, stdout, stderr = client.exec_command("rm -rf schemas")
    assert stdout.channel.recv_exit_status() == 0, "Schemas directory could not be removed"

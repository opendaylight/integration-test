import os
from time import sleep

import pytest
from src.rest import create_default_session
from src.ssh import open_connection, execute_command, upload_files_from_dir, execute_command
from src.variables import AUTH


@pytest.fixture(scope="module")
def create_odl_rest_session():
    session = create_default_session(auth=AUTH)
    yield session
    session.close

@pytest.fixture(scope="module")
def create_tools_ssh_session():
    client = open_connection(pytest.tools_ip, pytest.user, pytest.private_key, pytest.password)
    yield client
    client.close

@pytest.fixture(scope="module")
def connect_to_tools_system(create_tools_ssh_session):
    # Setup before executing the test

    client = create_tools_ssh_session

    # Deploy Artifact
    command = "wget -q --no-check-certificate -N 'https://nexus.opendaylight.org/content/repositories/opendaylight.release/org/opendaylight/netconf/netconf-testtool/3.0.6/netconf-testtool-3.0.6-executable.jar' 2>&1"
    _, _, exit_code = execute_command(client, command)

    assert exit_code == 0, "Deployment of Artifact failed"

    # NetconfKeywords Deploy Additional Schemas
    remote_dir = "schemas"

    command = "mkdir -p {}".format(remote_dir)
    _, _, exit_code = execute_command(client, command)

    assert exit_code == 0, "Creation of directory named {} on remote server failed".format(remote_dir)

    source_dir = os.path.join(os.path.dirname(os.path.realpath(__file__)), "schemas")
    upload_files_status = upload_files_from_dir(client, source_dir, remote_dir)
    assert upload_files_status is True, "Upload of schema files to remote server {} directory failed".format(remote_dir)

    # Start Testtool
    command = "nohup /usr/bin/java -Xmx1G -Djava.security.egd=file:/dev/./urandom -jar netconf-testtool-3.0.6-executable.jar --device-count 1 --debug true --schemas-dir ./schemas  --md-sal true > testtool.log 2>&1 & echo $!"
    pid, _, exit_code = execute_command(client, command)

    assert exit_code == 0, "Starting of testtool failed"

    yield client

    # Teardown of the test
    _, _, exit_code = execute_command(client, "kill -15 {}".format(pid))
    assert exit_code == 0, "Test tool could not be stopped"


def test_starttesttool(connect_to_tools_system):
    client = connect_to_tools_system

    # Chcek if device is up and running or not
    retries = 10
    command = 'netstat -punta 2> /dev/null | grep -E ":17830 .+ LISTEN .+java" | wc -l'
    running = False

    for i in range(retries):
        out, _, _ = execute_command(client, command)
        if int(out) != 1:
            sleep(1)
            continue
        else:
            running = True
            break

    assert running is True, "Testtool device is not up and running"

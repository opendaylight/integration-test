import os
from time import sleep
from ...src.variables import ODL_SYSTEM_IP, RESTCONFPORT, REST_API, AUTH
from ...src.ssh import execute_command


def test_starttesttool(connect_to_tools_system):
    session, client = connect_to_tools_system

    # Chcek if device is up and running or not
    retries = 10
    command = 'netstat -punta 2> /dev/null | grep -E ":17830 .+ LISTEN .+java" | wc -l'
    running = False

    for i in range(retries):
        stdin, stdout, stderr = execute_command(client, command)
        val = stdout.read().decode()[0]
        if int(val) != 1:
            sleep(1)
            continue
        else:
            running = True
            break

    assert running == True, "Testtool device is not up and running"

import logging
import os

import paramiko


def open_connection(ip_address, user, private_key, password):
    client = paramiko.SSHClient()
    client.load_system_host_keys()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())

    if len(password) > 0:
        client.connect(hostname=ip_address, port=22, username=user, password=password)
    else:
        client.connect(hostname=ip_address, port=22, username=user, key_filename=private_key)

    return client


def execute_command(client, command):
    _, stdout, stderr = client.exec_command(command)

    out = stdout.read().decode("utf-8").rstrip()
    if out != "":
        logging.debug("SSH out = %s", out)

    err = stderr.read().decode("utf-8").rstrip()
    if err != "":
        logging.debug("SSH err= %s", err)

    exit_code = stdout.channel.recv_exit_status()

    return out, err, exit_code


def upload_files_from_dir(client, source_dir, remote_dir):
    sftp = client.open_sftp()
    for file in os.listdir(source_dir):
        try:
            sftp.put(os.path.join(source_dir, file), "./schemas/{}".format(file))
        except IOError as e:
            logging.error(e)
            return False
    sftp.close()
    return True

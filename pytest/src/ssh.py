from variables import ODL_SYSTEM_IP, ODL_SYSTEM_USER, ODL_SYSTEM_PASSWORD
import paramiko
import logging
import os


# Variables

SSHKeywords__current_remote_working_directory = "."
SSHKeywords__current_venv_path = "/tmp/defaultvenv"
NETSTAT_COMMAND = "netstat -punta"


def ssh_login(client, ip_address, user, userhome, password=""):
    if len(password) > 0:
        client.connect(hostname=ip_address, port=22, username=user, password=password)
    else:
        client.connect(hostname=ip_address, port=22, username=user,
                       key_filename=os.path.join(userhome, ".ssh", "id_rsa"))
    return client


def open_connection_to_tools_system(user, userhome, ip_address=ODL_SYSTEM_IP, password=ODL_SYSTEM_PASSWORD):
    client = paramiko.SSHClient()
    client.load_system_host_keys()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    client = ssh_login(client, ip_address, user, userhome, password)
    return client


def execute_command(client, command):
    return client.exec_command(command)


def make_dir(client, remote_dir):
    sftp = client.open_sftp()
    try:
        sftp.mkdir(remote_dir)
    except IOError as e:
        logging.error(e)
        sftp.close()
        return False
    sftp.close()
    return True


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

def extract_if_list(arg):
    if isinstance(arg, list):
        return arg[0]
    else:
        return arg

def get_variables(version, curr_dir):    
    # if not provided to robot via commandline the default value seems to
    # be a list containing the version
    version = extract_if_list(version)
    curr_dir = extract_if_list(curr_dir)

    # set default variable values
    variables = {
        'ODLREST_CAPPS': '/restconf/config/packetcable:ccaps',
        'CCAP_TOKEN': 'ccap',
        'PACKETCABLE_RESOURCE_DIR': 
            ''.join([curr_dir, "/../../../variables/packetcable/",version])
    }

    # override variables for specific versions
    if (version == 'lithium'):
        variables['ODLREST_CAPPS'] = '/restconf/config/packetcable:ccap'
        variables['CCAP_TOKEN'] = 'ccaps'

    return variables

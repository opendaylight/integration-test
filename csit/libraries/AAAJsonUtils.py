"""
AAAJSonUtils library for looking up relevant information in a json record

This library can be used to take a chunk of json results and mine out
needed information for testing.
Author: Carmen Kelling - HP Enterprise
"""

import json
import jsonpath


def countnodes(args):
    """ Count the number of nodes in a chunk of JSON.

        Because json blobs come in multiple forms, use node, subnode or
        category to assist in defining what to count.

    Args:
        :param jsonblob: a smattering of JSON data to work through
        :param node: a node to look for such as users, groups, domains
        :param subnode: a sub-item to look for, such as domainid
        :param category: from a simple json record, a field to look for

    Returns:
        :returns ctr: the correct number of records have in the json
    """
    ctr = 0

    try:
        jsonobj = json.loads(args['jsonblob'])
    except KeyError:
        print "countnodes: json blob to parse not found"
        raise

    if 'subnode' in args:
        ctr = len(jsonobj)
    elif 'category' in args:
        category_ = args['category'].encode('ascii', 'ignore')
        ctr = len(jsonobj[category_])
    else:
        # working with a single record, short-cut and return count of 1
        return 1
    return ctr


def fieldcount(pobject, field):
    """ Helper-func - use countnodes to count the occurences of field in pobject

        example
        count the occurences of domainid in this single record...

        [ {
              "description": "default odl sdn domain",
              "domainid": 1,
              "enabled": "true",
              "name": "MasterTest Domain"
          } ]

    Args:
        :param pobject: JSON code to work through
        :param field: an element to search for and count

    Returns:
        :returns number_nodes: the correct number of fields you counted
        in the json
    """
    number_nodes = countnodes({'jsonblob': pobject, 'field': field})
    return number_nodes


def subnodecount(pobject, subnode):
    """ Helper-func - use countnodes to count subnode in pobject

        example
        count the occurences of domainid in this json.
        this chunk lacks nested dictionary keywords (users, domains, roles)...

        {
              "description": "odl master domain",
              "domainid": 1,
              "enabled": "true",
              "name": "Master Test Domain"
        }
        {
              "description": "sdn user domain",
              "domainid": 2,
              "enabled": "true",
              "name": "User Domain"
        }
        ...

    Args:
        :param pobject: JSON code to work through
        :param subnode: a subnode, such as domainid, to search for and count

    Returns:
        :returns number_nodes: the correct number of fields you counted
        in the json
    """
    number_nodes = countnodes({'jsonblob': pobject, 'subnode': subnode})
    return number_nodes


def nodecount(pobject, category, node):
    """ Helper-func - use countnodes function to count node of a category type

        example
        count the domainid in these properly formatted json blobs...

        "domains: [
            {
              "description": "odl master domain",
              "domainid": 1,
              "enabled": "true",
              "name": "Master Test Domain"
            }
            {
              "description": "sdn user domain",
              "domainid": 2,
              "enabled": "true",
              "name": "User Domain"
            }
            ...
        ]
        "users": [
            ...
        ]

    Args:
        :param pobject: JSON code to work through
        :param node: a node, such as domainid, to search for in a properly
        formatted json object, and count

    Returns:
        :returns number_nodes: the correct number of fields you counted
        in the json
    """
    number_nodes = \
        countnodes({'jsonblob': pobject, 'category': category, 'node': node})
    return number_nodes


def get_id_by_name(args):
    """ Get an ID by the Name field.

        Go through the json given, and pull out all ids that are identified
        by the corresponding name argument.

    Args:
        :param jsonblob: a smattering of JSON code to work through
        :param name: a name to look up in the database of json
        :param head: will be one of roles, users, domains
        :param typeval: literal value of either user, role or domain
        :param size: a count on the number of records to search

    Returns:
        :returns nodelist: return the first id that has same corresponding name
    """
    try:
        jsonobj = json.loads(args['jsonblob'])
    except KeyError:
        print "get_id_by_name: json blob not specified:"
        raise

    try:
        name = args['name']
    except KeyError:
        print "get_id_by_name: name [usr, domain, role] not specified in args"
        raise

    if 'head' in args:
        blobkey = args['head']
    else:
        # use an empty key when the arg is not specified.  deals with simpler
        # form
        blobkey = ''

    try:
        datatype = args['typeval']
    except KeyError:
        print "get_id_by_name: need a type arg to process correct name for id"
        raise

    try:
        ncount = args['size']
    except KeyError:
        raise

    nodelist = []

    # Loop through the records looking for the specified name.  When found,
    # return the corresponding attribute value
    if ncount > 0:
        for i in range(ncount):
            # build up some 'lookup' keys, call jsonpath with that key
            bkey1 = '$.' + blobkey + '[' + str(i) + '].name'
            typename = datatype + 'id'
            bkey2 = '$.' + blobkey + '[' + str(i) + '].' + typename

            # find records with same name
            name_record = jsonpath.jsonpath(jsonobj, bkey1)
            # find corresponding node info, for that name
            node_record = jsonpath.jsonpath(jsonobj, bkey2)

            # build up an alternative set of keys.  This lets you deal with
            # other format of json
            bkey3 = '$.' + blobkey + '.name'
            typename2 = datatype + 'id'
            bkey4 = '$.' + blobkey + '.' + typename2

            # find records with same name
            altname_record = jsonpath.jsonpath(jsonobj, bkey3)
            # find corresponding record node info, for that name
            altnode_record = jsonpath.jsonpath(jsonobj, bkey4)
            try:
                if name in list(name_record):
                    nodelist.append(node_record.pop())
            except:
                try:
                    if name in list(altname_record):
                        nodelist.append(altnode_record.pop())
                except:
                    raise

    try:
        return nodelist.pop()
    except LookupError:
        raise


def get_attribute_by_id(args):
    """ Get an attribute by the id field.

        Each json record in the json blob has a unique ID, return
        the corresponding attribute field from that record.  Could be
        description, name, email, password, or any field in available
        in that record.

    Args:
        :param jsonblob: a smattering of JSON code to work through
        :param id: the ID to look up in the database of json
        :param head: will be one of roles, users, domains
        :param typeval: literal value of either user, role or domain
        :param size: a count on the number of records to search

    Returns:
        :returns name_record: the name attribute value that corresponds
        to the provided id
    """
    try:
        jsonobj = json.loads(args['jsonblob'])
    except KeyError:
        print "get_attribute_by_id: json blob not specified:"
        raise

    try:
        nodeid = args['id']
    except KeyError:
        print "get_attribute_by_id: id to look for not specified in parameters"
        raise

    if 'attr' in args:
        attr = args['attr']
    else:
        # If caller does not specify a record attribute to return, then
        # simply default to giving the description of the id you are
        # searching on
        attr = 'description'

    if 'head' in args:
        # will be one of roles, users, domains, or empty to process more
        # specific grouping of json data
        blobkey = args['head']
    else:
        # use an empty key when the arg is not specified, allows us to
        # process chunk of JSON without the outer layer defining roles,
        # users, domains. (simpler format)
        blobkey = ''

    try:
        datatype = args['typeval']
    except KeyError:
        print "get_attribute_by_id: need type arg to process name for id"
        raise

    try:
        size = args['size']
    except KeyError:
        print "get_attribute_by_id: specify number of records we need"
        raise

    # Loop through the records looking for the nodeid, when found, return
    # the corresponding attribute value

    ncount = size
    if ncount > 0:
        for i in range(ncount):
            bkey1 = '$.' + blobkey + '[' + str(i) + '].' + attr
            bkey2 = '$.' + blobkey + '[' + str(i) + '].' + datatype + 'id'

            bkey3 = '$.' + blobkey + '.' + attr
            bkey4 = '$.' + blobkey + '.' + datatype + 'id'

            name_record = jsonpath.jsonpath(jsonobj, bkey1)
            node_record = jsonpath.jsonpath(jsonobj, bkey2)
            altname_record = jsonpath.jsonpath(jsonobj, bkey3)
            altnode_record = jsonpath.jsonpath(jsonobj, bkey4)

            if type(node_record) is list:
                if nodeid in list(node_record):
                    return name_record.pop()
            else:
                try:
                    node_record
                except:
                    print "not in list"
                else:
                    return name_record

            if type(altnode_record) is list:
                if nodeid in list(altnode_record):
                    return altname_record.pop()
                else:
                    try:
                        altnode_record
                    except:
                        print "not in list"
                    else:
                        return altname_record


def get_role_id_by_rolename(pobject, rolename, number_nodes):
    """ Helper-func - use get_id_by_name to obtain role-ids for a role-name

        sample record...
        "roles": [ {
              "description": "a role for admins",
              "name": "admin",
              "roleid": 1
          }
          {
              ...
          } ]

    Args:
        :param pobject: JSON blob to work through
        :param rolename: the name element to search for
        :param number_nodes: number of records to process

    Returns:
        :returns roleid:  a list of one or more roleid's that match
        the rolename given
    """
    roleid = get_id_by_name({'jsonblob': pobject,
                             'name': rolename,
                             'head': 'roles',
                             'size': number_nodes,
                             'typeval': 'role'})
    try:
        roleid
    except:
        raise
    else:
        return roleid


def get_role_name_by_roleid(pobject, roleid, number_nodes):
    """ Helper-func - use get_attribute_by_id to get role-name for a role-id

        sample record...
        "roles": [ {
              "description": "a role for admins",
              "name": "admin",
              "roleid": 1
          }
          {
              ...
          } ]

    Args:
        :param pobject: JSON blob to work through
        :param roleid: the identifier element to search for
        :param number_nodes: number of records to process

    Returns:
        :returns rolename:  the role name that corresponds to the record
        identified by the role-id
    """
    rolename = get_attribute_by_id({'jsonblob': pobject,
                                    'head': 'roles',
                                    'id': roleid,
                                    'attr': 'name',
                                    'size': number_nodes,
                                    'typeval': 'role'})
    try:
        rolename
    except:
        raise
    else:
        return rolename


def get_role_description_by_roleid(pobject, roleid, number_nodes):
    """ Helper-func - get role-description for a role-id

        sample record...
        "roles": [ {
              "description": "a role for admins",
              "name": "admin",
              "roleid": 1
          }
          {
              ...
          } ]

    Args:
        :param pobject: JSON blob to work through
        :param roleid: the identifier element to search for
        :param number_nodes: number of records to process

    Returns:
        :returns roledesc:  the role description that corresponds to the record
        identified by the role-id
    """
    roledesc = get_attribute_by_id({'jsonblob': pobject,
                                    'head': 'roles',
                                    'id': roleid,
                                    'attr': 'description',
                                    'size': number_nodes,
                                    'typeval': 'role'})
    try:
        roledesc
    except:
        raise
    else:
        return roledesc


def get_domain_id_by_domainname(pobject, domainname, number_nodes):
    """ Helper-func - get all domain-ids corresponding to domain-name

        sample record...
        "domains": [ {
              "description": "default odl sdn domain",
              "domainid": 1,
              "enabled": true,
              "name": "admin"
          }
          {
              ...
          } ]

    Args:
        :param pobject: JSON blob to work through
        :param domainname: the name element to search for
        :param number_nodes: number of records to process

    Returns:
        :returns domainid:  a list of one or more domain-id's that match
        the domain-name given
    """
    domainid = get_id_by_name({'jsonblob': pobject,
                               'name': domainname,
                               'size': number_nodes,
                               'typeval': 'domain'})

    try:
        domainid
    except:
        raise
    else:
        return domainid


def get_domain_name_by_domainid(pobject, domainid, number_nodes):
    """ Helper-func - get domain-name for a particular domainid

        sample record...
        "domains": [ {
              "description": "default odl sdn domain",
              "domainid": 1,
              "enabled": true,
              "name": "admin"
          }
          {
              ...
          } ]

    Args:
        :param pobject: JSON blob to work through
        :param domainid: the identifier element to search for
        :param number_nodes: number of records to process

    Returns:
        :returns domainname:  the domain name that corresponds to the record
        identified by the domainid
    """
    domainname = get_attribute_by_id({'jsonblob': pobject,
                                      'head': 'domains',
                                      'id': domainid,
                                      'attr': 'name',
                                      'size': number_nodes,
                                      'typeval': 'domain'})
    try:
        domainname
    except:
        raise
    else:
        return domainname


def get_domain_description_by_domainid(pobject, domainid, number_nodes):
    """ Helper-func - get the domaind descripton for a particular domainid

        sample record...
        "domains": [ {
              "description": "default odl sdn domain",
              "domainid": 1,
              "enabled": true,
              "name": "admin"
          }
          {
              ...
          } ]

    Args:
        :param pobject: JSON blob to work through
        :param domainid: the identifier element to search for
        :param number_nodes: number of records to process

    Returns:
        :returns domainname:  the domain description field that corresponds
        to the record identified by the domainid
    """
    domaindesc = get_attribute_by_id({'jsonblob': pobject,
                                      'head': 'domains',
                                      'id': domainid,
                                      'attr': 'description',
                                      'size': number_nodes,
                                      'typeval': 'domain'})
    try:
        domaindesc
    except:
        raise
    else:
        return domaindesc


def get_domain_state_by_domainid(pobject, domainid, number_nodes):
    """ Helper-func - get domain state field  for a particular domainid

        sample record...
        "domains": [ {
              "description": "default odl sdn domain",
              "domainid": 1,
              "enabled": true,
              "name": "admin"
          }
          {
              ...
          } ]

    Args:
        :param pobject: JSON blob to work through
        :param domainid: the identifier element to search for
        :param number_nodes: number of records to process

    Returns:
        :returns domainstate:  the domain state (enabled) field that
        corresponds to the record identified by the domainid
    """
    domainstate = get_attribute_by_id({'jsonblob': pobject,
                                       'head': 'domains',
                                       'id': domainid,
                                       'attr': 'enabled',
                                       'size': number_nodes,
                                       'typeval': 'domain'})
    try:
        domainstate
    except:
        raise
    else:
        return domainstate


def get_user_id_by_username(pobject, username, number_nodes):
    """ Helper-func - get user-ids corresponding to username

        sample record...
        "users": [ {
              "description": "admin user",
              "email": "admin@anydomain.com",
              "enabled": true,
              "userid": 1,
              "name": "admin",
              "password": "**********",
              "userid": 1
          }
          {
              ...
          } ]

    Args:
        :param pobject: JSON blob to work through
        :param username: the name element to search for
        :param number_nodes: number of records to process

    Returns:
        :returns userid:  a list of one or more user-id's that match
        the username given
    """
    userid = get_id_by_name({'jsonblob': pobject,
                             'name': username,
                             'head': 'users',
                             'size': number_nodes,
                             'typeval': 'user'})
    try:
        userid
    except:
        raise
    else:
        return userid


def get_user_password_by_userid(pobject, userid, number_nodes):
    """ Helper-func - get user password field for a particular userid

        sample record...
        "users": [ {
              "description": "admin user",
              "email": "admin@anydomain.com",
              "enabled": true,
              "userid": 1,
              "name": "admin",
              "password": "**********",
              "userid": 1
          }
          {
              ...
          } ]

    Args:
        :param pobject: JSON blob to work through
        :param userid: the identifier element to search for
        :param number_nodes: number of records to process

    Returns:
        :returns userpassword:  the raw password field that corresponds to
         the record identified by the userid
    """
    userpassword = get_attribute_by_id({'jsonblob': pobject,
                                        'head': 'users',
                                        'id': userid,
                                        'attr': 'password',
                                        'size': number_nodes,
                                        'typeval': 'user'})
    try:
        userpassword
    except:
        raise
    else:
        return userpassword


def get_user_name_by_userid(pobject, userid, number_nodes):
    """ Helper-func - get the username field for a particular userid

        sample record...
        "users": [ {
              "description": "admin user",
              "email": "admin@anydomain.com",
              "enabled": true,
              "userid": 1,
              "name": "admin",
              "password": "**********",
              "userid": 1
          }
          {
              ...
          } ]

    Args:
        :param pobject: JSON blob to work through
        :param userid: the identifier element to search for
        :param number_nodes: number of records to process

    Returns:
        :returns username:  the name field that corresponds to the record
        identified by the userid
    """
    username = get_attribute_by_id({'jsonblob': pobject,
                                    'head': 'users',
                                    'id': userid,
                                    'attr': 'name',
                                    'size': number_nodes,
                                    'typeval': 'user'})
    try:
        username
    except:
        raise
    else:
        return username


def get_user_state_by_userid(pobject, userid, number_nodes):
    """ Helper-func - get user state field for a particular userid

        sample record...
        "users": [ {
              "description": "admin user",
              "email": "admin@anydomain.com",
              "enabled": true,
              "userid": 1,
              "name": "admin",
              "password": "**********",
              "userid": 1
          }
          {
              ...
          } ]

    Args:
        :param pobject: JSON blob to work through
        :param userid: the identifier element to search for
        :param number_nodes: number of records to process

    Returns:
        :returns userstate:  the enabled field that corresponds to the record
        identified by the userid
    """
    userstate = get_attribute_by_id({'jsonblob': pobject,
                                     'head': 'users',
                                     'id': userid,
                                     'attr': 'enabled',
                                     'size': number_nodes,
                                     'typeval': 'user'})
    try:
        userstate
    except:
        raise
    else:
        return userstate


def get_user_email_by_userid(pobject, userid, number_nodes):
    """ Helper-func - get user email field for a particular userid

        sample record...
        "users": [ {
              "description": "admin user",
              "email": "admin@anydomain.com",
              "enabled": true,
              "userid": 1,
              "name": "admin",
              "password": "**********",
              "userid": 1
          }
          {
              ...
          } ]

    Args:
        :param pobject: JSON blob to work through
        :param userid: the identifier element to search for
        :param number_nodes: number of records to process

    Returns:
        :returns useremail:  the email field that corresponds to the record
        identified by the userid
    """
    useremail = get_attribute_by_id({'jsonblob': pobject,
                                     'head': 'users',
                                     'id': userid,
                                     'attr': 'email',
                                     'size': number_nodes,
                                     'typeval': 'user'})
    try:
        useremail
    except:
        raise
    else:
        return useremail


def get_user_description_by_userid(pobject, userid, number_nodes):
    """ Helper-func - get user description field for a particular userid

        sample record...
        "users": [ {
              "description": "admin user",
              "email": "admin@anydomain.com",
              "enabled": true,
              "userid": 1,
              "name": "admin",
              "password": "**********",
              "userid": 1
          }
          {
              ...
          } ]

    Args:
        :param pobject: JSON blob to work through
        :param userid: the identifier element to search for
        :param number_nodes: number of records to process

    Returns:
        :returns userdesc:  the description field that corresponds to the
        record identified by the userid
    """
    userdesc = get_attribute_by_id({'jsonblob': pobject,
                                    'head': 'users',
                                    'id': userid,
                                    'attr': 'description',
                                    'size': number_nodes,
                                    'typeval': 'user'})
    try:
        userdesc
    except:
        raise
    else:
        return userdesc

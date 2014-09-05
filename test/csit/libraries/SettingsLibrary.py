__author__ = "Basheeruddin Ahmed"
__copyright__ = "Copyright(c) 2014, Cisco Systems, Inc."
__license__ = "New-style BSD"
__email__ = "syedbahm@cisco.com"

from string import Template

# helps in taking the hostname entered by the user
#global hostname 
#global port

#def setHostname(host):
#     hostname=host

#def getServer():
#    return hostname +":"+"8080"

#Cars resource URL for GET
def getCarsUrl(hostname,port):

    return "http://"+hostname+":"+port+"/restconf/config/car:cars"

#People resouce URL for GET
def getPersonsUrl(hostname,port):

    return "http://"+hostname+":"+port+"/restconf/config/people:people"

#GET cars persons mapping resource URL
def getCarPersonUrl(hostname,port):

    return "http://"+hostname+":"+port+"/restconf/config/car-people:car-people"

#POST or DELETE URL
def getAddCarUrl(hostname,port):
    return "http://"+hostname+":"+port+"/restconf/config"
#POST or DELETE URL
def getAddPersonUrl(hostname,port):
    return "http://"+hostname+":"+port+"/restconf/config"

#POST URL -using rpc
def getAddPersonRpcUrl(hostname,port):
    return "http://"+hostname+":"+port+"/restconf/operations/people:add-person"

#POST URL for car person mapping
def getAddCarPersonUrl(hostname,port):
   return "http://"+hostname+":"+port+"/restconf/config"
#POST URL for buy car rpc
def getBuyCarRpcUrl(hostname,port):
    return "http://"+hostname+":"+port+"/restconf/operations/car-purchase:buy-car"


# Template for Car resource payload
add_car_payload_template = Template( '{\"car:cars\":{'
    '\"car-entry\": ['
        '{'
            '\"id\": \"$id\",'
            '\"category\": \"$category\",'
            '\"model\": \"$model\",'
            '\"manufacturer\": \"$manufacturer\",'
            '\"year\": \"$year\"'
        '}'
    ']'
'}'
'}')

# Template for Person resource payload
add_person_payload_template =  Template( '{\"people:people":{'
    '\"person\": ['
        '{'
            '\"id\": \"$personId\",'
            '\"gender\": \"$gender\",'
            '\"age\": \"$age\",'
            '\"address\": \"$address\",'
            '\"contactNo\":\"$contactNo\"'
        '}'
            ']'
     '}}')

# Template for Car Person mapping  payload
add_car_person_template = Template('{\"car-people:car-people\":{'
    '\"car-person\": ['
        '{'
           ' \"car-id\": \"$Id\",'
            '\"person-id\": \"$personId\"'
        '}'
    ']'
'}'
'}')

# Template for adding person using RPC
add_person_rpc_payload_template = Template ( '{'
                                                 '\"input\":'
                                                     '{'
                                                         '\"people:id\" : \"$personId\",'
                                                         '\"people:gender\":\"$gender\",'
                                                         '\"people:address\" : \"$address\",'
                                                         '\"people:contactNo\":\"$contactNo\",'
                                                         '\"people:age\":\"$age\"'
                                                     '}'
                                             '}')

# Template for buing car rpc
buy_car_rpc_template = Template ( '{'
    '\"input\" :'
        '{'
            '\"car-purchase:person\" : \"/people:people/people:person[people:id=\'$personId\']\",'
            '\"car-purchase:person-id\" : \"$personId\",'
            '\"car-purchase:car-id\" : \"$carId\"'
        '}'
'}')




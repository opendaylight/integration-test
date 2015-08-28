__author__ = "Basheeruddin Ahmed"
__copyright__ = "Copyright(c) 2014, Cisco Systems, Inc."
__license__ = "New-style BSD"
__email__ = "syedbahm@cisco.com"

from string import Template

# helps in taking the hostname entered by the user
global hostname
global port


def getServer():
    return hostname + ":" + port  # noqa


def getCarsUrl():
    """Cars resource URL for GET"""
    return "http://" + getServer() + "/restconf/config/car:cars"


def getPersonsUrl():
    """People resouce URL for GET"""
    return "http://" + getServer() + "/restconf/config/people:people"


def getCarPersonUrl():
    """GET cars persons mapping resource URL"""
    return "http://" + getServer() + "/restconf/config/car-people:car-people"


def getAddCarUrl():
    """POST or DELETE URL"""
    return "http://" + getServer() + "/restconf/config"


def getAddPersonUrl():
    """POST or DELETE URL"""
    return "http://" + getServer() + "/restconf/config"


def getAddPersonRpcUrl():
    """POST URL -using rpc"""
    return "http://" + getServer() + "/restconf/operations/people:add-person"


def getAddCarPersonUrl():
    """POST URL for car person mapping"""
    return "http://" + getServer() + "/restconf/config"


def getBuyCarRpcUrl():
    """POST URL for buy car rpc"""
    return "http://" + getServer() + "/restconf/operations/car-purchase:buy-car"


# Template for Car resource payload
add_car_payload_template = Template(
    """
    {"car:cars":{
        "car-entry": [
            {
                "id": "$id",
                "category": "$category",
                "model": "$model",
                "manufacturer": "$manufacturer",
                "year": "$year"
            }
        ]
    }}
    """)

# Template for Person resource payload
add_person_payload_template = Template(
    """
    {"people:people":{
        "person": [
            {
                "id": "$personId",
                "gender": "$gender",
                "age": "$age",
                "address": "$address",
                "contactNo":"$contactNo"
            }
        ]
    }}
    """)

# Template for Car Person mapping  payload
add_car_person_template = Template(
    """
    {"car-people:car-people":{
        "car-person": [
            {
                "car-id": "$Id",
                "person-id": "$personId"
            }
        ]
    }}
    """)

# Template for adding person using RPC
add_person_rpc_payload_template = Template(
    """
    {
    "input":
        {
            "people:id" : "$personId",
            "people:gender":"$gender",
            "people:address" : "$address",
            "people:contactNo":"$contactNo",
            "people:age":"$age"
        }
    }
    """)

# Template for buying car rpc
buy_car_rpc_template = Template(
    """
    {
    "input" :
        {
            "car-purchase:person" : "/people:people/people:person[people:id='$personId']",
            "car-purchase:person-id" : "$personId",
            "car-purchase:car-id" : "$carId"
        }
    }
    """)

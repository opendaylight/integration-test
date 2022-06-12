#Basic test to get the restconf modules, check 200 status and ietf-restconf presence.
#Importing required packages
import requests
import logging

ODL_SYSTEM_1_IP = "127.0.0.1"
ODL_SYSTEM_2_IP = "127.0.0.2"
ODL_SYSTEM_1_IP = "127.0.0.3"
ODL_SYSTEM_IP = ODL_SYSTEM_1_IP
RESTCONFPORT = 8181
ODL_RESTCONF_USER = "admin"
ODL_RESTCONF_PASSWORD = "admin"
AUTH = (ODL_RESTCONF_USER,ODL_RESTCONF_PASSWORD)
HEADERS_XML = {'Content-Type': 'application/xml'}
MODULES_API = "/rests/data/ietf-yang-library:modules-state"

#Function to create a session
def create_session(AUTH, HEADER):
    #Creating sesion object
    session = requests.Session()
    #Authentication
    session.auth = AUTH
    #Updating headers
    session.headers.update(HEADER)
    return session

#Function to make a get request
def make_get_request():
    session = create_session(AUTH, HEADERS_XML)

    #Making get request
    try:
        resp = session.get("http://{}:{}/{}".format(ODL_SYSTEM_IP, RESTCONFPORT, MODULES_API))
        logging.info(self.resp.json())
        return resp
    except Exception(e):
        logging.error(e)


class TestBasic:

    #Make api call
    resp = make_get_request()

    def test_get_restconf_module(self):
        assert isinstance(self.resp, requests.models.Response) == True

    def test_check_status(self):
        assert self.resp.status_code == 200

    def test_content(self):
        assert self.resp.content == "ietf-restconf"
        #Closing the session
        #Placing this line here, because this test will be run last in sequential order by pytest
        self.resp.close() 
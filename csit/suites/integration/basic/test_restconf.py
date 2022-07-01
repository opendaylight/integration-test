# Basic test to get the restconf modules, check 200 status and ietf-restconf presence.
# Importing required packages
import requests
import logging

# Function to create a session


def create_session(auth, header):
    # Creating sesion object
    session = requests.Session()
    # Authentication
    session.auth = auth
    # Updating headers
    session.headers.update(header)
    return session


# Function to make a get request


def make_get_request(auth, headers, odl_system_ip, restconfport, modules_api):
    session = create_session(auth, headers)

    # Making get request
    try:
        resp = session.get(
            "http://{}:{}{}".format(odl_system_ip, restconfport, modules_api)
        )
        logging.info(resp.json())
        return resp
    except Exception as e:
        logging.error(e)


class TestBasic:
    """ """
    # Make api call
    resp = make_get_request(
        ("admin", "admin"),
        {"Content-Type": "application/xml"},
        "127.0.0.1",
        8181,
        "/rests/data/ietf-yang-library:modules-state",
    )

    def test_get_restconf_module(self):
        """Check if restconf_module returns a response"""
        assert isinstance(self.resp, requests.models.Response) is True

    def test_check_status(self):
        """Check if the status code is 200"""
        assert self.resp.status_code == 200

    def test_content(self):
        """Check if the response content contains the word ietf-restconf"""
        # Checking if the text content contains "ietf-restconf" or not
        assert self.resp.text.find("ietf-restconf") != -1
        # Closing the session
        # Placing this line here, because this test will be run last in sequential order by pytest
        self.resp.close()

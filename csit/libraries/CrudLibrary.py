__author__ = "Basheeruddin Ahmed"
__copyright__ = "Copyright(c) 2014, Cisco Systems, Inc."
__license__ = "New-style BSD"
__email__ = "syedbahm@cisco.com"
import sys
import UtilLibrary
import SettingsLibrary
import time


def initCar(hostname, port):
    """Initiales the car shard"""
    x = 0
    strId = str(x)
    payload = SettingsLibrary.add_car_init_payload_template.substitute(
        id=strId, category="category" + strId, model="model" + strId,
        manufacturer="manufacturer" + strId,
        year=(2000 + x % 100))
    print("Initialization payload=")
    print(payload)
    resp = UtilLibrary.post(SettingsLibrary.getAddCarInitUrl(hostname, port), "admin", "admin", payload)
    print("the response of the POST to add car=")
    print(resp)
    return resp


def addCar(hostname, port, numberOfCars, *expected):
    """Creates the specified number of cars based on Cars yang model using RESTCONF"""
    for x in range(1, numberOfCars + 1):
        strId = str(x)
        payload = SettingsLibrary.add_car_payload_template.substitute(
            id=strId, category="category" + strId, model="model" + strId,
            manufacturer="manufacturer" + strId,
            year=(2000 + x % 100))
        print("payload formed after template substitution=")
        print(payload)
        # Send the POST request
        resp = UtilLibrary.post(SettingsLibrary.getAddCarUrl(hostname, port), "admin", "admin", payload)

        print("the response of the POST to add car=")
        print(resp)
        if expected and str(resp.status_code) not in expected:
            raise RuntimeError('Add car failed for {}:{} with status {}'.
                               format(hostname, port, resp.status_code))

    return resp

    # TBD: Detailed validation


def addPerson(hostname, port, numberOfPersons, *expected):
    """Creates the specified number of persons based on People yang model using main RPC
    <note>
        To enable RPC a non-user input person entry is created with personId=user0
    </note>
    """
    # FOR RPC TO WORK PROPERLY THE FIRST ENTRY SHOULD BE VIA RESTCONF
    if (numberOfPersons == 0):
        strId = str(numberOfPersons)
        payload = SettingsLibrary.add_person_payload_template.substitute(
            personId="user" + strId, gender="unknown", age=0,
            address=strId + "Way, Some Country, Some Zip  " + strId,
            contactNo="some number" + strId)
        # Send the POST request using RESTCONF
        resp = UtilLibrary.nonprintpost(SettingsLibrary.getAddPersonUrl(hostname, port), "admin", "admin", payload)
        return resp

    genderToggle = "Male"
    for x in range(1, numberOfPersons+1):
        if(genderToggle == "Male"):
            genderToggle = "Female"
        else:
            genderToggle = "Male"

        strId = str(x)

        payload = SettingsLibrary.add_person_rpc_payload_template.substitute(
            personId="user" + strId, gender=genderToggle, age=(20 + x % 100),
            address=strId + "Way, Some Country, Some Zip  " + str(x % 1000),
            contactNo= "some number" + strId)
        # Send the POST request using RPC
        resp = UtilLibrary.post(SettingsLibrary.getAddPersonRpcUrl(hostname, port), "admin", "admin", payload)

        print("payload formed after template substitution=")
        print(payload)
        print("the response of the POST to add person=")
        print(resp)
        if expected and str(resp.status_code) not in expected:
            raise RuntimeError('Add person failed for {}:{} with status {}'.
                               format(hostname, port, resp.status_code))

    return resp

    # TBD: Detailed validation


def addCarPerson(hostname, port, numberOfCarPersons):
    """This method is not exposed via commands as only getCarPersons is of interest

    addCarPerson entry happens when buyCar is called
    <note>
        To enable RPC a non-user input car-person entry is created with personId=user0
    </note>
    """
    # FOR RPC TO WORK PROPERLY THE FIRST ENTRY SHOULD BE VIA RESTCONF
    if (numberOfCarPersons == 0):
        payload = SettingsLibrary.add_car_person_template.substitute(
            Id=str(numberOfCarPersons), personId="user" + str(numberOfCarPersons))
        # Send the POST request REST CONF
        resp = UtilLibrary.nonprintpost(SettingsLibrary.getAddCarPersonUrl(hostname, port), "admin", "admin", payload)

        return resp

    for x in range(1, numberOfCarPersons+1):
        strId = str(x)

        payload = SettingsLibrary.add_car_person_template.substitute(Id=strId, personId="user" + strId)

        # Send the POST request REST CONF
        resp = UtilLibrary.post(SettingsLibrary.getAddCarPersonUrl(hostname, port), "admin", "admin", payload)

        print("payload formed after template substitution=")
        print(payload)

        print("the response of the POST to add car_person=")
        print(resp)

    print("getting the car_persons for verification")
    resp = getCarPersonMappings(hostname, port, 0)
    # TBD detailed validation
    return resp


def buyCar(hostname, port, numberOfCarBuyers, start=0):
    """Invokes an RPC REST call that does a car purchase by a person id

    <note>
        It is expected that the Car and Person entries are already created
        before invoking this method
    </note>
    """

    print "Buying " + str(numberOfCarBuyers) + " Cars"
    for x in range(start, start+numberOfCarBuyers):
        strId = str(x+1)

        payload = SettingsLibrary.buy_car_rpc_template.substitute(personId="user" + strId, carId=strId)

        # Send the POST request using RPC
        resp = UtilLibrary.post(SettingsLibrary.getBuyCarRpcUrl(hostname, port), "admin", "admin", payload)

        print(resp)
        print(resp.text)

        if (resp.status_code != 200):
            raise RuntimeError('Buy car failed for {}:{} with status {}'.
                               format(hostname, port, resp.status_code))


def getCars(hostname, port, ignore):
    """Uses the GET on car:cars resource to get all cars in the store using RESTCONF"""
    resp = UtilLibrary.get(SettingsLibrary.getCarsUrl(hostname, port), "admin", "admin")
    resp.encoding = 'utf-8'
    print(resp.text)
    return resp


def getPersons(hostname, port, ignore):
    """Uses the GET on people:people resource to get all persons in the store using RESTCONF

    <note>
        This also returns the dummy entry created for routed RPC
        with personId being user0
    </note>
    """
    resp = UtilLibrary.get(SettingsLibrary.getPersonsUrl(hostname, port), "admin", "admin")
    resp.encoding = 'utf-8'
    print(resp.text)
    return resp


def getCarPersonMappings(hostname, port, ignore):
    """Uses the GET on car-people:car-people resource

    to get all car-persons entry in the store using RESTCONF
    <note>
        This also returns the dummy entry created for routed RPC
        with personId being user0
    </note>
    """
    resp = UtilLibrary.get(SettingsLibrary.getCarPersonUrl(hostname, port), "admin", "admin")
    resp.encoding = 'utf-8'
    print (resp)

    return resp


def deleteAllCars(hostname, port, ignore):
    """delete all cars in the store using RESTCONF"""
    UtilLibrary.delete(SettingsLibrary.getCarsUrl(hostname, port), "admin", "admin")
    resp = getCars(hostname, port, ignore)
    print("Cars in store after deletion:" + str(resp))


def deleteAllPersons(hostname, port, ignore):
    """delete all persons in the store using RESTCONF"""
    UtilLibrary.delete(SettingsLibrary.getPersonsUrl(hostname, port), "admin", "admin")
    resp = getPersons(hostname, port, ignore)
    print("Persons in store after deletion:" + str(resp))


def deleteAllCarsPersons(hostname, port, ignore):
    """delete all car -poeple s in the store using RESTCONF"""
    UtilLibrary.delete(SettingsLibrary.getCarPersonUrl(hostname, port), "admin", "admin")
    resp = getPersons(hostname, port, ignore)
    print("Persons in store after deletion:" + str(resp))


def testlongevity(inputtime, port, *ips):
    """Write longevity"""
    max_time = int(inputtime)
    start_time = time.time()  # remember when we started
    while (time.time() - start_time) < max_time:
        for ip in ips:
            deleteAllCars(ip, port, 0)
            resp = getCars(ip, port, 0)
            if resp.status_code == 404:
                print("Pass: no cars found after deletion")
            else:
                print("Fail: Cars are present after deletion")
            deleteAllPersons(ip, port, 0)
            resp = getPersons(ip, port, 0)
            if resp.status_code == 404:
                print("Pass: no person found after deletion")
            else:
                print("Fail: people are present after deletion")

            addCar(ip, port, 100)
            time.sleep(20)
            resp = getCars(ip, port, 0)
            if resp.status_code == 200:
                print("Pass: car data available after addition")
                if resp.content.find("manufacturer100") == -1:
                    print("Fail: last car is not there")
                else:
                    print("Pass: car data matches")
            else:
                print("Fail: car addition failed")
            addPerson(ip, port, 0)
            addPerson(ip, port, 100)
            time.sleep(20)
            resp = getPersons(ip, port, 0)
            if resp.status_code == 200:
                print("Pass: people data available after addition")
                if resp.content.find("user100") == -1:
                    print("Fail: last person is not there")
                else:
                    print("Pass: person data matches")
            else:
                print("Fail: person addition failed")

            addCarPerson(ip, port, 0)
            buyCar(ip, port, 100)
            time.sleep(20)
            resp = getCarPersonMappings(ip, port, 0)
            if resp.status_code == 200:
                print("Pass: car person data available after addition")
                if resp.content.find("user100") == -1:
                    print("Fail: last car person is not there")
                else:
                    print("Pass: car person data matches")
            else:
                print("Fail: car person addition failed")
            time.sleep(60)    # sleep before next host starts working


#
# Usage message shown to user
#

def options():

    command = 'ac=Add Car\n\t\tap=Add Person \n\t\tbc=Buy Car\n\t\tgc=Get Cars\n\t\tgp=Get Persons\n\t\t' \
              'gcp=Get Car-Person Mappings\n\t\tdc=Delete All Cars\n\t\tdp=Delete All Persons)'

    param = '\n\t<param> is\n\t\t' \
            'number of cars to be added if <command>=ac\n\t\t' \
            'number of persons to be added if <command>=ap\n\t\t' \
            'number of car buyers if <command>=bc\n\t\t'\
            'pass 0 if <command>=gc or gp or gcp or dc or dp'\


    usageString = 'usage: python crud <ipaddress> <command> <param>\nwhere\n\t<ipaddress> = ODL server ip address' \
                  '\n\t<command> = any of the following commands \n\t\t'

    usageString = usageString + command + param

    print (usageString)


#
# entry point for command executions
#

def main():
    if len(sys.argv) < 4:
        options()
        quit(0)
    SettingsLibrary.hostname = sys.argv[1]
    SettingsLibrary.port = '8181'
    call = dict(ac=addCar, ap=addPerson, bc=buyCar,
                gc=getCars, gp=getPersons, gcp=getCarPersonMappings, dc=deleteAllCars, dp=deleteAllPersons)

    # FOR RPC TO WORK PROPERLY THE FIRST PERSON SHOULD BE ADDED VIA RESTCONF
    addPerson(SettingsLibrary.hostname, SettingsLibrary.port, 0)

    # FOR RPC TO WORK PROPERLY THE FIRST PERSON SHOULD BE ADDED VIA RESTCONF
    addCarPerson(SettingsLibrary.hostname, SettingsLibrary.port, 0)

    call[sys.argv[2]](SettingsLibrary.hostname, SettingsLibrary.port, int(sys.argv[3]))

#
# main invoked
if __name__ == "__main__":
    main()

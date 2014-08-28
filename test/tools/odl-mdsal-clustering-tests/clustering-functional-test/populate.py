__author__ = "Basheeruddin Ahmed"
__copyright__ = "Copyright(c) 2014, Cisco Systems, Inc."
__license__ = "New-style BSD"
__email__ = "syedbahm@cisco.com"
import sys
import util
import settings


#
#Creates the specified number of cars based on Cars yang model
# using RESTCONF
#

def addCar(numberOfCars):

    for x in range(1, numberOfCars+1):
        strId = str(x)
        payload = settings.add_car_payload_template.substitute(id=strId,category="category"+strId,model="model"+strId,
                                                           manufacturer="manufacturer"+strId,
                                                           year=(2000+x%100))
        print("payload formed after template substitution=")
        print(payload)
        # Send the POST request
        resp = util.post(settings.getAddCarUrl(),"admin", "admin",payload)

        print("the response of the POST to add car=")
        print(resp)

    print("getting the cars in store ")
    resp = getCars(0)

    #TBD: Detailed validation


#
#Creates the specified number of persons based on People yang model
# using main RPC
# <note>
#   To enable RPC a non-user input person entry is created with personId=user0
# </note>
#
def addPerson(numberOfPersons):
    #FOR RPC TO WORK PROPERLY THE FIRST ENTRY SHOULD BE VIA RESTCONF
    if(numberOfPersons==0):
        strId =str(numberOfPersons)
        payload = settings.add_person_payload_template.substitute(personId="user"+strId,gender="unknown",age=0,
                                                                  address=strId + "Way, Some Country, Some Zip  "+strId,
                                                                  contactNo= "some number"+strId)
        # Send the POST request using RESTCONF
        resp = util.nonprintpost(settings.getAddPersonUrl(),"admin", "admin",payload)
        return

    genderToggle = "Male"
    for x in range(1, numberOfPersons+1):
        if(genderToggle == "Male"):
            genderToggle = "Female"
        else:
            genderToggle = "Male"

        strId = str(x)

        payload = settings.add_person_rpc_payload_template.substitute(personId="user"+strId,gender=genderToggle,age=(20+x%100),
                                                                      address=strId + "Way, Some Country, Some Zip  "+str(x%1000),
                                                                      contactNo= "some number"+strId)
        # Send the POST request using RPC
        resp = util.post(settings.getAddPersonRpcUrl(),"admin", "admin",payload)

        print("payload formed after template substitution=")
        print(payload)
        print("the response of the POST to add person=")
        print(resp)

    print("getting the persons for verification")
    resp=getPersons(0)

    #TBD: Detailed validation

#This method is not exposed via commands as only getCarPersons is of interest
#addCarPerson entry happens when buyCar is called
# <note>
#   To enable RPC a non-user input car-person entry is created with personId=user0
# </note>
#
def addCarPerson(numberOfCarPersons):

    #FOR RPC TO WORK PROPERLY THE FIRST ENTRY SHOULD BE VIA RESTCONF
    if(numberOfCarPersons==0):
        payload = settings.add_car_person_template.substitute(Id=str(numberOfCarPersons),personId="user"+str(numberOfCarPersons))
        # Send the POST request REST CONF
        resp = util.nonprintpost(settings.getAddCarPersonUrl(),"admin", "admin",payload)

        return

    for x in range(1, numberOfCarPersons+1):
        strId = str(x)

        payload = settings.add_car_person_template.substitute(Id=strId,personId="user"+strId)

        # Send the POST request REST CONF
        resp = util.post(settings.getAddCarPersonUrl(),"admin", "admin",payload)

        print("payload formed after template substitution=")
        print(payload)

        print("the response of the POST to add car_person=")
        print(resp)

    print("getting the car_persons for verification")
    resp=getCarPersons(0)

    #TBD detailed validation

#
# Invokes an RPC REST call that does a car purchase by a person id
# <note>
# It is expected that the Car and Person entries are already created
# before invoking this method
# </note>
#

def buyCar(numberOfCarBuyers):
    for x in range(1, numberOfCarBuyers+1):
        strId = str(x)

        payload = settings.buy_car_rpc_template.substitute(personId="user"+strId,carId=strId)

        # Send the POST request using RPC
        resp = util.post(settings.getBuyCarRpcUrl(),"admin", "admin",payload)

        print("payload formed after template substitution=")
        print(payload)

        print("the response of the POST to buycar=")
        print(resp)

    print("getting the car_persons for verification")
    resp=getCarPersons(0)


#
# Uses the GET on car:cars resource
# to get all cars in the store using RESTCONF
#
#
def getCars(ignore):
    resp = util.get(settings.getCarsUrl(),"admin", "admin")
    print (resp)
    return resp

#
# Uses the GET on people:people resource
# to get all persons in the store using RESTCONF
#<note>
#This also returns the dummy entry created for routed RPC
# with personId being user0
#</note>
#
#
def getPersons(ignore):
    resp = util.get(settings.getPersonsUrl(),"admin","admin")
    print (resp)
    return resp

#
# Uses the GET on car-people:car-people resource
# to get all car-persons entry in the store using RESTCONF
#<note>
#This also returns the dummy entry created for routed RPC
# with personId being user0
#</note>
#
def getCarPersonMappings(ignore):
    resp = util.get(settings.getCarPersonUrl(),"admin","admin")
    print (resp)
    return resp

#
#delete all cars in the store using RESTCONF
#
#
def deleteAllCars(ignore):
    util.delete(settings.getCarsUrl(),"admin","admin")
    resp = getCars(ignore)
    print("Cars in store after deletion:"+ str(resp))

#
#delete all persons in the store using RESTCONF
#
#
def deleteAllPersons(ignore):
    util.delete(settings.getPersonsUrl(),"admin","admin")
    resp = getPersons(ignore)
    print("Persons in store after deletion:"+ str(resp))

#
# Usage message shown to user
#

def options():

    command = 'ac=Add Car\n\t\tap=Add Person \n\t\tbc=Buy Car\n\t\tgc=Get Cars\n\t\tgp=Get Persons\n\t\t' \
              'gcp=Get Car-Person Mappings\n\t\tdc=Delete All Cars\n\t\tdp=Delete All Persons)'

    param =  '\n\t<param> is\n\t\t' \
             'number of cars to be added if <command>=ac\n\t\t' \
             'number of persons to be added if <command>=ap\n\t\t' \
             'number of car buyers if <command>=bc\n\t\t'\
             'pass 0 if <command>=gc or gp or gcp or dc or dp'\


    usageString = 'usage: populate <ipaddress> <command> <param>\nwhere\n\t<ipaddress> = ODL server ip address' \
                  '\n\t<command> = any of the following commands \n\t\t'

    usageString = usageString + command +param

    print (usageString)


#
# entry point for command executions
#

def main():
    if len(sys.argv) < 4:
        options()
        quit(0)
    settings.hostname = sys.argv[1]
    settings.port = '8080'
    call = dict(ac=addCar, ap=addPerson, bc=buyCar,
                gc=getCars, gp=getPersons, gcp=getCarPersonMappings,dc=deleteAllCars,dp=deleteAllPersons)

    #FOR RPC TO WORK PROPERLY THE FIRST PERSON SHOULD BE ADDED VIA RESTCONF
    addPerson(0)

    #FOR RPC TO WORK PROPERLY THE FIRST PERSON SHOULD BE ADDED VIA RESTCONF
    addCarPerson(0)


    call[sys.argv[2]](int(sys.argv[3]))

#
# main invoked
main()

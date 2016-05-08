import re
DPN_ID_1 = 0
DPN_ID_2 = 0


def getDpnIds(uuid_1, bridgename, dpn_1, dpn_2):
    search = re.search(bridgename, uuid_1)
    if(search):
        DPN_ID_1 = dpn_1
        DPN_ID_2 = dpn_2
        print"The dpn_1 Id is :%s\nThe dpn_2 id is %s" % (DPN_ID_1, DPN_ID_2)
    else:
        DPN_ID_1 = dpn_2
        DPN_ID_2 = dpn_1
        print"The dpn_1 Id is :%s\nThe dpn_2 id is %s" % (DPN_ID_1, DPN_ID_2)
    return(DPN_ID_1, DPN_ID_2)

"""
Library for the robot based system test tool of the OpenDaylight project.
Authors: Baohua Yang@IBM, Denghui Huang@IBM
Updated: 2013-11-14
"""
import collections
import xml.etree.ElementTree as ET

'''
Common constants and functions for the robot framework.
'''

def collection_should_contain(collection, *members):
    """
    Fail if not every members is in the collection.
    """
    if not isinstance(collection, collections.Iterable):
        return False
    for m in members:
        if m not in collection:
            return False
    else:
        return True

def combine_strings(*strings):
    """
    Combines the given `strings` together and returns the result.
    The given strings are not altered by this keyword.
    """
    result = ''
    for s in strings:
        if isinstance(s,str) or isinstance(s,unicode):
            result += s
    if result == '':
        return None
    else:
        return result

        
def compare_xml(xml1, xml2):
    """
    compare the two XML files to see if they contain the same data
    but could be if different order.
    It just split the xml in to lines and just check the line is in
    the other file 
    """
    for line in xml1.rstrip().split('\n'):
        if line not in xml2.rstrip().split('\n'):
            return False

    for line in xml2.rstrip().split('\n'):
        if line not in xml1.rstrip().split('\n'):
            return False

    return True

    


if __name__ == '__main__':
    

    pass

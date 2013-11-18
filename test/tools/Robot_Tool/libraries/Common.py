"""
Library for the robot based system test tool of the OpenDaylight project.
Authors: Baohua Yang@IBM, Denghui Huang@IBM
Updated: 2013-11-14
"""
import collections

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

if __name__ == '__main__':
    pass

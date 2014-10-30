"""
Provision 3800 Object Definition
Authors: james.luhrsen@hp.com
Created: 2014-10-02
"""
import string
import robot
import re
from robot.libraries.BuiltIn import BuiltIn
from H3C import *

class H3C_5920(H3C):
    '''
    Comware 5920
    '''

    model = '5920'

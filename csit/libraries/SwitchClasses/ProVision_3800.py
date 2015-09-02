"""
Provision 3800 Object Definition
Authors: james.luhrsen@hp.com
Created: 2014-10-02
"""
import string
import robot
import re
from robot.libraries.BuiltIn import BuiltIn
from ProVision import *

class ProVision_3800(ProVision):
    '''
    ProVision 3800
    '''

    model = '3800'

"""
Robot testdoc and testlib generator
Authors: Kailash Khalasi (kkhalasi@iix.net)
Created: 2015-07-21
This script will issue a command to all the robot suites and libraries in the given directories
to generate documentation using Robot's "testdoc" and "libdoc" tool.
ex usage: python create_docs.py suitelocation librarylocation suitedocoutputlocation libdocoutputlocation
ex values:
suitelocation:$HOME/integration/test/csit/suites
librarylocation:$HOME/integration/test/csit/libraries
suitedocoutputlocation:/tmp/RobotDocs
libdocoutputlocation: /tmp/RobotLibs
"""

import os
import subprocess
from sys import argv

if len(argv) != 5:
    suiteRoot = os.getenv("HOME")+'/integration/test/csit/suites'
    libraryRoot = os.getenv("HOME")+'/integration/test/csit/libraries'
    tmpSuite = '/tmp/RobotDocs/'
    tmpLib = '/tmp/RobotLibs/'
    print "All arguments are not passed....Using default arguments:"
    print 'Suite Location: ' + suiteRoot
    print 'Library Location: ' + libraryRoot
    print 'Suite Doc Output Location: ' + tmpSuite
    print 'Library Doc Output Location: ' + tmpLib
else:
    script, suiteRoot, libraryRoot, tmpSuite, tmpLib = argv


def generate_docs(testDir, outputFolder, debug=False):
    """
    Generate Robot Documentation

    Args:
        testDir: The directory in which your robot files live (can be suites or libraries)
        outputFolder: The directory where you want your generated docs to be placed.

        This function will "walk" through each robot file in the given "suitelocation"
        and "librarylocation" and will issue a python -m robot.testdoc|libdoc on each
        of those files. The script will first determine if you've passed in a robot
        suite location or robot library location. The outcome generates an HTML file
        (our expected documents) to the given "suitedocoutputlocation"|"libdocoutputlocation".

    :param debug: Default is false. Setting debug to true will print the output of each
           command entered to generate a robot doc
    """

    if testDir == suiteRoot:
        doctype = 'testdoc'
    else:
        doctype = 'libdoc'

    for root, dirs, files, in os.walk(testDir):
        for file in files:
            if file.endswith(".robot"):
                cmd = 'python -m robot.' + doctype + ' ' + root + '/' + file + ' ' + outputFolder + file + '.html'
                print cmd
                p = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
                output, errors = p.communicate()
                if debug:
                    print output, errors

tmpDirs = [tmpSuite, tmpLib]
for dirs in tmpDirs:
    if not os.path.exists(dirs):
        os.makedirs(dirs)

generate_docs(suiteRoot, tmpSuite)
generate_docs(libraryRoot, tmpLib)

from datetime import datetime
import glob
import os
import time
import xml.etree.ElementTree as ET


def generate():
    BODY = {}

    ts = time.time()
    formatted_ts = datetime.fromtimestamp(ts).strftime("%Y-%m-%dT%H:%M:%S.%fZ")
    BODY["@timestamp"] = formatted_ts

    # Plots are obtained from csv files ( in archives directory in $WORKSPACE).

    csv_files = glob.glob("archives/*.csv")
    BODY["project"] = "opendaylight"
    BODY["subject"] = "test"

    # If there are no csv files, then it is a functional test.
    # Parse csv files and fill perfomance parameter values

    if len(csv_files) == 0:
        BODY["test-type"] = "functional"
    else:
        BODY["test-type"] = "performance"
        BODY["plots"] = {}
        for f in csv_files:
            key = (f.split("/")[-1])[:-4]
            BODY["plots"][key] = {}
            with open(f) as file:
                lines = file.readlines()
            props = lines[0].strip().split(",")
            vals = lines[1].strip().split(",")
            for i in range(len(props)):
                BODY["plots"][key][props[i]] = float(vals[i])

    # Fill the required parameters whose values are obtained from environment.

    BODY["jenkins-silo"] = os.environ["SILO"]
    BODY["test-name"] = os.environ["JOB_NAME"]
    BODY["test-run"] = int(os.environ["BUILD_NUMBER"])

    # Parsing robot log for stats on start-time, pass/fail tests and duration.

    robot_log = os.environ["WORKSPACE"] + "/output.xml"
    tree = ET.parse(robot_log)
    BODY["id"] = "{}-{}".format(os.environ["JOB_NAME"], os.environ["BUILD_NUMBER"])
    BODY["start-time"] = tree.getroot().attrib["generated"]
    BODY["pass-tests"] = int(tree.getroot().find("statistics")[0][1].get("pass"))
    BODY["fail-tests"] = int(tree.getroot().find("statistics")[0][1].get("fail"))
    endtime = tree.getroot().find("suite").find("status").get("endtime")
    starttime = tree.getroot().find("suite").find("status").get("starttime")
    elap_time = datetime.strptime(endtime, "%Y%m%d %H:%M:%S.%f") - datetime.strptime(
        starttime, "%Y%m%d %H:%M:%S.%f"
    )
    BODY["duration"] = str(elap_time)

    return BODY

#!/bin/bash

echo 'Usage: Download and unpack ODL you want to test,
put this file into $KARAF_HOME and start it,
with two arguments specifying SSH username and password
for the current user.
This test performs SSH connection to 127.0.0.1,
make sure it works (without needing 

Be sure to set $JAVA_HOME to the version you intend to test with.

This script requires Python 2.7 and virtualenv to work properly.
This script relies on integration/test repository
(it is cloned during execution), result is given as Robot output files,
mainly log.html.

This script uses "killall java" so beware, any other java process may get killed.
This script is not suited for multiple runs on the same installation.

Edit TOOLS_SYSTEM_PROMPT if you prompts not dollar sign.'
if [ "x$1" == "x" ]; then
    echo "Username needed!"
    exit 1
fi
USERNAME="$1"
if [ "x$2" == "x" ]; then
    echo "User password needed!"
    exit 1
fi
PASSWORD="$2"
killall java
export JAVA_OPTS="-Xmx8g"
sed -ie "s/featuresBoot=.*/featuresBoot=config,standard,region,package,kar,ssh,management,odl-restconf,odl-bgpcep-bgp-all,odl-bgpcep-data-change-counter,odl-netconf-connector-all/g" "etc/org.apache.karaf.features.cfg"
bin/start
ENV="test_env"
rm -rf "$ENV"
virtualenv "$ENV"
source "$ENV/bin/activate"
pip install --upgrade pip
pip --version
pip install docker-py importlib requests scapy netifaces netaddr ipaddr
pip install robotframework{,-{httplibrary,requests,sshlibrary,selenium2library}}
pip install jsonpath-rw
pip freeze
git clone "https://git.opendaylight.org/gerrit/integration/test"
pushd "test"
git fetch https://git.opendaylight.org/gerrit/integration/test refs/changes/77/35877/8
git checkout FETCH_HEAD
popd
pybot -N throughpcep -v CONTROLLER_PROMPT:"\$" \
-v NEXUSURLPREFIX:"http://nexus.opendaylight.org" \
-v CONTROLLER:"127.0.0.1" -v UPDATER_COLOCATED:"true" \
-v CONTROLLER_USER:"$USERNAME" -v CONTROLLER_PASSWORD:"$PASSWORD" \
"test/csit/suites/bgpcep/throughpcep/cases.robot"
deactivate
killall java

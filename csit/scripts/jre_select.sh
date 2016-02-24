# This script is not suitable for scriptplans, intended use is for TOOLS_SYSTEM.
#
# First argument is "JDKVERSION" string to set.
#
# FIXME: Deduplicate together with releng/builder: jjb/integration/*.sh snippets.

set -exu

export JDKVERSION="$1"
if [ ${JDKVERSION} == 'openjdk8' ]; then
    echo "Setting the JRE Version to 8"
    # dynamic_verify does not allow sudo, JAVA_HOME should be enough for karaf start.
    # sudo /usr/sbin/alternatives --set java /usr/lib/jvm/java-1.8.0-openjdk-1.8.0.60-2.b27.el7_1.x86_64/jre/bin/java
    export JAVA_HOME=/usr/lib/jvm/java-1.8.0
elif [ ${JDKVERSION} == 'openjdk7' ]; then
    echo "Setting the JRE Version to 7"
    # dynamic_verify does not allow sudo, JAVA_HOME should be enough for karaf start.
    # sudo /usr/sbin/alternatives --set java /usr/lib/jvm/java-1.7.0-openjdk-1.7.0.85-2.6.1.2.el7_1.x86_64/jre/bin/java
    export JAVA_HOME=/usr/lib/jvm/java-1.7.0
fi
echo "JAVA_HOME is ${JAVA_HOME}"
# Did you know that in HERE documents, single quote is an ordinary character, but backticks are still executing?
JAVA_RESOLVED=`readlink -e "${JAVA_HOME}/bin/java"`
echo "Java binary pointed at by JAVA_HOME: ${JAVA_RESOLVED}"
echo "JRE default version ..."
java -version

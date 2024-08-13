*** Settings ***
Documentation       Resource consisting purely of variable definitions useful for multiple project suites.
...
...                 Copyright (c) 2016 Cisco Systems, Inc. and others. All rights reserved.
...
...                 This program and the accompanying materials are made available under the
...                 terms of the Eclipse Public License v1.0 which accompanies this distribution,
...                 and is available at http://www.eclipse.org/legal/epl-v10.html
...
...
...                 These variables are considered global and immutable, so their names are in ALL_CAPS.
...
...                 If a variable is only specific to few projects, define it in csit/variables/{project}/Variables.robot file instead.
...                 If a variable only affects few Resources, define it in csit/libraries/{resource}.robot file instead.
...
...                 Please include a short comment on why the variable is useful and why particular value was chosen.
...                 Also a well-known variables provided by releng/builder script should be listed here,
...                 the value should be a reasonable default.
...
...                 Use ODL_SYSTEM instead of CONTROLLER and TOOLS_SYSTEM instead of MININET when referring to VMs.


*** Variables ***
# Keep this list sorted alphabetically.
&{ACCEPT_EMPTY}                             # Empty accept header. ODL should send JSON data in this case. TODO: Hide into more specific Resource if possible.
# Header for accpeting JSON data. TODO: Hide into more specific Resource if possible.
&{ACCEPT_JSON}
...                                         Accept=application/json
# Header for accepting XML data. TODO: Hide into more specific Resource if possible.
&{ACCEPT_XML}
...                                         Accept=application/xml
# Authentication tuple for accessing ODL RESTCONF server. TODO: Migrate most suites to TemplatedRequests, then chose a more descriptive name.
@{AUTH}
...                                         ${ODL_RESTCONF_USER}
...                                         ${ODL_RESTCONF_PASSWORD}
# Authentication tuple for accessing Keystone API serveri
@{AUTH_ADMIN_SDN}
...                                         admin
...                                         secret
# Authentication tuple for accessing Keystone API server
@{AUTH_CSC_SDN}
...                                         CSC_user
...                                         cscuser
# Authentication tuple for accessing Keystone API server
@{AUTH_CSC_NO_ADMIN}
...                                         CSC_user_no_admin
...                                         cscusernoadmin
# Authentication tuple for accessing ODL RESTCONF server with Keystone Authentication
@{AUTH_INVALID}
...                                         invaliduser
...                                         invinvuser
# Authentication tuple for accessing ODL RESTCONF server with Keystone Authentication
@{AUTH_SDN}
...                                         sdnadmin
...                                         sdnsdn
# Authentication tuple for accessing ODL RESTCONF server with Keystone Authentication
@{AUTH_SDN_DOMAIN}
...                                         sdnadmin@sdn
...                                         sdnsdn
# Authentication tuple for accessing ODL RESTCONF server with Keystone Authentication
@{AUTH_SDN_WRONG_DOM}
...                                         sdnadmin@wrong
...                                         sdnsdn
# FIXME: Move to a separate AAA-related Resource and add description.
${AUTH_TOKEN_API}
...                                         /oauth2/token
${BGP_TOOL_PORT}                            17900    # Tool side of BGP communication listens on this port.
# Some suites temporarily override org.opendaylight.bgpcep Karaf log level to this value.
${BGPCEP_LOG_LEVEL}
...                                         ${DEFAULT_BGPCEP_LOG_LEVEL}
# default location to find opendaylight root folder. Upstream CSIT overrides this on the pybot command line.
${BUNDLEFOLDER}
...                                         /opt/opendaylight
# FIXME: Move to a separate Resource and add description.
${CONFIG_TOPO_API}
...                                         /rests/data/network-topology:network-topology
# FIXME: Move to a separate Resource and add description.
${CONFIG_API}
...                                         /rests/data
# A shorthand. FIXME: Find who uses this and eliminate, or at least add a good description.
${CONTAINER}
...                                         default
${CONTROLLER}                               ${ODL_SYSTEM_IP}    # Deprecated. FIXME: Eradicate.
${CONTROLLER_PASSWORD}                      ${ODL_SYSTEM_PASSWORD}    # Deprecated. FIXME: Eradicate.
${CONTROLLER_PROMPT}                        ${DEFAULT_LINUX_PROMPT}    # Deprecated. FIXME: Eradicate.
${CONTROLLERS}                              ${ODL_SYSTEM_IP_LIST}    # Deprecated. FIXME: Eradicate.
# Max number of seconds test will wait for a controller to stop. FIXME: Hiden into a Resource and rename.
${CONTROLLER_STOP_TIMEOUT}
...                                         120
# A shorthand. FIXME: Find who uses this and eliminate, or at least add a good description.
${CREATE_PATHPOLICY_TOPOLOGY_FILE}
...                                         topo-3sw-2host_multipath.py
# A shorthand. FIXME: Find who uses this and eliminate, or at least add a good description.
${CREATE_PATHPOLICY_TOPOLOGY_FILE_PATH}
...                                         MininetTopo/${CREATE_PATHPOLICY_TOPOLOGY_FILE}
# A shorthand. FIXME: Find who uses this and eliminate, or at least add a good description.
${CREATE_VLAN_TOPOLOGY_FILE_PATH}
...                                         MininetTopo/${CREATE_VLAN_TOPOLOGY_FILE}
# A shorthand. FIXME: Find who uses this and eliminate, or at least add a good description.
${CTRLS}
...                                         controllers
# A shorthand. FIXME: Find who uses this and eliminate, or at least add a good description
${CTRLS_CREATE}
...                                         controllers.json
# Full path of custom.properties file
${CUSTOMPROP}
...                                         /tmp/${BUNDLEFOLDER}/etc/custom.properties
# Generic *_SYSTEM prompt for SSHLibrary.Read_Unti_Prompt. Current value is there for historic reasons. FIXME: Add -v to releng/builder and change this value to more common "$" (without quotes, with backslash). TODO: Replace usage with the strict version.
${DEFAULT_LINUX_PROMPT}
...                                         >
# A more strict prompt substring, this only matches Bash prompt, not Mininet prompt.
${DEFAULT_LINUX_PROMPT_STRICT}
...                                         ]>
# Fallback Karaf log level specific to org.opendaylight.bgpcep.
${DEFAULT_BGPCEP_LOG_LEVEL}
...                                         ${DEFAULT_ODL_LOG_LEVEL}
# Some suites allow to change overall Karaf log level, this is the default value to set or fall back.
${DEFAULT_ODL_LOG_LEVEL}
...                                         INFO
# Generic *_SYSTEM linux password. If empty, SSHLibrary.Login_With_Public_Key is attempted instead of SSHLibrary.Login. TODO: Rename to DEFAULT_LINUX_PASSWORD.
${DEFAULT_PASSWORD}
...                                         ${EMPTY}
# Fallback Karaf log level specific to org.opendaylight.protocol.
${DEFAULT_PROTOCOL_LOG_LEVEL}
...                                         ${DEFAULT_ODL_LOG_LEVEL}
# Generic *_SYSTEM linux user name name. TODO: Rename to DEFUALT_LINUX_USER. FIXME: Add -v to releng/builder and change the value to something more common, e.g. "vagrant".
${DEFAULT_USER}
...                                         jenkins
# Generic *_SYSTEM SSH.Login timeout. Some systems are slow to authenticate.
${DEFAULT_TIMEOUT}
...                                         30s
${DEFAULT_TIMEOUT_HTTP}                     5    # Used for HTTP connections
# Port to use when interacting with ElasticSearch. FIXME: Hide into a specific Resource.
${ELASTICPORT}
...                                         9200
@{EMPTY_LIST}                               # Empty list for KWs with list parameters, see: https://github.com/robotframework/robotframework/issues/2243
# Some suites need this to avoid getting stuck. FIXME: Move to the Resource which uses this.
${ENABLE_GLOBAL_TEST_DEADLINES}
...                                         True
${ESCAPE_CHARACTER}                         \x1b    # A more readable alias to the special escape character.
# global flag (can/should be tweak on pybot command line) which suites can use if they are validating exceptions to pass/fail tests on
${FAIL_ON_EXCEPTIONS}
...                                         False
${FIB_ENTRIES_URL}                          ${CONFIG_API}/odl-fib:fibEntries/
# A shorthand. FIXME: Find who uses this and eliminate, or at least add a good description.
${FLOWFILTERENTRIES_CREATE}
...                                         flowfilterentries.json
# A shorthand. FIXME: Find who uses this and eliminate, or at least add a good description.
${FLOWFILTERS}
...                                         flowfilters/in
# A shorthand. FIXME: Find who uses this and eliminate, or at least add a good description.
${FLOWFILTERS_CREATE}
...                                         flowfilters.json
# A shorthand. FIXME: Find who uses this and eliminate, or at least add a good description.
${FLOWFILTERS_UPDATE}
...                                         flowfilterentries
# A shorthand. FIXME: Find who uses this and eliminate, or at least add a good description.
${FLOWLISTS}
...                                         flowlists
# A shorthand. FIXME: Find who uses this and eliminate, or at least add a good description.
${FLOWLISTS_CREATE}
...                                         flowlists.json
# A shorthand. FIXME: Find who uses this and eliminate, or at least add a good description.
${FLOWLISTENTRIES_CREATE}
...                                         flowlistentries.json
# Deprecated. Sometimes conflicts with argument name. TODO: Migrate most suites to TemplatedRequests, then chose a more descriptive name.
&{HEADERS}
...                                         Content-Type=application/json
# Content type for JSON data, used to work around Requests auto-serialization. FIXME: keep it as 'application/json' to make it work for both Bierman02 & RFC8040 URLs. Change it to RFC8040 media type once RFC8040 migration is completed.
&{HEADERS_YANG_JSON}
...                                         Content-Type=application/json
&{HEADERS_YANG_RFC8040_JSON}                Content-Type=application/yang-data+json
# Content type for XML data. TODO: Hide into more specific Resource if possible.
&{HEADERS_XML}
...                                         Content-Type=application/xml
${KARAF_PROMPT_LOGIN}                       opendaylight-user    # This is used for karaf console login.
${ICMP_TYPE}                                135
# Larger substring of Karaf prompt, shorter ones may result in false positives.
${KARAF_DETAILED_PROMPT}
...                                         @${ESCAPE_CHARACTER}\[0m${ESCAPE_CHARACTER}\[34mroot${ESCAPE_CHARACTER}\[0m>
${KARAF_HOME}                               ${WORKSPACE}${/}${BUNDLEFOLDER}    # Karaf home directory path.
# location of karaf.log in standard CSIT jobs
${KARAF_LOG}
...                                         ${WORKSPACE}/${BUNDLEFOLDER}/data/log/karaf.log
${KARAF_PASSWORD}                           karaf    # Plaintext password to authenticate to Karaf console.
# This is used for interactive read until prompt in regexp format.
${KARAF_PROMPT}
...                                         opendaylight-user.*root.*>
${KARAF_SHELL_PORT}                         8101    # ODL provides SSH access to Karaf consoleon this port.
${KARAF_USER}                               karaf    # User name to authenticate to Karaf SSH console.
# Implementation detail related to SSHLibrary.Login_With_Public_Key. TODO: Hide in SSHKeywords.
${KEYFILE_PASS}
...                                         any
# Full path of keystore for TLS communication
${KEYSTORE_PATH}
...                                         /tmp/${BUNDLEFOLDER}/configuration/ssl/.keystore
# Relative path of keystore for TLS communication
${KEYSTORE_RELATIVE_PATH}
...                                         configuration/ssl/.keystore
# FIXME: Move to a separate LispFlowMapping-related Resource and add description.
${LFM_RPC_API}
...                                         /rests/operations/odl-mappingservice
# FIXME: Move to a separate LispFlowMapping-related Resource and add description.
${LFM_RPC_API_LI}
...                                         /rests/operations/lfm-mapping-database
# FIXME: Move to a separate LispFlowMapping-related Resource and add description.
${LFM_SB_RPC_API}
...                                         /rests/operations/odl-lisp-sb
# FIXME: Move to a separate Resource and add description.
${MODULES_API}
...                                         /rests/data/ietf-yang-library:modules-state?content=nonconfig
${ODL_AKKA_PORT}                            2550    # Port number akka cluster communicates on
${ODL_BGP_PORT}                             1790    # ODL side of BGP communication listens on this port number.
# Deprecated. Not clear if this refers to HTTP or SSH sessions. FIXME: Eradicate, or at least convert to a resource-private variable.
${ODL_CONTROLLER_SESSION}
...                                         ${NONE}
${ODL_NETCONF_CONFIG_PORT}                  1830    # Port number ODL NETCONF server of Config Subsystem listens on.
${ODL_NETCONF_MDSAL_PORT}                   2830    # Port number ODL NETCONF server of MD-SAL listens on.
# Namespace of standardized NETCONF elements.
${ODL_NETCONF_NAMESPACE}
...                                         urn:ietf:params:xml:ns:netconf:base:1.0
# Both ODL Netconf servers require this password to authenticate.
${ODL_NETCONF_PASSWORD}
...                                         ${ODL_RESTCONF_PASSWORD}
${ODL_NETCONF_PROMPT}                       ]]>]]>    # Standard prompt string for NETCONF protocol.
# Both ODL Netconf servers require this user name to authenticate.
${ODL_NETCONF_USER}
...                                         ${ODL_RESTCONF_USER}
# Codename of OpenFlowPlugin implementation ODL is configured to use.
${ODL_OF_PLUGIN}
...                                         lithium
# TODO: get rid of all uses of ODL_OF_PORT and use ODL_OF_PORT_6633 instead, if 6653 is not acceptable
${ODL_OF_PORT}                              6633    # Port number ODL communicates using OpenFlow protocol on.
${ODL_OF_PORT_6633}                         6633    # Port number ODL communicates using OpenFlow protocol on.
${ODL_OF_PORT_6653}                         6653    # Port number ODL communicates using OpenFlow protocol on.
# Username for basic HTTP authentication used by requests against ODL RESTCONF server.
${ODL_RESTCONF_USER}
...                                         admin
# Plaintext password for basic HTTP authentication used by requests against ODL RESTCONF server.
${ODL_RESTCONF_PASSWORD}
...                                         admin
${ODL_SYSTEM_1_IP}                          127.0.0.1    # IP address of system hosting member 1 od ODL cluster.
${ODL_SYSTEM_2_IP}                          127.0.0.2    # IP address of system hosting member 2 od ODL cluster.
${ODL_SYSTEM_3_IP}                          127.0.0.3    # IP address of system hosting member 3 od ODL cluster.
# IP address of system hosting ODL for SSHLibrary to connect to. First node if ODL is a cluster.
${ODL_SYSTEM_IP}
...                                         ${ODL_SYSTEM_1_IP}
# Deprecated. List of ODL cluster member IP addresses. See ClusterManagement.robot for alternatives.
@{ODL_SYSTEM_IP_LIST}
...                                         ${ODL_SYSTEM_1_IP}
...                                         ${ODL_SYSTEM_2_IP}
...                                         ${ODL_SYSTEM_3_IP}
${ODL_SYSTEM_USER}                          ${DEFAULT_USER}    # Linux username specific for ODL systems.
# Linux password (or empty to use public key) specific for ODL systems.
${ODL_SYSTEM_PASSWORD}
...                                         ${DEFAULT_PASSWORD}
# Bash prompt substring specific for ODL systems.
${ODL_SYSTEM_PROMPT}
...                                         ${DEFAULT_LINUX_PROMPT}
# FIXME: Move to a separate Resource and add description.
${OPERATIONAL_API}
...                                         /rests/data
# FIXME: Move to a separate Resource and add description.
${OPERATIONAL_TOPO_API}
...                                         /rests/data/network-topology:network-topology
${OS_CMD_SUCCESS}                           Command Returns 0
# Port number ODL uses for OVSDB protocol communication. TODO: Move to OVSDB-specific Resource.
${OVSDBPORT}
...                                         6640
${PASSWORD}                                 ${DEFAULT_PASSWORD}    # Deprecated. FIXME: Eradicate.
# A shorthand. FIXME: Find who uses this and eliminate, or at least add a good description.
${PORTMAP_CREATE}
...                                         portmap.json
${PORT}                                     8080    # Deprecated. Generic HTTP port. FIXME: Eradicate.
# A shorthand. FIXME: Find who uses this and eliminate, or at least add a good description.
${PORTS}
...                                         ports/detail.json
# Deprecated. FIXME: Name is to generic. Eradicate.
${PREFIX}
...                                         http://${ODL_SYSTEM_IP}:${PORT}
# Some suites temporarily override org.opendaylight.protocol Karaf log level to this value.
${PROTOCOL_LOG_LEVEL}
...                                         ${DEFAULT_PROTOCOL_LOG_LEVEL}
${PWD}                                      ${ODL_RESTCONF_PASSWORD}    # Deprecated. FIXME: Eradicate.
${REGEX_IPROUTE}
...                                         ip-route:169.254.169.254 via [0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}
${REGEX_IPV4}                               [0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}
${REGEX_NAMESERVER}                         nameserver [0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}
${REGEX_OBTAINED}                           [0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3} obtained
${REGEX_UUID}                               [0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}
${RESTCONFPORT}                             8181    # Primary port for ODL RESTCONF, although 8080 should also work.
${RESTCONFPORT_TLS}                         8443    # Port for ODL RESTCONF Secure (TLS) operations
# Deprecated. Restconf port used by AD-SAL services. FIXME: Eradicate.
${RESTPORT}
...                                         8282
${REST_API}                                 /rests/data
# FIXME: Move to a separate AAA-related Resource and add description.
${REVOKE_TOKEN_API}
...                                         /oauth2/revoke
# Scope, used for some types of HTTP requests agains ODL RESTCONF. TODO: Migrate most suites to TemplatedRequests or AuthStandalone, then chose a more descriptive name.
${SCOPE}
...                                         sdn
# Accept and Content type for XML data. TODO: Hide into more specific Resource if possible.
&{SEND_ACCEPT_XML_HEADERS}
...                                         Content-Type=application/xml
...                                         Accept=application/xml
# Implementation detail related to SSHLibrary.Login_With_Public_Key. TODO: Hide in SSHKeywords.
${SSH_KEY}
...                                         id_rsa
# A shorthand. FIXME: Find who uses this and eliminate, or at least add a good description.
${SW}
...                                         switches
${TOOLS_SYSTEM_1_IP}                        127.0.0.1    # IP address of first system hosting testing tools.
${TOOLS_SYSTEM_2_IP}                        127.0.0.2    # IP address of second system hosting testing tools.
${TOOLS_SYSTEM_3_IP}                        127.0.0.3    # IP address of third system hosting testing tools.
# IP address of primary system hosting testing tools.
${TOOLS_SYSTEM_IP}
...                                         ${TOOLS_SYSTEM_1_IP}
${TOOLS_SYSTEM_USER}                        ${DEFAULT_USER}    # Linux user name specific for tools systems.
${TOOLS_SYSTEM_PASSWORD}                    ${DEFAULT_PASSWORD}    # Linux password specific for tools systems.
# Bash prompt substring specific for tools systems.
${TOOLS_SYSTEM_PROMPT}
...                                         ${DEFAULT_LINUX_PROMPT}
# Part of Mininet configuration? FIXME: Find who uses this and eliminate, or at least add a good description.
${TOPO_TREE_DEPTH}
...                                         3
# Part of Mininet configuration? FIXME: Find who uses this and eliminate, or at least add a good description.
${TOPO_TREE_FANOUT}
...                                         2
# Part of Mininet configuration? FIXME: Find who uses this and eliminate, or at least add a good description.
${TOPO_TREE_LEVEL}
...                                         2
# FIXME: Move to a separate Resource and add description.
${TOPOLOGY_URL}
...                                         network-topology:network-topology/topology
${USER}                                     ${ODL_RESTCONF_USER}    # Deprecated. FIXME: Eradicate.
# A shorthand. FIXME: Find who uses this and eliminate, or at least add a good description.
${VBRIFS}
...                                         interfaces
# A shorthand. FIXME: Find who uses this and eliminate, or at least add a good description.
${VBRIFS_CREATE}
...                                         interfaces.json
# A shorthand. FIXME: Find who uses this and eliminate, or at least add a good description.
${VBRS}
...                                         vbridges
# A shorthand. FIXME: Find who uses this and eliminate, or at least add a good description.
${VBRS_CREATE}
...                                         vbridges.json
# A shorthand. FIXME: Find who uses this and eliminate, or at least add a good description.
${VLANMAP_CREATE}
...                                         vlanmaps.json
# Keep this list sorted alphabetically.

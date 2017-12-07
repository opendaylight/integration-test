*** Settings ***
Documentation     Resource consisting purely of variable definitions useful for multiple project suites.
...
...               Copyright (c) 2016 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...
...               These variables are considered global and immutable, so their names are in ALL_CAPS.
...
...               If a variable is only specific to few projects, define it in csit/variables/{project}/Variables.robot file instead.
...               If a variable only affects few Resources, define it in csit/libraries/{resource}.robot file instead.
...
...               Please include a short comment on why the variable is useful and why particular value was chosen.
...               Also a well-known variables provided by releng/builder script should be listed here,
...               the value should be a reasonable default.
...
...               Use ODL_SYSTEM instead of CONTROLLER and TOOLS_SYSTEM instead of MININET when referring to VMs.

*** Variables ***
# Keep this list sorted alphabetically.
&{ACCEPT_EMPTY}    # Empty accept header. ODL should send JSON data in this case. TODO: Hide into more specific Resource if possible.
&{ACCEPT_JSON}    Accept=application/json    # Header for accpeting JSON data. TODO: Hide into more specific Resource if possible.
&{ACCEPT_XML}     Accept=application/xml    # Header for accepting XML data. TODO: Hide into more specific Resource if possible.
${ALERTFIELDCONTENTRULERECORD}    /restconf/config/alertrule:alertFieldContentRuleRecord/    # FIXME: Move to a separate Centinel-related Resource and add description.
${ALERTFIELDVALUERULERECORD}    /restconf/config/alertrule:alertFieldValueRuleRecord    # FIXME: Move to a separate Centinel-related Resource and add description.
${ALERTMESSAGECOUNTRULERECORD}    /restconf/config/alertrule:alertMessageCountRuleRecord/    # FIXME: Move to a separate Centinel-related Resource and add description.
@{AUTH}           ${ODL_RESTCONF_USER}    ${ODL_RESTCONF_PASSWORD}    # Authentication tuple for accessing ODL RESTCONF server. TODO: Migrate most suites to TemplatedRequests, then chose a more descriptive name.
@{AUTH_SDN}       sdnadmin    sdnsdn    # Authentication tuple for accessing ODL RESTCONF server with Keystone Authentication
@{AUTH_SDN_DOMAIN}    sdnadmin@sdn    sdnsdn    # Authentication tuple for accessing ODL RESTCONF server with Keystone Authentication
@{AUTH_SDN_WRONG_DOM}    sdnadmin@wrong    sdnsdn    # Authentication tuple for accessing ODL RESTCONF server with Keystone Authentication
@{AUTH_INVALID}    invaliduser    invinvuser    # Authentication tuple for accessing ODL RESTCONF server with Keystone Authentication
@{AUTH_CSC_SDN}    CSC_user    cscuser    # Authentication tuple for accessing Keystone API server
@{AUTH_CSC_NO_ADMIN}    CSC_user_no_admin    cscusernoadmin    # Authentication tuple for accessing Keystone API server
@{AUTH_ADMIN_SDN}    admin    secret    # Authentication tuple for accessing Keystone API server
${AUTH_TOKEN_API}    /oauth2/token    # FIXME: Move to a separate AAA-related Resource and add description.
${BGP_TOOL_PORT}    17900    # Tool side of BGP communication listens on this port.
${BGPCEP_LOG_LEVEL}    ${DEFAULT_BGPCEP_LOG_LEVEL}    # Some suites temporarily override org.opendaylight.bgpcep Karaf log level to this value.
${BUNDLEFOLDER}    /opt/opendaylight    # default location to find opendaylight root folder. Upstream CSIT overrides this on the pybot command line
${CTRLS}          controllers    # A shorthand. FIXME: Find who uses this and eliminate, or at least add a good description.
${CTRLS_CREATE}    controllers.json    # A shorthand. FIXME: Find who uses this and eliminate, or at least add a good description.
${CONFIG_NODES_API}    /restconf/config/opendaylight-inventory:nodes    # FIXME: Move to a separate Resource and add description.
${CONFIG_TOPO_API}    /restconf/config/network-topology:network-topology    # FIXME: Move to a separate Resource and add description.
${CONFIG_API}     /restconf/config    # FIXME: Move to a separate Resource and add description.
${CONTAINER}      default    # A shorthand. FIXME: Find who uses this and eliminate, or at least add a good description.
${CONTROLLER}     ${ODL_SYSTEM_IP}    # Deprecated. FIXME: Eradicate.
${CONTROLLER_PASSWORD}    ${ODL_SYSTEM_PASSWORD}    # Deprecated. FIXME: Eradicate.
${CONTROLLER_PROMPT}    ${DEFAULT_LINUX_PROMPT}    # Deprecated. FIXME: Eradicate.
${CONTROLLERS}    ${ODL_SYSTEM_IP_LIST}    # Deprecated. FIXME: Eradicate.
${CONTROLLER_CONFIG_MOUNT}    /restconf/config/network-topology:network-topology/topology/topology-netconf/node/controller-config/yang-ext:mount    # FIXME: Move to a separate Resource and add description.
${CONTROLLER_STOP_TIMEOUT}    120    # Max number of seconds test will wait for a controller to stop. FIXME: Hiden into a Resource and rename.
${CREATE_PATHPOLICY_TOPOLOGY_FILE}    topo-3sw-2host_multipath.py    # A shorthand. FIXME: Find who uses this and eliminate, or at least add a good description.
${CREATE_PATHPOLICY_TOPOLOGY_FILE_PATH}    MininetTopo/${CREATE_PATHPOLICY_TOPOLOGY_FILE}    # A shorthand. FIXME: Find who uses this and eliminate, or at least add a good description.
${CREATE_VLAN_TOPOLOGY_FILE}    vlan_vtn_test.py    # A shorthand. FIXME: Find who uses this and eliminate, or at least add a good description.
${CREATE_VLAN_TOPOLOGY_FILE_PATH}    MininetTopo/${CREATE_VLAN_TOPOLOGY_FILE}    # A shorthand. FIXME: Find who uses this and eliminate, or at least add a good description.
${CUSTOMPROP}     /tmp/${BUNDLEFOLDER}/etc/custom.properties    # Full path of custom.properties file
${DEFAULT_LINUX_PROMPT}    >    # Generic *_SYSTEM prompt for SSHLibrary.Read_Unti_Prompt. Current value is there for historic reasons. FIXME: Add -v to releng/builder and change this value to more common "$" (without quotes, with backslash). TODO: Replace usage with the strict version.
${DEFAULT_LINUX_PROMPT_STRICT}    ]>    # A more strict prompt substring, this only matches Bash prompt, not Mininet prompt.
${DEFAULT_BGPCEP_LOG_LEVEL}    ${DEFAULT_ODL_LOG_LEVEL}    # Fallback Karaf log level specific to org.opendaylight.bgpcep.
${DEFAULT_ODL_LOG_LEVEL}    INFO    # Some suites allow to change overall Karaf log level, this is the default value to set or fall back.
${DEFAULT_PASSWORD}    ${EMPTY}    # Generic *_SYSTEM linux password. If empty, SSHLibrary.Login_With_Public_Key is attempted instead of SSHLibrary.Login. TODO: Rename to DEFAULT_LINUX_PASSWORD.
${DEFAULT_PROTOCOL_LOG_LEVEL}    ${DEFAULT_ODL_LOG_LEVEL}    # Fallback Karaf log level specific to org.opendaylight.protocol.
${DEFAULT_USER}    jenkins    # Generic *_SYSTEM linux user name name. TODO: Rename to DEFUALT_LINUX_USER. FIXME: Add -v to releng/builder and change the value to something more common, e.g. "vagrant".
${DEFAULT_TIMEOUT}    30s    # Generic *_SYSTEM SSH.Login timeout. Some systems are slow to authenticate.
${DEFAULT_TIMEOUT_HTTP}    5    # Used for HTTP connections
${DELETE_DASHBOARDRECORD}    /restconf/operations/dashboardrule:delete-dashboard    # FIXME: Move to a separate Centinel-related Resource and add description.
${ELASTICPORT}    9200    # Port to use when interacting with ElasticSearch. FIXME: Hide into a specific Resource.
${ENABLE_GLOBAL_TEST_DEADLINES}    True    # Some suites need this to avoid getting stuck. FIXME: Move to the Resource which uses this.
${ESCAPE_CHARACTER}    \x1b    # A more readable alias to the special escape character.
${FAIL_ON_EXCEPTIONS}    False    # global flag (can/should be tweak on pybot command line) which suites can use if they are validating exceptions to pass/fail tests on
${FIB_ENTRIES_URL}    ${CONFIG_API}/odl-fib:fibEntries/
${FLOWFILTERENTRIES_CREATE}    flowfilterentries.json    # A shorthand. FIXME: Find who uses this and eliminate, or at least add a good description.
${FLOWFILTERS}    flowfilters/in    # A shorthand. FIXME: Find who uses this and eliminate, or at least add a good description.
${FLOWFILTERS_CREATE}    flowfilters.json    # A shorthand. FIXME: Find who uses this and eliminate, or at least add a good description.
${FLOWFILTERS_UPDATE}    flowfilterentries    # A shorthand. FIXME: Find who uses this and eliminate, or at least add a good description.
${FLOWLISTS}      flowlists    # A shorthand. FIXME: Find who uses this and eliminate, or at least add a good description.
${FLOWLISTS_CREATE}    flowlists.json    # A shorthand. FIXME: Find who uses this and eliminate, or at least add a good description.
${FLOWLISTENTRIES_CREATE}    flowlistentries.json    # A shorthand. FIXME: Find who uses this and eliminate, or at least add a good description.
${GBP_BASE_ENDPOINTS_API}    /restconf/operational/base-endpoint:endpoints    # FIXME: Move to a separate GroupBasedPolicy-related Resource and add description.
${GBP_ENDPOINTS_API}    /restconf/operational/endpoint:endpoints    # FIXME: Move to a separate GroupBasedPolicy-related Resource and add description.
${GBP_REGEP_API}    /restconf/operations/endpoint:register-endpoint    # FIXME: Move to a separate GroupBasedPolicy-related Resource and add description.
${GBP_TENANTS_API}    /restconf/config/policy:tenants    # FIXME: Move to a separate GroupBasedPolicy-related Resource and add description.
${GBP_TUNNELS_API}    /restconf/config/opendaylight-inventory:nodes    # FIXME: Move to a separate GroupBasedPolicy-related Resource and add description.
${GBP_UNREGEP_API}    /restconf/operations/endpoint:unregister-endpoint    # FIXME: Move to a separate GroupBasedPolicy-related Resource and add description.
${GENIUS_IFM_CONFIG_FLAG}    ${KARAF_HOME}/etc/opendaylight/datastore/initial/config/genius-ifm-config.xml
${GET_CONFIGURATION_URI}    /restconf/operational/configuration:configurationRecord/    # FIXME: Move to a separate Centinel-related Resource and add description.
${GET_DASHBOARDRECORD}    /restconf/operational/dashboardrule:dashboardRecord/    # FIXME: Move to a separate Centinel-related Resource and add description.
${GET_INTENTS_URI}    /retconf/config/intent:intents    # FIXME: Move to a separate Nemo-related Resource and add description.
&{HEADERS}        Content-Type=application/json    # Deprecated. Sometimes conflicts with argument name. TODO: Migrate most suites to TemplatedRequests, then chose a more descriptive name.
&{HEADERS_YANG_JSON}    Content-Type=application/yang.data+json    # Content type for JSON data, used to work around Requests auto-serialization. TODO: Hide into more specific Resource if possible.
&{HEADERS_XML}    Content-Type=application/xml    # Content type for XML data. TODO: Hide into more specific Resource if possible.
${KARAF_PROMPT_LOGIN}    opendaylight-user    # This is used for karaf console login.
${ICMP_TYPE}      135
${KARAF_DETAILED_PROMPT}    @${ESCAPE_CHARACTER}[0m${ESCAPE_CHARACTER}[34mroot${ESCAPE_CHARACTER}[0m>    # Larger substring of Karaf prompt, shorter ones may result in false positives.
${KARAF_HOME}     ${WORKSPACE}${/}${BUNDLEFOLDER}    # Karaf home directory path.
${KARAF_LOG}      ${WORKSPACE}/${BUNDLEFOLDER}/data/log/karaf.log    # location of karaf.log in standard CSIT jobs
${KARAF_PASSWORD}    karaf    # Plaintext password to authenticate to Karaf console.
${KARAF_PROMPT}    opendaylight-user.*root.*>    # This is used for interactive read until prompt in regexp format.
${KARAF_SHELL_PORT}    8101    # ODL provides SSH access to Karaf consoleon this port.
${KARAF_USER}     karaf    # User name to authenticate to Karaf SSH console.
${KEYFILE_PASS}    any    # Implementation detail related to SSHLibrary.Login_With_Public_Key. TODO: Hide in SSHKeywords.
${KEYSTORE_PATH}    /tmp/${BUNDLEFOLDER}/configuration/ssl/.keystore    # Full path of keystore for TLS communication
${KEYSTORE_RELATIVE_PATH}    configuration/ssl/.keystore    # Relative path of keystore for TLS communication
${LFM_RPC_API}    /restconf/operations/odl-mappingservice    # FIXME: Move to a separate LispFlowMapping-related Resource and add description.
${LFM_RPC_API_LI}    /restconf/operations/lfm-mapping-database    # FIXME: Move to a separate LispFlowMapping-related Resource and add description.
${LFM_SB_RPC_API}    /restconf/operations/odl-lisp-sb    # FIXME: Move to a separate LispFlowMapping-related Resource and add description.
${MODULES_API}    /restconf/modules    # FIXME: Move to a separate Resource and add description.
${NEUTRON}        127.0.0.1    # FIXME: Move to a separate Neutron-related Resource and add description.
${NEUTRONURL}     http://${NEUTRON}:9696    # FIXME: Move to a separate Neutron-related Resource and add description.
${NEUTRON_NB_API}    /controller/nb/v2/neutron    # FIXME: Move to a separate Neutron-related Resource and add description.
${NEUTRON_NETWORKS_API}    ${NEUTRON_NB_API}/networks    # FIXME: Move to a separate Neutron-related Resource and add description.
${NEUTRON_SUBNETS_API}    ${NEUTRON_NB_API}/subnets    # FIXME: Move to a separate Neutron-related Resource and add description.
${NEUTRON_PORTS_API}    ${NEUTRON_NB_API}/ports    # FIXME: Move to a separate Neutron-related Resource and add description.
${NEUTRON_ROUTERS_API}    ${NEUTRON_NB_API}/routers    # FIXME: Move to a separate Neutron-related Resource and add description.
${ODL_AKKA_PORT}    2550    # Port number akka cluster communicates on
${ODL_BGP_PORT}    1790    # ODL side of BGP communication listens on this port number.
${ODL_CONTROLLER_SESSION}    ${NONE}    # Deprecated. Not clear if this refers to HTTP or SSH sessions. FIXME: Eradicate, or at least convert to a resource-private variable.
${ODL_NETCONF_CONFIG_PORT}    1830    # Port number ODL NETCONF server of Config Subsystem listens on.
${ODL_NETCONF_MDSAL_PORT}    2830    # Port number ODL NETCONF server of MD-SAL listens on.
${ODL_NETCONF_NAMESPACE}    urn:ietf:params:xml:ns:netconf:base:1.0    # Namespace of standardized NETCONF elements.
${ODL_NETCONF_PASSWORD}    ${ODL_RESTCONF_PASSWORD}    # Both ODL Netconf servers require this password to authenticate.
${ODL_NETCONF_PROMPT}    ]]>]]>    # Standard prompt string for NETCONF protocol.
${ODL_NETCONF_USER}    ${ODL_RESTCONF_USER}    # Both ODL Netconf servers require this user name to authenticate.
${ODL_OF_PLUGIN}    lithium    # Codename of OpenFlowPlugin implementation ODL is configured to use.
# TODO: get rid of all uses of ODL_OF_PORT and use ODL_OF_PORT_6633 instead, if 6653 is not acceptable
${ODL_OF_PORT}    6633    # Port number ODL communicates using OpenFlow protocol on.
${ODL_OF_PORT_6633}    6633    # Port number ODL communicates using OpenFlow protocol on.
${ODL_OF_PORT_6653}    6653    # Port number ODL communicates using OpenFlow protocol on.
${ODL_RESTCONF_USER}    admin    # Username for basic HTTP authentication used by requests against ODL RESTCONF server.
${ODL_RESTCONF_PASSWORD}    admin    # Plaintext password for basic HTTP authentication used by requests against ODL RESTCONF server.
${ODL_STOP}       /bin/stop
${ODL_START}      /bin/start
${ODL_SYSTEM_1_IP}    127.0.0.1    # IP address of system hosting member 1 od ODL cluster.
${ODL_SYSTEM_2_IP}    127.0.0.2    # IP address of system hosting member 2 od ODL cluster.
${ODL_SYSTEM_3_IP}    127.0.0.3    # IP address of system hosting member 3 od ODL cluster.
${ODL_SYSTEM_IP}    ${ODL_SYSTEM_1_IP}    # IP address of system hosting ODL for SSHLibrary to connect to. First node if ODL is a cluster.
@{ODL_SYSTEM_IP_LIST}    ${ODL_SYSTEM_1_IP}    ${ODL_SYSTEM_2_IP}    ${ODL_SYSTEM_3_IP}    # Deprecated. List of ODL cluster member IP addresses. See ClusterManagement.robot for alternatives.
${ODL_SYSTEM_USER}    ${DEFAULT_USER}    # Linux username specific for ODL systems.
${ODL_SYSTEM_PASSWORD}    ${DEFAULT_PASSWORD}    # Linux password (or empty to use public key) specific for ODL systems.
${ODL_SYSTEM_PROMPT}    ${DEFAULT_LINUX_PROMPT}    # Bash prompt substring specific for ODL systems.
${OPERATIONAL_API}    /restconf/operational    # FIXME: Move to a separate Resource and add description.
${OPERATIONS_API}    /restconf/operations    # FIXME: Move to a separate Resource and add description.
${OPERATIONAL_GBP_TENANTS_API}    /restconf/operational/policy:tenants    # FIXME: Move to a separate GroupBasedPolicy-related Resource and add description.
${OPERATIONAL_NODES_API}    /restconf/operational/opendaylight-inventory:nodes    # FIXME: Move to a separate Resource and add description.
${OPERATIONAL_NODES_NETVIRT}    /restconf/operational/network-topology:network-topology/topology/netvirt:1    \    # FIXME: Move to a separate Resource and add description.
${OPERATIONAL_TOPO_API}    /restconf/operational/network-topology:network-topology    # FIXME: Move to a separate Resource and add description.
${OS_SYSTEM_PROMPT}    \$    # Prompt substring specific to OpenStack systems.
${OS_CMD_SUCCESS}    Command Returns 0
${OSREST}         /v2.0/networks    # FIXME: Move to a separate Neutron-related Resource and add description.
${OVSDBPORT}      6640    # Port number ODL uses for OVSDB protocol communication. TODO: Move to OVSDB-specific Resource.
${PASSWORD}       ${DEFAULT_PASSWORD}    # Deprecated. FIXME: Eradicate.
${PORTMAP_CREATE}    portmap.json    # A shorthand. FIXME: Find who uses this and eliminate, or at least add a good description.
${PORT}           8080    # Deprecated. Generic HTTP port. FIXME: Eradicate.
${PORTS}          ports/detail.json    # A shorthand. FIXME: Find who uses this and eliminate, or at least add a good description.
${PREDEFINE_CONNECTION_URI}    /restconf/config/nemo-object:connection-definitions    # FIXME: Move to a separate Nemo-related Resource and add description.
${PREDEFINE_NODE_URI}    /restconf/config/nemo-object:node-definitions    # FIXME: Move to a separate Nemo-related Resource and add description.
${PREDEFINE_ROLE_URI}    /restconf/config/nemo-user:user-roles    # FIXME: Move to a separate Nemo-related Resource and add description.
${PREFIX}         http://${ODL_SYSTEM_IP}:${PORT}    # Deprecated. FIXME: Name is to generic. Eradicate.
${PROTOCOL_LOG_LEVEL}    ${DEFAULT_PROTOCOL_LOG_LEVEL}    # Some suites temporarily override org.opendaylight.protocol Karaf log level to this value.
${PWD}            ${ODL_RESTCONF_PASSWORD}    # Deprecated. FIXME: Eradicate.
${REGEX_IPROUTE}    ip-route:169.254.169.254 via [0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}
${REGEX_IPV4}     [0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}
${REGEX_NAMESERVER}    nameserver [0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}
${REGEX_OBTAINED}    [0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3} obtained
${REGEX_UUID}     [0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}
${REGISTER_TENANT_URI}    /restconf/operations/nemo-intent:register-user    # FIXME: Move to a separate Nemo-related Resource and add description.
${RESTCONFPORT}    8181    # Primary port for ODL RESTCONF, although 8080 should also work.
${RESTCONFPORT_TLS}    8443    # Port for ODL RESTCONF Secure (TLS) operations
${RESTPORT}       8282    # Deprecated. Restconf port used by AD-SAL services. FIXME: Eradicate.
${REVOKE_TOKEN_API}    /oauth2/revoke    # FIXME: Move to a separate AAA-related Resource and add description.
${SCOPE}          sdn    # Scope, used for some types of HTTP requests agains ODL RESTCONF. TODO: Migrate most suites to TemplatedRequests or AuthStandalone, then chose a more descriptive name.
&{SEND_ACCEPT_XML_HEADERS}    Content-Type=application/xml    Accept=application/xml    # Accept and Content type for XML data. TODO: Hide into more specific Resource if possible.
${SET_ALERTFIELDCONTENTRULERECORD}    /restconf/operations/alertrule:set-alert-field-content-rule    # FIXME: Move to a separate Centinel-related Resource and add description.
${SET_ALERTFIELDVALUERULERECORD}    /restconf/operations/alertrule:set-alert-field-value-rule    # FIXME: Move to a separate Centinel-related Resource and add description.
${SET_ALERTMESSAGECOUNTRULERECORD}    /restconf/operations/alertrule:set-alert-message-count-rule    # FIXME: Move to a separate Centinel-related Resource and add description.
${SET_CONFIGURATION_URI}    /restconf/operations/configuration:set-centinel-configurations    # FIXME: Move to a separate Centinel-related Resource and add description.
${SET_DASHBOARDRECORD}    /restconf/operations/dashboardrule:set-dashboard    # FIXME: Move to a separate Centinel-related Resource and add description.
${SET_STREAMRECORD}    /restconf/operations/stream:set-stream    # FIXME: Move to a separate Centinel-related Resource and add description.
${SET_SUBSCRIBEUSER}    /restconf/operations/subscribe:subscribe-user    # FIXME: Move to a separate Centinel-related Resource and add description.
${SSH_KEY}        id_rsa    # Implementation detail related to SSHLibrary.Login_With_Public_Key. TODO: Hide in SSHKeywords.
${STREAMRECORD_CONFIG}    /restconf/config/stream:streamRecord    # FIXME: Move to a separate Centinel-related Resource and add description.
${STRUCTURE_INTENT_URI}    /restconf/operations/nemo-intent:structure-style-nemo-update    # FIXME: Move to a separate Nemo-related Resource and add description.
${SUBSCRIPTION}    /restconf/config/subscribe:subscription/    # FIXME: Move to a separate Centinel-related Resource and add description.
${SW}             switches    # A shorthand. FIXME: Find who uses this and eliminate, or at least add a good description.
${TOOLS_SYSTEM_1_IP}    127.0.0.1    # IP address of first system hosting testing tools.
${TOOLS_SYSTEM_2_IP}    127.0.0.2    # IP address of second system hosting testing tools.
${TOOLS_SYSTEM_3_IP}    127.0.0.3    # IP address of third system hosting testing tools.
${TOOLS_SYSTEM_IP}    ${TOOLS_SYSTEM_1_IP}    # IP address of primary system hosting testing tools.
${TOOLS_SYSTEM_USER}    ${DEFAULT_USER}    # Linux user name specific for tools systems.
${TOOLS_SYSTEM_PASSWORD}    ${DEFAULT_PASSWORD}    # Linux password specific for tools systems.
${TOOLS_SYSTEM_PROMPT}    ${DEFAULT_LINUX_PROMPT}    # Bash prompt substring specific for tools systems.
${TOPO_TREE_DEPTH}    3    # Part of Mininet configuration? FIXME: Find who uses this and eliminate, or at least add a good description.
${TOPO_TREE_FANOUT}    2    # Part of Mininet configuration? FIXME: Find who uses this and eliminate, or at least add a good description.
${TOPO_TREE_LEVEL}    2    # Part of Mininet configuration? FIXME: Find who uses this and eliminate, or at least add a good description.
${TOPOLOGY_URL}    network-topology:network-topology/topology    # FIXME: Move to a separate Resource and add description.
${USER}           ${ODL_RESTCONF_USER}    # Deprecated. FIXME: Eradicate.
${VBRIFS}         interfaces    # A shorthand. FIXME: Find who uses this and eliminate, or at least add a good description.
${VBRIFS_CREATE}    interfaces.json    # A shorthand. FIXME: Find who uses this and eliminate, or at least add a good description.
${VBRS}           vbridges    # A shorthand. FIXME: Find who uses this and eliminate, or at least add a good description.
${VBRS_CREATE}    vbridges.json    # A shorthand. FIXME: Find who uses this and eliminate, or at least add a good description.
${VLANMAP_CREATE}    vlanmaps.json    # A shorthand. FIXME: Find who uses this and eliminate, or at least add a good description.
${VTNC}           127.0.0.1    # IP address where VTN Coordinator application is running. TODO: Move to a VTN-specific Resource.
&{VTNC_HEADERS}    Content-Type=application/json    username=admin    password=adminpass    # Dict of headers to use for HTTP requests against VTN Coordinator. TODO: Move to a VTN-specific Resource.
${VTNC_PREFIX}    http://${VTNC}:${VTNCPORT}    # Shorthand for composing HTTP requests. TODO: Move to a VTN-specific Resource.
${VTNCPORT}       8083    # Port number VTN Coordinator listens on. TODO: Move to a VTN-specific Resource.
${VTN_INVENTORY_NODE_API}    /restconf/operational/vtn-inventory:vtn-nodes    # Path part of restconf URL towards operational vtn-nodes. TODO: Move to a VTN-specific Resource.
${VTNS}           vtns    # A shorthand. FIXME: Find who uses this and eliminate, or at least add a good description.
${VTNS_CREATE}    vtns.json    # A shorthand. FIXME: Find who uses this and eliminate, or at least add a good description.
${VTNWEBAPI}      /vtn-webapi    # Directory part of URI used when sending HTTP requests to VTN Coordinator. TODO: Move to a VTN-specific Resource.
# Keep this list sorted alphabetically.

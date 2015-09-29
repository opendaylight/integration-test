*** Settings ***
Library           SSHLibrary
Library           String
Library           DateTime
Library           RequestsLibrary
Library           json
Library           SSHLibrary
Library           Collections
Library           XML
Variables         ../variables/Variables.py
Resource          ./Utils.robot

*** Keywords ***
Get VtnCo
    [Documentation]    Download the VTN Coordinator from Controller VM
    Log    Download the VTN Coordinator bz2 file
    SSHLibrary.Open_Connection    ${CONTROLLER}
    SSHLibrary.Login_With_Public_Key    ${CONTROLLER_USER}    ${USER_HOME}/.ssh/${SSH_KEY}    any
    ${VTNC_FILENAME}=    Catenate    SEPARATOR=/    ${WORKSPACE}    vtn_coordinator.tar.bz2
    SSHLibrary.Get_File    ${WORKSPACE}/${BUNDLEFOLDER}/externalapps/*vtn-coordinator*-bin.tar.bz2    ${VTNC_FILENAME}
    SSHLibrary.Close_Connection
    SSHLibrary.Open_Connection    ${MININET}
    SSHLibrary.Login_With_Public_Key    ${MININET_USER}    ${USER_HOME}/.ssh/${SSH_KEY}    any
    SSHLibrary.Put_File    ${VTNC_FILENAME}    /tmp
    SSHLibrary.Close_Connection

Start SuiteVtnCo
    [Documentation]    Download and startup the VTN Coordinator.
    Log    Start the VTN Coordinator
    Get VtnCo
    ${vtnc_conn_id}=    Open Connection    ${MININET}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=30s
    Set Suite Variable    ${vtnc_conn_id}
    Login With Public Key    ${MININET_USER}    ${USER_HOME}/.ssh/${SSH_KEY}    any
    ${VTNC_FILENAME}=    Catenate    SEPARATOR=/    ${WORKSPACE}    vtn_coordinator.tar.bz2
    Execute Command    tar -C/ -jxvf ${VTNC_FILENAME}
    Execute Command    /usr/local/vtn/sbin/db_setup
    Execute Command    /usr/local/vtn/bin/vtn_start
    Execute Command    /usr/local/vtn/bin/unc_dmctl status
    Execute Command    /usr/local/vtn/sbin/db_setup
    Execute Command    sed -i 's/odcdrv_ping_interval = 30/odcdrv_ping_interval = 10/g' /usr/local/vtn/modules/odcdriver.conf
    Execute Command    sed -i 's/physical_attributes_read_interval = 40/physical_attributes_read_interval = 15/g' /usr/local/vtn/modules/vtndrvintf.conf
    Execute Command    /usr/local/vtn/bin/vtn_start
    Execute Command    /usr/local/vtn/bin/unc_dmctl status
    Execute Command    /usr/local/vtn/bin/drvodc_control loglevel trace
    Execute Command    /usr/local/vtn/bin/lgcnw_control loglevel trace
    Execute Command    exit

Stop SuiteVtnCo
    [Documentation]    Exit the Launch Test
    Log    Stop the Launch Test

Start SuiteVtnCoTest
    [Documentation]    Start the VTNCo Test
    Create Session    session    http://${MININET}:8083    headers=${VTNC_HEADERS}

Stop SuiteVtnCoTest
    [Documentation]    Exit the VtnCo Test
    Delete All Sessions

Get Coordinator Version
    [Documentation]    Get API version for testing
    ${resp}    RequestsLibrary.Get    session    ${VTNWEBAPI}/api_version
    Should Be Equal As Strings    ${resp.status_code}    200

Add a Controller
    [Arguments]    ${ctrlname}    ${ctrlip}
    [Documentation]    Create a controller
    ${controllerinfo}    Create Dictionary    controller_id=${ctrlname}    type=odc    ipaddr=${CONTROLLER}    version=1.0
    ${controllercreate}    Create Dictionary    controller=${controllerinfo}
    ${controllercreate_json}=    json.dumps    ${controllercreate}
    ${resp}    RequestsLibrary.Post    session    ${VTNWEBAPI}/${CTRLS_CREATE}    data=${controllercreate_json}
    Should Be Equal As Strings    ${resp.status_code}    201

Remove Controller
    [Arguments]    ${ctrlname}
    [Documentation]    Delete a Controller
    ${resp}    RequestsLibrary.Delete    session    ${VTNWEBAPI}/${CTRLS}/${ctrlname}.json
    Should Be Equal As Strings    ${resp.status_code}    204

Update Controller
    [Arguments]    ${ctrlname}    ${ctrlip}    ${desc}
    [Documentation]    Update controller
    ${controllerinfo}    Create Dictionary    description=${desc}    ipaddr=${ctrlip}    version=1.0
    ${controllerupdate}    Create Dictionary    controller=${controllerinfo}
    ${controllerupdate_json}=    json.dumps    ${controllerupdate}
    ${resp}    RequestsLibrary.Put    session    ${VTNWEBAPI}/${CTRLS}/${ctrlname}.json    data=${controllerupdate_json}
    Should Be Equal As Strings    ${resp.status_code}    204

Audit Controller
    [Arguments]    ${ctrlname}
    [Documentation]    Trigger Manual Audit
    ${auditinfo}    Create Dictionary    force=false    real-network_audit=false
    ${auditupdate}    Create Dictionary    audit=${auditinfo}
    ${auditupdate_json}=    json.dumps    ${auditupdate}
    ${resp}    RequestsLibrary.Put    session    ${VTNWEBAPI}/${CTRLS}/${ctrlname}/audit.json    data=${auditupdate_json}
    Should Be Equal As Strings    ${resp.status_code}    204

Check Controller Status
    [Arguments]    ${ctrlname}    ${stat}
    [Documentation]    Get controller status
    ${resp}    RequestsLibrary.Get    session    ${VTNWEBAPI}/${CTRLS}/${ctrlname}.json
    ${contents}    To JSON    ${resp.content}
    ${controllerblock}    Get From Dictionary    ${contents}    controller
    ${status}    Get From Dictionary    ${controllerblock}    operstatus
    Should Be Equal As Strings    ${status}    ${stat}

Add a VTN
    [Arguments]    ${vtnname}    ${vtndescription}
    [Documentation]    Create VTN in Coordinator
    ${vtninfo}    Create Dictionary    vtn_name=${vtnname}    description=${vtndescription}
    ${vtncreate}    Create Dictionary    vtn=${vtninfo}
    ${vtncreate_json}=    json.dumps    ${vtncreate}
    ${resp}    RequestsLibrary.Post    session    ${VTNWEBAPI}/${VTNS_CREATE}    data=${vtncreate_json}
    Should Be Equal As Strings    ${resp.status_code}    201

Delete a VTN
    [Arguments]    ${vtnname}
    [Documentation]    Delete a VTN Created
    ${resp}    RequestsLibrary.Delete    session    ${VTNWEBAPI}/${VTNS}/${vtnname}.json
    Should Be Equal As Strings    ${resp.status_code}    204

Create VBR in VTN
    [Arguments]    ${vtnname}    ${vbrname}    ${ctrlname}
    [Documentation]    Create VBR for VTN in Coordinator
    ${vbrinfo}    Create Dictionary    vbr_name=${vbrname}    controller_id=${ctrlname}    domain_id=(DEFAULT)
    ${vbrcreate}    Create Dictionary    vbridge=${vbrinfo}
    ${vbrcreate_json}=    json.dumps    ${vbrcreate}
    ${resp}    RequestsLibrary.Post    session    ${VTNWEBAPI}/${VTNS}/${vtnname}/${VBRS_CREATE}    data=${vbrcreate_json}
    Should Be Equal As Strings    ${resp.status_code}    201

Create VBRIF in VBR
    [Arguments]    ${vtnname}    ${vbrname}    ${vbrifname}    ${ifdescription}    ${retcode}
    [Documentation]    Create VBR Interface in VBR
    ${vbrifinfo}    Create Dictionary    if_name=${vbrifname}    description=${ifdescription}
    ${vbrifcreate}    Create Dictionary    interface=${vbrifinfo}
    ${vbrifcreate_json}=    json.dumps    ${vbrifcreate}
    ${resp}    RequestsLibrary.Post    session    ${VTNWEBAPI}/${VTNS}/${vtnname}/${VBRS}/${vbrname}/${VBRIFS_CREATE}    data=${vbrifcreate_json}
    Should Be Equal As Strings    ${resp.status_code}    ${retcode}

Define Portmap for VBRIF
    [Arguments]    ${vtnname}    ${vbrname}    ${vbrifname}    ${logical_port_id}
    [Documentation]    Map Interface to a logical port
    ${logical_port_info}    Create Dictionary    logical_port_id=${logical_port_id}
    ${portmapdefine}    Create Dictionary    portmap=${logical_port_info}
    ${portmapdefine_json}=    json.dumps    ${portmapdefine}
    ${resp}    RequestsLibrary.Put    session    ${VTNWEBAPI}/${VTNS}/${vtnname}/${VBRS}/${vbrname}/${VBRIFS}/${vbrifname}/${PORTMAP_CREATE}    data=${portmapdefine_json}
    Should Be Equal As Strings    ${resp.status_code}    204

Add a FLOWLIST
    [Arguments]    ${flowlistname}    ${ipversion}
    [Documentation]    Create FLOWLIST in Coordinator
    ${flowlistinfo}    Create Dictionary    fl_name=${flowlistname}    ip_version=${ipversion}
    ${flowlistcreate}    Create Dictionary    flowlist=${flowlistinfo}
    ${flowlistcreate_json}=    json.dumps    ${flowlistcreate}
    ${resp}    RequestsLibrary.Post    session    ${VTNWEBAPI}/${FLOWLISTS_CREATE}    data=${flowlistcreate_json}
    Should Be Equal As Strings    ${resp.status_code}    201

Create FLOWLISTENTRY
    [Arguments]    ${flowlistname}
    [Documentation]    Create Flowlistentry for Coordinator
    ${flowlistentryinfo}    Create Dictionary    seqnum=233    macethertype=0x800    ipdstaddr=10.0.0.1    ipdstaddrprefix=32    ipsrcaddr=10.0.0.3
    ...    ipsrcaddrprefix=32    ipproto=1
    ${flowlistentrycreate}    Create Dictionary    flowlistentry=${flowlistentryinfo}
    ${flowlistentrycreate_json}=    json.dumps    ${flowlistentrycreate}
    ${resp}    RequestsLibrary.Post    session    ${VTNWEBAPI}/${FLOWLISTS}/${flowlistname}/${FLOWLISTENTRIES_CREATE}    data=${flowlistentrycreate_json}
    Should Be Equal As Strings    ${resp.status_code}    201

Create FLOWLISTENTRY_ANY in FLOWLIST
    [Arguments]    ${flowlistname}
    [Documentation]    Create Flowlistentry_any for Coordinator
    ${flowlistentryinfo}    Create Dictionary    seqnum=1
    ${flowlistentrycreate}    Create Dictionary    flowlistentry=${flowlistentryinfo}
    ${flowlistentrycreate_json}=    json.dumps    ${flowlistentrycreate}
    ${resp}    RequestsLibrary.Post    session    ${VTNWEBAPI}/${FLOWLISTS}/${flowlistname}/${FLOWLISTENTRIES_CREATE}    data=${flowlistentrycreate_json}
    Should Be Equal As Strings    ${resp.status_code}    201

Create VBRIF in FLOWFILTER
    [Arguments]    ${vtnname}    ${vbrname}    ${vbrifname}    ${ff_type}
    [Documentation]    create vbridge interface flowfilter
    ${flowfilters_info}    Create Dictionary    ff_type=${ff_type}
    ${flowfiltersdefine}    Create Dictionary    flowfilter=${flowfilters_info}
    ${flowfiltersdefine_json}=    json.dumps    ${flowfiltersdefine}
    ${resp}    RequestsLibrary.Post    session    ${VTNWEBAPI}/${VTNS}/${vtnname}/${VBRS}/${vbrname}/${VBRIFS}/${vbrifname}/${FLOWFILTERS_CREATE}    data=${flowfiltersdefine_json}
    Should Be Equal As Strings    ${resp.status_code}    201

Create FLOWFILTERENTRY DROP In VBRIFFLOWFILTER
    [Arguments]    ${vtnname}    ${vbrname}    ${vbrifname}    ${actiontype}
    [Documentation]    create domonstration with pass actiontype
    ${flowfilterentryinfo}    Create Dictionary    seqnum=233    fl_name=Flowlist1    action_type=${actiontype}    priority=3    dscp=55
    ${flowfilterentrycreate}    Create Dictionary    flowfilterentry=${flowfilterentryinfo}
    ${flowfilterentrycreate_json}=    json.dumps    ${flowfilterentrycreate}
    ${resp}    RequestsLibrary.Post    session    ${VTNWEBAPI}/${VTNS}/${vtnname}/${VBRS}/${vbrname}/${VBRIFS}/${vbrifname}/${FLOWFILTERS}/${FLOWFILTERENTRIES_CREATE}    data=${flowfilterentrycreate_json}
    Should Be Equal As Strings    ${resp.status_code}    201

Create FLOWFILTERENTRY PASS In VBRIFFLOWFILTER
    [Arguments]    ${vtnname}    ${vbrname}    ${vbrifname}    ${actiontype}    ${seqnum}
    [Documentation]    create domonstration with pass actiontype
    ${flowfilterentryinfo}    Create Dictionary    fl_name=Flowlist1    action_type=${actiontype}    priority=3    dscp=55
    ${flowfilterentrycreate}    Create Dictionary    flowfilterentry=${flowfilterentryinfo}
    ${flowfilterentrycreate_json}=    json.dumps    ${flowfilterentrycreate}
    ${resp}    RequestsLibrary.Put    session    ${VTNWEBAPI}/${VTNS}/${vtnname}/${VBRS}/${vbrname}/${VBRIFS}/${vbrifname}/${FLOWFILTERS}/${FLOWFILTERS_UPDATE}/${seqnum}    data=${flowfilterentrycreate_json}
    Should Be Equal As Strings    ${resp.status_code}    204

Create FLOWFILTER in VBR
    [Arguments]    ${vtnname}    ${vbrname}    ${ff_type}
    [Documentation]    create vtn flowfilter
    ${flowfilters_info}    Create Dictionary    ff_type=${ff_type}
    ${flowfiltersdefine}    Create Dictionary    flowfilter=${flowfilters_info}
    ${flowfiltersdefine_json}=    json.dumps    ${flowfiltersdefine}
    ${resp}    RequestsLibrary.Post    session    ${VTNWEBAPI}/${VTNS}/${vtnname}/${VBRS}/${vbrname}/${FLOWFILTERS_CREATE}    data=${flowfiltersdefine_json}
    Should Be Equal As Strings    ${resp.status_code}    201

Create FLOWFILTERENTRY PASS in VBRFLOWFILTER
    [Arguments]    ${vtnname}    ${vbrname}    ${actiontype}
    [Documentation]    create domonstration with pass actiontype
    ${flowfilterentryinfo}    Create Dictionary    seqnum=233    fl_name=Flowlist1    action_type=${actiontype}    priority=3    dscp=55
    ${flowfilterentryinfo_1}    Create Dictionary    vnode_name=${vbrname}    fl_name=Flowlist1    direction=in
    ${flowfilterentrycreate}    Create Dictionary    flowfilterentry=${flowfilterentryinfo}
    ${flowfilterentrycreate_json}=    json.dumps    ${flowfilterentrycreate}
    ${resp}    RequestsLibrary.Post    session    ${VTNWEBAPI}/${VTNS}/${vtnname}/${VBRS}/${vbrname}/${FLOWFILTERS}/${FLOWFILTERENTRIES_CREATE}    data=${flowfilterentrycreate_json}
    Should Be Equal As Strings    ${resp.status_code}    201

Create FLOWFILTER in VTN
    [Arguments]    ${vtnname}    ${ff_type}
    [Documentation]    create vtn flowfilter
    ${flowfilters_info}    Create Dictionary    ff_type=${ff_type}
    ${flowfiltersdefine}    Create Dictionary    flowfilter=${flowfilters_info}
    ${flowfiltersdefine_json}=    json.dumps    ${flowfiltersdefine}
    ${resp}    RequestsLibrary.Post    session    ${VTNWEBAPI}/${VTNS}/${vtnname}/${FLOWFILTERS_CREATE}    data=${flowfiltersdefine_json}
    Should Be Equal As Strings    ${resp.status_code}    201

Create FLOWFILTERENTRY PASS in VTNFLOWFILTER
    [Arguments]    ${vtnname}    ${actiontype}
    [Documentation]    create domonstration with pass actiontype
    ${flowfilterentryinfo}    Create Dictionary    seqnum=233    fl_name=Flowlist1    action_type=${actiontype}    priority=3    dscp=55
    ${flowfilterentrycreate}    Create Dictionary    flowfilterentry=${flowfilterentryinfo}
    ${flowfilterentrycreate_json}=    json.dumps    ${flowfilterentrycreate}
    ${resp}    RequestsLibrary.Post    session    ${VTNWEBAPI}/${VTNS}/${vtnname}/${FLOWFILTERS}/${FLOWFILTERENTRIES_CREATE}    data=${flowfilterentrycreate_json}
    Should Be Equal As Strings    ${resp.status_code}    201

Create VLANMAP in VBRIDGE
    [Arguments]    ${vtnname}    ${vbrname}    ${vlanid}
    [Documentation]    Create VLANMAP for VBRIDGE in Coordinator
    ${vlaninfo}    Create Dictionary    vlan_id=${vlanid}
    ${vlancreate}    Create Dictionary    vlanmap=${vlaninfo}
    ${vlancreate_json}=    json.dumps    ${vlancreate}
    ${resp}    RequestsLibrary.Post    session    ${VTNWEBAPI}/${VTNS}/${vtnname}/${VBRS}/${vbrname}/${VLANMAP_CREATE }    data=${vlancreate_json}
    Should Be Equal As Strings    ${resp.status_code}    201

Delete a FLOWLIST
    [Arguments]    ${flowlistname}
    [Documentation]    Delete a Flowlist
    ${resp}    RequestsLibrary.Delete    session    ${VTNWEBAPI}/${FLOWLISTS}/${flowlistname}.json
    Should Be Equal As Strings    ${resp.status_code}    204

Test Ping
    [Arguments]    ${host1}    ${host2}
    [Documentation]    Ping hosts to check connectivity
    Write    ${host1} ping -c 4 ${host2}
    ${result}    Read Until    mininet>
    Should Contain    ${result}    64 bytes

Verify Switch
    [Arguments]    ${ctrlname}    ${switch_id}
    [Documentation]    Get switch
    ${resp}    RequestsLibrary.Get    session    ${VTNWEBAPI}/${CTRLS}/${ctrlname}/${SW}/${switch_id}.json
    ${contents}    To JSON    ${resp.content}
    ${switchblock}    Get From Dictionary    ${contents}    switch
    ${status}    Get From Dictionary    ${switchblock}    switch_id
    Should Be Equal As Strings    ${status}    ${switch_id}

Verify SwitchPort
    [Arguments]    ${ctrlname}    ${switch_id}
    [Documentation]    Get switch
    ${resp}    RequestsLibrary.Get    session    ${VTNWEBAPI}/${CTRLS}/${ctrlname}/${SW}/${switch_id}/${PORTS}
    Should Be Equal As Strings    ${resp.status_code}    200

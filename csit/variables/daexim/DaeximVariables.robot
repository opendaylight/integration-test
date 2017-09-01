*** Settings ***
Documentation     Resource consisting purely of variable definitions useful for multiple project suites.

*** Variables ***
${CANCEL_EXPORT_URL}    /restconf/operations/data-export-import:cancel-export
${EXPORT_FILE}    ${CURDIR}/schedule_export.json
${EXP_DIR}        /tmp/Export
${EXPORT_EXCLUDE_FILE}    ${CURDIR}/schedule_export_exclude.json
${SCHEDULE_EXPORT_URL}    /restconf/operations/data-export-import:schedule-export
${EXP_DATA_FILE}    odl_backup_config.json
${EXP_OPER_FILE}    odl_backup_operational.json
${MODELS_FILE}    odl_backup_models.json
${STATUS_EXPORT_URL}    /restconf/operations/data-export-import:status-export
${NETCONF_PAYLOAD_JSON}    ../variables/daexim/netconf_mount.json
${NETCONF_MOUNT_URL}    /restconf/config/network-topology:network-topology/topology/topology-netconf/node/
${TOPOLOGY_URL}    /restconf/config/network-topology:network-topology/
${NETCONF_EP_NAME}    CONTROLLER1
${EXPORT_INITIAL_STATUS}    initial
${EXPORT_SCHEDULED_STATUS}    scheduled
${EXPORT_COMPLETE_STATUS}    complete
${FIRST_CONTROLLER_INDEX}    1
${NTCF_TPLG_OPR_URL}    /restconf/operational/network-topology:network-topology/topology/topology-netconf/node/
${NETCONF_PORT}    1830
${NTCF_OPR_STATUS}    connected
${DAEXIM_DATA_DIRECTORY}    ../variables/daexim/daexim
${MDL_DEF_FLAG}    true
${STR_DEF_FLAG}    data
${IMPORT_PAYLOAD}    ../variables/daexim/import.json
${IMPORT_URL}     /restconf/operations/data-export-import:immediate-import
@{Networks}       mynet1    mynet2    mynet3    mynet4    mynet5    mynet6    mynet7
...               mynet8    mynet9    mynetA
@{Subnets}        ipv4s1    ipv4s2    ipv4s3    ipv4s4    ipv4s5    ipv4s6    ipv4s7
...               ipv4s8    ipv4s9    ipv4s10
@{VM_list}        vm1    vm2    vm3    vm4    vm5    vm6    vm7
...               vm8    vm9    vm10
@{V4subnets}      11.0.0.0    12.0.0.0    13.0.0.0    14.0.0.0    15.0.0.0    16.0.0.0    17.0.0.0
...               18.0.0.0    19.0.0.0    20.0.0.0
@{V4subnet_names}    subnet1v4    subnet2v4    subnet3v4    subnet4v4    subnet5v4    subnet6v4    subnet7v4
...               subnet8v4    subnet9v4    subnet10v4
@{port_name}      P11    P12    P13    P14    P15    P16    P17
...               P18    P19    P20
@{port_name1}     P21    P22    P23    P24    P25    P26    P27
...               P28    P29    P30
@{VM_list1}       vm11    vm12    vm13    vm14    vm15    vm16    vm17
...               vm18    vm19    vmA
${PING_PASS}      , 0% packet loss
${block_cmd}      netstat -nap | grep
${block_port}     6653
${block_port1}    6640

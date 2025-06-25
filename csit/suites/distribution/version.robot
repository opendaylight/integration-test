*** Settings ***
Documentation       Suite for testing ODL distribution ability to report ist version via Restconf.
...
...                 Copyright (c) 2016 Cisco Systems, Inc. and others. All rights reserved.
...
...                 This program and the accompanying materials are made available under the
...                 terms of the Eclipse Public License v1.0 which accompanies this distribution,
...                 and is available at http://www.eclipse.org/legal/epl-v10.html
...
...
...                 Features needed to be installed:
...                 odl-distribution-version (the main feature, defines the version string holder as a config module)
...                 odl-netconf-connector (controller-config device is used to access the config subsystem)
...                 odl-restconf (or odl-restconf-noauth, to get restconf access to the data mounted by controller-config)
...
...                 Variables needed to be rovided on pybot invocation:
...                 ${BUNDLEFOLDER} (directory name of ODL installation, as it is suffxed by the distribution version)
...
...                 This suite require both Restconf and Netconf-connector to be ready,
...                 so it is recommended to run netconfready.robot before running this suite.
...
...                 TODO: Figure out a way to reliably predict Odlparent version.
...                 Possibly, inspection of system/org/opendaylight/odlparent/ would be required.

Resource            ${CURDIR}/../../libraries/distribution/StreamDistro.robot
Resource            ${CURDIR}/../../libraries/TemplatedRequests.robot
Resource            ${CURDIR}/../../libraries/SetupUtils.robot

Suite Setup         Suite_Setup
Suite Teardown      Suite_Teardown
Test Setup          SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown       SetupUtils.Teardown_Test_Show_Bugs_If_Test_Failed

Default Tags        critical    distribution    version


*** Variables ***
${VERSION_VARDIR}           ${CURDIR}/../../variables/distribution/version
${DEVICE_NAME}              controller-config
${NETCONF_DEV_FOLDER}       ${CURDIR}/../../variables/netconf/device/full-uri-device
${NETCONF_MOUNT_FOLDER}     ${CURDIR}/../../variables/netconf/device/full-uri-mount


*** Test Cases ***
Distribution_Version
    [Documentation]    Get version string as a part of ${BUNDLEFOLDER} and match with what RESTCONF says.
    # ${BUNDLEFOLDER} typically looks like this: karaf-0.8.0-SNAPSHOT
    ${filename_prefix} =    StreamDistro.Compose_Zip_Filename_Prefix
    ${version} =    BuiltIn.Evaluate    """${BUNDLEFOLDER}"""[len("""${filename_prefix}-"""):]
    BuiltIn.Wait_Until_Keyword_Succeeds
    ...    60x
    ...    3s
    ...    TemplatedRequests.Get_As_Json_Templated
    ...    folder=${VERSION_VARDIR}
    ...    mapping={"VERSION":"${version}"}
    ...    verify=True


*** Keywords ***
Suite_Setup
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    TemplatedRequests.Create_Default_Session
    IF    """${USE_NETCONF_CONNECTOR}""" == """False"""
        Configure_Netconf_Device
    END

Suite_Teardown
    IF    """${USE_NETCONF_CONNECTOR}""" == """False"""    Remove_Netconf_Device

Configure_Netconf_Device
    [Documentation]    Configures netconf device if ${USE_NETCONF_CONNECTOR} is False.
    &{mapping} =    BuiltIn.Create_Dictionary
    ...    DEVICE_NAME=${DEVICE_NAME}
    ...    DEVICE_PORT=1830
    ...    DEVICE_IP=${ODL_SYSTEM_IP}
    ...    DEVICE_USER=admin
    ...    DEVICE_PASSWORD=admin
    ...    RESTCONF_ROOT=${RESTCONF_ROOT}
    TemplatedRequests.Put_As_Xml_Templated    ${NETCONF_DEV_FOLDER}    mapping=${mapping}
    BuiltIn.Wait_Until_Keyword_Succeeds
    ...    10x
    ...    3s
    ...    TemplatedRequests.Get_As_Xml_Templated
    ...    ${NETCONF_MOUNT_FOLDER}
    ...    mapping=${mapping}

Remove_Netconf_Device
    [Documentation]    Removes netconf device if ${USE_NETCONF_CONNECTOR} is False.
    &{mapping} =    BuiltIn.Create_Dictionary
    ...    DEVICE_NAME=${DEVICE_NAME}
    ...    RESTCONF_ROOT=${RESTCONF_ROOT}
    TemplatedRequests.Delete_Templated    ${NETCONF_DEV_FOLDER}    mapping=${mapping}

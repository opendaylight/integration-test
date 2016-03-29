*** Variables ***
# list of ports available to be used in each feature listing
${clustering}                                   2550
${openflow_legacy}                              6633
${openflow_iana}                                6653
${ovsdb}                                        6640
${netide}                                       6644
${vpnservice}                                   6645
${web-portal}                                   8080
${restconf}                                     8181
${authz}                                        8185
${xsql}                                         34343
${jddbc}                                        40004

# feature lists (alphabetical order) and every port that should be opened after that feature
# is installed.
@{ports-odl-aaa-api}
@{ports-odl-aaa-authn}                          ${clustering}    ${web-portal}    ${restconf}
@{ports-odl-aaa-authn-mdsal-cluster}            ${clustering}    ${web-portal}    ${restconf}
@{ports-odl-aaa-authn-no-cluster}               ${clustering}    ${web-portal}    ${restconf}
@{ports-odl-aaa-authn-sssd-no-cluster}          ${clustering}    ${web-portal}    ${restconf}
# @{ports-odl-aaa-authz}                          ${clustering}    ${web-portal}    ${restconf}  # email sent to ryan goulding
@{ports-odl-aaa-authz}                          ${clustering}
@{ports-odl-aaa-keystone-plugin}                ${clustering}    ${web-portal}    ${restconf}
@{ports-odl-aaa-netconf-plugin}                 ${clustering}    ${web-portal}    ${restconf}
@{ports-odl-aaa-netconf-plugin-no-cluster}      ${clustering}    ${web-portal}    ${restconf}
@{ports-odl-aaa-shiro}                          ${clustering}    ${web-portal}    ${restconf}
@{ports-odl-aaa-sssd-plugin}                    ${clustering}    ${web-portal}    ${restconf}
@{ports-odl-akka-all}
@{ports-odl-akka-clustering}                    #TODO: need to figure out why a feature with -clustering in it's name is not bringing in a clustering port (e.g. 2550)
@{ports-odl-akka-leveldb}
@{ports-odl-akka-persistence}
@{ports-odl-akka-scala}
@{ports-odl-akka-system}
@{ports-odl-alto-basic}                         ${clustering}    ${web-portal}    ${restconf}    ${authz}    ${xsql}    ${jddbc}
@{ports-odl-alto-core}                          ${clustering}    ${web-portal}    ${restconf}    ${authz}    ${xsql}    ${jddbc}
@{ports-odl-alto-extension}                     ${clustering}    ${openflow_legacy}    ${openflow_iana}
@{ports-odl-alto-hosttracker}
@{ports-odl-alto-manual-maps}                   ${clustering}    ${web-portal}    ${restconf}    ${authz}    ${xsql}    ${jddbc}
@{ports-odl-alto-nonstandard-northbound-route}
@{ports-odl-alto-nonstandard-service-models}
@{ports-odl-alto-nonstandard-types}
@{ports-odl-alto-northbound}                    ${clustering}    ${web-portal}    ${restconf}    ${authz}
#@{ports-odl-netide-rest}                        ${clustering}    ${web-portal}    ${restconf}    ${openflow_legacy}    ${openflow_iana}    ${netide}    ${authz}    ${xsql}    ${jddbc}
#@{ports-odl-openflowplugin-flow-services-li}    ${clustering}    ${openflow_legacy}    ${openflow_iana}
#@{ports-odl-vpnservice-openstack}               ${clustering}    ${web-portal}    ${restconf}    ${openflow_legacy}    ${openflow_iana}    ${ovsdb}    ${vpnservice}    ${authz}

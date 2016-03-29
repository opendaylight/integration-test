*** Variables ***
# list of TCP ports available to be used in each feature listing
${tcp_usc_1069}                                     1069
${tcp_centinel_syslog}                              1514
${tcp_bgp}                                          1790
${tcp_clustering_2550}                              2550
${tcp_clustering_2552}                              2552
${tcp_pcep}                                         4189
${tcp_openflow_legacy}                              6633
${tcp_openflow_iana}                                6653
${tcp_ovsdb}                                        6640
${tcp_netide}                                       6644
${tcp_vpnservice}                                   6645
${tcp_web-portal}                                   8080
${tcp_restconf}                                     8181
${tcp_authz}                                        8185
${tcp_bmp_monitor}                                  12345
${tcp_xsql}                                         34343
${tcp_jddbc}                                        40004

# list of UDP ports available to be used in each feature listing
${udp_usc_1069}                                     1069
${udp_capwap}                                       5246
${udp_coap}                                         5683

# feature lists (alphabetical order) and every port that should be opened after that feature
# is installed.
@{tcp_ports-odl-aaa-api}
@{tcp_ports-odl-aaa-authn}                          ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}
@{tcp_ports-odl-aaa-authn-mdsal-cluster}            ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}
@{tcp_ports-odl-aaa-authn-no-cluster}               ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}
@{tcp_ports-odl-aaa-authn-sssd-no-cluster}          ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}
@{tcp_ports-odl-aaa-authz}                          ${tcp_clustering_2550}
@{tcp_ports-odl-aaa-keystone-plugin}                ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}
@{tcp_ports-odl-aaa-netconf-plugin}                 ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}
@{tcp_ports-odl-aaa-netconf-plugin-no-cluster}      ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}
@{tcp_ports-odl-aaa-shiro}                          ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}
@{tcp_ports-odl-aaa-sssd-plugin}                    ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}
@{tcp_ports-odl-akka-all}
@{tcp_ports-odl-akka-clustering}                    #TODO: need to figure out why a feature with -clustering in it's name is not bringing in a clustering port (e.g. 2550)
@{tcp_ports-odl-akka-leveldb}
@{tcp_ports-odl-akka-persistence}
@{tcp_ports-odl-akka-scala}
@{tcp_ports-odl-akka-system}
@{tcp_ports-odl-alto-basic}                         ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}    ${tcp_authz}    ${tcp_xsql}    ${tcp_jddbc}
@{tcp_ports-odl-alto-core}                          ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}    ${tcp_authz}    ${tcp_xsql}    ${tcp_jddbc}
@{tcp_ports-odl-alto-extension}                     ${tcp_clustering_2550}    ${tcp_openflow_legacy}   ${tcp_openflow_iana}
@{tcp_ports-odl-alto-hosttracker}
@{tcp_ports-odl-alto-manual-maps}                   ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}    ${tcp_authz}    ${tcp_xsql}    ${tcp_jddbc}
@{tcp_ports-odl-alto-nonstandard-northbound-route}
@{tcp_ports-odl-alto-nonstandard-service-models}
@{tcp_ports-odl-alto-nonstandard-types}
@{tcp_ports-odl-alto-northbound}                    ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}    ${tcp_authz}
@{tcp_ports-odl-alto-release}                       ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}    ${tcp_authz}    ${tcp_xsql}    ${tcp_jddbc}
@{tcp_ports-odl-alto-resourcepool}                  ${tcp_clustering_2550}                                                            ${tcp_xsql}    ${tcp_jddbc}
@{tcp_ports-odl-alto-simpleird}                     ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}    ${tcp_authz}    ${tcp_xsql}    ${tcp_jddbc}
@{tcp_ports-odl-alto-spce}                          ${tcp_clustering_2550}    ${tcp_openflow_legacy}   ${tcp_openflow_iana}
@{tcp_ports-odl-alto-standard-northbound-route}     ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}    ${tcp_authz}    ${tcp_xsql}    ${tcp_jddbc}
@{tcp_ports-odl-alto-standard-resource-translator}
@{tcp_ports-odl-alto-standard-service-models}       ${tcp_clustering_2550}                                                            ${tcp_xsql}    ${tcp_jddbc}
@{tcp_ports-odl-alto-standard-types}
@{tcp_ports-odl-benchmark-api}
@{tcp_ports-odl-bgpcep-bgp}                         ${tcp_clustering_2550}    ${tcp_bgp}
@{tcp_ports-odl-bgpcep-bgp-all}                     ${tcp_clustering_2550}    ${tcp_bgp}
@{tcp_ports-odl-bgpcep-bgp-benchmark}               ${tcp_clustering_2550}
@{tcp_ports-odl-bgpcep-bgp-dependencies}
@{tcp_ports-odl-bgpcep-bgp-flowspec}                ${tcp_clustering_2550}
@{tcp_ports-odl-bgpcep-bgp-inet}
@{tcp_ports-odl-bgpcep-bgp-labeled-unicast}         ${tcp_clustering_2550}
@{tcp_ports-odl-bgpcep-bgp-linkstate}               ${tcp_clustering_2550}
@{tcp_ports-odl-bgpcep-bgp-openconfig}              ${tcp_clustering_2550}
@{tcp_ports-odl-bgpcep-bgp-parser}
@{tcp_ports-odl-bgpcep-bgp-rib-api}                 ${tcp_clustering_2550}
@{tcp_ports-odl-bgpcep-bgp-rib-impl}                ${tcp_clustering_2550}
@{tcp_ports-odl-bgpcep-bgp-topology}                ${tcp_clustering_2550}
@{tcp_ports-odl-bgpcep-bmp}                         ${tcp_clustering_2550}    ${tcp_bmp_monitor}
@{tcp_ports-odl-bgpcep-data-change-counter}         ${tcp_clustering_2550}
@{tcp_ports-odl-bgpcep-dependencies}
@{tcp_ports-odl-bgpcep-pcep}                        ${tcp_clustering_2550}    ${tcp_pcep}
@{tcp_ports-odl-bgpcep-pcep-all}                    ${tcp_clustering_2550}    ${tcp_pcep}
@{tcp_ports-odl-bgpcep-pcep-api}
@{tcp_ports-odl-bgpcep-pcep-auto-bandwidth}
@{tcp_ports-odl-bgpcep-pcep-dependencies}
@{tcp_ports-odl-bgpcep-pcep-impl}
@{tcp_ports-odl-bgpcep-pcep-segment-routing}
@{tcp_ports-odl-bgpcep-pcep-stateful07}
@{tcp_ports-odl-bgpcep-pcep-topology}
@{tcp_ports-odl-bgpcep-pcep-topology-provider}      ${tcp_clustering_2550}    ${tcp_pcep}
@{tcp_ports-odl-bgpcep-pcep-tunnel-provider}        ${tcp_clustering_2550}    ${tcp_pcep}
@{tcp_ports-odl-bgpcep-programming-api}
@{tcp_ports-odl-bgpcep-programming-impl}            ${tcp_clustering_2550}
@{tcp_ports-odl-bgpcep-rsvp}
@{tcp_ports-odl-bgpcep-rsvp-dependencies}
@{tcp_ports-odl-capwap-ac-rest}                     ${tcp_clustering_2550}    ${tcp_clustering_2552}    ${tcp_web-portal}    ${tcp_restconf}    ${tcp_authz}    ${tcp_usc_1069}
@{udp_ports-odl-capwap-ac-rest}                     ${udp_usc_1069}           ${udp_capwap}
@{tcp_ports-odl-capwap-api}
@{tcp_ports-odl-capwap-impl}                        ${tcp_clustering_2550}    ${tcp_clustering_2552}    ${tcp_usc_1069}
@{udp_ports-odl-capwap-impl}                        ${udp_usc_1069}           ${udp_capwap}    # NOTE: capwap impl consumes usc
@{tcp_ports-odl-centinel-all}                       ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}    ${tcp_authz}    ${tcp_xsql}    ${tcp_jddbc}    ${tcp_centinel_syslog}
@{tcp_ports-odl-centinel-api}
@{tcp_ports-odl-centinel-core}                      ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}    ${tcp_authz}    ${tcp_xsql}    ${tcp_jddbc}
@{tcp_ports-odl-centinel-laas}                      ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}    ${tcp_authz}    ${tcp_xsql}    ${tcp_jddbc}
@{tcp_ports-odl-centinel-streamhandler}             ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}    ${tcp_authz}    ${tcp_xsql}    ${tcp_jddbc}    ${tcp_centinel_syslog}
@{tcp_ports-odl-centinel-ui}                        ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}    ${tcp_authz}    ${tcp_xsql}    ${tcp_jddbc}
@{tcp_ports-odl-clustering-test-app}                ${tcp_clustering_2550}
@{tcp_ports-odl-config-all}
@{tcp_ports-odl-config-api}
@{tcp_ports-odl-config-core}
@{tcp_ports-odl-config-manager}
@{tcp_ports-odl-config-manager-facade-xml}
@{tcp_ports-odl-config-netconf-connector}
@{tcp_ports-odl-config-netconf-connector}
@{tcp_ports-odl-config-netty}
@{tcp_ports-odl-config-netty-api}
@{tcp_ports-odl-config-netty-config-api}
@{tcp_ports-odl-config-persister}
@{tcp_ports-odl-config-persister-all}
@{tcp_ports-odl-config-startup}
# TODO: DIDM seems to be bringing in some random UDP port.  Email sent to understand better
# @{tcp_ports-odl-didm-all}                                     ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}    ${tcp_authz}    ${tcp_xsql}    ${tcp_jddbc}    ${tcp_openflow_legacy}   ${tcp_openflow_iana}
# @{tcp_ports-odl-didm-drivers}                                 ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}    ${tcp_authz}    ${tcp_xsql}    ${tcp_jddbc}    ${tcp_openflow_legacy}   ${tcp_openflow_iana}
# @{tcp_ports-odl-didm-hp-all}                                  ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}    ${tcp_authz}    ${tcp_xsql}    ${tcp_jddbc}    ${tcp_openflow_legacy}   ${tcp_openflow_iana}
# @{tcp_ports-odl-didm-hp-impl}                                 ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}    ${tcp_authz}    ${tcp_xsql}    ${tcp_jddbc}    ${tcp_openflow_legacy}   ${tcp_openflow_iana}
# @{tcp_ports-odl-didm-identification}                          ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}    ${tcp_authz}    ${tcp_xsql}    ${tcp_jddbc}    ${tcp_openflow_legacy}   ${tcp_openflow_iana}
# @{tcp_ports-odl-didm-ovs-all}                                 ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}    ${tcp_authz}    ${tcp_xsql}    ${tcp_jddbc}    ${tcp_openflow_legacy}   ${tcp_openflow_iana}
# @{tcp_ports-odl-didm-ovs-impl}                                ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}    ${tcp_authz}    ${tcp_xsql}    ${tcp_jddbc}    ${tcp_openflow_legacy}   ${tcp_openflow_iana}
# @{tcp_ports-odl-didm-util}                                    ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}    ${tcp_authz}    ${tcp_xsql}    ${tcp_jddbc}    ${tcp_openflow_legacy}   ${tcp_openflow_iana}
@{tcp_ports-odl-dlux-all}                           ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}    ${tcp_authz}
@{tcp_ports-odl-dlux-core}                          ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}    ${tcp_authz}
@{tcp_ports-odl-dlux-node}                          ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}    ${tcp_authz}
@{tcp_ports-odl-dlux-yangui}                        ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}    ${tcp_authz}
@{tcp_ports-odl-dlux-yangvisualizer}                ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}    ${tcp_authz}
@{tcp_ports-odl-dsbenchmark}                        ${tcp_clustering_2550}
@{tcp_ports-odl-extras-all}                         ${tcp_web-portal}    ${tcp_restconf}
@{tcp_ports-odl-faas-all}                           ${tcp_clustering_2550}    ${tcp_openflow_legacy}   ${tcp_openflow_iana}    ${tcp_ovsdb}
@{tcp_ports-odl-faas-base}
@{tcp_ports-odl-faas-fabricmgr}                     ${tcp_clustering_2550}
@{tcp_ports-odl-faas-uln-mapper}                    ${tcp_clustering_2550}
@{tcp_ports-odl-faas-vxlan-fabric}                  ${tcp_clustering_2550}
@{tcp_ports-odl-faas-vxlan-ovs-adapter}             ${tcp_clustering_2550}    ${tcp_openflow_legacy}   ${tcp_openflow_iana}    ${tcp_ovsdb}
@{tcp_ports-odl-groupbasedpolicy-base}              ${tcp_clustering_2550}
@{tcp_ports-odl-groupbasedpolicy-faas}              ${tcp_clustering_2550}
@{tcp_ports-odl-groupbasedpolicy-iovisor}           ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}    ${tcp_authz}
@{tcp_ports-odl-groupbasedpolicy-netconf}           ${tcp_clustering_2550}
@{tcp_ports-odl-groupbasedpolicy-neutronmapper}     ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}    ${tcp_authz}    ${tcp_openflow_legacy}   ${tcp_openflow_iana}    ${tcp_ovsdb}
@{tcp_ports-odl-groupbasedpolicy-ofoverlay}         ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}    ${tcp_authz}    ${tcp_openflow_legacy}   ${tcp_openflow_iana}    ${tcp_ovsdb}
@{tcp_ports-odl-groupbasedpolicy-ovssfc}            ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}    ${tcp_authz}    ${tcp_openflow_legacy}   ${tcp_openflow_iana}    ${tcp_ovsdb}
@{tcp_ports-odl-groupbasedpolicy-ui}                ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}    ${tcp_authz}
@{tcp_ports-odl-groupbasedpolicy-uibackend}         ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}    ${tcp_authz}
@{tcp_ports-odl-guava}
@{tcp_ports-odl-hbaseclient}                        ${tcp_web-portal}    ${tcp_restconf}
@{tcp_ports-odl-iotdm-onem2m}                       ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}    ${tcp_authz}       ${tcp_xsql}    ${tcp_jddbc}    8282  # TODO: iotdm seems to conflict with 8282 that controller opens up
@{udp_ports-odl-iotdm-onem2m}                       ${udp_coap}
@{tcp_ports-odl-jolokia}                            ${tcp_web-portal}    ${tcp_restconf}
@{tcp_ports-odl-l2switch-addresstracker}            ${tcp_clustering_2550}    ${tcp_openflow_legacy}   ${tcp_openflow_iana}
@{tcp_ports-odl-l2switch-all}                       ${tcp_clustering_2550}    ${tcp_openflow_legacy}   ${tcp_openflow_iana}
@{tcp_ports-odl-l2switch-arphandler}                ${tcp_clustering_2550}    ${tcp_openflow_legacy}   ${tcp_openflow_iana}
@{tcp_ports-odl-l2switch-hosttracker}               ${tcp_clustering_2550}    ${tcp_openflow_legacy}   ${tcp_openflow_iana}
@{tcp_ports-odl-l2switch-loopremover}               ${tcp_clustering_2550}    ${tcp_openflow_legacy}   ${tcp_openflow_iana}
@{tcp_ports-odl-l2switch-packethandler}             ${tcp_clustering_2550}    ${tcp_openflow_legacy}   ${tcp_openflow_iana}
@{tcp_ports-odl-l2switch-switch}                    ${tcp_clustering_2550}    ${tcp_openflow_legacy}   ${tcp_openflow_iana}
@{tcp_ports-odl-l2switch-switch-rest}               ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}    ${tcp_authz}    ${tcp_openflow_legacy}   ${tcp_openflow_iana}
@{tcp_ports-odl-l2switch-switch-ui}                 ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}    ${tcp_authz}       ${tcp_xsql}    ${tcp_jddbc}    ${tcp_openflow_legacy}   ${tcp_openflow_iana}
#@{ports-odl-netide-rest}                        ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}    ${tcp_openflow_legacy}    ${tcp_openflow_iana}    ${netide}    ${tcp_authz}    ${tcp_xsql}    ${tcp_jddbc}
#@{ports-odl-openflowplugin-flow-services-li}    ${tcp_clustering_2550}    ${tcp_openflow_legacy}    ${tcp_openflow_iana}
#@{ports-odl-vpnservice-openstack}               ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}    ${tcp_openflow_legacy}    ${tcp_openflow_iana}    ${ovsdb}    ${vpnservice}    ${tcp_authz}

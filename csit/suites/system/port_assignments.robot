*** Variables ***
# list of TCP ports available to be used in each feature listing
${tcp_usc_1069}                                     1069
${tcp_centinel_syslog}                              1514
${tcp_bgp}                                          1790
${tcp_netconf_nb}                                   1830
${tcp_clustering_2550}                              2550
${tcp_clustering_2552}                              2552
${tcp_pcep}                                         4189
${tcp_openflow_legacy}                              6633
${tcp_openflow_iana}                                6653
${tcp_ovsdb}                                        6640
${tcp_netide}                                       6644
${tcp_vpnservice}                                   6645
${tcp_vpnservice}                                   6645
${tcp_web-portal}                                   8080
${tcp_restconf}                                     8181
${tcp_authz}                                        8185
${tcp_netconf_test_server}                          8383
${tcp_sfc}                                          9999
${tcp_bmp_monitor}                                  12345
${tcp_xsql}                                         34343
${tcp_jddbc}                                        40004
${tcp_sxp}                                          64999
# list of UDP ports available to be used in each feature listing
${udp_usc_1069}                                     1069
${udp_syslog}                                       1514
${udp_netflow}                                      2055
${udp_lisp}                                         4342
${udp_capwap}                                       5246
${udp_coap}                                         5683

# feature lists (alphabetical order) and every port that should be opened after that feature
# is installed.
@{tcp_ports-odl-aaa-api}
@{tcp_ports-odl-aaa-authn}                                 ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}
@{tcp_ports-odl-aaa-authn-mdsal-cluster}                   ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}
@{tcp_ports-odl-aaa-authn-no-cluster}                      ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}
@{tcp_ports-odl-aaa-authn-sssd-no-cluster}                 ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}
@{tcp_ports-odl-aaa-authz}                                 ${tcp_clustering_2550}
@{tcp_ports-odl-aaa-keystone-plugin}                       ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}
@{tcp_ports-odl-aaa-netconf-plugin}                        ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}
@{tcp_ports-odl-aaa-netconf-plugin-no-cluster}             ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}
@{tcp_ports-odl-aaa-shiro}                                 ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}
@{tcp_ports-odl-aaa-sssd-plugin}                           ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}
@{tcp_ports-odl-akka-all}
@{tcp_ports-odl-akka-clustering}                    #TODO: need to figure out why a feature with -clustering in it's name is not bringing in a clustering port (e.g. 2550)
@{tcp_ports-odl-akka-leveldb}
@{tcp_ports-odl-akka-persistence}
@{tcp_ports-odl-akka-scala}
@{tcp_ports-odl-akka-system}
@{tcp_ports-odl-alto-basic}                                ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}    ${tcp_authz}    ${tcp_xsql}    ${tcp_jddbc}
@{tcp_ports-odl-alto-core}                                 ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}    ${tcp_authz}    ${tcp_xsql}    ${tcp_jddbc}
@{tcp_ports-odl-alto-extension}                            ${tcp_clustering_2550}    ${tcp_openflow_legacy}   ${tcp_openflow_iana}
@{tcp_ports-odl-alto-hosttracker}
@{tcp_ports-odl-alto-manual-maps}                          ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}    ${tcp_authz}    ${tcp_xsql}    ${tcp_jddbc}
@{tcp_ports-odl-alto-nonstandard-northbound-route}
@{tcp_ports-odl-alto-nonstandard-service-models}
@{tcp_ports-odl-alto-nonstandard-types}
@{tcp_ports-odl-alto-northbound}                           ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}    ${tcp_authz}
@{tcp_ports-odl-alto-release}                              ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}    ${tcp_authz}    ${tcp_xsql}    ${tcp_jddbc}
@{tcp_ports-odl-alto-resourcepool}                         ${tcp_clustering_2550}                                                            ${tcp_xsql}    ${tcp_jddbc}
@{tcp_ports-odl-alto-simpleird}                            ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}    ${tcp_authz}    ${tcp_xsql}    ${tcp_jddbc}
@{tcp_ports-odl-alto-spce}                                 ${tcp_clustering_2550}    ${tcp_openflow_legacy}   ${tcp_openflow_iana}
@{tcp_ports-odl-alto-standard-northbound-route}            ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}    ${tcp_authz}    ${tcp_xsql}    ${tcp_jddbc}
@{tcp_ports-odl-alto-standard-resource-translator}
@{tcp_ports-odl-alto-standard-service-models}              ${tcp_clustering_2550}                                                            ${tcp_xsql}    ${tcp_jddbc}
@{tcp_ports-odl-alto-standard-types}
@{tcp_ports-odl-benchmark-api}
@{tcp_ports-odl-bgpcep-bgp}                                ${tcp_clustering_2550}    ${tcp_bgp}
@{tcp_ports-odl-bgpcep-bgp-all}                            ${tcp_clustering_2550}    ${tcp_bgp}
@{tcp_ports-odl-bgpcep-bgp-benchmark}                      ${tcp_clustering_2550}
@{tcp_ports-odl-bgpcep-bgp-dependencies}
@{tcp_ports-odl-bgpcep-bgp-flowspec}                       ${tcp_clustering_2550}
@{tcp_ports-odl-bgpcep-bgp-inet}
@{tcp_ports-odl-bgpcep-bgp-labeled-unicast}                ${tcp_clustering_2550}
@{tcp_ports-odl-bgpcep-bgp-linkstate}                      ${tcp_clustering_2550}
@{tcp_ports-odl-bgpcep-bgp-openconfig}                     ${tcp_clustering_2550}
@{tcp_ports-odl-bgpcep-bgp-parser}
@{tcp_ports-odl-bgpcep-bgp-rib-api}                        ${tcp_clustering_2550}
@{tcp_ports-odl-bgpcep-bgp-rib-impl}                       ${tcp_clustering_2550}
@{tcp_ports-odl-bgpcep-bgp-topology}                       ${tcp_clustering_2550}
@{tcp_ports-odl-bgpcep-bmp}                                ${tcp_clustering_2550}    ${tcp_bmp_monitor}
@{tcp_ports-odl-bgpcep-data-change-counter}                ${tcp_clustering_2550}
@{tcp_ports-odl-bgpcep-dependencies}
@{tcp_ports-odl-bgpcep-pcep}                               ${tcp_clustering_2550}    ${tcp_pcep}
@{tcp_ports-odl-bgpcep-pcep-all}                           ${tcp_clustering_2550}    ${tcp_pcep}
@{tcp_ports-odl-bgpcep-pcep-api}
@{tcp_ports-odl-bgpcep-pcep-auto-bandwidth}
@{tcp_ports-odl-bgpcep-pcep-dependencies}
@{tcp_ports-odl-bgpcep-pcep-impl}
@{tcp_ports-odl-bgpcep-pcep-segment-routing}
@{tcp_ports-odl-bgpcep-pcep-stateful07}
@{tcp_ports-odl-bgpcep-pcep-topology}
@{tcp_ports-odl-bgpcep-pcep-topology-provider}             ${tcp_clustering_2550}    ${tcp_pcep}
@{tcp_ports-odl-bgpcep-pcep-tunnel-provider}               ${tcp_clustering_2550}    ${tcp_pcep}
@{tcp_ports-odl-bgpcep-programming-api}
@{tcp_ports-odl-bgpcep-programming-impl}                   ${tcp_clustering_2550}
@{tcp_ports-odl-bgpcep-rsvp}
@{tcp_ports-odl-bgpcep-rsvp-dependencies}
@{tcp_ports-odl-capwap-ac-rest}                            ${tcp_clustering_2550}    ${tcp_clustering_2552}    ${tcp_web-portal}    ${tcp_restconf}    ${tcp_authz}    ${tcp_usc_1069}
@{udp_ports-odl-capwap-ac-rest}                            ${udp_usc_1069}           ${udp_capwap}
@{tcp_ports-odl-capwap-api}
@{tcp_ports-odl-capwap-impl}                               ${tcp_clustering_2550}    ${tcp_clustering_2552}    ${tcp_usc_1069}
@{udp_ports-odl-capwap-impl}                               ${udp_usc_1069}           ${udp_capwap}    # NOTE: capwap impl consumes usc
@{tcp_ports-odl-centinel-all}                              ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}    ${tcp_authz}    ${tcp_xsql}    ${tcp_jddbc}    ${tcp_centinel_syslog}
@{tcp_ports-odl-centinel-api}
@{tcp_ports-odl-centinel-core}                             ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}    ${tcp_authz}    ${tcp_xsql}    ${tcp_jddbc}
@{tcp_ports-odl-centinel-laas}                             ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}    ${tcp_authz}    ${tcp_xsql}    ${tcp_jddbc}
@{tcp_ports-odl-centinel-streamhandler}                    ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}    ${tcp_authz}    ${tcp_xsql}    ${tcp_jddbc}    ${tcp_centinel_syslog}
@{tcp_ports-odl-centinel-ui}                               ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}    ${tcp_authz}    ${tcp_xsql}    ${tcp_jddbc}
@{tcp_ports-odl-clustering-test-app}                       ${tcp_clustering_2550}
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
@{tcp_ports-odl-dlux-all}                                  ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}    ${tcp_authz}
@{tcp_ports-odl-dlux-core}                                 ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}    ${tcp_authz}
@{tcp_ports-odl-dlux-node}                                 ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}    ${tcp_authz}
@{tcp_ports-odl-dlux-yangui}                               ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}    ${tcp_authz}
@{tcp_ports-odl-dlux-yangvisualizer}                       ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}    ${tcp_authz}
@{tcp_ports-odl-dsbenchmark}                               ${tcp_clustering_2550}
@{tcp_ports-odl-extras-all}                                ${tcp_web-portal}    ${tcp_restconf}
@{tcp_ports-odl-faas-all}                                  ${tcp_clustering_2550}    ${tcp_openflow_legacy}   ${tcp_openflow_iana}    ${tcp_ovsdb}
@{tcp_ports-odl-faas-base}
@{tcp_ports-odl-faas-fabricmgr}                            ${tcp_clustering_2550}
@{tcp_ports-odl-faas-uln-mapper}                           ${tcp_clustering_2550}
@{tcp_ports-odl-faas-vxlan-fabric}                         ${tcp_clustering_2550}
@{tcp_ports-odl-faas-vxlan-ovs-adapter}                    ${tcp_clustering_2550}    ${tcp_openflow_legacy}   ${tcp_openflow_iana}    ${tcp_ovsdb}
@{tcp_ports-odl-groupbasedpolicy-base}                     ${tcp_clustering_2550}
@{tcp_ports-odl-groupbasedpolicy-faas}                     ${tcp_clustering_2550}
@{tcp_ports-odl-groupbasedpolicy-iovisor}                  ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}    ${tcp_authz}
@{tcp_ports-odl-groupbasedpolicy-netconf}                  ${tcp_clustering_2550}
@{tcp_ports-odl-groupbasedpolicy-neutronmapper}            ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}    ${tcp_authz}    ${tcp_openflow_legacy}   ${tcp_openflow_iana}    ${tcp_ovsdb}
@{tcp_ports-odl-groupbasedpolicy-ofoverlay}                ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}    ${tcp_authz}    ${tcp_openflow_legacy}   ${tcp_openflow_iana}    ${tcp_ovsdb}
@{tcp_ports-odl-groupbasedpolicy-ovssfc}                   ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}    ${tcp_authz}    ${tcp_openflow_legacy}   ${tcp_openflow_iana}    ${tcp_ovsdb}
@{tcp_ports-odl-groupbasedpolicy-ui}                       ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}    ${tcp_authz}
@{tcp_ports-odl-groupbasedpolicy-uibackend}                ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}    ${tcp_authz}
@{tcp_ports-odl-guava}
@{tcp_ports-odl-hbaseclient}                               ${tcp_web-portal}    ${tcp_restconf}
@{tcp_ports-odl-iotdm-onem2m}                              ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}    ${tcp_authz}       ${tcp_xsql}    ${tcp_jddbc}    8282  # TODO: iotdm seems to conflict with 8282 that controller opens up
@{udp_ports-odl-iotdm-onem2m}                              ${udp_coap}
@{tcp_ports-odl-jolokia}                                   ${tcp_web-portal}    ${tcp_restconf}
@{tcp_ports-odl-l2switch-addresstracker}                   ${tcp_clustering_2550}    ${tcp_openflow_legacy}   ${tcp_openflow_iana}
@{tcp_ports-odl-l2switch-all}                              ${tcp_clustering_2550}    ${tcp_openflow_legacy}   ${tcp_openflow_iana}
@{tcp_ports-odl-l2switch-arphandler}                       ${tcp_clustering_2550}    ${tcp_openflow_legacy}   ${tcp_openflow_iana}
@{tcp_ports-odl-l2switch-hosttracker}                      ${tcp_clustering_2550}    ${tcp_openflow_legacy}   ${tcp_openflow_iana}
@{tcp_ports-odl-l2switch-loopremover}                      ${tcp_clustering_2550}    ${tcp_openflow_legacy}   ${tcp_openflow_iana}
@{tcp_ports-odl-l2switch-packethandler}                    ${tcp_clustering_2550}    ${tcp_openflow_legacy}   ${tcp_openflow_iana}
@{tcp_ports-odl-l2switch-switch}                           ${tcp_clustering_2550}    ${tcp_openflow_legacy}   ${tcp_openflow_iana}
@{tcp_ports-odl-l2switch-switch-rest}                      ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}    ${tcp_authz}    ${tcp_openflow_legacy}   ${tcp_openflow_iana}
@{tcp_ports-odl-l2switch-switch-ui}                        ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}    ${tcp_authz}       ${tcp_xsql}    ${tcp_jddbc}    ${tcp_openflow_legacy}   ${tcp_openflow_iana}
@{tcp_ports-odl-lacp-plugin}                               ${tcp_clustering_2550}    ${tcp_openflow_legacy}   ${tcp_openflow_iana}
@{tcp_ports-odl-lacp-rest}                                 ${tcp_web-portal}    ${tcp_restconf}
@{tcp_ports-odl-lacp-ui}                                   ${tcp_web-portal}    ${tcp_restconf}
@{tcp_ports-odl-lispflowmapping-inmemorydb}
@{tcp_ports-odl-lispflowmapping-mappingservice}            ${tcp_web-portal}    ${tcp_restconf}
@{tcp_ports-odl-lispflowmapping-mappingservice-shell}      ${tcp_web-portal}    ${tcp_restconf}
@{tcp_ports-odl-lispflowmapping-models}
@{tcp_ports-odl-lispflowmapping-msmr}                      ${tcp_web-portal}    ${tcp_restconf}
@{tcp_ports-odl-lispflowmapping-neutron}                   ${tcp_web-portal}    ${tcp_restconf}
@{tcp_ports-odl-lispflowmapping-southbound}                ${tcp_web-portal}    ${tcp_restconf}
@{tcp_ports-odl-lispflowmapping-ui}                        ${tcp_web-portal}    ${tcp_restconf}
@{tcp_ports-odl-lmax}
@{tcp_ports-odl-mdsal-all}
@{tcp_ports-odl-mdsal-apidocs}                             ${tcp_web-portal}    ${tcp_restconf}
@{tcp_ports-odl-mdsal-benchmark}
@{tcp_ports-odl-mdsal-binding}
@{tcp_ports-odl-mdsal-binding-api}
@{tcp_ports-odl-mdsal-binding-base}
@{tcp_ports-odl-mdsal-binding-dom-adapter}
@{tcp_ports-odl-mdsal-binding-runtime}
@{tcp_ports-odl-mdsal-broker}
@{tcp_ports-odl-mdsal-broker-local}
@{tcp_ports-odl-mdsal-clustering}
@{tcp_ports-odl-mdsal-clustering-commons}
@{tcp_ports-odl-mdsal-common}
@{tcp_ports-odl-mdsal-distributed-datastore}
@{tcp_ports-odl-mdsal-dom}
@{tcp_ports-odl-mdsal-dom-api}
@{tcp_ports-odl-mdsal-dom-broker}
@{tcp_ports-odl-mdsal-models}
@{tcp_ports-odl-mdsal-remoterpc-connector}
@{tcp_ports-odl-mdsal-xsql}
# TODO: odl-message-bus and odl-message-bus-collector is blowing up the logs (BindException, config-pusher ERROR, etc.)
@{tcp_ports-odl-message-bus}                               ${tcp_web-portal}    ${tcp_restconf}    ${tcp_netconf_nb}    ${tcp_netconf_test_server}
@{tcp_ports-odl-message-bus-collector}
@{tcp_ports-odl-messaging4transport}
@{tcp_ports-odl-messaging4transport-api}
@{tcp_ports-odl-nemo-api}
@{tcp_ports-odl-nemo-cli-renderer}                         ${tcp_web-portal}    ${tcp_restconf}
@{tcp_ports-odl-nemo-engine}
@{tcp_ports-odl-nemo-engine-rest}                          ${tcp_web-portal}    ${tcp_restconf}
@{tcp_ports-odl-nemo-engine-ui}                            ${tcp_web-portal}    ${tcp_restconf}
@{tcp_ports-odl-nemo-openflow-renderer}                    ${tcp_web-portal}    ${tcp_restconf}
@{tcp_ports-odl-netconf-all}
@{tcp_ports-odl-netconf-api}
@{tcp_ports-odl-netconf-client}
# TODO: odl-netconf-clustered-topology, odl-netconf-connector, odl-netconf-connector-all, odl-netconf-mdsal is blowing up the logs (BindException, config-pusher ERROR, etc.)
@{tcp_ports-odl-netconf-clustered-topology}                ${tcp_web-portal}    ${tcp_restconf}    ${tcp_netconf_nb}    ${tcp_netconf_test_server}
@{tcp_ports-odl-netconf-connector}
@{tcp_ports-odl-netconf-connector-all}
@{tcp_ports-odl-netconf-connector-ssh}                     ${tcp_web-portal}    ${tcp_restconf}    ${tcp_netconf_nb}    ${tcp_netconf_test_server}
@{tcp_ports-odl-netconf-impl}
@{tcp_ports-odl-netconf-mapping-api}
@{tcp_ports-odl-netconf-mdsal}                             ${tcp_web-portal}    ${tcp_restconf}    ${tcp_netconf_nb}    ${tcp_netconf_test_server}
@{tcp_ports-odl-netconf-monitoring}
@{tcp_ports-odl-netconf-netty-util}
@{tcp_ports-odl-netconf-notifications-api}
@{tcp_ports-odl-netconf-notifications-impl}
@{tcp_ports-odl-netconf-ssh}                               ${tcp_web-portal}    ${tcp_restconf}    ${tcp_netconf_nb}    ${tcp_netconf_test_server}
@{tcp_ports-odl-netconf-tcp}                               ${tcp_netconf_test_server}
@{tcp_ports-odl-netconf-topology}                          ${tcp_web-portal}    ${tcp_restconf}    ${tcp_netconf_nb}    ${tcp_netconf_test_server}
@{tcp_ports-odl-netconf-util}
@{tcp_ports-odl-netide-api}
@{tcp_ports-odl-netide-impl}
@{tcp_ports-odl-netide-rest}                               ${tcp_web-portal}    ${tcp_restconf}
@{tcp_ports-odl-netty}
@{tcp_ports-odl-netvirt-api}
@{tcp_ports-odl-netvirt-hwgw}
@{tcp_ports-odl-netvirt-rest}                              ${tcp_web-portal}    ${tcp_restconf}
@{tcp_ports-odl-netvirt-ui}                                ${tcp_web-portal}    ${tcp_restconf}
@{tcp_ports-odl-neutron-northbound-api}                    ${tcp_web-portal}    ${tcp_restconf}
@{tcp_ports-odl-neutron-service}                           ${tcp_web-portal}    ${tcp_restconf}
@{tcp_ports-odl-neutron-spi}
@{tcp_ports-odl-neutron-transcriber}                       ${tcp_web-portal}    ${tcp_restconf}
@{tcp_ports-odl-nic-console}                               ${tcp_web-portal}    ${tcp_restconf}
@{tcp_ports-odl-nic-core-hazelcast}
@{tcp_ports-odl-nic-core-mdsal}                            ${tcp_web-portal}    ${tcp_restconf}
@{tcp_ports-odl-nic-graph}                                 ${tcp_web-portal}    ${tcp_restconf}
@{tcp_ports-odl-nic-intent-statemachine}                   ${tcp_web-portal}    ${tcp_restconf}
@{tcp_ports-odl-nic-listeners}                             ${tcp_web-portal}    ${tcp_restconf}
@{tcp_ports-odl-nic-neutron-integration}                   ${tcp_web-portal}    ${tcp_restconf}
@{tcp_ports-odl-nic-pipeline-manager}
@{tcp_ports-odl-nic-renderer-gbp}                          ${tcp_web-portal}    ${tcp_restconf}
@{tcp_ports-odl-nic-renderer-nemo}
@{tcp_ports-odl-nic-renderer-of}                           ${tcp_web-portal}    ${tcp_restconf}
@{tcp_ports-odl-nic-renderer-vtn}                          ${tcp_web-portal}    ${tcp_restconf}
@{tcp_ports-odl-ntfbenchmark}
# TODO: all odl-of-config-* are blowing up the logs (BindException, config-pusher ERROR, etc.)
@{tcp_ports-odl-of-config-all}
@{tcp_ports-odl-of-config-rest}
@{tcp_ports-odl-of-config-southbound-all}
@{tcp_ports-odl-of-config-southbound-api}
@{tcp_ports-odl-of-config-southbound-ofconfigmodels}
@{tcp_ports-odl-of-config-southbound-rest}
@{tcp_ports-odl-onem2m-api}
@{tcp_ports-odl-onem2m-coap}                               ${tcp_web-portal}    ${tcp_restconf}
# TODO: all odl-onem2m-core are blowing up the logs (BindException, config-pusher ERROR, etc.)
@{tcp_ports-odl-onem2m-core}                               ${tcp_web-portal}    ${tcp_restconf}
@{tcp_ports-odl-onem2m-core-rest}                          ${tcp_web-portal}    ${tcp_restconf}
@{tcp_ports-odl-onem2m-http}                               ${tcp_web-portal}    ${tcp_restconf}
@{tcp_ports-odl-onem2m-mqtt}                               ${tcp_web-portal}    ${tcp_restconf}
@{tcp_ports-odl-onem2m-notifier}                           ${tcp_web-portal}    ${tcp_restconf}
@{tcp_ports-odl-onem2m-ui}                                 ${tcp_web-portal}    ${tcp_restconf}
@{tcp_ports-odl-openflowjava-all}
@{tcp_ports-odl-openflowjava-protocol}
@{tcp_ports-odl-openflowplugin-all}                        ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}    ${tcp_xsql}    ${tcp_jddbc}    ${tcp_authz}    ${tcp_openflow_legacy}   ${tcp_openflow_iana}
@{tcp_ports-odl-openflowplugin-all-li}                     ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}    ${tcp_xsql}    ${tcp_jddbc}    ${tcp_authz}    ${tcp_openflow_legacy}   ${tcp_openflow_iana}
@{tcp_ports-odl-openflowplugin-app-bulk-o-matic}           ${tcp_clustering_2550}                                                                                           ${tcp_openflow_legacy}   ${tcp_openflow_iana}
@{tcp_ports-odl-openflowplugin-app-bulk-o-matic-li}        ${tcp_clustering_2550}                                                                                           ${tcp_openflow_legacy}   ${tcp_openflow_iana}
@{tcp_ports-odl-openflowplugin-app-config-pusher}          ${tcp_clustering_2550}                                                                                           ${tcp_openflow_legacy}   ${tcp_openflow_iana}
@{tcp_ports-odl-openflowplugin-app-config-pusher-li}       ${tcp_clustering_2550}                                                                                           ${tcp_openflow_legacy}   ${tcp_openflow_iana}
@{tcp_ports-odl-openflowplugin-app-lldp-speaker}           ${tcp_clustering_2550}                                                                                           ${tcp_openflow_legacy}   ${tcp_openflow_iana}
@{tcp_ports-odl-openflowplugin-app-lldp-speaker-li}        ${tcp_clustering_2550}                                                                                           ${tcp_openflow_legacy}   ${tcp_openflow_iana}
@{tcp_ports-odl-openflowplugin-app-table-miss-enforcer}    ${tcp_clustering_2550}                                                                                           ${tcp_openflow_legacy}   ${tcp_openflow_iana}
@{tcp_ports-odl-openflowplugin-app-table-miss-enforcer-li}    ${tcp_clustering_2550}                                                                                        ${tcp_openflow_legacy}   ${tcp_openflow_iana}
@{tcp_ports-odl-openflowplugin-drop-test}                  ${tcp_clustering_2550}                                                                                           ${tcp_openflow_legacy}   ${tcp_openflow_iana}
@{tcp_ports-odl-openflowplugin-drop-test-li}               ${tcp_clustering_2550}                                                                                           ${tcp_openflow_legacy}   ${tcp_openflow_iana}
@{tcp_ports-odl-openflowplugin-flow-services}              ${tcp_clustering_2550}                                                                                           ${tcp_openflow_legacy}   ${tcp_openflow_iana}
@{tcp_ports-odl-openflowplugin-flow-services-li}           ${tcp_clustering_2550}                                                                                           ${tcp_openflow_legacy}   ${tcp_openflow_iana}
@{tcp_ports-odl-openflowplugin-flow-services-rest}         ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}                                   ${tcp_authz}    ${tcp_openflow_legacy}   ${tcp_openflow_iana}
@{tcp_ports-odl-openflowplugin-flow-services-rest-li}      ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}                                   ${tcp_authz}    ${tcp_openflow_legacy}   ${tcp_openflow_iana}
@{tcp_ports-odl-openflowplugin-flow-services-ui}           ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}    ${tcp_xsql}    ${tcp_jddbc}    ${tcp_authz}    ${tcp_openflow_legacy}   ${tcp_openflow_iana}
@{tcp_ports-odl-openflowplugin-flow-services-ui-li}        ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}    ${tcp_xsql}    ${tcp_jddbc}    ${tcp_authz}    ${tcp_openflow_legacy}   ${tcp_openflow_iana}
@{tcp_ports-odl-openflowplugin-nsf-model}
@{tcp_ports-odl-openflowplugin-nsf-model-li}
@{tcp_ports-odl-openflowplugin-nsf-services}               ${tcp_clustering_2550}
@{tcp_ports-odl-openflowplugin-nsf-services-li}            ${tcp_clustering_2550}
@{tcp_ports-odl-openflowplugin-nxm-extensions}             ${tcp_clustering_2550}                                                                                           ${tcp_openflow_legacy}   ${tcp_openflow_iana}
@{tcp_ports-odl-openflowplugin-nxm-extensions-li}          ${tcp_clustering_2550}                                                                                           ${tcp_openflow_legacy}   ${tcp_openflow_iana}
@{tcp_ports-odl-openflowplugin-southbound}                 ${tcp_clustering_2550}                                                                                           ${tcp_openflow_legacy}   ${tcp_openflow_iana}
@{tcp_ports-odl-openflowplugin-southbound-li}              ${tcp_clustering_2550}                                                                                           ${tcp_openflow_legacy}   ${tcp_openflow_iana}
@{tcp_ports-odl-ovsdb-hwvtepsouthbound}                    ${tcp_clustering_2550}                                                                                                                                            ${tcp_ovsdb}
@{tcp_ports-odl-ovsdb-hwvtepsouthbound-api}
@{tcp_ports-odl-ovsdb-hwvtepsouthbound-rest}               ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}                                   ${tcp_authz}                                                                                              ${tcp_ovsdb}
@{tcp_ports-odl-ovsdb-hwvtepsouthbound-test}               ${tcp_clustering_2550}                                                                                                                                            ${tcp_ovsdb}
@{tcp_ports-odl-ovsdb-hwvtepsouthbound-ui}                 ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}    ${tcp_xsql}    ${tcp_jddbc}    ${tcp_authz}                                                     ${tcp_ovsdb}
@{tcp_ports-odl-ovsdb-library}                             ${tcp_clustering_2550}
@{tcp_ports-odl-ovsdb-openstack}                           ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}    ${tcp_xsql}    ${tcp_jddbc}    ${tcp_authz}    ${tcp_openflow_legacy}   ${tcp_openflow_iana}    ${tcp_ovsdb}
@{tcp_ports-odl-ovsdb-openstack-clusteraware}              ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}                                                   ${tcp_openflow_legacy}   ${tcp_openflow_iana}    ${tcp_ovsdb}
@{tcp_ports-odl-ovsdb-openstack-it}
@{tcp_ports-odl-ovsdb-schema-hardwarevtep}
@{tcp_ports-odl-ovsdb-schema-openvswitch}
@{tcp_ports-odl-ovsdb-sfc}                                 ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}    ${tcp_xsql}    ${tcp_jddbc}    ${tcp_authz}    ${tcp_openflow_legacy}   ${tcp_openflow_iana}    ${tcp_ovsdb}
@{tcp_ports-odl-ovsdb-sfc-api}
@{tcp_ports-odl-ovsdb-sfc-rest}                            ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}    ${tcp_xsql}    ${tcp_jddbc}    ${tcp_authz}    ${tcp_openflow_legacy}   ${tcp_openflow_iana}    ${tcp_ovsdb}
@{tcp_ports-odl-ovsdb-sfc-ui}                              ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}    ${tcp_xsql}    ${tcp_jddbc}    ${tcp_authz}    ${tcp_openflow_legacy}   ${tcp_openflow_iana}    ${tcp_ovsdb}
@{tcp_ports-odl-ovsdb-southbound-api}
@{tcp_ports-odl-ovsdb-southbound-impl}                     ${tcp_clustering_2550}                                                                                                                                            ${tcp_ovsdb}
@{tcp_ports-odl-ovsdb-southbound-impl-rest}                ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}                                   ${tcp_authz}                                                     ${tcp_ovsdb}
@{tcp_ports-odl-ovsdb-southbound-impl-ui}                  ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}    ${tcp_xsql}    ${tcp_jddbc}    ${tcp_authz}                                                     ${tcp_ovsdb}
@{tcp_ports-odl-ovsdb-southbound-test}                     ${tcp_clustering_2550}                                                                                                                                            ${tcp_ovsdb}
@{tcp_ports-odl-ovsdb-ui}                                  ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}                                   ${tcp_authz}
@{tcp_ports-odl-packetcable-policy-model}
@{tcp_ports-odl-packetcable-policy-server}                 ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}                                   ${tcp_authz}
@{tcp_ports-odl-packetcable-policy-server-all}             ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}                                   ${tcp_authz}
@{tcp_ports-odl-protocol-framework}
@{tcp_ports-odl-restconf}                                  ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}                                   ${tcp_authz}
@{tcp_ports-odl-restconf-all}                              ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}                                   ${tcp_authz}
@{tcp_ports-odl-restconf-noauth}                           ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}                                   ${tcp_authz}
@{tcp_ports-odl-sdni-aggregator}                           ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}    ${tcp_xsql}    ${tcp_jddbc}    ${tcp_authz}    ${tcp_openflow_legacy}   ${tcp_openflow_iana}
@{tcp_ports-odl-sdni-api}                                  ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}    ${tcp_xsql}    ${tcp_jddbc}    ${tcp_authz}    ${tcp_openflow_legacy}   ${tcp_openflow_iana}
@{tcp_ports-odl-sdni-wrapper}                              ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}    ${tcp_xsql}    ${tcp_jddbc}    ${tcp_authz}    ${tcp_openflow_legacy}   ${tcp_openflow_iana}
@{tcp_ports-odl-sdninterfaceapp-all}                       ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}    ${tcp_xsql}    ${tcp_jddbc}    ${tcp_authz}    ${tcp_openflow_legacy}   ${tcp_openflow_iana}
@{tcp_ports-odl-sfc-bootstrap}                             ${tcp_clustering_2550}
@{tcp_ports-odl-sfc-model}
@{tcp_ports-odl-sfc-netconf}                               ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}                                   ${tcp_authz}
@{tcp_ports-odl-sfc-ovs}                                   ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}                                   ${tcp_authz}                                                     ${tcp_ovsdb}
@{tcp_ports-odl-sfc-provider}                              ${tcp_clustering_2550}
@{tcp_ports-odl-sfc-provider-rest}                         ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}                                   ${tcp_authz}
@{tcp_ports-odl-sfc-sb-rest}                               ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}                                   ${tcp_authz}    ${tcp_openflow_legacy}   ${tcp_openflow_iana}    ${tcp_ovsdb}                                                              ${tcp_sfc}
@{tcp_ports-odl-sfc-scf-openflow}                          ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}                                   ${tcp_authz}    ${tcp_openflow_legacy}   ${tcp_openflow_iana}    ${tcp_ovsdb}
@{tcp_ports-odl-sfc-test-consumer}                         ${tcp_clustering_2550}
@{tcp_ports-odl-sfc-ui}                                    ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}                                   ${tcp_authz}
@{tcp_ports-odl-sfc-vnfm-tacker}                           ${tcp_clustering_2550}
@{tcp_ports-odl-sfclisp}                                   ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}                                   ${tcp_authz}
@{udp_ports-odl-sfclisp}                                   ${udp_lisp}
@{tcp_ports-odl-sfcofl2}                                   ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}                                   ${tcp_authz}    ${tcp_openflow_legacy}   ${tcp_openflow_iana}    ${tcp_ovsdb}
@{tcp_ports-odl-snbi-all}                                  ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}                                   ${tcp_authz}
@{tcp_ports-odl-snbi-dlux}                                 ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}                                   ${tcp_authz}
@{tcp_ports-odl-snbi-shellplugin}                          ${tcp_clustering_2550}
@{tcp_ports-odl-snbi-southplugin}                          ${tcp_clustering_2550}
# TODO: random udp port comes up with snmp*
@{tcp_ports-odl-snmp-plugin}                               ${tcp_clustering_2550}
@{tcp_ports-odl-snmp4sdn-all}                              ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}                                   ${tcp_authz}
@{tcp_ports-odl-snmp4sdn-snmp4sdn}                         ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}                                   ${tcp_authz}
@{tcp_ports-odl-sxp-all}                                   ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}                                   ${tcp_authz}    ${tcp_sxp}
@{tcp_ports-odl-sxp-api}
@{tcp_ports-odl-sxp-controller}                            ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}                                   ${tcp_authz}    ${tcp_sxp}
@{tcp_ports-odl-sxp-core}
@{tcp_ports-odl-tcpmd5-all}
@{tcp_ports-odl-tcpmd5-base}
@{tcp_ports-odl-tcpmd5-netty}
@{tcp_ports-odl-tcpmd5-nio}
@{tcp_ports-odl-toaster}                                   ${tcp_clustering_2550}
@{tcp_ports-odl-topoprocessing-framework}                  ${tcp_clustering_2550}
@{tcp_ports-odl-topoprocessing-i2rs}                       ${tcp_clustering_2550}
@{tcp_ports-odl-topoprocessing-inventory}                  ${tcp_clustering_2550}
@{tcp_ports-odl-topoprocessing-inventory-rendering}        ${tcp_clustering_2550}
@{tcp_ports-odl-topoprocessing-mlmt}                       ${tcp_clustering_2550}
@{tcp_ports-odl-topoprocessing-network-topology}           ${tcp_clustering_2550}
@{tcp_ports-odl-tsdr-cassandra}                            ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}                                   ${tcp_authz}
@{tcp_ports-odl-tsdr-controller-metrics-collector}         ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}                                   ${tcp_authz}
@{tcp_ports-odl-tsdr-core}                                 ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}                                   ${tcp_authz}
@{tcp_ports-odl-tsdr-hbase}                                ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}                                   ${tcp_authz}
@{tcp_ports-odl-tsdr-hsqldb}                               ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}                                   ${tcp_authz}
@{tcp_ports-odl-tsdr-hsqldb-all}                           ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}                                   ${tcp_authz}    ${tcp_openflow_legacy}   ${tcp_openflow_iana}
@{tcp_ports-odl-tsdr-netflow-statistics-collector}         ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}                                   ${tcp_authz}    ${tcp_openflow_legacy}   ${tcp_openflow_iana}
@{udp_ports-odl-tsdr-netflow-statistics-collector}         ${udp_netflow}
@{tcp_ports-odl-tsdr-openflow-statistics-collector}        ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}                                   ${tcp_authz}    ${tcp_openflow_legacy}   ${tcp_openflow_iana}
# TODO: snmp data collector also bringing a random udp port
@{tcp_ports-odl-tsdr-snmp-data-collector}                  ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}                                   ${tcp_authz}
@{tcp_ports-odl-tsdr-syslog-collector}                     ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}                                   ${tcp_authz}
@{udp_ports-odl-tsdr-syslog-collector}                     ${udp_syslog}
@{tcp_ports-odl-ttp-all}                                   ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}                                   ${tcp_authz}
@{tcp_ports-odl-ttp-model}
@{tcp_ports-odl-ttp-model-rest}                            ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}                                   ${tcp_authz}
@{tcp_ports-odl-unimgr}                                    ${tcp_clustering_2550}                                                                                                                                            ${tcp_ovsdb}
@{tcp_ports-odl-unimgr-api}
@{tcp_ports-odl-unimgr-console}                            ${tcp_clustering_2550}                                                                                                                                            ${tcp_ovsdb}
@{tcp_ports-odl-unimgr-rest}                               ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}                                   ${tcp_authz}                                                     ${tcp_ovsdb}
@{tcp_ports-odl-unimgr-ui}                                 ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}    ${tcp_xsql}    ${tcp_jddbc}    ${tcp_authz}                                                     ${tcp_ovsdb}
@{tcp_ports-odl-usc-agent}
@{tcp_ports-odl-usc-api}
@{tcp_ports-odl-usc-channel}                               ${tcp_clustering_2550}    ${tcp_clustering_2552}                                                                                            ${tcp_usc_1069}
@{udp_ports-odl-usc-channel}                               ${udp_usc_1069}
@{tcp_ports-odl-usc-channel-rest}                          ${tcp_clustering_2550}    ${tcp_clustering_2552}    ${tcp_web-portal}    ${tcp_restconf}    ${tcp_xsql}    ${tcp_jddbc}    ${tcp_authz}     ${tcp_usc_1069}
@{udp_ports-odl-usc-channel-rest}                          ${udp_usc_1069}
@{tcp_ports-odl-usc-channel-ui}                            ${tcp_clustering_2550}    ${tcp_clustering_2552}    ${tcp_web-portal}    ${tcp_restconf}    ${tcp_xsql}    ${tcp_jddbc}    ${tcp_authz}     ${tcp_usc_1069}
@{udp_ports-odl-usc-channel-ui}                            ${udp_usc_1069}
@{tcp_ports-odl-usecplugin}                                ${tcp_clustering_2550}
@{tcp_ports-odl-usecplugin-api}
@{tcp_ports-odl-usecplugin-rest}                           ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}
@{tcp_ports-odl-usecplugin-ui}                             ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}
@{tcp_ports-odl-vpnservice-api}                            ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}                                   ${tcp_authz}    ${tcp_openflow_legacy}    ${tcp_openflow_iana}    ${tcp_ovsdb}
@{tcp_ports-odl-vpnservice-core}                           ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}    ${tcp_xsql}    ${tcp_jddbc}    ${tcp_authz}    ${tcp_openflow_legacy}    ${tcp_openflow_iana}    ${tcp_ovsdb}    ${tcp_vpnservice}
@{tcp_ports-odl-vpnservice-impl}                           ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}                                   ${tcp_authz}    ${tcp_openflow_legacy}    ${tcp_openflow_iana}    ${tcp_ovsdb}    ${tcp_vpnservice}
@{tcp_ports-odl-vpnservice-impl-rest}                      ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}                                   ${tcp_authz}    ${tcp_openflow_legacy}    ${tcp_openflow_iana}    ${tcp_ovsdb}    ${tcp_vpnservice}
@{tcp_ports-odl-vpnservice-impl-ui}                        ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}    ${tcp_xsql}    ${tcp_jddbc}    ${tcp_authz}    ${tcp_openflow_legacy}    ${tcp_openflow_iana}    ${tcp_ovsdb}    ${tcp_vpnservice}
@{tcp_ports-odl-vpnservice-intent}                         ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}                                   ${tcp_authz}    ${tcp_openflow_legacy}    ${tcp_openflow_iana}
@{tcp_ports-odl-vpnservice-openstack}                      ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}                                                   ${tcp_openflow_legacy}    ${tcp_openflow_iana}    ${tcp_ovsdb}    ${tcp_vpnservice}    ${tcp_authz}
@{tcp_ports-odl-vtn-manager}                               ${tcp_clustering_2550}                                                                                           ${tcp_openflow_legacy}    ${tcp_openflow_iana}
@{tcp_ports-odl-vtn-manager-neutron}                       ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}                                                   ${tcp_openflow_legacy}    ${tcp_openflow_iana}    ${tcp_ovsdb}
@{tcp_ports-odl-vtn-manager-rest}                          ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}                                   ${tcp_authz}    ${tcp_openflow_legacy}    ${tcp_openflow_iana}
# TODO: yangpush took too long to give prompt back.  looks like it might be making really large log messages too.
@{tcp_ports-odl-yangpush}                                  ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}                                                                                                                     ${tcp_netconf_nb}
@{tcp_ports-odl-yangpush-api}
# TODO: yangpush-rest, yangpush-ui took too long to give prompt back.  looks like it might be making really large log messages too.
@{tcp_ports-odl-yangpush-rest}                             ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}                                   ${tcp_authz}                                                                      ${tcp_netconf_nb}    ${tcp_netconf_test_server}
@{tcp_ports-odl-yangpush-ui}                               ${tcp_clustering_2550}    ${tcp_web-portal}    ${tcp_restconf}    ${tcp_xsql}    ${tcp_jddbc}                                                                                                           ${tcp_netconf_test_server}
@{tcp_ports-odl-yangtools-common}
@{tcp_ports-odl-yangtools-yang-data}
@{tcp_ports-odl-yangtools-yang-parser}
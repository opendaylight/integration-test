*** Varables ***
# Variable reflecting the port, followed by primary feature which binds the port,
# followed by other features that pull in the primary feature.
# TCP ports
${tcp_6633}       odl-openflowplugin-southbound    odl-openflowplugin-flow-services    odl-openflowplugin-flow-services-rest
${tcp_6653}       odl-openflowplugin-southbound    odl-openflowplugin-flow-services    odl-openflowplugin-flow-services-rest
${tcp_8181}       odl-restconf-noauth    odl-restconf    odl-openflowplugin-flow-services-rest
# UDP ports
<rpc xmlns="urn:ietf:params:xml:ns:netconf:base:1.0" message-id="m-5">
<edit-config>
<target>
<candidate/>
</target>
<default-operation>none</default-operation>
<config>
<vpp xmlns="urn:opendaylight:params:xml:ns:yang:v3po">
<bridge-domains>
<bridge-domain xmlns:a="urn:ietf:params:xml:ns:netconf:base:1.0" a:operation="replace">
<name>testBD2</name>
<forward>false</forward>
<learn>false</learn>
<unknown-unicast-flood>false</unknown-unicast-flood>
<arp-termination>false</arp-termination>
<flood>true</flood>
</bridge-domain>
</bridge-domains>
</vpp>
</config>
</edit-config>
</rpc>

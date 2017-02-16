<rpc xmlns="urn:ietf:params:xml:ns:netconf:base:1.0" message-id="m-3">
<get-config>
<source>
<running/>
</source>
<filter xmlns:ns0="urn:ietf:params:xml:ns:netconf:base:1.0" ns0:type="subtree">
<vpp xmlns="urn:opendaylight:params:xml:ns:yang:v3po">
<bridge-domains>
<bridge-domain>
<name>testBD2</name>
</bridge-domain>
</bridge-domains>
</vpp>
</filter>
</get-config>
</rpc>

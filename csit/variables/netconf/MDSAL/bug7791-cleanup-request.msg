<rpc message-id="m-7" xmlns="urn:ietf:params:xml:ns:netconf:base:1.0">
<edit-config>
    <target>
        <candidate/>
    </target>
    <test-option>
        set
    </test-option>
    <default-operation>none</default-operation>
    <config xmlns:a="urn:ietf:params:xml:ns:netconf:base:1.0">
    <vpp xmlns="urn:opendaylight:params:xml:ns:yang:v3po" a:operation="remove"/>
    </config>
</edit-config>
</rpc>

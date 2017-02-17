<rpc message-id="m-3" a="64" xmlns="urn:ietf:params:xml:ns:netconf:base:1.0">
    <edit-config>
        <target>
            <candidate/>
        </target>
        <default-operation>none</default-operation>
        <config>
            <cars xmlns="urn:opendaylight:params:xml:ns:yang:controller:config:sal-clustering-it:car">
                <car-entry>
                    <id>bug7791</id>
                    <model xmlns:a="urn:ietf:params:xml:ns:netconf:base:1.0" a:operation="replace">2</model>
                </car-entry>
            </cars>
        </config>
    </edit-config>
</rpc>

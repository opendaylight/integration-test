UNIFICATION_NT = '''<topology xmlns="urn:opendaylight:topology:correlation" xmlns:n="urn:TBD:params:xml:ns:yang:network-topology">
                        <n:topology-id>topo:1</n:topology-id>
                        <correlations>
                            <output-model>{output-model}</output-model>
                            <correlation>
                                <correlation-id>1</correlation-id>
                                <type>{type}</type>
                                <correlation-item>{correlation-item}</correlation-item>
                                <aggregation>
                                    <aggregation-type>{aggregation-type}</aggregation-type>
                                    <mapping>
                                        <input-model>{input-model}</input-model>
                                        <underlay-topology>{underlay-topology-id}</underlay-topology>
                                        <!-- target field -->
                                        <aggregate-inside>false</aggregate-inside>
                                    </mapping>
                                    <mapping>
                                        <input-model>{input-model}</input-model>
                                        <underlay-topology>{underlay-topology-id}</underlay-topology>
                                        <!-- target field -->
                                        <aggregate-inside>false</aggregate-inside>
                                    </mapping>
                                </aggregation>
                            </correlation>
                        </correlations>
                    </topology>'''

UNIFICATION_NT_AGGREGATE_INSIDE = '''<topology xmlns="urn:opendaylight:topology:correlation" xmlns:n="urn:TBD:params:xml:ns:yang:network-topology">
                        <n:topology-id>topo:1</n:topology-id>
                        <correlations>
                            <output-model>{output-model}</output-model>
                            <correlation>
                                <correlation-id>1</correlation-id>
                                <type>{type}</type>
                                <correlation-item>{correlation-item}</correlation-item>
                                <aggregation>
                                    <aggregation-type>{aggregation-type}</aggregation-type>
                                    <mapping>
                                        <input-model>{input-model}</input-model>
                                        <underlay-topology>{underlay-topology-id}</underlay-topology>
                                        <!-- target field -->
                                        <aggregate-inside>true</aggregate-inside>
                                    </mapping>
                                </aggregation>
                            </correlation>
                        </correlations>
                    </topology>'''

UNIFICATION_FILTRATION_NT_AGGREGATE_INSIDE = '''<topology xmlns="urn:opendaylight:topology:correlation" xmlns:n="urn:TBD:params:xml:ns:yang:network-topology">
                        <n:topology-id>topo:1</n:topology-id>
                        <correlations>
                            <output-model>{output-model}</output-model>
                            <correlation>
                                <correlation-id>1</correlation-id>
                                <type>{type}</type>
                                <correlation-item>{correlation-item}</correlation-item>
                                <aggregation>
                                    <aggregation-type>{aggregation-type}</aggregation-type>
                                    <mapping>
                                        <input-model>{input-model}</input-model>
                                        <underlay-topology>{underlay-topology-id}</underlay-topology>
                                        <aggregate-inside>true</aggregate-inside>
                                        <!-- target field -->
                                        <!-- apply filters -->
                                    </mapping>
                                </aggregation>
                                <filtration>
                                    <underlay-topology>{underlay-topology-id}</underlay-topology>
                                    <!-- Filter -->
                                </filtration>
                            </correlation>
                        </correlations>
                    </topology>'''

UNIFICATION_FILTRATION_NT = '''<topology xmlns="urn:opendaylight:topology:correlation" xmlns:n="urn:TBD:params:xml:ns:yang:network-topology">
                        <n:topology-id>topo:1</n:topology-id>
                        <correlations>
                            <output-model>{output-model}</output-model>
                            <correlation>
                                <correlation-id>1</correlation-id>
                                <type>{type}</type>
                                <correlation-item>{correlation-item}</correlation-item>
                                <aggregation>
                                    <aggregation-type>{aggregation-type}</aggregation-type>
                                    <mapping>
                                        <input-model>{input-model}</input-model>
                                        <underlay-topology>{underlay-topology-id}</underlay-topology>
                                        <aggregate-inside>false</aggregate-inside>
                                        <!-- target field -->
                                        <!-- apply filters -->
                                    </mapping>
                                    <mapping>
                                        <input-model>{input-model}</input-model>
                                        <underlay-topology>{underlay-topology-id}</underlay-topology>
                                        <aggregate-inside>false</aggregate-inside>
                                        <!-- target field -->
                                        <!-- apply filters -->
                                    </mapping>
                                </aggregation>
                                <filtration>
                                    <underlay-topology>{underlay-topology-id}</underlay-topology>
                                    <!-- Filter -->
                                </filtration>
                            </correlation>
                        </correlations>
                    </topology>'''

FILTRATION_NT = '''<topology xmlns="urn:opendaylight:topology:correlation" xmlns:n="urn:TBD:params:xml:ns:yang:network-topology">
                    <n:topology-id>topo:1</n:topology-id>
                    <correlations>
                        <output-model>{output-model}</output-model>
                        <correlation>
                            <correlation-id>1</correlation-id>
                            <type>filtration-only</type>
                            <correlation-item>{correlation-item}</correlation-item>
                            <filtration>
                                <underlay-topology>{underlay-topology-id}</underlay-topology>
                                <!-- Filter -->
                            </filtration>
                        </correlation>
                    </correlations>
                </topology>'''

APPLY_FILTERS = '''
<apply-filters>{filter-id}</apply-filters>
'''

TARGET_FIELD = '''
<target-field>
    <target-field-path>{target-field-path}</target-field-path>
    <matching-key>{matching-key}</matching-key>
</target-field>
'''

SCRIPTING = '''
<scripting>
    <language>{language}</language>
    <script>
        {script}
    </script>
</scripting>
'''
FILTER_SCRIPT = '''<filter>
                        <input-model>{input-model}</input-model>
                        <filter-id>1</filter-id>
                        <target-field>{target-field}</target-field>
                        <filter-type>script</filter-type>
                        <script-filter>
                            <scripting>
                                <language>{language}</language>
                                <script>
                                  {script}
                                </script>
                            </scripting>
                        </script-filter>
                 </filter>'''


FILTER_IPV4 = '''<filter>
                        <input-model>{input-model}</input-model>
                        <filter-id>1</filter-id>
                        <target-field>{target-field}</target-field>
                        <filter-type>ipv4-address</filter-type>
                        <ipv4-address-filter>
                             <ipv4-address>{ipv4}</ipv4-address>
                        </ipv4-address-filter>
                 </filter>'''

FILTER_IPV6 = '''<filter>
                        <input-model>{input-model}</input-model>
                        <filter-id>1</filter-id>
                        <target-field>{target-field}</target-field>
                        <filter-type>ipv6-address</filter-type>
                        <ipv6-address-filter>
                             <ipv6-address>{ipv6}</ipv6-address>
                        </ipv6-address-filter>
                 </filter>'''

FILTER_RANGE_NUMBER = '''<filter>
                        <input-model>{input-model}</input-model>
                        <filter-id>1</filter-id>
                        <target-field>{target-field}</target-field>
                        <filter-type>range-number</filter-type>
                        <range-number-filter>
                             <min-number-value>{min}</min-number-value>
                             <max-number-value>{max}</max-number-value>
                        </range-number-filter>
                 </filter>'''

FILTER_RANGE_STRING = '''<filter>
                        <input-model>{input-model}</input-model>
                        <filter-id>1</filter-id>
                        <target-field>{target-field}</target-field>
                        <filter-type>range-string</filter-type>
                        <range-string-filter>
                             <min-string-value>{min}</min-string-value>
                             <max-string-value>{max}</max-string-value>
                        </range-string-filter>
                 </filter>'''

FILTER_SPECIFIC_NUMBER = '''<filter>
                        <input-model>{input-model}</input-model>
                        <filter-id>1</filter-id>
                        <target-field>{target-field}</target-field>
                        <filter-type>specific-number</filter-type>
                        <specific-number-filter>
                             <specific-number>{number}</specific-number>
                        </specific-number-filter>
                 </filter>'''

FILTER_SPECIFIC_STRING = '''<filter>
                        <input-model>{input-model}</input-model>
                        <filter-id>1</filter-id>
                        <target-field>{target-field}</target-field>
                        <filter-type>specific-string</filter-type>
                        <specific-string-filter>
                             <specific-string>{string}</specific-string>
                        </specific-string-filter>
                 </filter>'''

LINK_COMPUTATION_INSIDE = '''<link-computation xmlns="urn:opendaylight:topology:link:computation" xmlns:n="urn:opendaylight:topology:correlation">
            <output-model>{output-model}</output-model>
            <node-info>
                <node-topology>topo:1</node-topology>
                <input-model>{input-model}</input-model>
            </node-info>
            <link-info>
                <link-topology>{underlay-topology-id}</link-topology>
                <input-model>{input-model}</input-model>
            </link-info>
        </link-computation>'''

LINK_COMPUTATION = '''<link-computation xmlns="urn:opendaylight:topology:link:computation" xmlns:n="urn:opendaylight:topology:correlation">
            <output-model>{output-model}</output-model>
            <node-info>
                <node-topology>topo:1</node-topology>
                <input-model>{input-model}</input-model>
            </node-info>
            <link-info>
                <link-topology>{underlay-topology-1-id}</link-topology>
                <input-model>{input-model}</input-model>
            </link-info>
            <link-info>
                <link-topology>{underlay-topology-2-id}</link-topology>
                <input-model>{input-model}</input-model>
            </link-info>
        </link-computation>'''

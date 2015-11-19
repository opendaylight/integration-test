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
                                        <underlay-topology>und-topo:1</underlay-topology>
                                        <target-field>{target-field}</target-field>
                                        <aggregate-inside>false</aggregate-inside>
                                    </mapping>
                                    <mapping>
                                        <input-model>{input-model}</input-model>
                                        <underlay-topology>und-topo:2</underlay-topology>
                                        <target-field>{target-field}</target-field>
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
                                        <underlay-topology>und-topo:1</underlay-topology>
                                        <target-field>{target-field}</target-field>
                                        <aggregate-inside>true</aggregate-inside>
                                    </mapping>
                                </aggregation>
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
				<underlay-topology>und-topo:1</underlay-topology>  
				<!-- Filter -->
			    </filtration>
			</correlation>
		    </correlations>
		</topology>'''

FILTER_IPV4 = '''<filter>
		   	<input-model>{input-model}</input-model>
		   	<filter-id>1</filter-id>
		    	<target-field>{target-field}</target-field>
                 	<filter-type>ipv4-address</filter-type>
	                <ipv4-address-filter>
	        		<ipv4-address>{ipv4}</ipv4-address>
		   	</ipv4-address-filter>
                 </filter>'''

RPC_SEND_BARRIER_DATA = '''<input xmlns="urn:opendaylight:flow:transaction">
    <node xmlns:inv="urn:opendaylight:inventory">/inv:nodes/inv:node[inv:id="openflow:1"]</node>
</input>'''

RPC_SEND_ECHO_DATA = '''<input xmlns="urn:opendaylight:echo:service">
    <node xmlns:inv="urn:opendaylight:inventory">/inv:nodes/inv:node[inv:id="openflow:1"]</node>
    <data>aGVsbG8gYmFzZSA2NC4gaW5wdXQ=</data>
</input>'''

RPC_SEND_UPDATE_TABLE_DATA = '''<input xmlns="urn:opendaylight:table:service">
  <node xmlns:inv="urn:opendaylight:inventory">/inv:nodes/inv:node[inv:id="openflow:1"]</node>
  <updated-table>
    <table-features>  <!-- model opendaylight-table-types, grouping table-features  -->
      <table-id>0</table-id>
      <name>table 0 - dummy name</name>
      <metadata-match>21</metadata-match>
      <metadata-write>22</metadata-write>
      <max-entries>55</max-entries>
      <config>DEPRECATED-MASK</config>
    </table-features>
  </updated-table>
</input>'''

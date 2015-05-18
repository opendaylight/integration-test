import json


class SanityLibrary:

    def get_flow_content(self, tid=1, fid=1, priority=1):

        flow_template = '''<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<flow xmlns="urn:opendaylight:flow:inventory">
    <strict>false</strict>
    <instructions>
        <instruction>
            <order>0</order>
            <apply-actions>
                <action>
                    <order>0</order>
                    <drop-action/>
                </action>
            </apply-actions>
        </instruction>
    </instructions>
    <table_id>%s</table_id>
    <id>%s</id>
    <cookie_mask>4294967295</cookie_mask>
    <installHw>false</installHw>
    <match>
        <ethernet-match>
            <ethernet-type>
                <type>2048</type>
            </ethernet-type>
        </ethernet-match>
        <ipv4-source>10.0.0.1</ipv4-source>
    </match>
    <cookie>%s</cookie>
    <flow-name>%s</flow-name>
    <priority>%s</priority>
    <barrier>false</barrier>
</flow>'''

        flow_data = flow_template % (tid, fid, fid, 'TestFlow-{0}'.format(fid), priority)
        return flow_data

    def is_cluter_set_up(self, rsp1, rsp2, rsp3):
        try:
            states = []
            for r in [rsp1, rsp2, rsp3]:
                rj = json.loads(r)
                states.append(rj['value']['RaftState'])
                states.sort()
            if states == ['Follower', 'Follower', 'Leader']:
                return True
        except Exception:
            return False
        return False

    def get_persistence(self, rsp):
        try:
            rj = json.loads(rsp)
            return rj['module'][0]['distributed-datastore-provider:config-properties']['persistent']
        except:
            pass


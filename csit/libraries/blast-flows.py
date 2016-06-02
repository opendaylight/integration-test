import netaddr
import copy
import json
import requests
import argparse


URL = 'http://{}:8181/restconf/config/opendaylight-inventory:nodes/node/openflow:1/table/0'
# CURL_CMD = 'curl -X POST -H "Content-Type: application/json" -H "Authorization: Basic YWRtaW46YWRtaW4=" -d {} -v "{}"'
START_IP = int(netaddr.IPAddress('10.0.0.1'))
TEMPLATE = {
    "flow": [
        {
            "hard-timeout": 65000,
            "idle-timeout": 65000,
            "cookie_mask": 4294967295,
            "flow-name": "FLOW-NAME-TEMPLATE",
            "priority": 2,
            "cookie": 0,
            "table_id": 0,
            "id": "FLOW-ID-TEMPLATE",
            "match": {
                "ipv4-destination": "0.0.0.0/32",
                "ethernet-match": {
                    "ethernet-type": {
                        "type": 2048
                    }
                }
            },
            "instructions": {
                "instruction": [
                    {
                        "order": 0,
                        "apply-actions": {
                            "action": [
                                {
                                    "drop-action": {},
                                    "order": 0
                                }
                            ]
                        }
                    }
                ]
            }
        }
    ]
}


def populate_template(fid, template):
    flow = copy.deepcopy(template['flow'][0])

    flow['id'] = fid
    flow['cookie'] = fid
    flow['flow-name'] = 'generated-flow-{}'.format(fid)
    flow['match']['ipv4-destination'] = '{}/32'.format(str(netaddr.IPAddress(START_IP + fid)))

    return flow


def generate_flow_payload(start_id=0, end_id=1000, template=TEMPLATE):
    flow_data = [populate_template(fid, template) for fid in range(start_id, end_id)]

    return {"table": [{"id": 0, "flow": flow_data}]}


def post_flows(payload, node):
    url = URL.format(node)
    r = requests.put(url, data=json.dumps(payload), verify=False, auth=('admin', 'admin'),
                     headers={'content-type': 'application/json'})
    print(r.status_code)
    print(r.content)


def blast_flows(start_id, end_id, template_file):
    if template_file:
        with open(args.template_file, 'r') as f:
            template = json.load(f)
    else:
        template = TEMPLATE

    flows = generate_flow_payload(int(start_id), int(end_id), template)
    print('generated {} flows... doing PUT to {}'.format(len(flows['table'][0]['flow']), args.node))
    post_flows(flows, args.node)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Flow blaster")
    parser.add_argument("--node", type=str, default='10.25.2.12',
                        help="Cluster node")
    parser.add_argument("--start-id", type=int, default=0, help="Start flow id")
    parser.add_argument("--end-id", type=int, default=1000, help="End flow id")
    parser.add_argument("--template-file", default='', help="Template file")

    args = parser.parse_args()

    blast_flows(args.start_id, args.end_id, args.template_file)

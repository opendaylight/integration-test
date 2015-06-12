#!/usr/bin/python
import time

import flow_config_blaster
import json


class FlowConfigBulkBlaster(flow_config_blaster.FlowConfigBlaster):
    """
    Reusing FlowConfigBlaster class providing flow operations based on bulk processing
    """

    FLW_ADD_RPC_URL = "restconf/operations/sal-bulk-flow:add-flows-rpc"
    FLW_REMOVE_RPC_URL = "restconf/operations/sal-bulk-flow:remove-flows-rpc"
    FLW_ADD_DS_URL = "restconf/operations/sal-bulk-flow:add-flows-ds"
    FLW_REMOVE_DS_URL = "restconf/operations/sal-bulk-flow:remove-flows-ds"

    def __init__(self, *args, **kwargs):
        super(FlowConfigBulkBlaster, self).__init__(*args, **kwargs)
        self.bulk_type = 'RPC'

    def update_post_url_template(self, action):
        """
        Update url templates (defined in parent class) in order to point to bulk API rpcs.
        :param action: user intention (currently only 'ADD' is supported)
        """
        if self.bulk_type == 'RPC':
            self.post_url_template = 'http://%s:' + self.port + '/'
            if action == 'ADD':
                self.post_url_template += self.FLW_ADD_RPC_URL
            elif action == 'REMOVE':
                self.post_url_template += self.FLW_REMOVE_RPC_URL
        elif self.bulk_type == 'DS':
            self.post_url_template = 'http://%s:' + self.port + '/'
            if action == 'ADD':
                self.post_url_template += self.FLW_ADD_DS_URL
            elif action == 'REMOVE':
                self.post_url_template += self.FLW_REMOVE_DS_URL

    def assemble_post_url(self, host, node):
        """
        Format url to final form using substitutions. Here the node is ignored.
        :param host: controller address
        :param node: node identifier
        :return: finalized url
        """
        return self.post_url_template % host

    def create_flow_from_template(self, flow_id, ipaddr, node_id):
        """
        Create one flow beased on template and given values
        :param flow_id: flow identifier
        :param ipaddr: part of flow match
        :param node_id: node identifier
        :return: flow structure ready to use
        """
        # python 2.7 specific syntax (super)
        flow = super(FlowConfigBulkBlaster, self).create_flow_from_template(flow_id, ipaddr, node_id)
        flow_id = flow['id']
        del(flow['id'])
        if self.bulk_type == 'DS':
            flow['flow-id'] = flow_id
        flow['node'] = '/opendaylight-inventory:nodes/opendaylight-inventory' \
                       ':node[opendaylight-inventory:id="openflow:{}"]'.format(node_id)
        return flow

    def convert_to_json(self, flow_list, node_id=None):
        """
        Converts given list of flows into string of json form.
        :param flow_list: list of flows to convert
        :param node_id: identifier of corresponding node
        :return: json string
        """
        json_input = None
        if self.bulk_type == 'RPC':
            json_input = {'input': {'bulk-flow-item': flow_list}}
        elif self.bulk_type == 'DS':
            json_input = {'input': {'bulk-flow-ds-item': flow_list}}

        flow_data = json.dumps(json_input)
        # print flow_data
        return flow_data


if __name__ == "__main__":
    ############################################################################
    # This program executes the base performance test. The test adds flows into
    # the controller's config space. This function is basically the CLI frontend
    # to the FlowConfigBlaster class and drives its main functions: adding and
    # deleting flows from the controller's config data store
    ############################################################################
    parser = flow_config_blaster.create_arguments_parser()
    parser.add_argument('--bulk-type', default='RPC', dest='bulk_type',
                        choices=['RPC', 'DS'],
                        help='Bulk type to use: RPC, DS (default is RPC)')

    in_args = parser.parse_args()

    if in_args.file != '':
        flow_template = flow_config_blaster.get_json_from_file(in_args.file)
    else:
        flow_template = None

    fcbb = FlowConfigBulkBlaster(in_args.host, in_args.port, in_args.cycles,
                                 in_args.threads, in_args.fpr, in_args.nodes,
                                 in_args.flows, in_args.startflow, in_args.auth)
    fcbb.bulk_type = in_args.bulk_type
    fcbb.update_post_url_template('ADD')

    # Run through <cycles>, where <threads> are started in each cycle and
    # <flows> are added from each thread
    fcbb.add_blaster()

    print '\n*** Total flows added: %s' % fcbb.get_ok_flows()
    print '    HTTP[OK] results:  %d\n' % fcbb.get_ok_rqsts()

    if in_args.delay > 0:
        print '*** Waiting for %d seconds before the delete cycle ***\n' % in_args.delay
        time.sleep(in_args.delay)

    # Run through <cycles>, where <threads> are started in each cycle and
    # <flows> previously added in an add cycle are deleted in each thread
    if in_args.delete:
        fcbb.delete_blaster()
        print '\n*** Total flows deleted: %s' % fcbb.get_ok_flows()
        print '    HTTP[OK] results:    %d\n' % fcbb.get_ok_rqsts()

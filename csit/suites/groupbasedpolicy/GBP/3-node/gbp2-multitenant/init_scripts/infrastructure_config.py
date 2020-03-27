# Config for switches, tunnelIP is the local IP address.
switches = [
    {"name": "sw1", "type": "gbp", "dpid": "1"},
    {"name": "sw2", "type": "gbp", "dpid": "2"},
    {"name": "sw3", "type": "gbp", "dpid": "3"},
]

defaultContainerImage = "alagalah/odlpoc_ovs230"
# defaultContainerImage='ubuntu:14.04'

# Note that tenant name and endpointGroup name come from policy_config.py

hosts = [
    {
        "name": "h35_2",
        "mac": "00:00:00:00:35:02",
        "ip": "10.0.35.2/24",
        "switch": "sw1",
    },
    {
        "name": "h35_3",
        "ip": "10.0.35.3/24",
        "mac": "00:00:00:00:35:03",
        "switch": "sw2",
    },
    {
        "name": "h35_4",
        "ip": "10.0.35.4/24",
        "mac": "00:00:00:00:35:04",
        "switch": "sw3",
    },
    {
        "name": "h35_5",
        "ip": "10.0.35.5/24",
        "mac": "00:00:00:00:35:05",
        "switch": "sw1",
    },
    {
        "name": "h35_6",
        "ip": "10.0.35.6/24",
        "mac": "00:00:00:00:35:06",
        "switch": "sw2",
        "tenant": "GBPPOC2",
        "endpointGroup": "test",
    },
    {
        "name": "h35_7",
        "ip": "10.0.35.7/24",
        "mac": "00:00:00:00:35:07",
        "switch": "sw3",
        "tenant": "GBPPOC2",
        "endpointGroup": "test",
    },
    {
        "name": "h35_8",
        "ip": "10.0.35.8/24",
        "mac": "00:00:00:00:35:08",
        "switch": "sw1",
        "tenant": "GBPPOC2",
        "endpointGroup": "test",
    },
    {
        "name": "h35_9",
        "ip": "10.0.35.9/24",
        "mac": "00:00:00:00:35:09",
        "switch": "sw2",
        "tenant": "GBPPOC2",
        "endpointGroup": "test",
    },
    {
        "name": "h36_2",
        "ip": "10.0.36.2/24",
        "mac": "00:00:00:00:36:02",
        "switch": "sw3",
    },
    {
        "name": "h36_3",
        "ip": "10.0.36.3/24",
        "mac": "00:00:00:00:36:03",
        "switch": "sw1",
    },
    {
        "name": "h36_4",
        "ip": "10.0.36.4/24",
        "mac": "00:00:00:00:36:04",
        "switch": "sw2",
    },
    {
        "name": "h36_5",
        "ip": "10.0.36.5/24",
        "mac": "00:00:00:00:36:05",
        "switch": "sw3",
    },
    {
        "name": "h36_6",
        "ip": "10.0.36.6/24",
        "mac": "00:00:00:00:36:06",
        "switch": "sw1",
        "tenant": "GBPPOC2",
        "endpointGroup": "test",
    },
    {
        "name": "h36_7",
        "ip": "10.0.36.7/24",
        "mac": "00:00:00:00:36:07",
        "switch": "sw2",
        "tenant": "GBPPOC2",
        "endpointGroup": "test",
    },
    {
        "name": "h36_8",
        "ip": "10.0.36.8/24",
        "mac": "00:00:00:00:36:08",
        "switch": "sw3",
        "tenant": "GBPPOC2",
        "endpointGroup": "test",
    },
    {
        "name": "h36_9",
        "ip": "10.0.36.9/24",
        "mac": "00:00:00:00:36:09",
        "switch": "sw1",
        "tenant": "GBPPOC2",
        "endpointGroup": "test",
    },
]

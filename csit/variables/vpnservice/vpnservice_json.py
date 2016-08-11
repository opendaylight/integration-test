tenantId = '6c53df3a-3456-11e5-a151-feff819cdc9f'

neutron_l3vpn = {
    "input": {
        "l3vpn": [{
                  "id": "4ae8cd92-48ca-49b5-94e1-b2921a260003",
                  "name": "vpn",
                  "route-distinguisher": ['100:1'],
                  "export-RT": ['100:1'],
                  "import-RT": ['100:1'],
                  "tenant-id": tenantId
                  }]
    }
}

get_delete_l3vpn = {
    "input": {
        "id": ["4ae8cd92-48ca-49b5-94e1-b2921a260003"]
    }
}


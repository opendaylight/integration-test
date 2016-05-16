"""
The purpose of this script to create enough traffic in config datastore
to trigger creation of Snapshot.
This script uses PATCH http method for handling "moving segment" of cars.
The car data is minimal, containing only a numeric ID.
This script is tailored to behavior of Berylium-SR2,
if the behavior changes, new script will be needed.
"""


import argparse
import string
import requests


car_entry_template = string.Template('''      {
       "id": $ID
      }''')


patch_data_template = string.Template'''{
 "ietf-restconf:yang-patch": {
  "patch-id": "0",
  "edit": [
   {
    "edit-id": "0",
    "operation": "replace",
    "target": "/car:car-entry[car:id='0']",
    "value": {
     "car:car-entry": [
$ENTRIES
     ]
    }
   }
  ]
 }
}''')


def main:
    """
    This program executes requested action based in given parameters

    It provides "car", "people" and "car-people" crud operations.
    """

    parser = argparse.ArgumentParser(description="Config datastore"
                                                 "scale test script")
    parser.add_argument("--host", default="127.0.0.1",
                        help="Host where odl controller is running."
                             "(default: 127.0.0.1)")
    parser.add_argument("--port", default="8181",
                        help="Port on which odl's RESTCONF is listening"
                             "(default: 8181)")
    parser.add_argument("--start-id", type=int, default=1,
                        help="ID number of the first car. (default:1)")
    parser.add_argument("--segment-size", type=int, default=1,
                        help="Number of cars in segment. (default:1)")
    parser.add_argument("--iterations", type=int, default=1,
                        help="How many times the segment sent. (default:1)")
    parser.add_argument("--move-per-iter", type=int, default=1,
                        help="Each segment has IDs moved by this. (default:1)")
                        default=1)
    parser.add_argument("--user", help="Restconf user name", default="admin")
    parser.add_argument("--password", help="Restconf password", default="admin")

    args = parser.parse_args()

    auth = (args.user, args.password)
    url = "http://" + host + ':' + port
    headers = {"Content-Type": "application/yang.patch+json"}
    session = requests.Session(headers=headers, auth=auth, stream=True)
    for iteration in range(args.iterations):
        start_id = args.start_id + iteration * args.move_per_iter
        entry_list = []
        for num_entry in range(args.segment_size):
            str_id = str(start_id + num_entry)
            entry_list.append(car_entry_template.substitute({"ID": str_id}))
        mapping = {"ENTRIES": ",\n".join(entry_list)}
        data = patch_data_template.substitute(mapping)
        session.patch(url=url, data=data)


if __name__ == "__main__":
    main()


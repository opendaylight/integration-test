"""
The purpose of this script to create enough traffic in config datastore
to trigger creation of Snapshot.
This script uses PUT http method for handling/replacing "moving segment" of cars.
The car data is minimal, containing only an ID (car-<num>).
"""


import argparse
import string
import sys
import requests


def main():
    """
    The main function that does it all.

    TODO: Move argument parsing to a separate function,
    so allow the main logic to be started programmatically?
    """

    # Constants
    car_entry_template = string.Template(
        """      {
       "id": "car-$NUM"
      }"""
    )

    patch_data_template = string.Template(
        """{
 "cars": {
  "car-entry": [
$ENTRIES
     ]
    }
}"""
    )

    # Arguments
    parser = argparse.ArgumentParser(description="Config datastore" "scale test script")
    parser.add_argument(
        "--host",
        default="127.0.0.1",
        help="Host where odl controller is running." "(default: 127.0.0.1)",
    )
    parser.add_argument(
        "--port",
        default="8181",
        help="Port on which odl's RESTCONF is listening" "(default: 8181)",
    )
    parser.add_argument(
        "--start-id",
        type=int,
        default=1,
        help="ID number of the first car. (default:1)",
    )
    parser.add_argument(
        "--segment-size",
        type=int,
        default=1,
        help="Number of cars in segment. (default:1)",
    )
    parser.add_argument(
        "--iterations",
        type=int,
        default=1,
        help="How many times the segment sent. (default:1)",
    )
    parser.add_argument(
        "--move-per-iter",
        type=int,
        default=1,
        help="Each segment has IDs moved by this. (default:1)",
    )
    parser.add_argument("--user", help="Restconf user name", default="admin")
    parser.add_argument("--password", help="Restconf password", default="admin")

    args = parser.parse_args()

    # Logic
    url = "http://" + args.host + ":" + args.port + "/restconf/config/car:cars"
    auth = (args.user, args.password)
    headers = {"Content-Type": "application/json"}
    session = requests.Session()
    for iteration in range(args.iterations):
        entry_list = []
        for num_entry in range(args.segment_size):
            num_id = args.start_id + iteration * args.move_per_iter + num_entry
            entry_list.append(car_entry_template.substitute({"NUM": str(num_id)}))
        mapping = {"ID": str(iteration), "ENTRIES": ",\n".join(entry_list)}
        data = patch_data_template.substitute(mapping)
        response = session.put(url=url, auth=auth, headers=headers, data=data)
        if response.status_code not in [200, 201, 204]:
            print("status: {}".format(response.status_code))
            print("text: {}".format(response.text))
            sys.exit(1)


if __name__ == "__main__":
    main()

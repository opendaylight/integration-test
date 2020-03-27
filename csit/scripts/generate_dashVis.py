# SPDX-License-Identifier: EPL-1.0
##############################################################################
# Copyright (c) 2018 The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
##############################################################################
import yaml
import copy

import json

# Pretty Printer


def p(x):
    print(json.dumps(x, indent=4, sort_keys=False))


class panelsJSON:
    def __init__(self):
        self.content = {
            "gridData": {"h": None, "i": None, "w": None, "x": None, "y": None},
            "id": None,
            "panelIndex": None,
            "type": "visualization",
            "version": "6.2.4",
        }

        self.counter = 0

    def create(self, co_ords, id):
        self.counter += 1
        temp = copy.deepcopy(self.content)
        temp["gridData"]["h"] = co_ords["h"]
        temp["gridData"]["i"] = str(self.counter)
        temp["gridData"]["w"] = co_ords["w"]
        temp["gridData"]["x"] = co_ords["x"]
        temp["gridData"]["y"] = co_ords["y"]

        temp["id"] = id
        temp["panelIndex"] = str(self.counter)

        return temp


def generate(viz_config):
    dash = panelsJSON()
    viz = [dash.create(i["co_ords"], i["id"]) for _, i in viz_config.items()]
    return viz


if __name__ == "__main__":
    with open("dashboard.yaml", "r") as f:
        config = yaml.safe_load(f)
        p(generate(config["dashboard"]["viz"]))

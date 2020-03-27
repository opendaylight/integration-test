# Template for UIState (Currently supports only colors)
UI_STATE_BODY = {"vis": {"colors": None}}


def generate(dash_config, viz_config):

    colors = {}

    # Check for 'color' key in 'series' or 'seriesParams' in
    # either viz_config and dash_config

    # Note:- 'series' simplifies 'seriesParams' and 'aggs'
    # and avoids duplication

    try:
        series = dash_config["y-axis"]["series"]
        for _, value in series.items():
            try:
                colors[value["label"]] = value["color"]
            except KeyError:
                continue
    except KeyError:
        pass

    try:
        series = viz_config["series"]
        for _, value in series.items():
            try:
                colors[value["label"]] = value["color"]
            except KeyError:
                continue
    except KeyError:
        pass

    try:
        seriesParams = dash_config["y-axis"]["seriesParams"]
        for _, value in seriesParams.items():
            try:
                colors[value["label"]] = value["color"]
            except KeyError:
                continue
    except KeyError:
        pass

    try:
        seriesParams = viz_config["seriesParams"]
        for _, value in seriesParams.items():
            try:
                colors[value["label"]] = value["color"]
            except KeyError:
                continue
    except KeyError:
        pass

    UI_STATE_BODY["vis"]["colors"] = colors

    return UI_STATE_BODY

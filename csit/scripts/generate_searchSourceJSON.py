from copy import deepcopy as dc

SEARCH_SOURCE_FORMAT = {"index": None, "filter": [],
                        "query": {"language": "lucene", "query": ""}}

FILTER_FORMAT = {
    "query": {
        "match": {
            "placeholder_field": {
                "query": "query_phrase",
                "type": "phrase"
            }
        }
    }
}


def generate(dash_config, viz_config, index_pattern):

    search_source = dc(SEARCH_SOURCE_FORMAT)

    try:
        filters = dash_config['filter']
        for _, value in filters.items():
            try:
                temp = dc(FILTER_FORMAT)
                temp['query']['match'][value['field']
                                       ] = \
                    temp['query']['match']['placeholder_field']
                temp['query']['match'][value['field']
                                       ]['query'] = value['match-with']
                del temp['query']['match']['placeholder_field']
                search_source['filter'].append(temp)
            except KeyError:
                continue
    except KeyError:
        pass

    try:
        filters = viz_config['filter']
        for _, value in filters.items():
            try:
                temp = dc(FILTER_FORMAT)
                temp['query']['match'][value['field']
                                       ] = \
                    temp['query']['match']['placeholder_field']
                temp['query']['match'][value['field']
                                       ]['query'] = value['match-with']
                del temp['query']['match']['placeholder_field']
                search_source['filter'].append(temp)
            except KeyError:
                continue
    except KeyError:
        pass

    search_source['index'] = index_pattern

    return search_source

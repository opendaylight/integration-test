import generate_visState as vis_gen
import yaml
import json

from elasticsearch import Elasticsearch, RequestsHttpConnection, exceptions
import sys


try:
	es = Elasticsearch("https://a4ff38b99ef2c7626450543021b4c134.us-east-1.aws.found.io:9243/", http_auth=('dibyadas998','P7u^q1sLN@uIVgwub%8W3nJ#!e4S@anV'))
except Exception as e:
	print('Unexpected Error Occurred. Exiting')
	print(e)
	

with open('viz_config.yaml','r') as f:
		config = yaml.safe_load(f)

p = lambda x: print(json.dumps(x,indent=6, sort_keys=True))


def JSONToString(jobj):
	retval = str(jobj)
	retval = retval.replace('\'', '"')
	retval = retval.replace(': ', ':')
	retval = retval.replace(', ', ',')
	retval = retval.replace('True', 'true')
	retval = retval.replace('False', 'false')
	retval = retval.replace('None', 'null')
	return retval


SEARCH_SOURCE = {"index": None, "filter":[], "query":{"language":"lucene","query":""}}

for _,i in config.items():
	visState = vis_gen.generate(i)

	SEARCH_SOURCE['index'] = i['index_pattern']
	VIZ_BODY = {
		'type': 'visualization',
		'visualization': {
		  "title": None,
		  "visState": None,
		  "uiStateJSON": "{}",
		  "description": None,
		  "version": 1,
		  "kibanaSavedObjectMeta": {
			"searchSourceJSON": JSONToString(SEARCH_SOURCE)
		  }
		}
	}

	VIZ_BODY['visualization']['title'] = i['title']
	VIZ_BODY['visualization']['visState'] = JSONToString(visState)
	VIZ_BODY['visualization']['description'] = i['desc']

	p(VIZ_BODY)
	index = '.kibana'
	ES_ID = 'visualization:{}'.format(i['id'])
	temp = VIZ_BODY
	res = es.index(index=index, doc_type='doc', id=ES_ID, body=temp)
	print(json.dumps(res,indent=4))

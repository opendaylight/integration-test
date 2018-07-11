import generate_dashVis as dash_gen
import yaml
import json

from elasticsearch import Elasticsearch, RequestsHttpConnection, exceptions
import sys


try:
	es = Elasticsearch('https://a4ff38b99ef2c7626450543021b4c134.us-east-1.aws.found.io:9243/', http_auth=('dibyadas998','P7u^q1sLN@uIVgwub%8W3nJ#!e4S@anV'))
except Exception as e:
	print('Unexpected Error Occurred. Exiting')
	print(e)

with open('dash_config.yaml','r') as f:
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


for _,i in config.items():
	DASH_BODY = {
		'type': 'dashboard',
		'dashboard': {
	      'title': None,
	      'description': None,
	      'panelsJSON': None,
	      'optionsJSON': '{\"darkTheme\":false,\"hidePanelTitles\":false,\"useMargins\":true}',
	      'version': 1,
	      'kibanaSavedObjectMeta': {
	        'searchSourceJSON': '{\"query\":{\"language\":\"lucene\",\"query\":\"\"},\"filter\":[],\"highlightAll\":true,\"version\":true}'
	      }
	    }
	}

	DASH_BODY['dashboard']['title'] = i['title']
	DASH_BODY['dashboard']['description'] = i['desc']
	DASH_BODY['dashboard']['panelsJSON'] = JSONToString(dash_gen.generate(i['viz']))
	p(dash_gen.generate(i['viz']))

	index = '.kibana'
	ES_ID = 'dashboard:{}'.format(i['id'])
	temp = DASH_BODY
	res = es.index(index=index, doc_type='doc', id=ES_ID, body=temp)
	print(json.dumps(res,indent=4))
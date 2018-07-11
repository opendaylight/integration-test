import yaml
import copy

import json
p = lambda x: print(json.dumps(x,indent=4, sort_keys=False))

class panelsJSON:
	def __init__(self):
		self.content = {
			'gridData': {
			  'h': None,
			  'i': None,
			  'w': None,
			  'x': None,
			  'y': None
			},
			'id': None,
			'panelIndex': None,
			'type': 'visualization',
			'version': '6.2.4'
		  }

		self.counter = 0

	def create(self,co_ords,id):
		self.counter += 1
		temp = copy.deepcopy(self.content)
		temp['gridData']['h'] = co_ords['h']
		temp['gridData']['i'] = str(self.counter)
		temp['gridData']['w'] = co_ords['w']
		temp['gridData']['x'] = co_ords['x']
		temp['gridData']['y'] = co_ords['y']

		temp['id'] = id
		temp['panelIndex'] = str(self.counter)

		return temp



def generate(viz_config):
	dash = panelsJSON()
	viz = [dash.create(i['co_ords'],i['id']) for _,i in viz_config.items()]
	return viz

if __name__ == '__main__':
	with open('dash_config.yaml','r') as f:
		config = yaml.safe_load(f)
		p(generate(config['dashboard-1']['viz']))

	

	
		
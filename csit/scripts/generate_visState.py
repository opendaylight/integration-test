import yaml
import copy

import json
p = lambda x: print(json.dumps(x,indent=4, sort_keys=False))

class visState:
	def __init__(self):
		self.content = {
			'title': None,
			'type': None,
			'params': {
				'type': None,
				'grid': {
					'categoryLines': False,
					'style': {
					'color': '#eee'
				  }
				},
				'categoryAxes': None,
				'valueAxes': None,
				'seriesParams': None,
				'addTooltip': True,
				'addLegend': True,
				'legendPosition': 'right',
				'times': [],
				'addTimeMarker': False
			},
			'aggs': None
		}

	def create(self,config):
		temp = self.content
		temp['title'] = config['title']
		temp['type'] = temp['params']['type'] = config['type']

		cat = categoryAxes()
		temp['params']['categoryAxes'] = [copy.deepcopy(cat.create()) for i in range(config['num_cat_axes'])]

		val = ValueAxes()
		temp['params']['valueAxes'] = [copy.deepcopy(val.create(position=i['position'],
			title=i['title'])) for _,i in config['value_axes'].items()]

		agg = aggs()

		temp['aggs'] = [copy.deepcopy(agg.create(field=i['field'],
			custom_label=i['custom_label'],schema=i['schema'])) for _,i in config['aggs'].items()]

		temp['params']['seriesParams'] = [seriesParams(i['data_type'],i['mode'],
			i['label'],i['agg_id'],i['value_axis']).create() for _,i in config['seriesParams'].items()]

		return temp



class categoryAxes:
	def __init__(self):
		self.content = {
			'id': None,
			'type': 'category',
			'position': 'bottom',
			'show': True,
			'style': {},
			'scale': {
			  'type': 'linear'
			},
			'labels': {
			  'show': True,
			  'truncate': 100
			},
			'title': {}
		}
		self.counter = 0

	def create(self):
		self.counter += 1
		temp = copy.deepcopy(self.content)
		temp['id'] = 'CategoryAxis-{}'.format(self.counter)
		return temp



class ValueAxes:
	def __init__(self):
		self.content = {
			'id': None,
			'name': None,
			'type': 'value',
			'position': 'left',
			'show': True,
			'style': {},
			'scale': {
			  'type': 'linear',
			  'mode': 'normal'
			},
			'labels': {
			  'show': True,
			  'rotate': 0,
			  'filter': False,
			  'truncate': 100
			},
			'title': {
			  'text': None
			}
		}
		self.counter = 0

	def create(self,position='left',title='Value'):
		self.counter += 1
		temp = copy.deepcopy(self.content)
		temp['id'] = 'ValueAxis-{}'.format(self.counter)
		if position == 'left':
			temp['name'] = 'LeftAxis-{}'.format(self.counter)
		elif position == 'right':
			temp['name'] = 'RightAxis-{}'.format(self.counter)
		else:
			# raise ValueError('Not one of left or right')
			temp['name'] = 'LeftAxis-{}'.format(self.counter) # assuming default

		temp['title']['text'] = title

		return temp


class seriesParams:
	def __init__(self,data_type,mode,label,agg_id,value_axis):
		self.content = {
			'show': True,
			'type': data_type,
			'mode': mode,
			'data': {
				'label': label,
				'id': str(agg_id)
			},
			'valueAxis': 'ValueAxis-{}'.format(value_axis),
			'drawLinesBetweenPoints': True,
			'showCircles': True
		}

	def create(self):
		return self.content


class aggs:
	def __init__(self):
		self.content = {
		  'id': None,
		  'enabled': True,
		  'type': None,
		  'schema': None,
		  'params': {
			'field': None,
			'customLabel': None
		  }
		}
		self.counter = 0

	def create(self,field,custom_label,schema):
		self.counter += 1
		temp = copy.deepcopy(self.content)
		temp['id'] = str(self.counter)
		temp['params']['field'] = field
		temp['params']['customLabel'] = custom_label
		temp['schema'] = schema
		if schema == 'metric':
			temp['type'] = 'max'
			return temp	
		elif schema == 'segment':
			temp['type'] = 'terms'
			temp['params']['size'] = 20 ## default
			temp['params']['order'] = 'asc'
			temp['params']['orderBy'] = '_term'
		return temp

def generate(config):
	vis = visState()
	return vis.create(config)


if __name__ == '__main__':
	with open('viz_config.yaml','r') as f:
		config = yaml.safe_load(f)

	for _,i in config.items():
		out = generate(i)
		p(out)
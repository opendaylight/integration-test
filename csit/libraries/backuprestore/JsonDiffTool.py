import argparse
import logging
import jsonpatch
import json
from jsonpathl import jsonpath
import types
import sys

"""
Library for checking differences between json files,
allowing pre-filtering those files using a number
of jsonpath expressions
This library supports the automated verification
of backup & restore use cases for applications
Updated: 2017-04-10
"""

__author__ = "Diego Granados"
__copyright__ = "Copyright(c) 2017, Ericsson."
__license__ = "New-style BSD"
__email__ = "diego.jesus.granados.lopez@ericsson.com"

def fromPathToJsonPatch(matchedpath):
    ''' Given a json path (using jsonpath notation), to a json patch (RFC 6902)
    which can be used to remove the document fragment pointed by the input path
    Note that such conversion is not formally specified anywhere, so the conversion
    rules are experimentation-based

    :param matchedpath: the input path (using jsonpath notation, see http://goessner.net/articles/JsonPath)
    :return: the corresponding json patch for removing the fragment
    '''

    logging.info('starting. filter path: %s', matchedpath)

    # First step: path format change
    # typical input: $['ietf-yang-library:modules-state']['module'][57]
    # desired output: /ietf-yang-library:modules-state/module/57

    matchedpath = matchedpath.replace('$.', '/')
    matchedpath = matchedpath.replace('$[\'', '/')
    matchedpath = matchedpath.replace('\'][\'', '/')
    matchedpath = matchedpath.replace('\']', '/')

    # this one is for the $[2] pattern
    if '$[' in matchedpath and ']' in matchedpath:
        matchedpath = matchedpath.replace('$[', '/')
        matchedpath = matchedpath.replace(']', '')

    matchedpath = matchedpath.replace('[', '')
    matchedpath = matchedpath.replace(']', '')
    matchedpath = matchedpath.rstrip('/')
    # if (matchedpath.endswith('/')):
    #     matchedpath = matchedpath.substring(0, len(matchedpath))

    # Now, for input: /ietf-yang-library:modules-state/module/57
    # desired output: [{"op":"remove","path":"/ietf-yang-library:modules-state/module/57"}]

    logging.info('final filter path: %s', matchedpath)
    asPatch = '[{{"op\":\"remove\",\"path\":\"{0}\"}}]'.format(matchedpath)
    logging.info('generated patch line: %s', asPatch)
    return asPatch

def applyFilter(jsonArg, filteringLine):
    ''' Filters a json document by removing the elements identified by a filtering pattern

    :param jsonArg: the document to filter
    :param filteringLine: The filtering pattern. This is specified using jsonpath notation grammar
            (see http://goessner.net/articles/JsonPath/)
    :return: the filtered document
    '''

    logging.info('applyFilter:starting. jsonPath filter=[%s]', filteringLine)

    res = jsonpath(jsonArg, filteringLine, result_type='PATH')
    if type(res) == types.BooleanType or len(res) == 0:
        logging.info('applyFilter: The prefilter [%s] matched nothing', filteringLine);
        return jsonArg
    if (len(res) > 1):
        raise AssertionError('Bad pre-filter [%s] (returned [%d] entries, should return one at most'
                             , filteringLine, len(res));
    asJsonPatch = fromPathToJsonPatch(res[0])
    logging.info('applyFilter: applying patch! resolved patch =%s', asJsonPatch)
    patchedJson = jsonpatch.apply_patch(jsonArg,asJsonPatch);

    logging.info('applyFilter: json after patching: %s', patchedJson)
    return patchedJson


def prefilter(jsonArg, initialPreFilter):
    ''' Performs the prefiltering of a json file
    :param jsonArg: the json document to filter (as string)
    :param initialPreFilter: a file containing a number of filtering patterns (using jsonpath notation)
    :return: the original document, python-deserialized and having the fragments
        matched by the filtering patterns removed
    '''

    if not initialPreFilter:
        logging.info('prefilter not found!')
        # whether it is filtered or not, return as json so it can be handled uniformly from now on
        return json.loads(jsonArg)

    with open(initialPreFilter) as f:
        lines = f.read().splitlines()
    logging.info('prefilter:lines in prefilter file: %d ', len(lines))
    lines = filter(lambda k: not k.startswith('#'), lines)
    logging.info('prefilter:lines after removing comments: %d ', len(lines))
    jsonArgsAsJson = json.loads(jsonArg)
    for filteringLine in lines:
        jsonArgsAsJson = applyFilter(jsonArgsAsJson, filteringLine)

    return jsonArgsAsJson


def prefilterJsonFilesThenCompare(args):
    ''' Main function. Prefilters the input files using provided prefiltering patterns,
        then returns number of differences (and the differences themselves, when requested)

    :param args: Input arguments, already parsed
    :return: the number of differences (from a jsonpatch standpoint) between the input
             json files (those input files can be prefiltered using a number of patterns when
             requested)
    '''

    logging.info('prefilterJsonFilesThenCompare: starting!')
    with open(args.initialFile) as f:
        jsonInitial = file.read(f)
    with open(args.finalFile) as f2:
        jsonFinal = file.read(f2)

    patch = jsonpatch.JsonPatch.from_diff(jsonInitial, jsonFinal)
    logging.info('prefilterJsonFilesThenCompare:differences before patching: %d', len(list(patch)))

    jsonInitialFiltered = prefilter(jsonInitial, args.initialPreFilter)
    jsonFinalFiltered = prefilter(jsonFinal, args.finalPreFilter)

    patchAfterFiltering = jsonpatch.JsonPatch.from_diff(jsonInitialFiltered, jsonFinalFiltered)
    differencesAfterPatching = list(patchAfterFiltering)
    logging.info('prefilterJsonFilesThenCompare: differences after patching: %d', len(differencesAfterPatching))

    if args.printDifferences:
        for patchline in differencesAfterPatching:
            print json.dumps(patchline)

    print len(differencesAfterPatching)
    return len(differencesAfterPatching)

def Json_Diff_Check_Keyword(jsonBefore, jsonAfter, filterBefore, filterAfter):
    input_argv = ['-i', jsonBefore, '-f', jsonAfter, '-ipf', filterBefore, '-fpf', filterAfter]
    sys.argv[1:] = input_argv
    logging.info('starting. constructed command line: %s', sys.argv)
    return Json_Diff_Check()

def parseArgs(args):
    parser = argparse.ArgumentParser(description='both initial and final json files are compared for differences. '
                                                'The program returns 0 when the json contents are the same, or the number of'
                                                ' differences otherwise. Both json files can be prefiltered for certain patterns'
                                                ' before checking the differences')

    parser.add_argument('-i', '--initialFile', required='true', dest='initialFile', action='store',
                        help='initial json file')
    parser.add_argument('-f', '--finalFile', required='true', dest='finalFile', action='store', help='final json file')
    parser.add_argument('-ipf', '--initialPreFilter', dest='initialPreFilter',
                        help='File with pre-filtering patterns to apply to the initial json file before comparing')
    parser.add_argument('-fpf', '--finalPreFilter', dest='finalPreFilter',
                        help='File with pre-filtering patterns to apply to the final json file before comparing')
    parser.add_argument('-pd', '--printDifferences', action='store_true',
                        help='on differences found, prints the list of paths for the found differences before exitting')
    parser.add_argument('-v', '--verbose', dest='verbose', action='store_true', help='generate log information')
    return parser.parse_args(args)

def Json_Diff_Check():

    args = parseArgs(sys.argv[1:])

    if hasattr(args, 'verbose'):
        if args.verbose:
            logging.basicConfig(level=logging.DEBUG)

    if args.printDifferences:
        logging.info('(will print differences)')

    result = prefilterJsonFilesThenCompare(args)
    return result

if __name__ == '__main__':
        Json_Diff_Check()

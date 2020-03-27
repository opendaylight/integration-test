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


def from_path_to_jsonpatch(matchedpath):
    """ Given a json path (using jsonpath notation), to a json patch (RFC 6902)
    which can be used to remove the document fragment pointed by the input path
    Note that such conversion is not formally specified anywhere, so the conversion
    rules are experimentation-based

    :param matchedpath: the input path (using jsonpath notation, see http://goessner.net/articles/JsonPath)
    :return: the corresponding json patch for removing the fragment
    """

    logging.info("starting. filter path: %s", matchedpath)

    # First step: path format change
    # typical input: $['ietf-yang-library:modules-state']['module'][57]
    # desired output: /ietf-yang-library:modules-state/module/57

    matchedpath = matchedpath.replace("$.", "/")
    matchedpath = matchedpath.replace("$['", "/")
    matchedpath = matchedpath.replace("']['", "/")
    matchedpath = matchedpath.replace("']", "/")

    # this one is for the $[2] pattern
    if "$[" in matchedpath and "]" in matchedpath:
        matchedpath = matchedpath.replace("$[", "/")
        matchedpath = matchedpath.replace("]", "")

    matchedpath = matchedpath.replace("[", "")
    matchedpath = matchedpath.replace("]", "")
    matchedpath = matchedpath.rstrip("/")

    # Now, for input: /ietf-yang-library:modules-state/module/57
    # desired output: [{"op":"remove","path":"/ietf-yang-library:modules-state/module/57"}]

    logging.info("final filter path: %s", matchedpath)
    as_patch = '[{{"op":"remove","path":"{0}"}}]'.format(matchedpath)
    logging.info("generated patch line: %s", as_patch)
    return as_patch


def apply_filter(json_arg, filtering_line):
    """ Filters a json document by removing the elements identified by a filtering pattern

    :param json_arg: the document to filter
    :param filtering_line: The filtering pattern. This is specified using jsonpath notation grammar
            (see http://goessner.net/articles/JsonPath/)
    :return: the filtered document
    """

    logging.info("apply_filter:starting. jsonPath filter=[%s]", filtering_line)

    res = jsonpath(json_arg, filtering_line, result_type="PATH")
    if isinstance(res, types.BooleanType) or len(res) == 0:
        logging.info("apply_filter: The prefilter [%s] matched nothing", filtering_line)
        return json_arg
    if len(res) > 1:
        raise AssertionError(
            "Bad pre-filter [%s] (returned [%d] entries, should return one at most",
            filtering_line,
            len(res),
        )
    as_json_patch = from_path_to_jsonpatch(res[0])
    logging.info("apply_filter: applying patch! resolved patch =%s", as_json_patch)
    patched_json = jsonpatch.apply_patch(json_arg, as_json_patch)

    logging.info("apply_filter: json after patching: %s", patched_json)
    return patched_json


def prefilter(json_arg, initial_prefilter):
    """ Performs the prefiltering of a json file
    :param json_arg: the json document to filter (as string)
        :type json_arg: str
    :param initial_prefilter: a file containing a number of filtering patterns (using jsonpath notation)
    :return: the original document, python-deserialized and having the fragments
        matched by the filtering patterns removed
    """

    if not initial_prefilter:
        logging.info("prefilter not found!")
        # whether it is filtered or not, return as json so it can be handled uniformly from now on
        return json.loads(json_arg)

    with open(initial_prefilter) as f:
        lines = f.read().splitlines()
    logging.info("prefilter:lines in prefilter file: %d ", len(lines))
    lines = filter(lambda k: not k.startswith("#"), lines)
    logging.info("prefilter:lines after removing comments: %d ", len(lines))
    json_args_as_json = json.loads(json_arg)
    for filtering_line in lines:
        json_args_as_json = apply_filter(json_args_as_json, filtering_line)

    return json_args_as_json


def prefilter_json_files_then_compare(args):
    """ Main function. Prefilters the input files using provided prefiltering patterns,
        then returns number of differences (and the differences themselves, when requested)

    :param args: Input arguments, already parsed
    :return: the number of differences (from a jsonpatch standpoint) between the input
             json files (those input files can be prefiltered using a number of patterns when
             requested)
    """

    logging.info("prefilter_json_files_then_compare: starting!")
    with open(args.initialFile) as f:
        json_initial = file.read(f)
    with open(args.finalFile) as f2:
        json_final = file.read(f2)

    patch = jsonpatch.JsonPatch.from_diff(json_initial, json_final)
    logging.info(
        "prefilter_json_files_then_compare:differences before patching: %d",
        len(list(patch)),
    )

    json_initial_filtered = prefilter(json_initial, args.initial_prefilter)
    json_final_filtered = prefilter(json_final, args.finalPreFilter)

    patch_after_filtering = jsonpatch.JsonPatch.from_diff(
        json_initial_filtered, json_final_filtered
    )
    differences_after_patching = list(patch_after_filtering)
    logging.info(
        "prefilter_json_files_then_compare: differences after patching: %d",
        len(differences_after_patching),
    )

    if args.printDifferences:
        for patchline in differences_after_patching:
            print(json.dumps(patchline))

    print(len(differences_after_patching))
    return len(differences_after_patching)


def Json_Diff_Check_Keyword(json_before, json_after, filter_before, filter_after):
    input_argv = [
        "-i",
        json_before,
        "-f",
        json_after,
        "-ipf",
        filter_before,
        "-fpf",
        filter_after,
        "-pd",
    ]
    sys.argv[1:] = input_argv
    logging.info("starting. constructed command line: %s", sys.argv)
    return Json_Diff_Check()


def parse_args(args):
    parser = argparse.ArgumentParser(
        description="both initial and final json files are compared for differences. "
        "The program returns 0 when the json contents are the same, or the "
        "number of"
        " differences otherwise. Both json files can be prefiltered for "
        "certain patterns"
        " before checking the differences"
    )

    parser.add_argument(
        "-i",
        "--initialFile",
        required="true",
        dest="initialFile",
        action="store",
        help="initial json file",
    )
    parser.add_argument(
        "-f",
        "--finalFile",
        required="true",
        dest="finalFile",
        action="store",
        help="final json file",
    )
    parser.add_argument(
        "-ipf",
        "--initial_prefilter",
        dest="initial_prefilter",
        help="File with pre-filtering patterns to apply to the initial json file before comparing",
    )
    parser.add_argument(
        "-fpf",
        "--finalPreFilter",
        dest="finalPreFilter",
        help="File with pre-filtering patterns to apply to the final json file before comparing",
    )
    parser.add_argument(
        "-pd",
        "--printDifferences",
        action="store_true",
        help="on differences found, prints the list of paths for the found differences before exitting",
    )
    parser.add_argument(
        "-v",
        "--verbose",
        dest="verbose",
        action="store_true",
        help="generate log information",
    )
    return parser.parse_args(args)


def Json_Diff_Check():
    args = parse_args(sys.argv[1:])

    if hasattr(args, "verbose"):
        if args.verbose:
            logging.basicConfig(level=logging.DEBUG)

    if args.printDifferences:
        logging.info("(will print differences)")

    result = prefilter_json_files_then_compare(args)
    return result


if __name__ == "__main__":
    Json_Diff_Check()

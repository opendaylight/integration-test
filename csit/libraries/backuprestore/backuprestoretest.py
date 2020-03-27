import unittest
import sys
import JsonDiffTool

"""
Unit tests for the Json Diff Tool library
Updated: 2017-04-24
"""

__author__ = "Diego Granados"
__copyright__ = "Copyright(c) 2017, Ericsson."
__license__ = "New-style BSD"
__email__ = "diego.jesus.granados.lopez@ericsson.com"


class PathConversionTest(unittest.TestCase):
    """
    Conversions from jsonpath paths to jsonpatch patches used to remove the element pointed by the path
    """

    def testArrayElementConversion(self):
        self.assertEquals(
            '[{"op":"remove","path":"/ietf-yang-library:modules-state/module/56"}]',
            JsonDiffTool.from_path_to_jsonpatch(
                "/ietf-yang-library:modules-state/module/56"
            ),
            "Array element conversion failed!",
        )

    def testMapValueElementConversion(self):
        self.assertEquals(
            '[{"op":"remove","path":"/ietf-yang-library:modules-state/module/blablah"}]',
            JsonDiffTool.from_path_to_jsonpatch(
                "/ietf-yang-library:modules-state/module/blablah"
            ),
            "Array element conversion failed!",
        )


class JsonDiffToolTest(unittest.TestCase):
    """
    Tests for the tool itself, including both command-line and RIDE keyword invokation style
    """

    def testSimpleDifferenceCountingWithoutFiltering(self):
        """
        Identical documents
        """
        self.assertEquals(
            0,
            JsonDiffTool.Json_Diff_Check_Keyword(
                "testinput/arrayTwoNames.json",
                "testinput/arrayTwoNamesCopy.json",
                "",
                "",
            ),
            "failed! (expected 0 differences)",
        )

    def testEqualFilesWithScrambledArrayOrder(self):
        """
        This is moving an array element from one position to other. RFC 6902 describes this as "moving
        a value", but this jsonpatch implementation constructs a patch using remove + add. Acceptable though
        """
        self.assertEquals(
            2,
            JsonDiffTool.Json_Diff_Check_Keyword(
                "testinput/arrayTwoNames.json",
                "testinput/arrayTwoNamesReversed.json",
                "",
                "",
            ),
            "failed! (expected 2 differences)",
        )

    def testEqualFilesWithChangedAttributeOrder(self):
        """
        Attributes in different order. It's not a difference
        """
        self.assertEquals(
            0,
            JsonDiffTool.Json_Diff_Check_Keyword(
                "testinput/setTwoNames.json",
                "testinput/setTwoNamesReversed.json",
                "",
                "",
            ),
            "failed! (expected 0 differences)",
        )

    def testSimpleDifferenceSecondFileWithExtraAttrib(self):
        self.assertEquals(
            1,
            JsonDiffTool.Json_Diff_Check_Keyword(
                "testinput/setTwoNames.json",
                "testinput/setTwoNamesExtraAttrib.json",
                "",
                "",
            ),
            "failed! (expected 1 differences)",
        )

    def testSimpleDifferenceCountingWithoutFiltering(self):
        """
        Example coming from a true daexim export. No prefilters used
        """
        input_argv = [
            "-i",
            "testinput/mainTestCase/odl_backup_operational_before.json",
            "-f",
            "testinput/mainTestCase/odl_backup_operational_after.json",
        ]
        sys.argv[1:] = input_argv
        self.assertEquals(
            16,
            JsonDiffTool.Json_Diff_Check(),
            "main failed! expected 16 differences, result was: "
            + str(JsonDiffTool.Json_Diff_Check()),
        )

    def testSimpleDifferenceCountingUsingSingleMatchingBeforeFilter(self):
        """
        Using a prefilter for the initial file The prefilter contains one expression only
        """
        input_argv = [
            "-i",
            "testinput/mainTestCase/odl_backup_operational_before.json",
            "-f",
            "testinput/mainTestCase/odl_backup_operational_after.json",
            "-ipf",
            "testinput/mainTestCase/json_prefilter.conf",
            "-v",
        ]
        sys.argv[1:] = input_argv
        self.assertEquals(
            15,
            JsonDiffTool.Json_Diff_Check(),
            "main failed! expected 15 differences, result was: "
            + str(JsonDiffTool.Json_Diff_Check()),
        )

    def testSimpleDifferenceCountingUsingMatchingBeforeFilterMatchingTwoEntries(self):
        """
        Using a prefilter for the initial file The prefilter contains two expressions
        """
        input_argv = [
            "-i",
            "testinput/mainTestCase/odl_backup_operational_before.json",
            "-f",
            "testinput/mainTestCase/odl_backup_operational_after.json",
            "-ipf",
            "testinput/mainTestCase/json_prefilter_two_matches.conf",
            "-v",
        ]
        sys.argv[1:] = input_argv
        self.assertEquals(
            14,
            JsonDiffTool.Json_Diff_Check(),
            "main failed! expected 14 differences, result was: "
            + str(JsonDiffTool.Json_Diff_Check()),
        )

    def testSimpleDifferenceCountingUsingSingleMatchingBeforeFilter(self):
        """
        Using a prefilter for both initial and final files
        """
        input_argv = [
            "-i",
            "testinput/mainTestCase/odl_backup_operational_before.json",
            "-f",
            "testinput/mainTestCase/odl_backup_operational_after.json",
            "-ipf",
            "testinput/mainTestCase/json_prefilter.conf",
            "-fpf",
            "testinput/mainTestCase/json_postfilter.conf",
            "-v",
        ]
        sys.argv[1:] = input_argv
        self.assertEquals(
            16,
            JsonDiffTool.Json_Diff_Check(),
            "main failed! expected 16 differences, result was: "
            + str(JsonDiffTool.Json_Diff_Check()),
        )

    def testUsingANonExistingFile(self):
        """
        The second file does not exist. Exception expected
        """
        self.assertRaises(
            IOError,
            JsonDiffTool.Json_Diff_Check_Keyword,
            "testinput/arrayTwoNames.json",
            "testinput/thisFileDoesNotExist.json",
            "",
            "",
        )

    def testNotPassingAMandatoryParameter(self):
        """
        Both initial and final json files are mandatory
        """
        input_argv = ["-f", "testinput/mainTestCase/odl_backup_operational_after.json"]
        # parser = JsonDiffTool.parseArgs(input_argv)

        with self.assertRaises(SystemExit) as cm:
            JsonDiffTool.parse_args(input_argv)

        # 2 for missing argument
        self.assertEqual(cm.exception.code, 2)

    def testUsingNotMatchingFilterExpressions(self):
        """
        Using prefilter files whose expressions match nothing
        """
        input_argv = [
            "-i",
            "testinput/mainTestCase/odl_backup_operational_before.json",
            "-f",
            "testinput/mainTestCase/odl_backup_operational_after.json",
            "-ipf",
            "testinput/mainTestCase/json_prefilter_zero_matches.conf",
            "-fpf",
            "testinput/mainTestCase/json_prefilter_zero_matches.conf",
            "-v",
        ]
        sys.argv[1:] = input_argv
        self.assertEquals(
            16,
            JsonDiffTool.Json_Diff_Check(),
            "main failed! expected 16 differences, result was: "
            + str(JsonDiffTool.Json_Diff_Check()),
        )


if __name__ == "__main__":
    unittest.main()

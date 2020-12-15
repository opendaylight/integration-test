from xmldiff.main import diff_texts
from xmldiff.actions import MoveNode


def compare(xml_text1, xml_text2, strict=False):
    diffs = diff_texts(xml_text1, xml_text2)
    if not strict:
        diffs = [diff for diff in diffs if not isinstance(diff, MoveNode)]
    return diffs


def are_same(xml_text1, xml_text2, strict=False):
    diffs = compare(xml_text1, xml_text2, strict)
    return len(diffs) == 0

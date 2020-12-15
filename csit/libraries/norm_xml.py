def loads_sorted(text, strict=False):
    """Return Python object with sorted arrays and dictionary keys."""
    object_decoded = _json.loads(text, cls=_Decoder, object_hook=_Hsfod)
    return object_decoded


def dumps_indented(obj, indent=1):
    """
    Wrapper for json.dumps with default indentation level.

    The main value is that BuiltIn.Evaluate cannot easily accept Python object
    as part of its argument.
    Also, allows to use something different from RequestsLibrary.To_Json

    """
    pretty_json = _json.dumps(obj, separators=(",", ": "), indent=indent)
    return pretty_json + "\n"  # to avoid diff "no newline" warning line

def normalize_xml_text(
    text,
    strict=False,
    indent=1,
    keys_with_bits=[],
    keys_with_volatiles=[],
    jmes_path=None,
):
    """
    Attempt to return sorted indented JSON string.

    If jmes_path is set the related subset of JSON data is returned as
    indented JSON string if the subset exists. Empty string is returned if the
    subset doesn't exist.
    Empty string is returned if text is not passed.
    If parse error happens:
    If strict is true, raise the exception.
    If strict is not true, return original text with error message.
    If keys_with_bits is non-empty, run sort_bits on intermediate Python object.
    """

    if not text:
        return ""

    #if jmes_path:
    #    json_obj = _json.loads(text)
    #    subset = jmespath.search(jmes_path, json_obj)
    #    if not subset:
    #        return ""
    #    text = _json.dumps(subset)

    #try:
    object_decoded = loads_sorted(text)
    #except ValueError as err:
    #    if strict:
    #        raise err
    #    else:
    #        return str(err) + "\n" + text
    #if keys_with_bits:
    #    sort_bits(object_decoded, keys_with_bits)
    #if keys_with_volatiles:
    #    hide_volatile(object_decoded, keys_with_volatiles)

    pretty_json = dumps_indented(object_decoded, indent=indent)

    return pretty_json

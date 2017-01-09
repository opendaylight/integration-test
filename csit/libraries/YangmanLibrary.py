"""
Yangman library for additional keywords needed for testing Yangman module.
Author: Dasa Simkova
"""


def verify_string_contains_substring(full_string, substring):
    """Removes leading and trailing spaces from a chosen string."""
    if substring in full_string:
        return True
    else:
        return False

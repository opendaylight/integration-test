"""
Library for 'tools' used in mdsal project.
"""

from robot.api import logger


def get_autorelease_dir(bundle_url):
    """Extracts autoreelase-xxxx part of the url if this is present

    :param bundle_url: url
    :type bundle_url: str

    :return: part of the given url with autorelease keyword or None
    :rtype: string or None
    """
    logger.info("Bundle url:{}".format(bundle_url))
    if 'autorelease' not in bundle_url:
        return None
    return [part for part in bundle_url.split("/") if 'autorelease' in part][0]

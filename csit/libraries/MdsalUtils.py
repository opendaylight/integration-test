"""Library"""

def get_autorelease_dir(bundle_url):
    if 'autorelease' not in url:
        return None
    return [part for part in url.split("/") if 'autorelease' in part][0]   

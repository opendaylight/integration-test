"""Library"""

def get_autorelease_dir(bundle_url):
    if 'autorelease' not in bundle_url:
        return None
    return [part for part in bundle_url.split("/") if 'autorelease' in part][0]   

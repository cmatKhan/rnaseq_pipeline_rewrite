import requests
from urllib.request import HTTPError

def postData(url, data, **kwargs):
    """
        post data to url
        :params url: url to the site (this should be complete, eg to update counts http://13.59.167.2/api/Counts) NOTE: pass this url, no id, etc, and use the kwargs option for a put
        :params data: the body of the request
        :throws: HTTPError
    """
    try:
        r = requests.post(url, data=data)
        r.raise_for_status()
    except HTTPError:
        raise Exception(r.reason)
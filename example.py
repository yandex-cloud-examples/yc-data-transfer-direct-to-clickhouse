# -*- coding: utf-8 -*-
# Common code example: https://yandex.ru/dev/direct/doc/examples-v5/python3-requests-campaigns.html
import sys
import os
import json

import requests
import awswrangler as wr
import pandas as pd

def foo(event, context):
    if sys.version_info < (3,):
        def u(x):
            try:
                return x.encode("utf8")
            except UnicodeDecodeError:
                return x
    else:
        def u(x):
            if type(x) == type(b''):
                return x.decode('utf8')
            else:
                return x

    # --- Input data ---

    #  The Campaigns service address for JSON requests

    # Uncomment the line below if you use non-sandbox campaign
    # CampaignsURL = 'https://api.direct.yandex.com/json/v5/campaigns'
    
    # Uncomment the line below if you use sandbox. Comment it otherwise
    CampaignsURL = 'https://api-sandbox.direct.yandex.com/json/v5/campaigns'

    # OAuth token of the user on behalf of which requests will be executed
    TOKEN = os.environ['TOKEN']

    # Object Storage bucket where the file will be placed
    BUCKET = os.environ['BUCKET']

    # The login of the advertising agency's client
    # Uncomment the line below if the requests are made on behalf of an advertising agency
    # clientLogin = 'CLIENT_LOGIN'

    # --- Making a request and processing the results ---

    #  Creating HTTP header of the request
    headers = {"Authorization": "Bearer " + TOKEN,
            # "Client-Login": clientLogin,  # Uncomment that string if the requests are made on behalf of an advertising agency
            "Accept-Language": "ru",  # Language of the response messages
            }

    # Creating the request body
    body = {"method": "get", # The method used.
            "params": {"SelectionCriteria": {}, # Campaign selection criteria. To obtain all campaigns, leave it blank
                    "FieldNames": ["Id", "Name"] # Parameters to obtain
                    }}
    
    # Converting the request body to JSON
    jsonBody = json.dumps(body, ensure_ascii=False).encode('utf8')

    # Request execution
    try:
        result = requests.post(CampaignsURL, jsonBody, headers=headers)

        # Debugging information. Uncomment the lines below to analyze the application behavior

        # print("Request headers: {}".format(result.request.headers))
        # print("Request: {}".format(u(result.request.body)))
        # print("Response headers: {}".format(result.headers))
        # print("Response: {}".format(u(result.text)))
        # print("\n")

        # Processing the request results
        if result.status_code != 200 or result.json().get("error", False):
            print("An error has occurred while connecting the Yandex Direct API server.")
            print("Error code: {}".format(result.json()["error"]["error_code"]))
            print("Error description: {}".format(u(result.json()["error"]["error_detail"])))
            print("RequestId: {}".format(result.headers.get("RequestId", False)))
        else:
            print("RequestId: {}".format(result.headers.get("RequestId", False)))
            print("Score information: {}".format(result.headers.get("Units", False)))

            json_result = result.json()

            df_result = pd.DataFrame(json_result['result']['Campaigns'])
            wr.config.s3_endpoint_url = 'https://storage.yandexcloud.net'

            wr.s3.to_parquet(
                df=df_result,
                path=f's3://{BUCKET}/',
                dataset=True)

    # Failed to connect the Yandex Direct API server
    except requests.exceptions.ConnectionError:
        print("An error has occurred while connecting the Yandex Direct API server. Repeat the request later")

    # Another error has occurred
    except Exception as exc:
        print(str(exc))
        print("An unexpected error has occurred. Analyze the application behavior")

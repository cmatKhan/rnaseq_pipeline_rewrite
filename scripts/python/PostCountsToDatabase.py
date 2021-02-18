    #!/usr/bin/env python

    import pandas as pd
    import requests
    import json
    from urllib.request import HTTPError
    from rnaseq_tools import utils
    from rnaseq_tools.StandardDataObject import StandardData

    #from urllib.request import urlopen, HTTPError
    #try:
    #html = urlopen('http://www.test.com')
    #except HTTPError as e:
    #print(e)
    #else:
    #print('its ok')

    sd = StandardData(interactive=True)
    # TODO: SET PARAMS FOR OVERWRITE = T/F AND ALTERNATE BTWN PUT/POST DEPENDING ON ERROR RESPONSE

    # read count_file in as pandas df
    count_file_df = pd.read_csv("${read_count_tsv}", sep='\t', names=['htseq_col', "${fastq_simple_name}"])

    # remove the htseq stuff at the bottom of the file (it starts with __, eg __ambiguous)
    gene_counts = count_file_df[~count_file_df.htseq_col.str.startswith("__")]

    # maybe push this into its own channel?
    htseq_log_data = count_file_df[count_file_df.htseq_col.str.startswith("__")] # TODO: SEND THIS INTO HTSEQ QC CHANNEL? Handle here?

    # get the count dict in structure {fastqFileName: [counts]}
    count_dict = count_file_df.drop(['htseq_col'], axis=1).to_dict(orient="list")

    # this is the body of the request. fastqFileNumber is the foreign key of Counts
    data = {'fastqFileNumber': "${fastq_file_number}", 'rawCounts': json.dumps(count_dict)}

    # TODO: make this a parameter
    url = 'http://13.59.167.2/api/Counts/'

    try:
        utils.postData(url, data, sd.logger)
    except(HTTPError):
        sd.logger.warning('COUNTS http post failed on fastq: %s, fastqfilenumber: %s' %("${fastq_simple_name}", "${fastq_file_number}"))
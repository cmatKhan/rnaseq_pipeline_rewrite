

import re

def parseAlignmentLog(alignment_log_file_path):
    """
        parse the information on the alignment out of a novoalign log
        :param alignment_log_file_path: the filepath to a novoalign alignment log
        :returns: a dictionary of the parsed data of the input file
    """
    library_metadata_dict = {}
    alignment_regex_dict = {'LIBRARY_SIZE': r"(?<=Read Sequences:\s)\s*\d*",
                            'UNIQUE_ALIGNMENT': r"(?<=Unique Alignment:\s)\s*\d*",
                            'MULTI_MAP': r"(?<=Multi Mapped:\s)\s*\d*",
                            'NO_MAP': r"(?<=No Mapping Found:\s)\s*\d*",
                            'HOMOPOLY_FILTER': r"(?<=Homopolymer Filter:\s)\s*\d*",
                            'READ_LENGTH_FILTER': r"(?<=Read Length:\s)\s*\d*"}

    # open the log path
    alignment_file = open(alignment_log_file_path, 'r')
    alignment_file_text = alignment_file.read()
    # loop over alignment_regex dict and enter values extracted from alignment_file into alignment_metadata_dict
    for alignment_category, regex_pattern in alignment_regex_dict.items():
        # extract the value corresponding to the alignment_category regex (see alignment_regex_dict)
        try:
            extracted_value = int(re.findall(regex_pattern, alignment_file_text)[0])
        except ValueError:
            msg = 'problem with file %s' % alignment_log_file_path
            print(msg)
        except IndexError:
            print('No %s in %s. Value set to 0' % (alignment_category, alignment_log_file_path))
            extracted_value = 0
        # check that the value is both an int and not 0
        if isinstance(extracted_value, int):
            library_metadata_dict.setdefault(alignment_category, extracted_value)
        else:
            print('cannot find %s in %s' % (alignment_category, alignment_log_file_path))

    # close the alignment_file and return
    alignment_file.close()

    return library_metadata_dict

    output: {'LIBRARY_SIZE': 35003, 'UNIQUE_ALIGNMENT': 22737, 'MULTI_MAP': 1986, 'NO_MAP': 10233, 'HOMOPOLY_FILTER': 47, 'READ_LENGTH_FILTER': 0}
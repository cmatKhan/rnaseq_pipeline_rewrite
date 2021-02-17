process writePipelineInfo {

    executor "local"
    beforeScript "ml rnaseq_pipeline"

    input:
        tuple val(run_directory), val(organism), val(strandedness) from pipeline_info_ch

    script:
"""
#!/usr/bin/env python

from rnaseq_tools.OrganismDataObject import OrganismData
from rnaseq_tools import utils
import os

# instantiate OrganismDataObject (see brentlab rnaseq_pipeline)
od = OrganismData(organism = "${organism}", interactive=True)

# create pipeline_info subdir of in rnaseq_pipeline/align_count_results/${organism}_pipeline_info
pipeline_info_subdir_path = os.path.join(od.align_count_results, "${run_directory}", "${organism}_pipeline_info")
utils.mkdirp(pipeline_info_subdir_path)

# write version info from the module .lua file (see the .lua whatis statements)
pipeline_info_txt_file_path = os.path.join(pipeline_info_subdir_path, 'pipeline_info.txt')
cmd_pipeline_info = 'module whatis rnaseq_pipeline 2> %s' %pipeline_info_txt_file_path
utils.executeSubProcess(cmd_pipeline_info)

# include the date processed in pipeline_info_subdir_path/pipeline_into.txt
with open(pipeline_info_txt_file_path, "a+") as file:
    file.write('')
    current_datetime = od.year_month_day + '_' + utils.hourMinuteSecond()
    file.write('Date processed: %s' %current_datetime)
    file.write('')

# set annotation_file
if "${organism}" == 'KN99' and "${strandedness}" == 'no':
      annotation_file = od.annotation_file_no_strand
else:
    annotation_file = od.annotation_file
# include the head of the gff/gtf in pipeline_info
cmd_annotation_info = 'head %s >> %s' %(annotation_file, pipeline_info_txt_file_path)
utils.executeSubProcess(cmd_annotation_info)

# TODO: try copying nextflow jobscript to pipeline_info

"""
}

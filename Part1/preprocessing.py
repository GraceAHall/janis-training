
# import workflow builder
from janis_core import WorkflowBuilder, String

# Bioinformatics types
from janis_bioinformatics.data_types import FastqGzPairedEnd, FastaWithIndexes, Bam

# Tools
from janis_bioinformatics.tools.bwa import BwaMemLatest
from janis_bioinformatics.tools.samtools import SamToolsView_1_9
from janis_bioinformatics.tools.gatk4 import (
    Gatk4MarkDuplicates_4_1_4,
    Gatk4SortSam_4_1_4,
    Gatk4SetNmMdAndUqTags_4_1_4,
)


w = WorkflowBuilder("preprocessingWorkflow")


w.input("sample_name", String)
w.input("read_group", String)
w.input("fastq", FastqGzPairedEnd)
w.input("reference", FastaWithIndexes)
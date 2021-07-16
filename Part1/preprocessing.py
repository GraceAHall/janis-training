from janis_core import WorkflowBuilder, String

# Import bioinformatics types
from janis_bioinformatics.data_types import FastqGzPairedEnd, FastaWithIndexes, Bam

# Import bioinformatics tools
from janis_bioinformatics.tools.bwa import BwaMemLatest
from janis_bioinformatics.tools.samtools import SamToolsView_1_9
from janis_bioinformatics.tools.gatk4 import (
    Gatk4MarkDuplicates_4_1_4,
    Gatk4SortSam_4_1_4,
    Gatk4SetNmMdAndUqTags_4_1_4,
)

# Construct the workflow here
w = WorkflowBuilder("preprocessingWorkflow")

w.input("sample_name", String)
w.input("read_group", String)
w.input("fastq", FastqGzPairedEnd)
w.input("reference", FastaWithIndexes)

w.step(
    "bwamem",   # step identifier
    BwaMemLatest(
        reads=w.fastq,
        readGroupHeaderLine=w.read_group,
        reference=w.reference,
        markShorterSplits=True,
    )
)

w.step(
    "samtoolsview",
    SamToolsView_1_9(
        sam=w.bwamem.out
    )
)

w.step(
    "markduplicates",
    Gatk4MarkDuplicates_4_1_4(
        bam=w.samtoolsview.out, 
        assumeSortOrder="queryname"
    ),
)

w.output("tmp_out_unsortedbam", Bam, source=w.markduplicates.out)
#!/usr/bin/env cwl-runner
class: Workflow
cwlVersion: v1.2

requirements:
- class: InlineJavascriptRequirement
- class: StepInputExpressionRequirement
- class: MultipleInputFeatureRequirement

inputs:
- id: sample_name
  type: string
- id: read_group
  type: string
- id: fastq
  type:
    type: array
    items: File
- id: reference
  type: File
  secondaryFiles:
  - pattern: .fai
  - pattern: .amb
  - pattern: .ann
  - pattern: .bwt
  - pattern: .pac
  - pattern: .sa
  - pattern: ^.dict
- id: bwamem_markShorterSplits
  doc: Mark shorter split hits as secondary (for Picard compatibility).
  type: boolean
  default: true
- id: markduplicates_assumeSortOrder
  doc: |-
    If not null, assume that the input file has this order even if the header says otherwise. Exclusion: This argument cannot be used at the same time as ASSUME_SORTED. The --ASSUME_SORT_ORDER argument is an enumerated type (SortOrder), which can have one of the following values: [unsorted, queryname, coordinate, duplicate, unknown]
  type: string
  default: queryname
- id: bwamem_runtime_memory
  type: float?
- id: bwamem_runtime_cpu
  type: int?
- id: bwamem_runtime_disks
  type: int?
- id: bwamem_runtime_seconds
  type: int?
- id: samtoolsview_runtime_memory
  type: float?
- id: samtoolsview_runtime_cpu
  type: int?
- id: samtoolsview_runtime_disks
  type: int?
- id: samtoolsview_runtime_seconds
  type: int?
- id: markduplicates_runtime_memory
  type: float?
- id: markduplicates_runtime_cpu
  type: int?
- id: markduplicates_runtime_disks
  type: int?
- id: markduplicates_runtime_seconds
  type: int?

outputs:
- id: tmp_out_unsortedbam
  type: File
  outputSource: markduplicates/out

steps:
- id: bwamem
  label: BWA-MEM
  in:
  - id: reference
    source: reference
  - id: reads
    source: fastq
  - id: readGroupHeaderLine
    source: read_group
  - id: markShorterSplits
    source: bwamem_markShorterSplits
  - id: runtime_memory
    source: bwamem_runtime_memory
  - id: runtime_cpu
    source: bwamem_runtime_cpu
  - id: runtime_disks
    source: bwamem_runtime_disks
  - id: runtime_seconds
    source: bwamem_runtime_seconds
  run: tools/bwamem_v0_7_15.cwl
  out:
  - id: out
- id: samtoolsview
  label: 'SamTools: View'
  in:
  - id: sam
    source: bwamem/out
  - id: runtime_memory
    source: samtoolsview_runtime_memory
  - id: runtime_cpu
    source: samtoolsview_runtime_cpu
  - id: runtime_disks
    source: samtoolsview_runtime_disks
  - id: runtime_seconds
    source: samtoolsview_runtime_seconds
  run: tools/SamToolsView_1_9_0.cwl
  out:
  - id: out
- id: markduplicates
  label: 'GATK4: Mark Duplicates'
  in:
  - id: bam
    source:
    - samtoolsview/out
    linkMerge: merge_nested
  - id: assumeSortOrder
    source: markduplicates_assumeSortOrder
  - id: runtime_memory
    source: markduplicates_runtime_memory
  - id: runtime_cpu
    source: markduplicates_runtime_cpu
  - id: runtime_disks
    source: markduplicates_runtime_disks
  - id: runtime_seconds
    source: markduplicates_runtime_seconds
  run: tools/Gatk4MarkDuplicates_4_1_4_0.cwl
  out:
  - id: out
  - id: metrics
id: preprocessingWorkflow

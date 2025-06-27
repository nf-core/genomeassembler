branch refactor-assemblers:

The idea is to move from pipepline / run level choice of assemblers towards a per-sample level choice.
Most obviously this will facilitate comparisons between assembly strategies for the same reads across assemblers from one run, which is probably an important use-case.
Still, pipeline-level settings should ne propagated (but sample-levels should take priority) to also make one-size-fits-all runs possible.

Things to do:

    - Modify sample sheet
        - Single assembler (ONT or HIFI)
        - Hybrid assembler (ONT and HIFI)
        - Assembler scaffolding (ONT assembler, HIFI assembler)
        - Columns to add:
          -> strategy:
                - "single"
                - "hybrid"
                - "scaffold" -> Assembler 1 will do ONT, assembler 2 will do HiFi.
          -> assembler1 (required for single and hybrid): ["flye","hifiasm"]
          -> assembler1_args (optional; can be global via params.assembler1_args)
          -> assembler2 (required for scaffold): ["flye","hifiasm"]
          -> assembler2_args (optional; can be global via params.assembler2_args)
          -> assembly_scaffolding (required for scaffold): ["ont_on_hifi", "hifi_on_ont"]
          -> QC_reads: ["ont", "hifi"] 
          -> genome_size: genome_size
          -> polish: "medaka", "pilon", "medaka+pilon" (both polish initial assembly), "medaka-pilon" (first medaka then pilon)
    
    - Params to remove:
        - ont
        - hifi
        - genome_size

    - Refactor pipeline to carry this information.

        - Probably should make use of channel branching to achieve this reasonably

# The main channel

This channel is of map type. This means that it is not suitable for many things, but positional retrieval of entries from a channel that is not static seems like a way to create problems.
This means that for joining, some dropping of k/v pairs and back-and-forth between map and list is required.
The main channel is intially defined from the sample-sheet, but extended / modified throughout the pipeline run, it contains a number of entries. 
The main chnanel goes into each subworkflow and comes out of each subworkflow.
Conditional execution within subworkflows is done via branching of the main channel,
processing of the branch that is worked on, and mixing back of modified main channel with the untouched branch.
The subworkflow emits ch_main into the workflow.
To enter into processes (!) input (list) channels are created via (multi)mapping.

This means that there is no conditional execution of subworkflows, but everything goes into all subworkflows, but may come out untouched.

# Reporting

Generally, reporting works as before, but an additional 

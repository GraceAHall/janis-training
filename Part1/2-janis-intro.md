# Janis Workshop (1.2)

## Introduction to Janis

Janis is workflow framework that uses Python to construct a declarative workflow. It has a simple workflow API within Python that you use to build your workflow. Janis converts your pipeline to the Common Workflow Language (CWL) or Workflow Description Language (WDL) for execution, which can then be published, shared or archived. 

This workshop uses a bioinformatics focus example, but Janis is a generic workflow assistant and can be used outside of the computational genomics.

- Janis GitHub: https://github.com/PMCC-BioinformaticsCore/janis
- Janis Documentation: https://janis.readthedocs.io/en/latest

## Foundations

- A workflow is a collection of tools that are run in an organised manner.

- A workflow specification is a format that exactly describes the relationship between your tools. Popular workflow specification types include:

    - Common Workflow Language (CWL)
    - Workflow Description Language (WDL)
    - [_Unsupported_] Nextflow
    - [_Unsupported_] Snakemake

- YAML (.yml) is a file-format for specifying key-value pairs (like a dictionary). YAML is very similar to, and is in fact a superset of JSON.

### What is Janis

Janis is a project that aims to address two questions:

- How do we build pipelines that can run everywhere?
- How can we make running pipelines easier?

In fact, Janis is actually split into two components that addresses these questions separately:

- `janis-core` - Helps users **build** portable pipelines using existing workflow **specifications**.
- `janis-assistant` - Helps users **run** pipelines using existing workflow **engines**.

### Fundamental features

- Janis uses an _abstracted execution environment_ which removes the shared file system you may be used to in other pipelining systems.

    - For a file or directory to be available to your tool, you need to EXPLICITLY include it. 
        - This includes associated files, if you want an indexed bam, you must use the [`BamBai`](https://janis.readthedocs.io/en/latest/datatypes/indexedbam.html) type. 

    - Outputs of a _tool_ must be EXPLICITLY collected to be used by future steps, else they will be removed.

    - Outputs of a workflow must be EXPLICITLY collected.

    - A step's requirements (its inputs) can be an input to a workflow, or the output of a previous step (hence creating a dependency).

        ![Diagram of variant-calling workflow showing connections](graphics/variantcaller.png)

- In Janis, all tasks are executed inside a isolated virtual environment called a [_Container_](https://www.docker.com/resources/what-container). Docker and Singularity are two common container types. (Docker containers can be executed by Singularity.)

### Setup

A virtual environment is the best way to install Janis. It contains all the dependencies separately, and avoid polluting your local Python installation. It also preserves the version of Janis in a reproducible way.


1. Create a directory for all the activities of this workshop.

    ```bash
    # from now on, we will refer to this directory as $JW (it stands for janis workshop)
    mkdir janis-workshop
    cd janis-workshop
    
    # create an environment variable for this directory for easier reference.
    export JW=$(pwd)
   ```

2. Create and activate a virtualenv:
   ```bash
    # create virtual environment
    python3 -m venv env

    # activate the virtual environment
    source env/bin/activate
    ```
   
    > When you execute `which python`, you should get `$JW/env/bin/python`

3. Install Janis through PIP:

    ```bash
    pip install janis-pipelines
    ```
   > When you execute `which janis`, you should get `$JW/env/bin/janis`
   > 
   > If that is not the path you see, we want to exit and re-activate the virtual environment
   > 
   > ```
   > # To exit
   > deactivate
   > 
   > # To turn on the virtual environment again
   > source env/bin/activate
   > ```

4. Test that Janis (and associated modules) were installed:

    ```bash
    janis -v
    #--------------------  -------
    #janis-core            v0.11.x
    #janis-assistant       v0.11.x
    #janis-templates       v0.11.x
    #janis-unix            v0.11.x
    #janis-bioinformatics  v0.11.x
    #janis-pipelines       v0.11.x
    #--------------------  -------
    ```

#### Download data

We will start with downloading all the test data required for this workshop. In this workshop, we use:

- A test sample based on [Genome-In-A-Bottle NA12878](https://github.com/genome-in-a-bottle/giab_data_indexes), with reads being cut down to a single gene region (chr17:43044045-43125733)
- A test reference genome (and other resource bundle databases) derived from human HG38 reference provided by [GATK Resource Bundle]( https://console.cloud.google.com/storage/browser/genomics-public-data/references/hg38/v0/), cut down to a single gene region (chr17:43044045-43125733).

```bash
# You might see warnings when untarring this workshop data due
# to a difference of tar versions when archiving on macOS.

wget -q -O- "https://github.com/PMCC-BioinformaticsCore/janis-training/raw/master/resources/data.tar" \
    | tar -xv
```



The download contains folders for data, references and the solutions. You can confirm this with:

```bash
ls -lGh
drwxr-xr-x@  5 user  staff   160B  7 May 19:47 data
drwxr-xr-x   9 user  staff   288B  7 May 19:08 env
drwxr-xr-x@  4 user  staff   128B  7 May 19:47 part1
drwxr-xr-x@  6 user  staff   192B  7 May 19:47 part2
drwxr-xr-x@ 14 user  staff   448B  7 May 19:47 reference
```

### Setting up Janis 

Next, let's initialise our Janis environment. This step is only required on the first time we setup Janis on a new environment.

```bash
janis init local 
```

Running this command will create a configuration file at `~/.janis/janis.conf`.

We'll use a text editor to edit to the first line in our template from `engine: cromwell` to `engine: cwltool`:

The file should look like:

```yaml
engine: cwltool
notifications:
  email: null
template:
  id: local
```

Janis will automatically use the config for the rest of the workshop. 

> Although we've used the `local` template, you could instead use `singularity` or use an advanced configuration (like `slurm_singularity` or `pbs_singularity`), important when used in High Performance Computing (HPC) environments. 

### How does Janis run a workflow?

Janis leverages community driven engines to run workflows. For this workshop, we will use the [cwltool](https://github.com/common-workflow-language/cwltool) execution engine to run translated Janis workflow (in Common Workflow Language [CWL](https://www.commonwl.org/)) using Dockerised tools. CWLTool is automatically installed with the Janis assistant.

For our tests, Janis will:

- Convert an example workflow to CWL,
- Run the CWL workflow with cwltool,
- Watch the progress of the workflow,
- Copy the outputs, and remove the execution directory on success.

> It's important to note that building workflows in Janis does NOT limit you to running with Janis. You are free to take the exported CWL and WDL specifications to run your workflow on your own platform.


### Running a simple test workflow 

To test that Janis is configured properly, we will run a simple workflow called [`Hello`](https://janis.readthedocs.io/en/latest/tools/unix/hello.html) (click the link to see the documentation). We'll supply an input called `inp`, with value `"Hello, World"`, this will get printed to stdout, and this stdout is captured as an output. This will test that Janis can run in your environment correctly. 

We must specify an output directory (`-o`) to contain the execution and outputs, we'll ask Janis to output our results to a subdirectory called `my_hello`. 

```bash
janis run -o my_hello hello --inp "Hello, World"
```

This command will:

- Create an output directory called `my_hello` (relative to the current directory)
- Convert `hello` Janis workflow to `hello` CWL workflow
- Submit workflow to the cwltool and run a task that calls "echo"
- Collect the results

You will see logs from cwltool in the terminal. There is a number of statements that are worth highlighting:

```bash
... [INFO]: Starting task with id = 'a6acf2'
... [INFO]: CWLTool has started with pid=41562
... # Selected CWLTool logs
... [INFO]: Task has finished with status: Completed
... [INFO]: View the task outputs: file:///$JW/my_hello
```

We can track the progress of our workflow with:

```bash
janis watch my_hello/
```

You will see a progress screen like the following 

```
SID:        a6acf2
EngId:      a6acf2
Engine:     cwltool

Task Dir:   $JW/my_hello
Exec Dir:   $JW/my_hello/janis

Status:     completed
Duration:   9s
Start:      2020-07-15T08:14:01.408996+00:00
Finish:     2020-07-15T08:14:09.941033+00:00
Updated:    1m:05s ago (2020-07-15T08:14:09+00:00)

Jobs: 
        [✓] hello (7s)   

```


In our output folder, there are two items (`ls -l my_hello`):
```
drwxr-xr-x  12 user  staff  384  7 May 19:50 janis
-rw-r--r--   1 user  staff   13  7 May 19:49 out
```

The output to the task is called `out`, as this is the name of the output that the `hello` tool specifies.

```bash
cat my_hello/out
# Hello, world!
```

> The `janis` folder contains information about the execution, including `logs`, we'll see more about that later

## Toolbox of prebuild tools

We ran a workflow called `hello`, but where did this Workflow come from? Janis contains a toolbox of prebuilt tools and workflows. This information is available in the documentation:

- Tools: https://janis.readthedocs.io/en/latest/tools/index.html
- Pipelines: https://janis.readthedocs.io/en/latest/pipelines/index.html

In fact, we use these prebuilt tools to run our internal analysis, and these exist on the Registry.

These tools exist in separate modules to Janis, which means they can be updated independent of other janis functionality. It also means that you could create your own private registry of unpublished tools independent of what Janis provides.

We'll have a look at the toolbox when we build our workflow.

[Next >](3-janis-run-alignment.md)


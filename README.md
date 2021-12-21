[![Build Status](https://travis-ci.org/crest-cassia/xsub.svg?branch=master)](https://travis-ci.org/crest-cassia/xsub)
[![Coverage Status](https://coveralls.io/repos/crest-cassia/xsub/badge.svg?branch=master&service=github)](https://coveralls.io/github/crest-cassia/xsub?branch=master)

# xsub

A wrapper for job schedulers.
Job schedulers used in HPCs, such as Torque, often have its own I/O format.
Users have to change their scripts to conform with its dialect.
This is a wrapper script to absorb the difference.
This script is intended to be used by [OACIS](https://github.com/crest-cassia/oacis).

Although only a few types of schedulers are currently supported, you can send an enhance request to us or you can just extend it by yourself.

## Installation

- Install Ruby 2.0.0 or later.
  - If Ruby is already installed in your system, you do not have to worry about it. Try `ruby --version` to check the version of Ruby.
  - If Ruby is not installed on your system, we recommend using [rbenv](https://github.com/sstephenson/rbenv) to install Ruby.

- Clone this repository

  ```
  git clone https://github.com/crest-cassia/xsub.git
  ```

- set `PATH` and `XSUB_TYPE` environment variables in your ~/.bash_profile
  - set `PATH` so as to include the bin directory of xsub. Then you can use `xsub`, `xstat`, and `xdel` commands.
  - set XSUB_TYPE to be one of the supported schedulers listed below.
  - If you run xsub from OACIS, please set these variables in .bash_profile even if your login shell is zsh. This is because OACIS executes xsub on bash launched as a login shell.
    - do not set these environment variables in .bashrc because it is loaded only in an interactive shell, not in a login shell.

  ```sh:.bash_profile
  export PATH="$HOME/xsub/bin:$PATH"
  export XSUB_TYPE="torque"
  ```

### Supported Schedulers

List of available schedulers.

- **none**
  - If you are not using a scheduler, please use this. The command is executed as a usual process.
- **torque**
  - [Torque](http://www.adaptivecomputing.com/products/open-source/torque/)
  - `qsub`, `qstat`, `qdel` commands are used.
- **fx10**
  - a scheduler for fx10.
  - `pjsub`, `pjstat`, `pjdel` commands are used.
- **k**
  - [K computer](http://www.aics.riken.jp/en/).
  - `pjsub`, `pjstat`, `pjdel` commands are used.
  - Files in the work_dir are staged-in.
  - Files created in the `work_dir` are staged-out.
- **slurm_focus**
  - [FOCUS supercomputer system](http://www.j-focus.or.jp/focus/)
  - `fjsub`, `fjstat`, `fjdel` commands are used.
- **fx100nagoya**, **cx400nagoya**
  - FX100 and CX400 in [Nagoya University](http://www.icts.nagoya-u.ac.jp/en/sc/)
  - `pjsub`, `pjstat`, `pjdel` commands are used.
  - Set your `$XSUB_TYPE` as
  ```sh:.bash_profile.local
  if [ $(uname -n) = 'hpcifx' ]; then
    export XSUB_TYPE=fx100nagoya
  elif [ $(uname -n) = 'hpcicx' ]; then
    export XSUB_TYPE=cx400nagoya
  fi
  ```
- **fugaku**
  - Fugaku
  - `pjsub`, `pjstat`, `pjdel` commands are used.

- **fx700**
  - FX700 in [R-CCS](https://www.r-ccs.riken.jp/)
  - `sbatch`, `squeue`, `scancel` commands are used.

- **OakForest-PACS (OFP)**
  - OacForest-PACS in the Univ. of Tokyo
  - Set `GROUP` environment variable as in
  ```sh:.bash_profile.local
  # XSUB setup for OakForest-PACS
  export XSUB_TYPE="ofp"
  export GROUP="myGroup"
  export PATH=$PATH:$HOME/xsub/bin
  ```


## Contact

- Send your feedback to us!
  - `oacis-dev _at_ googlegroups.com` (replace _at_ with @)
  - We appreciate your questions, feature requests, and bug reports.

## License

The MIT License (MIT)

Copyright (c) 2014,2015 RIKEN, AICS

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


## Specification

Three commands **xsub**, **xstat**, and **xdel** are provided.
These correspond to qsub, qstat, and qdel of Torque.

It prints JSON to the standard output so that the outputs are easily handled by other programs.

### xsub

submit a job to a scheduler

- **usage**: `xsub {job_script}`
- **options**:
  - "-d WORKDIR" : set working directory
    - when the job is executed, the current directory is set to this working directory.
    - if the directory does not exist, a new directory is created.
  - "-p PARAMETERS" : set parameters required to submit a job
  - "-t" : show parameters to submit a job in JSON format. Job is not submitted.
  - "-l" : Path to the log file directory.
    - If this option is not given, the logs are printed in the current directory.
    - If the directory does not exist, a new directory is created.

- **output format**:
  - when "-t" option is given, it prints JSON as follows.
    - it must have a "parameters" field.
    - Each parameter has "description", "default", and "format" fields.
      - "description" and/or "format" fields can be an empty string.
      - format is given as a regular expression. If the given parameter does not match the format, xsub fails.

  ```json
  {
    "parameters": {
      "mpi_procs": {
        "description": "MPI process",
        "default": 1,
        "format": "^[1-9]\\d*$"
      },
      "omp_threads": {
        "description": "OMP threads",
        "default": 1,
        "format": "^[1-9]\\d*$"
      },
      "ppn": {
        "description": "Process per node",
        "default": 1,
        "format": "^[1-9]\\d*$"
      },
      "elapsed": {
        "description": "Limit on elapsed time",
        "default": "1:00:00",
        "format": "^\\d+:\\d{2}:\\d{2}$"
      }
    }
  }
  ```

  - when job is submitted, the output format looks like the following.
    - it must have a key "job_id". The value of job_id can be either a number or a string.
  ```json
  {
    "job_id": 21507
  }
  ```
  - When it succeeds, return code is zero. When it fails, return code is non-zero.

- **example**

```sh
xsub job.sh -d work_dir -l log_dir -p '{"mpi_procs":3,"omp_threads":4,"ppn":4,"elapsed":"2:00:00"}'
```

### xstat

show a status of a job

- **usage**: `xstat {job_id}` or `xstat`
  - when "job_id" is given, show the status of the job
  - when "job_id" is not given, show current the status of the scheduler

- **output format**:
  - when "job_id" is given, it prints JSON as follows.
  ```json
  {
    "status": "running",
  }
  ```
    - status field takes either "queued", "running", or "finished".
      - "queued" means the job is in queue.
      - "running" means the job is running.
      - "finished" means the job is finished or the job is not found.
- when job_id is not given, it prints the status of all jobs.
    - output format is not defined. It usually prints the output of `qstat` command.

- **example**

```sh
xstat 12345   # => { "status": "queued" }
```

### xdel

delete a job

- **usage**: `xdel {job_id}`
  - cancel the specified job
    - if the job finished successfully, return code is zero.
    - if the cancel command fails, return code is non-zero.
  - output format is not defined.

## Extending

- If you are not familiar with Ruby, just send us an email.
- If you are familiar with Ruby, you can extend xsub by yourself.
  - Fork the repository.
  - Add another class which inherits `Xsub::Scheduler` class.
    - Define the same methods and constants as the existing classes.
    - Locate your new class at `lib/schedulers` directory. Then your file is automatically loaded.
    - Because this library is small, you can read the whole source code easily.
    - After you implemented your scheduler class, test following the instructions [here](test/instruction.md).
  - set `XSUB_TYPE` environment variable to your new class name.
    - For example, if your class name is `MyScheduler`, then write `XSUB_TYPE=MyScheduler` to your `.bash_profile`. (case-insensitive)

- We would appreciate it if you send us your enhancement as a pull request.

### Sending pull request

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

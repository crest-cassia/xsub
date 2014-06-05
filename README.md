(This repository is work in progress!)

# AnyScheduler

A wrapper for job schedulers.
Job schedulers used in HPCs, such as Torque, often have its own I/O format.
Users have to change their scripts to conform with its dialect.

To solve this problem, we propose a unified I/O format for job scheduler.
This gem is one implementation that wraps Torque to have the proposed specification.

## Proposed Specification

Scheduler has three commands **asub**, **astat**, and **adel**.
These correspond to qsub, qstat, and qdel of Torque.

It prints JSON to the standard output. The format shown later is the minimal one. You can add arbitrary fields if you want.

### asub

A script to submit a job.

- **usage**: `qsub {job_script}`
- **options**:
  - "-d WORKDIR" : set working directory
  - "-p PARAMETERS" : set parameters required to submit a job
  - "-t" : show parameters to submit a job in JSON format. Job is not submitted.

- **output format**:
  - when "-t" option is given, it prints JSON as follows.
    - it must have a "parameters" field.
    - Each parameter has "description" field and "default" field. "description" field is optional.
  ```json
  {
    "parameters": {
      "mpi_procs": {
        "description": "MPI process",
        "default": 1
      },
      "omp_threads": {
        "description": "OMP threads",
        "default": 1
      },
      "ppn": {
        "description": "Process per node",
        "default": 1
      },
      "elapsed": {
        "description": "Limit on elapsed time",
        "default": "1:00:00"
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

### astat

(TODO)

### adel

(TODO)


## Installation

Add this line to your application's Gemfile:

    gem 'any_scheduler'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install any_scheduler

## Usage

TODO: Write usage instructions here

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

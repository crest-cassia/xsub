# Procedure of integration test

To verify xsub working properly, test the following items.

## testing xsub

- run `xsub -t`
    ```
    xsub -t
    ```
    - verify output JSON has "parameters" and "template" keys

- run xsub command as follows. (change the parameters properly for each host.)
    ```
    xsub sleep5.sh -d work_dir -l log_dir -p '{"mpi_procs":2,"omp_threads":4}'
    ```
    - verify JSON is printed to stdout. It should contain "job_id" key.
    - verify a job is submitted to the scheduler
    - verify `work_dir/sleep5_xsub.sh` is created and it has appropriate parameters
    - verify `log_dir/xsub.log` is created and the log is written to this file
    - verify `work_dir/pwd.txt` contains the path to work_dir after the job has finished
    - clean up directory as follows
        ```
        rm -rf work_dir log_dir
        ```

## testing xstat

- run xsub and xstat command as follows
    ```
    xsub sleep5.sh -d work_dir -l log_dir | ruby -r json -e 'puts JSON.load($stdin.read)["job_id"]'
    xstat 1234
    ```
    - verify JSON having "status" key is printed to stdout as follows
        ```
        {
          "status": "running",
          "raw_output": [
            "  PID TTY           TIME CMD",
            "66694 ttys001    0:00.00 bash /Users/murase/work/xsub/test/sleep5_xsub2.sh"
          ]
        }
        ```
    - verify status is queued or running
    - after job finished, run xstat command again and verify the status changed to finished
        ```
        xstat 66694
        ```
    - to clean up,
        ```
        rm -rf work_dir log_dir
        ```

- run xstat without argument
    ```
    xstat
    ```
    - verify you see the status of the jobs submitted to the scheduler

## testing xdel

- run the following command. (replace the job id properly.)
    ```
    xsub sleep5.sh -d work_dir -l log_dir | ruby -r json -e 'puts JSON.load($stdin.read)["job_id"]'
    xdel 1234
    xstat 1234
    ```
    - verify the job is deleted using stat command of the scheduler
    - to clean up,
        ```
        rm -rf work_dir log_dir
        ```

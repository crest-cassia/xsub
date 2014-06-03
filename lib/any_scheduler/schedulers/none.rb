require "any_scheduler/base"

module AnyScheduler

  class SchedulerNone < Base

    TEMPLATE = <<EOS
. <%= job_file %>
EOS

    PARAMETERS = {}

    def submit_job(script_path)
      cmd = "nohup bash #{script_path} > /dev/null 2>&1 < /dev/null &"
      output = `#{cmd}`
      raise "rc is not zero: #{output}" unless $?.to_i == 0
      psid = `echo $!`
      raise "echo failed" unless $?.to_i == 0
      {job_id: psid, output: output}
    end
  end
end

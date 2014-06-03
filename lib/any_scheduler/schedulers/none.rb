module AnyScheduler

  class SchedulerNone < Base

    TEMPLATE = <<EOS
. <%= job_file %>
EOS

    PARAMETERS = {}

    def submit_job(script_path)
      cmd = "nohup bash #{script_path} > /dev/null 2>&1 < /dev/null & echo $!"
      @logger.info "#{cmd} is invoked"
      output = `#{cmd}`
      raise "rc is not zero: #{output}" unless $?.to_i == 0
      psid = output.lines.last.to_i
      @logger.info "process id: #{psid}"
      {job_id: psid, output: output}
    end
  end
end

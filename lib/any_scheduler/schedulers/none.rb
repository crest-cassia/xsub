module AnyScheduler

  class SchedulerNone < Base

    TEMPLATE = <<EOS
. <%= job_file %>
EOS

    PARAMETERS = {}

    def submit_job(script_path)
      full_path = File.expand_path(script_path)
      cmd = "nohup bash #{full_path} > /dev/null 2>&1 < /dev/null & echo $!"
      @logger.info "#{cmd} is invoked"
      output = ""
      FileUtils.mkdir_p(@work_dir)
      Dir.chdir(@work_dir) {
        output = `#{cmd}`
        raise "rc is not zero: #{cmd}" unless $?.to_i == 0
      }
      psid = output.lines.to_a.last.to_i
      @logger.info "process id: #{psid}"
      {job_id: psid, output: output}
    end

    def status(job_id)
      cmd = "ps -p #{job_id}"
      output = `#{cmd}`
      status = $?.to_i == 0 ? :running : :finished
      { status: status, detail: output }
    end
  end
end

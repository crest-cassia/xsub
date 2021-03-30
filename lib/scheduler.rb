module Xsub

  class Scheduler

    def self.descendants
      ObjectSpace.each_object(Class).select { |klass| klass < self and klass.name }
    end

    def self.get_scheduler(scheduler_name = nil)
      scheduler_name ||= ENV['XSUB_TYPE']
      unless scheduler_name
        candidates = descendants.map {|k| k.name.split('::').last }
        raise " XSUB_TYPE is not set: select from #{candidates.inspect}"
      end
      scheduler = descendants.find do |klass|
        klass.name.split('::').last.downcase == scheduler_name.downcase
      end
      raise "scheduler is not found: #{scheduler_name}" unless scheduler
      scheduler
    end

    def multiple_status(job_id_list)
      results = {}
      job_id_list.each{|job_id|
        results[job_id] = status(job_id)
      }
      results
    end
  end
end


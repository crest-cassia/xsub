module Xsub

  class Scheduler

    def self.descendants
      ObjectSpace.each_object(Class).select { |klass| klass < self }
    end

    def self.get_scheduler(scheduler_name = nil)
      scheduler_name ||= ENV['XSUB_TYPE']
      unless scheduler_name
        candidates = descendants.map {|klass| klass.name.split('::').last }
        raise " XSUB_TYPE is not set: select from #{candidates.inspect}"
      end
      scheduler = descendants.find do |klass|
        klass.name.split('::').last.downcase == scheduler_name.downcase
      end
      raise "scheduler is not found: #{scheduler_name}" unless scheduler
      scheduler
    end
  end
end


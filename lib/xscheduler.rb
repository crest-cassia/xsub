require 'pp'
require 'json'
require 'fileutils'
require "xscheduler/version"
require "xscheduler/template"
require "xscheduler/base"
require "xscheduler/schedulers/none"
require "xscheduler/schedulers/torque"

module AnyScheduler

  SCHEDULER_TYPE = {
    none: AnyScheduler::SchedulerNone,
    torque: AnyScheduler::SchedulerTorque
  }

  CONFIG_FILE_PATH = File.expand_path('~/.any_scheduler.json')

  def self.load_scheduler
    unless File.exist?(CONFIG_FILE_PATH)
      $stderr.puts "Create config file #{CONFIG_FILE_PATH}"
      raise "Config file (#{CONFIG_FILE_PATH}) not found"
    end
    type = JSON.load(File.open(CONFIG_FILE_PATH))["scheduler_type"].to_sym
    scheduler(type)
  end

  def self.scheduler(scheduler_type)
    key = scheduler_type.to_sym
    raise "not supported type" unless SCHEDULER_TYPE.has_key?(key)
    SCHEDULER_TYPE[scheduler_type.to_sym].new
  end
end

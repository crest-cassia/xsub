require 'pp'
require 'json'
require 'fileutils'
require "xsub/version"
require "xsub/template"
require "xsub/base"
require "xsub/schedulers/none"
require "xsub/schedulers/torque"

module Xsub

  SCHEDULER_TYPE = {
    none: Xsub::SchedulerNone,
    torque: Xsub::SchedulerTorque
  }

  CONFIG_FILE_PATH = File.expand_path('~/.xsub')

  def self.load_scheduler
    unless File.exist?(CONFIG_FILE_PATH)
      $stderr.puts "Create config file #{CONFIG_FILE_PATH}"
      raise "Config file (#{CONFIG_FILE_PATH}) not found"
    end
    type = File.open(CONFIG_FILE_PATH).read.chomp.to_sym
    scheduler(type)
  end

  def self.scheduler(scheduler_type)
    key = scheduler_type.to_sym
    raise "not supported type" unless SCHEDULER_TYPE.has_key?(key)
    SCHEDULER_TYPE[scheduler_type.to_sym].new
  end
end

require 'pp'
require 'json'
require 'fileutils'
require 'pry'
require "any_scheduler/version"
require "any_scheduler/template"
require "any_scheduler/base"
require "any_scheduler/schedulers/none"
require "any_scheduler/schedulers/torque"

module AnyScheduler

  SCHEDULER_TYPE = {
    none: AnyScheduler::SchedulerNone,
    torque: AnyScheduler::SchedulerTorque
  }

  def self.scheduler(scheduler_type)
    key = scheduler_type.to_sym
    raise "not supported type" unless SCHEDULER_TYPE.has_key?(key)
    SCHEDULER_TYPE[scheduler_type.to_sym]
  end
end

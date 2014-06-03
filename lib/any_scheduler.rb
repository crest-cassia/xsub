require 'pp'
require 'json'
require 'fileutils'
require 'pry'
require "any_scheduler/version"
require "any_scheduler/template"
require "any_scheduler/base"

module AnyScheduler

  def self.scheduler(scheduler_type)
    case scheduler_type.to_sym
    when :none
      require "any_scheduler/schedulers/none"
      AnyScheduler::SchedulerNone.new
    when :torque
    when :pjm
    else
      raise "not supported type"
    end
  end
end

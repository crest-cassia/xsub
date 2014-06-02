require 'pp'
require "any_scheduler/version"

module AnyScheduler

  extend self

  def show_param
    pp "show param"
  end

  def submit(args, parameters)
    pp args, parameters
  end
end

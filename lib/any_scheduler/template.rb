require 'erb'

module AnyScheduler

  module Template
    def self.render( template, variables )
      b = binding
      variables.each do |name, value|
        b.local_variable_set(name.to_sym, value)
      end
      ERB.new(template).result(b)
    end
  end
end

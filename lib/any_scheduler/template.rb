module AnyScheduler

  class Template
    def initialize( variables )
      variables.each { |name, value| instance_variable_set("@#{name}", value) }
    end

    def resolve( template )
      ERB.new(template).result(binding)
    end
  end
end

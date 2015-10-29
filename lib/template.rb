require 'erb'

module Xsub

  module Template

    class Namespace

      def initialize(hash)
        hash.each do |key,val|
          singleton_class.send(:define_method, key) { val }
        end
      end

      def get_binding
        binding
      end
    end

    def self.render( template, variables )
      b = Namespace.new(variables).get_binding
      ERB.new(template).result(b)
    end
  end
end

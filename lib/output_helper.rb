module Xsub

  class OutputHelper

    def self.run
      is_json_mode = (ENV['XSUB_FORCE_JSON'] == '1')
      is_success = true

      if is_json_mode then
        require 'stringio'
        require 'json'
        original_stdout = $stdout
        original_stderr = $stderr
        $stdout = StringIO.new
        $stderr = StringIO.new
        error = nil
      end

      begin
        yield
      rescue => e
        if is_json_mode then
          error = e
        else
          raise e
        end
      end

      if is_json_mode then
        results = {}
        merge_json!(results, :STDOUT, $stdout.string)
        merge_json!(results, :STDERR, $stderr.string)
        merge_json!(results, :ERROR, error == nil ? "" : error.message)

        original_stdout.write JSON.pretty_generate(results)
        $stdout = original_stdout
        $stderr = original_stderr

        if error != nil then
          raise error
        end
      end
    end

    def self.merge_json!(hash, key, json_string)
      unless json_string.eql?("") then
        begin
          hash.merge!(JSON.parse(json_string))
        rescue
          hash[key] = json_string
        end
      end
    end
  end
end

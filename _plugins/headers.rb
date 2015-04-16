module Jekyll
  module Commands
    class Serve
      class << self
        alias :_original_webrick_options :webrick_options
      end

      def self.webrick_options(config)
        _original_webrick_options(config).tap do |options|
          options[:MimeTypes].merge!({ "html" => "text/html; charset=utf-8" })
        end
      end
    end
  end
end

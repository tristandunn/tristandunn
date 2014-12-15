require "htmlcompressor"
require "uglifier"

module Jekyll
  HTML_COMPRESSOR = HtmlCompressor::Compressor.new({
    compress_javascript: true,
    javascript_compressor: Uglifier.new,
    remove_intertag_spaces: true,
    remove_surrounding_spaces: HtmlCompressor::Compressor::BLOCK_TAGS_MIN
  })

  class Page
    def output_with_compression
      if ext == ".xml"
        output_without_compression
      else
        HTML_COMPRESSOR.compress(output_without_compression)
      end
    end

    alias_method :output_without_compression, :output
    alias_method :output, :output_with_compression
  end

  class Post
    def output_with_compression
      HTML_COMPRESSOR.compress(output_without_compression)
    end

    alias_method :output_without_compression, :output
    alias_method :output, :output_with_compression
  end
end

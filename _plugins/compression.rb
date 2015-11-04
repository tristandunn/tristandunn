require "htmlcompressor"

HTML_COMPRESSOR = HtmlCompressor::Compressor.new({
  remove_intertag_spaces: true,
  remove_surrounding_spaces: HtmlCompressor::Compressor::BLOCK_TAGS_MIN
})

Jekyll::Hooks.register(:documents, :post_render) do |page|
  page.output = HTML_COMPRESSOR.compress(page.output)
end

Jekyll::Hooks.register(:pages, :post_render) do |page|
  next if page.ext == ".xml"

  page.output = HTML_COMPRESSOR.compress(page.output)
end

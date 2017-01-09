# has to be required so we don't define it multiple times.
module Kramdown
  module Parser
    class GfmLink < Kramdown::Parser::GFM
      def initialize(*doc)
        super
        @block_parsers.unshift(:gfmlink)
      end
         
      GFMLINK_START = /\[\[(.*?)\]\]/u
         
      def parse_gfmlink
        @src.pos += @src.matched_size
        el = Element.new(:gfmlink, nil, {'gfmlink' => @src[1]})
        @tree.children << el
      end
      define_parser(:gfmlink, GFMLINK_START, '\[\[')
    end
  end
end

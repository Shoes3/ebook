# -*- encoding: utf-8 -*-
# Preprocess for menus those [[ ]] links

require("kramdown")

module Kramdown
  
  module Converter
    class Menuparse < Base
        attr_accessor :image_hash
         
        def initialize(root, options)
          #puts "MenuParse init opts: #{options.inspect}"
          if options 
            @image_hash = options[:img_hash]
            @header_hash = options[:hdr_hash]
            @link_hash = options[:lnk_hash]
            @menu_list = options[:menu_list]
            #@section = options[:chapter]
            #puts "setting up @image_hash #{@image_hash.inspect}"
          end
          super
        end
         
      DISPATCHER = Hash.new {|h,k| h[k] = "convert_#{k}"}
         
      def convert(el)
        send(DISPATCHER[el.type], el)
      end
         
      def convert_root(el)
        results = []
        el.children.each do |inner_el|
          results << send(DISPATCHER[inner_el.type], inner_el)
        end
        results
      end
         
      def convert_blank(el)
        #%{para("\n")}
      end
      
      # TODO: fix these in kd-render
      def convert_br(el)
      end
      
      def convert_blockquote(el)
      end
      
      def convert_table(el)
      end
      
      def convert_ol(el)
      end
      
      def convert_html_element(el)
      end
      
      #end of *this* TODO
         
      def convert_text(el)
      end
         
      def convert_header(el)
        #puts "hdr: #{el.options[:raw_text]} #{el.options[:level]}"
        #@header_hash[el.options[:raw_text]] = el.options[:level]
      end
         
      def convert_p(el)
        results = []
        el.children.each do |inner_el|
          results << send(DISPATCHER[inner_el.type], inner_el)
        end
        #%[flow(:margin_left => 6, :margin_right => gutter) { #{results.join(";")} }]
      end
         
      def convert_ul(el)
        results = []
        el.children.each do |inner_el|
          results << send(DISPATCHER[inner_el.type], inner_el)
        end
        #results
      end
         
      def convert_li(el)
        results = []
        el.children.each do |inner_el|
          results << %[flow(:margin_left => 30) { fill black; oval -10, 10, 6; #{send(DISPATCHER[inner_el.type], inner_el)} }]
        end
        #results
      end
      ##alias :convert_ol :convert_ul
      ##alias :convert_dl :convert_ul
                  
      def convert_smart_quote(el)
        #%{para("'", :margin_left => 0, :margin_right => 0)}
      end
         
      def convert_a(el)
        results = []
        el.children.each do |inner_el|
          results << inner_el.value if inner_el.type.eql?(:text)
        end
        #%[para(link("#{results.join}") { open_url("#{el.attr['href']}") }, :margin_left => 0, :margin_right => 0)]
        return nil
      end
      
      # TODO: syntax highlight not working (no errors - just doesn't return anything)
      def convert_codespan(el)
      end
         
      def convert_codeblock(el)
        #puts el.type
      end
         
      def convert_strong(el)
        #%[para "STRONG"]
      end
      
      def convert_img(el)
        url = el.attr['src']
        ext = File.extname(url);
        hsh = @image_hash
        fname = "#{el.attr['alt']}#{ext}"
        fname.gsub!(' ', '-');
        #puts "alt tag: #{fname}"
        if !fname || fname[0] == '.' # start of extension 
          # someone didn't put an alt tag like they were supposed to do. 
          fname = File.basename(url)
          #puts "missing alt - using #{fname}"
        end
        hsh[url] = fname
      end
  
      def convert_typographic_sym(el)
        #%[para"??"]
      end
         
      def convert_em(el)
        #%[para '-']
      end
      
      def convert_gfmlink(el)
        str =  el.attr['gfmlink']
        @menu_list << "#{str.gsub(' ', '-')}.md"
        #dblbracket = el.value[/\[\[(.*)\]\]/]
        #if dblbracket
        #  menu = dblbracket[2..-3].gsub(' ', '-')
        #  @menu_list << "#{menu}.md"
        #  #puts "LINK: #{menu}" 
        #end
      end
      
      def syntax_highlighter(converter, text, lang, type)
        opts = converter.options[:syntax_highlighter_opts].dup
        lexer = ::Rouge::Lexer.find_fancy(lang || opts[:default_lang], text)
        return nil unless lexer

        opts[:wrap] = false if type == :span

        formatter = ::Rouge::Formatters::ShoesFormatter.new(opts)
        formatter.format(lexer.lex(text))
      end
      # TODO: end
    end
  end
end

def to_menuparse(e)
   puts "to_menuparse called"
   e.kind_of?(Array) ? (e.each { |n| to_menuparse(n) }) : (eval e unless e.nil?)
   return 
end





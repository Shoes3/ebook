# https://github.com/Shoes3/shoes3/wiki
# http://www.w3schools.com/tags/tag_li.asp
# http://stackoverflow.com/questions/4900167/override-module-method-from-another-module

require("rouge")
require("kramdown")
require("pp")

def open_url(url)
  if RbConfig::CONFIG['host_os'] =~ /mswin|mingw|cygwin/
    system("start #{url}")
  elsif RbConfig::CONFIG['host_os'] =~ /darwin/
    system("open #{url}")
  elsif RbConfig::CONFIG['host_os'] =~ /linux|bsd/
    system("xdg-open #{url}")
  end
end

module Rouge
   module Formatters
      class ShoesFormatter < Formatter
         tag 'shoes'
         
         def initialize(options)
            @inline_theme = options.fetch(:inline_theme, nil)
            @inline_theme = Theme.find(@inline_theme).new if @inline_theme.is_a? String
            puts @inline_theme.render
         end
         
         def stream(tokens, &b)
            tokens.each do |tok, val|
               yield "\t#{@inline_theme.style_for(tok).rendered_rules.to_a.join(';')}\n"
               yield "#{tok} #{val.inspect}\n"
            end
         end
      end
   end
end

module Kramdown
   module Converter
      class Shoes < Base
         #include ShoesRouge
         def initialize(root, options)
            super
            #options[:syntax_highlighter] = "rouge"
            puts options
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
            %{para("\n")}
         end
         
         def convert_text(el)
            %{para("#{el.value}", :margin_left => 0, :margin_right => 0)}
         end
         
         def convert_header(el)
            %{para(strong("#{el.options[:raw_text]}\n"), :margin_left => 6, :margin_right => gutter)}
         end
         
         def convert_p(el)
            results = []
            el.children.each do |inner_el|
               results << send(DISPATCHER[inner_el.type], inner_el)
            end
            %[flow(:margin_left => 6, :margin_right => gutter) { #{results.join(";")} }]
         end
         
         def convert_ul(el)
            results = []
            el.children.each do |inner_el|
               results << send(DISPATCHER[inner_el.type], inner_el)
            end
            results
         end
         
         def convert_li(el)
            results = []
            el.children.each do |inner_el|
               results << %[flow(:margin_left => 30) { fill black; oval -10, 10, 6; #{send(DISPATCHER[inner_el.type], inner_el)} }]
            end
            results
         end
         #alias :convert_ol :convert_ul
         #alias :convert_dl :convert_ul
                  
         def convert_smart_quote(el)
            %{para("'", :margin_left => 0, :margin_right => 0)}
         end
         
         def convert_a(el)
            results = []
            el.children.each do |inner_el|
               results << inner_el.value if inner_el.type.eql?(:text)
               #send(DISPATCHER[inner_el.type], inner_el)
            end
            %[para(link("#{results.join}") { open_url("#{el.attr['href']}") }, :margin_left => 0, :margin_right => 0)]
         end
         
         def convert_codespan(el)
            puts el
            #puts highlight_code(el.value, el.attr['class'], :span)
            #h = ::Kramdown::Converter.syntax_highlighter(@options[:syntax_highlighter])
            #puts h.call(self, el.value, el.attr['class'], :span)
            puts syntax_highlighter(self, el.value, el.attr['class'], :span)
         end
         
         def convert_codeblock(el)
            puts el.type
         end
         
         def syntax_highlighter(converter, text, lang, type)
            opts = converter.options[:syntax_highlighter_opts].dup
            lexer = ::Rouge::Lexer.find_fancy(lang || opts[:default_lang], text)
            return nil unless lexer

            opts[:wrap] = false if type == :span

            formatter = ::Rouge::Formatters::ShoesFormatter.new(opts)
            formatter.format(lexer.lex(text))
         end
      end
   end
end

def rendering(e)
   e.kind_of?(Array) ? (e.each { |n| rendering(n) }) : (eval e unless e.nil?)
end

Shoes.app {
   doc = Kramdown::Document.new(File.read("fts-md/manual-en.txt"), { :syntax_highlighter => "rouge", :syntax_highlighter_opts => { css_class: false, line_numbers: false, inline_theme: "github" } }).to_shoes
   
   #info doc.inspect
   rendering(doc)
}

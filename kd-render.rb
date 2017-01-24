# https://github.com/Shoes3/shoes3/wiki
# http://www.w3schools.com/tags/tag_li.asp
# http://stackoverflow.com/questions/4900167/override-module-method-from-another-module
# cjc : This has to populate the cfg sections and add to the picky db

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
        #puts @inline_theme.render
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
      ##include ShoesRouge
      def initialize(root, options)
        @cfg = options[:cfg]
        @chapter = options[:chapter]
        ## options[:syntax_highlighter] = "rouge"
        #puts options
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
         
      def convert_text(el)
        #%{para("#{el.value}", :margin_left => 0, :margin_right => 0)}
        %{para("#{el.value.gsub("\n", ' ')}", :margin_left => 0, :margin_right => 0)}
      end
         
      def convert_header(el)
        #%{para(strong("#{el.options[:raw_text]}\n"), :margin_left => 6, :margin_right => gutter)}
        hlevel = el.options[:level]
        txt = el.options[:raw_text]
        case hlevel
        when 1
          #puts "header 1 #{txt}"
          %{para(strong("#{txt}"), :size => 22, :margin_left => 6, :margin_right => gutter)}
        when 2 
          #puts "header 2 #{txt}"
          %{para(strong("#{txt}"), :size => 18, :margin_left => 6, :margin_right => gutter)}
        when 3
          #puts "header 3 #{txt}"
          %{para(strong("#{txt}"), :size => 14, :margin_left => 6, :margin_right => gutter)}
        when 4
          #puts "header 4 #{txt}"
          %{para(strong("#{txt}"), :size => 12, :margin_left => 6, :margin_right => gutter)}
        when 5
          #puts "header 5 #{txt}"
          %{para(strong("#{txt}"), :size => 10, :margin_left => 6, :margin_right => gutter)}
        when 6
          #puts "header 6 #{txt}"
          %{para(strong("#{txt}"), :size => 8, :margin_left => 6, :margin_right => gutter)}
        else
          puts "header default"
          %{para(strong("#{txt}"), :margin_left => 6, :margin_right => gutter)}
        end
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
          #results << %[flow(:margin_left => 30) { para "\u2022"; #{send(DISPATCHER[inner_el.type], inner_el)} }]
        end
        results
      end
      ##alias :convert_ol :convert_ul
      ##alias :convert_dl :convert_ul
                
                
      # TODO?
      def convert_smart_quote(el)
        t = case el.value
          when :lsquo
            "\u2018"
          when :rsquo
            "\u2019"
          when :ldquo
            "\u201C"
          when :rdquo
            "\u201D"
        end
        #puts "smartquote sub #{t}"
        %{para("#{t}", :margin_left => 0, :margin_right => 0)}
      end
         
      def convert_a(el)
        #puts "convert a called #{el.inspect}"
        results = []
        el.children.each do |inner_el|
          results << inner_el.value if inner_el.type.eql?(:text)
            ##send(DISPATCHER[inner_el.type], inner_el)
        end
        %[para(link("#{results.join}") { open_url("#{el.attr['href']}") }, :margin_left => 0, :margin_right => 0)]
      end
      
      # from are `back ticks` in markdown
      def convert_codespan(el)
        # need to escape some things in the string like "
        str = el.value
        str.gsub!(/\"/, '\"')
        %[para "#{str}", font: 'monospace', stroke: coral]
      end
      
      def convert_codeblock (el)
        # More crazy logic?
        str = el.value
        exe_str = nil
        display_str = nil
        if str[/Shoes\.app/]
          #puts "code is excutable: #{el.value}"
          exe_str = str
        else 
          #puts "code can't be run: #{str}"
          return %Q[render_copy(#{el.value.inspect})]
        end
        if @cfg['syntax_highlight']
          # do the hightling of 'exe_str' save results in 'display_str'
          #return highlight_codeblock el
        end
        #%[render_code(%{#{el.value}})]
        %Q[render_code(#{el.value.inspect}, #{display_str})]
      end
         
      # TODO: syntax highlight not working (no errors - just doesn't return anything)
      def highlight_codeblock(el)
        #puts highlight_code(el.value, el.attr['class'], :span)
        #h = ::Kramdown::Converter.syntax_highlighter(@options[:syntax_highlighter])
        #puts h.call(self, el.value, el.attr['class'], :span)
        #puts syntax_highlighter(self, el.value, el.attr['class'], :span)
        puts "SB #{el.inspect}"
        nil # until it's ready for Shoes to eval it. 
      end
         
      def convert_strong(el)
        results = []
        el.children.each do |inner_el|
          results << inner_el.value
        end
        t = results.size > 1 ? results.join : results[0]
        %[para strong("#{t}")]
      end
      
      def convert_img(el)
        url = el.attr['src']
        ext = File.extname(url);
        lcl = @cfg['images'][url]
        if lcl
          %[image "#{@cfg['doc_home']}/.ebook/images/#{lcl}"]
        else
          puts "Not an image: #{url}"
          nil
        end
      end
      
      def convert_gfmlink(el)
        str =  el.attr['gfmlink']
        #puts "gfmlink find: #{str}"
        # defer to Run Time method to figure it where to go
        %[para(link("#{str}") { show_link("#{str}")})]
      end
  
      def convert_typographic_sym(el)
        sub = case el.value
          when :hellip
            "\u2026"
          when :ndash # non breaking dash
            "\u2013"
          else
            # The Dotted Cross! - gotta pick something for unknown
            "\u2025"
        end
        #puts "typegrapic sub: #{sub}"
        %[para"#{sub}"]
      end
         
      # I think this means Shoes italic, not strong
      def convert_em(el)
        results = []
        el.children.each do |inner_el|
          results << inner_el.value
        end
        t = results.size > 1 ? results.join : results[0]
        %[para "#{t}", :emphasis => "italic"]        
      end
      
      # TODO: fix these in kd-render?
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

def rendering(e)
   e.kind_of?(Array) ? (e.each { |n| rendering(n) }) : (eval e unless e.nil?)
end


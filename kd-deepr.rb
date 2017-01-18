# https://github.com/Shoes3/shoes3/wiki
# http://www.w3schools.com/tags/tag_li.asp
# http://stackoverflow.com/questions/4900167/override-module-method-from-another-module
# cjc : This gets very deep have to parse just about everything in the file into
#       new intro, sections, subsections. Very Shoes manual like. Nasty.

require("rouge")
require("kramdown")
require 'fileutils'
include FileUtils

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
    class Deeplook < Base
      ##include ShoesRouge
      def initialize(root, options)
        @cfg = options[:cfg]
        ## options[:syntax_highlighter] = "rouge"
        #puts options
        @intro = []
        @section = ''
        @subsection  = ''
        @results = []
        @level = 0
        @muddled = '' # this is computed My-SubSection.md used for hash keys
                      # by shoes_render. 
        @rstack = []
        puts "init deeplook"
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
      end
         
      def convert_text(el)
        @results << %{para("#{el.value.gsub("\n", ' ')}", :margin_left => 0, :margin_right => 0)}
        return nil
      end
      
      # @level is the current level to close to put @results into
      # the cfg in the proper place to show_ebook can display them
      def close_level (new_name)
        # debugging - create a dump file for level's content
        if @level > 0
          dfl = "dump/#{@level}-#{@muddled}.rbd"
          mkdir_p('dump');
          File.open(dfl,'w') do |fl|
           fl.write @results
          end
        end
        # TODO: beware hash key collisions
        case @level
          when 1
            @cfg['have_nav'] = true
            @cfg['nested'] = true
            opening = @cfg['book_title']
            @cfg['toc']['root'] = opening
            landing = {title: opening, code: @results}
            @cfg['code_struct'] << landing
            @cfg['link_hash'][opening] = landing

          when 2
            sect_nm = @muddled
            @cfg['toc']['section_order'] << @section
            landing = {title: sect_nm, code: @results}
            @cfg['code_struct'] << landing
            @cfg['link_hash'][sect_nm] = landing 
            @cfg['sections'][@section][:display_order] = [sect_nm]
          when 3
            sect_nm = @section
            ss_nm = @muddled
            @cfg['sections'][sect_nm][:display_order] << ss_nm
            landing = {title: ss_nm, code: @results}
            @cfg['code_struct'] << landing
            @cfg['link_hash'][ss_nm] = landing
          when 0
            puts "discarding content before first header"
        end
        @results = []
      end
      
      # builds the section, subsections in cgf['sections'] etc
      # copies accumatlated code into cfg['code_landing'] and cfg['link_hash']
      def convert_header(el)
        hlevel = el.options[:level]
        txt = el.options[:raw_text]
        mdkey = txt.gsub(' ','-')
        mdkey << '.md'
        case hlevel
        when 1    # intro - only one of these 
          #close_level txt
          @muddled = mdkey
          @level = 1
          @cfg['toc']['section_order'] = [] # replace existing
          @results = [%{para(strong("#{txt}"), :size => 22, :margin_left => 6, :margin_right => gutter)}]
        when 2    # section
          close_level txt
          @level = 2
          @muddled = mdkey
          @section = txt
          @cfg['sections'][@section] = { :title => txt, :display_order => [] }
          puts "level 2 #{txt} for #{@cfg['sections'][@section].inspect}"
          @results = [%{para(strong("#{txt}"), :size => 18, :margin_left => 6, :margin_right => gutter)}]
        when 3   # subsection - [methods if you're thinking like Shoes Manual]
          close_level txt
          @level = 3
          @muddled = mdkey
          @subsection = txt
          puts "level 3 #{@section} under #{@cfg['sections'][@section].inspect}"
          #@cfg['sections'][@section][:display_order] << mdkey
          @results = [%{para(strong("#{txt}"), :size => 14, :margin_left => 6, :margin_right => gutter)}]
        when 4
          @results << %{para(strong("#{txt}"), :size => 12, :margin_left => 6, :margin_right => gutter)}
        when 5
          @results << %{para(strong("#{txt}"), :size => 10, :margin_left => 6, :margin_right => gutter)}
        when 6
          @results << %{para(strong("#{txt}"), :size => 8, :margin_left => 6, :margin_right => gutter)}
        else
          puts "header default"
          @results << %{para(strong("#{txt}"), :margin_left => 6, :margin_right => gutter)}
        end
        return nil
      end
         
      def save
        @rstack.push @results
        @results = []
      end
      
      def restore
        prev = @rstack.pop
        newc = @results
        @results = prev + newc
      end
      
      def convert_p(el)
        results = []
        el.children.each do |inner_el|
          results << send(DISPATCHER[inner_el.type], inner_el)
        end
        @results << %[flow(:margin_left => 6, :margin_right => gutter) { #{results.join(";")} }]
        return nil
      end
         
      def convert_ul(el)
        save
        el.children.each do |inner_el|
          @results << send(DISPATCHER[inner_el.type], inner_el)
        end
        restore
        return nil
      end
      
      
      def convert_li(el)
        save
        el.children.each do |inner_el|
          @results << %[flow(:margin_left => 30) { fill black; oval -10, 10, 6; #{send(DISPATCHER[inner_el.type], inner_el)} }]
          #results << %[flow(:margin_left => 30) { para "\u2022"; #{send(DISPATCHER[inner_el.type], inner_el)} }]
        end
        restore
        return nil
      end
      ##alias :convert_ol :convert_ul
      ##alias :convert_dl :convert_ul
                
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
        @results << %{para("#{t}", :margin_left => 0, :margin_right => 0)}
        return nil
      end
         
      def convert_a(el)
        #puts "convert a called #{el.inspect}"
        save
        el.children.each do |inner_el|
          @results << inner_el.value if inner_el.type.eql?(:text)
            ##send(DISPATCHER[inner_el.type], inner_el)
        end
        restore
        @results << %[para(link("#{@results.join}") { open_url("#{el.attr['href']}") }, :margin_left => 0, :margin_right => 0)]
        return nil
      end
      
      # from are `back ticks` in markdown
      def convert_codespan(el)
        # need to escape some things in the string like "
        str = el.value
        str.gsub!(/\"/, '\"')
         @results << %[para "#{str}", font: 'monospace', stroke: coral]
        return nil
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
          @results << %Q[render_copy(#{el.value.inspect})]
          return nil
        end
        if @cfg['syntax_highlight']
          # do the hightling of 'exe_str' save results in 'display_str'
          #return highlight_codeblock el
        end
        #%[render_code(%{#{el.value}})]
         @results << %Q[render_code(#{el.value.inspect}, #{display_str})]
        return nil
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
        save
        el.children.each do |inner_el|
          @results << inner_el.value
        end
        t = results.size > 1 ? @results.join : @results[0]
        restore
        @results << %[para strong("#{t}")]
        return nil
      end
      
      def convert_img(el)
        url = el.attr['src']
        ext = File.extname(url);
        lcl = @cfg['images'][url]
        if lcl
          @results << %[image "#{@cfg['doc_home']}/.ebook/images/#{lcl}"]
        else
          puts "Not an image: #{url}"
        end
        return nil
     end
      
      def convert_gfmlink(el)
        str =  el.attr['gfmlink']
        #puts "gfmlink find: #{str}"
        # defer to Run Time method to figure it where to go
        @results << %[para(link("#{str}") { show_link("#{str}")})]
        return nil
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
        @results << %[para"#{sub}"]
        return nil
      end
         
      # I think this means Shoes italic, not strong
      def convert_em(el)
        results = []
        el.children.each do |inner_el|
          results << inner_el.value
        end
        t = results.size > 1 ? results.join : results[0]
        @results << %[para "#{t}", :emphasis => "italic"]        
        return nil
     end
      
      # begin TODO fix these in kd-render/kd-deepr
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
      #end TODO fix above 
    end
  end
end

#def to_deeplook(e)
#   puts "to_deeplook called #{e.inspect}"
#   e.kind_of?(Array) ? (e.each { |n| rendering(n) }) : (eval e unless e.nil?)
#end


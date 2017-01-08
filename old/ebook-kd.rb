# -*- encoding: utf-8 -*-
# https://github.com/Shoes3/shoes3/wiki
# http://www.w3schools.com/tags/tag_li.asp

require("kramdown")

def open_url(url)
  if RbConfig::CONFIG['host_os'] =~ /mswin|mingw|cygwin/
    system("start #{url}")
  elsif RbConfig::CONFIG['host_os'] =~ /darwin/
    system("open #{url}")
  elsif RbConfig::CONFIG['host_os'] =~ /linux|bsd/
    system("xdg-open #{url}")
  end
end

@image_cache = {}

module Kramdown
   module Converter
      class Shoes < Base
         def initialize(root, options)
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
         
         def convert_codeblock(el)
            puts el.type
         end
         
         def convert_smart_quote(el)
            %{para("'", :margin_left => 0, :margin_right => 0)}
         end
         
         def convert_a(el)
            results = []
            el.children.each do |inner_el|
               results << inner_el.value if inner_el.type.eql?(:text)
               #send(DISPATCHER[inner_el.type], inner_el)
            end
            %[para(link("#{results.join}") { open_url("#{el.attr['href']}") })]
         end
         
         def convert_strong(el)
           %[para "STRONG"]
         end
         
         def convert_codespan(el)
           %[para "CODESPAN"]
         end
         
        def convert_img(el)
          puts el.attr['src']
          #%[image "#{el.attr['src']}"] # crashes shoes 
          url = el.attr['src']
          ext = File.extname(url);
          %[para "IMAGE_HERE: #{el.attr['alt']}#{ext}"]
        end
  
         def convert_typographic_sym(el)
           %[para"??"]
         end
         
         def convert_em(el)
           %[para '-']
         end
      end
   end
end

def rendering(e)
   e.kind_of?(Array) ? (e.each { |n| rendering(n) }) : (eval e unless e.nil?)
end

# need to get those images downloaded. Find them. Check if we have them
# download if not
def pre_process(doc)

end



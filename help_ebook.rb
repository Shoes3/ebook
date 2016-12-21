 # help_ebook 
module Shoes::Ebook
  require 'kd-render'
  def render_section 
    if cfg['nested']
       cfg['sections'].each do |section, section_hash|
        section_hash[:files].each do |fl|
          #puts "render document #{fl}"
          #para "document #{fl}"
          docpath = File.join(cfg['doc_home'], section_hash[:dir], fl)
          puts "deep render #{docpath}"
          render_doc = Kramdown::Document.new(File.read(docpath), 
            { :syntax_highlighter => "rouge",
              :syntax_highlighter_opts => { css_class: false, line_numbers: false, inline_theme: "github" },
             input: cfg['input_format']
            }
          ).to_shoes
        rendering(render_doc)
        end
      end
    else
      # flat dir of md
      cfg['sections'].each do |section, section_hash|
        section_hash[:files].each do |fl|
          #puts "render document #{fl}"
          #para "document #{fl}"
          docpath = File.join(cfg['doc_home'], fl)
          puts "flat render #{docpath}"
          render_doc = Kramdown::Document.new(File.read(docpath), 
            { :syntax_highlighter => "rouge",
              :syntax_highlighter_opts => { css_class: false, line_numbers: false, inline_theme: "github" },
             input: cfg['input_format'], gfm_quirks: ['hard_wrap'], 
            }
          ).to_shoes
        rendering(render_doc)
        end
      end
    end
    #cfg['files'].each do |relpath|
    #  render_doc = Kramdown::Document.new(File.read(@doc), 
    #    { :syntax_highlighter => "rouge",
    #      :syntax_highlighter_opts => { css_class: false, line_numbers: false, inline_theme: "github" },
    #      input: 'GFM'
    #    }
    #  ).to_shoes
    #  rendering(render_doc)
    #end
  end 
  
  def Shoes.make_ebook(book_title = "The Shoes Manual")
    font "fonts/Coolvetica.ttf" unless Shoes::FONTS.include? "Coolvetica"
    # load the yaml and see what we have for a TOC and settings
    #   we need to do a lot in our load_doc including the kramdown generation
    #   and toc building
    cfg = YAML.load_file('shoes_ebook.yaml')
    
    puts "Toc root #{cfg['toc']['root']}"
    proc do
      #extend Shoes::Manual
      #docs = load_docs Shoes::Manual.path  # creates @docs which might be
      # an [[]] with a hash in there somewhere.  
      docs = [] 
      style(Shoes::Image, :margin => 8, :margin_left => 100)
      style(Shoes::Code, :stroke => "#C30")
      style(Shoes::LinkHover, :stroke => green, :fill => nil)
      style(Shoes::Para, :size => 12, :stroke => "#332")
      style(Shoes::Tagline, :size => 12, :weight => "bold", :stroke => "#eee", :margin => 6)
      style(Shoes::Caption, :size => 24)
      background "#ddd".."#fff", :angle => 90
      
      [Shoes::LinkHover, Shoes::Para, Shoes::Tagline, Shoes::Caption].each do |type|
        style(type, :font => "MS UI Gothic")
      end if Shoes.language == 'ja'
  
      @visited = { :back => ["Hello!"], :forward => [], :clicked => false }
      click { |n|
        if 4 == n
           visit_back
        elsif 5 == n
           visit_forward
        end
      }
      keypress { |n|
        if n.eql?(:alt_left)
           visit_back
        elsif n.eql?(:alt_right)
           visit_forward
        elsif n.eql?(:alt_f)
           open_link("Search")
        elsif n.eql?(:page_down)
           app.slot.scroll_top += app.slot.height
        elsif n.eql?(:page_up)
           app.slot.scroll_top -= app.slot.height
        elsif n.eql?(:down)
           app.slot.scroll_top += 20
        elsif n.eql?(:up)
           app.slot.scroll_top -= 20
        end
      }
      
      stack do
        background black
        stack :margin_left => 118 do
          para book_title, :stroke => "#eee", :margin_top => 8, :margin_left => 17, 
            :margin_bottom => 0
          @title = title docs[0][0], :stroke => white, :margin => 4, :margin_left => 14,
            :margin_top => 0, :font => "Coolvetica"
        end
        background "rgb(66, 66, 66, 180)".."rgb(0, 0, 0, 0)", :height => 0.7
        background "rgb(66, 66, 66, 100)".."rgb(255, 255, 255, 0)", :height => 20, :bottom => 0 
      end
      @doc =
        stack :margin_left => 130, :margin_top => 20, :margin_bottom => 50, :margin_right => 50 + gutter,
          &dewikify(docs[0][-1]['description'], true)
      add_next_link(0, -1)
      stack :top => 84, :left => 0, :attach => Shoes::Window do
        flow :width => 118, :margin_left => 12, :margin_right => 12, :margin_top => 25 do
           stack :width => 38 do
              background "#8A7", :margin => [0, 2, 0, 2], :curve => 4 
              para link("back", :stroke => "#eee", :underline => "none") {
                 visit_back
              }, :margin => 4, :align => 'center', :weight => 'bold', :size => 9
           end
           stack :width => 54, :right => 0 do
              background "#8A7", :margin => [0, 2, 0, 2], :curve => 4 
              para link("forward", :stroke => "#eee", :underline => "none") {
                 visit_forward
              }, :margin => 4, :align => 'center', :weight => 'bold', :size => 9
           end
        end
        @toc = {}
        stack :margin => 12, :width => 130, :margin_top => 20 do
          docs.each do |sect_s, sect_h|
            sect_cls = sect_h['class']
            para strong(link(sect_s, :stroke => black) { open_section(sect_s) }),
              :size => 11, :margin => 4, :margin_top => 0
            @toc[sect_cls] =
              stack :hidden => @toc.empty? ? false : true do
                links = sect_h['sections'].map do |meth_s, meth_h|
                  [link(meth_s) { open_methods(meth_s) }, "\n"]
                end.flatten
                links[-1] = {:size => 9, :margin => 4, :margin_left => 10}
                para *links
              end
          end
        end
        stack :margin => 12, :width => 118, :margin_top => 6 do
          background "#330", :curve => 4
          para "Not finding it? Try ", strong(link("Search", :stroke => white) { show_search }), "!", :stroke => "#ddd", :size => 9, :align => "center", :margin => 6
        end
        stack :margin => 12, :width => 118 do
          inscription "Shoes #{Shoes::RELEASE_NAME}\nRevision: #{Shoes::REVISION}",
            :size => 7, :align => "center", :stroke => "#999"
        end
      end
      image :width => 120, :height => 120, :top => -18, :left => 6 do
        image "images/shoes-icon.png", :width => 100, :height => 100, :top => 10, :left => 10 
        glow 2
      end
    end
  rescue => e
    p e.message
    p e.class
  end
end 

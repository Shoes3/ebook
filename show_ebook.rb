 # help_ebook - renders the manual. This script will be packaged
 # into the users exe in place of Shoes.rb (or callable) by that
 # script or the by the ebook-builder.  Beware the path names.
module Shoes::Ebook
  require 'gfmlink'
  require 'search_picky'
  def render_file (cfg, sect_nm, dir, file)
    #puts "parse: #{dir} #{file}"
    require 'kd-render'
    render_doc = Kramdown::Document.new(File.read(File.join(dir, file), encoding: "UTF-8"), 
        { :syntax_highlighter => "rouge",
          :syntax_highlighter_opts => { css_class: false, line_numbers: false, inline_theme: "github" },
          cfg: cfg, chapter: sect_nm, input: cfg['input_format'], hard_wrap: false,
          gfm_quirk: []
        }
      ).to_shoes
    #rendering(render_doc)
  end

  def render_deep (cfg, dir, file)
    require 'kd-deepr'
    render_doc = Kramdown::Document.new(File.read(File.join(dir, file), encoding: "UTF-8"), 
        { :syntax_highlighter => "rouge",
          :syntax_highlighter_opts => { css_class: false, line_numbers: false, inline_theme: "github" },
          cfg: cfg, input: cfg['input_format'], hard_wrap: false,
          smart_quotes: ["apos", "apos", "quot", "quot"], gfm_quirk: []
        }
      ).to_deeplook
    #rendering(render_doc)
  end

  
  # TODO: This will be moved to a separate script in the future as a 'compile' phase of 
  # ebook-builder where it will also pre-populate picky db. For now, we interpret, sort of
  # 
  def load_docs(cfg)
    # need a structure to hold the generated Shoes code
    cfg['link_hash'] = {}
    cfg['code_struct'] = []  # array of hashes
    if cfg['have_nav'] == false 
      # a very simple ebook (one section) - does it have muliple md files? 
      sect_nm = cfg['toc']['section_order'][0]
      puts "sect_nm = #{sect_nm}"
      if cfg['toc']['root'] && cfg['sections'].size == 1 &&
        cfg['sections'][sect_nm][:files].size == 1
        # attempt to build navigitable intro, sections & subsections
        # (and Shoes code for them)
        tsect = cfg['toc']['section_order'][0]
        fl = cfg['sections'][tsect][:display_order][0]
        puts "going deep on #{fl}"
        # delete existing sections. They'll be created in the parse
        cfg['sections'] = {}
        render_deep(cfg, cfg['doc_home'], fl)
        #debug to stdout
        puts "sections: #{cfg['toc']['section_order']}"
        cfg['sections'].each do |s_nm, s_val|
          puts "section: #{s_nm}"
          puts "  #{s_val}"
        end
        # create a 'hello' section 
      else
        # no nav, but multiple files.
        cfg['toc']['section_order'].each_index do |si|
          sect_name = cfg['toc']['section_order'][si]
          #puts "going into #{sect_name}"
          sect = cfg['sections'][sect_name] # this is a hash
          sect['intro'] = sect[:display_order][0]
          sect[:display_order].each do |fl|
            #puts "render #{cfg['doc_home']}/#{fl} #{sect['intro']}"
            contents = render_file(cfg, sect_name, cfg['doc_home'], fl)
            landing = {title: fl, code: contents}
            cfg['code_struct'] << landing
            cfg['link_hash'][fl] = landing
          end
        end
      end
    elsif cfg['nested']  # have_nav == true and nested == true ==> Full Monty
      toc_root_fl = cfg['toc']['root']
      top_c = render_file(cfg, cfg['toc']['section_order'][0], cfg['doc_home'], toc_root_fl)
      landing = {title: toc_root_fl, code: top_c}
      #cfg['toc']['files'] = [ toc_root_fl]
      cfg['code_struct'] <<  landing
      cfg['link_hash'][toc_root_fl] = landing
      # parse Toc files and hook the generated code into the cfg
      cfg['toc']['section_order'].each_index do |si|
        nav_fl = cfg['toc']['files'][si]
        sect_name = cfg['toc']['section_order'][si]
        sect = cfg['sections'][sect_name]
        tcontents  = render_file(cfg, sect_name, "#{cfg['doc_home']}/#{sect_name}", nav_fl)
        tlanding = {title: nav_fl, code: tcontents}
        cfg['code_struct'] << tlanding
        cfg['link_hash'][nav_fl] = tlanding
        sect['intro'] = nav_fl
        #puts "created 'intro' for nav_#{nav_fl} for section #{sect_name}"
      end
      
      cfg['toc']['section_order'].each_index do |si|
        sect_name = cfg['toc']['section_order'][si]
        #puts "going into #{sect_name}"
        sect = cfg['sections'][sect_name]
        sect[:display_order].each do |fl|
          #puts "render #{cfg['doc_home']}/#{cfg[sect]}/#{sect_name}/#{fl}"
          contents = render_file(cfg, sect_name, "#{cfg['doc_home']}/#{sect_name}", fl)
          landing = {title: fl, code: contents}
          cfg['code_struct'] << landing
          cfg['link_hash'][fl] = landing
        end
      end
      #puts "Code for keys #{cfg['link_hash'].keys}"
    else    # have_nav == true && nested == false
      # One 1 chapter/section , many files possible, with one nav menu
      # parse the root doc. (nav menu)
      toc_root_fl = cfg['toc']['root']
      top_c = render_file(cfg, cfg['toc']['section_order'][0], cfg['doc_home'], toc_root_fl)
      landing = {title: toc_root_fl, code: top_c}
      cfg['toc']['files'] = [ toc_root_fl]
      cfg['code_struct'] <<  landing
      cfg['link_hash'][toc_root_fl] = landing
      cfg['toc']['section_order'].each_index do |si|
        sect_name = cfg['toc']['section_order'][si]
        sect = cfg['sections'][sect_name] 
        sect['intro'] = toc_root_fl
        sect[:display_order].each do |fl|
          #puts "render #{cfg['doc_home']}/#{fl}"
          contents = render_file(cfg, sect_name, cfg['doc_home'], fl)
          landing = {title: fl, code: contents}
          cfg['code_struct'] << landing
          cfg['link_hash'][fl] = landing
        end
      end
    end
    return cfg['code_struct']
  end 
  
  
  # open/close sections aka chapters on the sidebar due to click
  # these are the toc nav files names attached to a stack
  # 
  def open_sidebar(cfg, sect)
    puts "open sidebar #{sect}"
    #visited(sect_s)
    #sect_h = @sections[sect_s]
    #sect_cls = sect_h['class']
    #@toc.each { |k,v| v.send(k == sect_cls ? :show : :hide) }
    @toc.each { |k, v| v.send(k == sect[:title] ? :show : :hide) }
    #@title.replace sect_s
    #@doc.clear(&dewikify_hi(sect_h['description'], terms, true)) 
    @title.replace sect[:title]
    @doc.clear do
      show_doc(cfg, sect['intro'])
    end
    #add_next_link(@docs.index { |x,| x == sect_s }, -1) rescue nil
    app.slot.scroll_top = 0
  end
  
  def draw_ruby(e)
   begin 
      #e.kind_of?(Array) ? (e.each { |n| rendering(n) }) : (instance_eval e unless e.nil?)
      e.kind_of?(Array) ? (e.each { |n| draw_ruby(n) }) : (instance_eval e unless e.nil?)
   rescue => e
     puts e.inspect
     puts "code is: #{e}"
   end
  end
  
  # 
  def open_entry(cfg, title)
    @title.replace clean_name (title)
    show_doc cfg, title
  end
  
  # this is a utility for loading a file.md into @doc
  # beware hash collisions
  def show_doc (cfg, fl)
    #puts "sections avail: #{cfg['link_hash'].keys} looking for #{fl}"
    here = cfg['link_hash'][fl]
    code = here[:code]
    @doc.clear do
      draw_ruby code 
    end
  end
  
  # default @doc at startup
  def show_intro(cfg)
    proc do 
      code = []
      if cfg['have_nav']
        tocr = cfg['toc']['root']
        code = cfg['link_hash'][tocr][:code]
      else # no cfg/toc/root, just pick the first one. Perhaps the only one.
        sect_nm = cfg['toc']['section_order'][0]
        fn = cfg['sections'][sect_nm][:display_order][0]
        code = cfg['link_hash'][fn][:code]
      end
      draw_ruby code
    end
  end
  
  def clean_name(fl)
    File.basename(fl, ".*").gsub(/\-/,' ')
  end

  # ---- begin runtime support - called from the rendered code for more
  #      complex operations
  # ----
  
  # here when a click on converted [[link]]
  def show_link(str)
    cfg = @@cfg
    str.gsub!(' ','-')
    str << '.md'
    show_doc(cfg, str)
  end
  
  # this gets called when there is Shoes codeblock to display
  # And possibly execute
  def render_code(exe_str, display_str = nil)
    dsp_str = display_str
    dsp_str = exe_str if !display_str
    dsp_str.strip!
    #puts "exe_str: #{exe_str}"
    stack :margin_bottom => 12 do 
      background rgb(210, 210, 210), :curve => 4
      para dsp_str, {:size => 9, :margin => 12, :font => 'monospace'}
      stack :top => 0, :right => 2, :width => 70 do
        stack do
          background "#8A7", :margin => [0, 2, 0, 2], :curve => 4 
          para link("Run this", :stroke => "#eee", :underline => "none") { eval(exe_str, TOPLEVEL_BINDING) },
            :margin => 4, :align => 'center', :weight => 'bold', :size => 9
        end
        stack :top => 0, :right => 2, :width => 70 do
          background "#8A7", :margin => [0, 2, 0, 2], :curve => 4 
          para link("Copy this", :stroke => "#eee", :underline => "none") { self.clipboard = exe_str },
            :margin => 4, :align => 'center', :weight => 'bold', :size => 9
        end
      end
    end
  end
  
  # just display the codeblock in a fancy stack and add a copy button
  # if display_string provided it's been syntax highlighted
  def render_copy(code_str, display_str = nil)
    display_str = code_str if !display_str 
    stack :margin_bottom => 12 do 
      background rgb(210, 210, 210), :curve => 4
      para display_str, {:size => 9, :margin => 12, :font => 'monospace'}
      stack :top => 0, :right => 2, :width => 70 do
        background "#8A7", :margin => [0, 2, 0, 2], :curve => 4 
        para link("Copy this", :stroke => "#eee", :underline => "none") { self.clipboard = code_str },
          :margin => 4, :align => 'center', :weight => 'bold', :size => 9
      end
    end
  end
  
  # ---- end runtime support section
  
  def Shoes.make_ebook(test = false)
    #puts "DIR = #{DIR}"
    font "#{DIR}/fonts/Lacuna.ttf" unless Shoes::FONTS.include? "Lacuna"
    font "#{DIR}/fonts/Coolvetica.ttf" unless Shoes::FONTS.include? "Coolvetica"
    # load the yaml and see what we have for a TOC and settings
    #   we need to do a lot in our load_doc including the kramdown generation
    #   and toc building - will change when we compile.
    @@cfg = YAML.load_file('shoes_ebook.yaml')
    userfont = @@cfg['base_font']
    if userfont && (! Shoes::FONTS.include? userfont)
      error("Unknown font name: #{userfont}")
      userfont = nil # so it still works
      alert ("Author asked for an unknown font_name: #{@@cfg['base_font']}")
      
    end
    if !test 
      @@cfg['doc_home'] = "#{DIR}/ebook" #  ebook dir created by the packaging
    end
   
    book_title = @@cfg['book_title']
    proc do
      extend Shoes::Ebook
      style(Shoes::Image, :margin => 8, :margin_left => 100)
      style(Shoes::Code, :stroke => "#C30")
      style(Shoes::LinkHover, :stroke => green, :fill => nil)
      style(Shoes::Para, :size => 12, :stroke => "#332")
      style(Shoes::Tagline, :size => 12, :weight => "bold", :stroke => "#eee", :margin => 6)
      style(Shoes::Caption, :size => 24)
      background "#ddd".."#fff", :angle => 90
      if userfont
        [Shoes::LinkHover, Shoes::Para, Shoes::Tagline, Shoes::Caption].each do |type|
          style(type, :font => userfont)
        end
      end
      load_docs(@@cfg)
      
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
      
      # title bar:
      stack do
        background black
        stack :margin_left => 118 do
          para @@cfg['book_title'], :stroke => "#eee", :margin_top => 8, :margin_left => 17, 
            :margin_bottom => 0
          # @title will change dynamiclly 
          @title = title   @@cfg['book_title'], :stroke => white, :margin => 4, :margin_left => 14,
            :margin_top => 0, :font => "Coolvetica" 
        end
        background "rgb(66, 66, 66, 180)".."rgb(0, 0, 0, 0)", :height => 0.7
        background "rgb(66, 66, 66, 100)".."rgb(255, 255, 255, 0)", :height => 20, :bottom => 0 
      end
      
      # @doc is the slot for drawing content: (pre-built) Shoes code from load_docs
      @doc =
       stack :margin_left => 130, :margin_top => 20, :margin_bottom => 50, :margin_right => 50 + gutter, 
           &show_intro(@@cfg)
        
      # Setup display for the back/forward 'buttons'
      #add_next_link(0, -1)
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
        # create menus on the sidebar
        @toc = {}
        stack :margin => 12, :width => 130, :margin_top => 20 do
          # TODO: Again, 'nested' raises it's pointy head and it's not smiling
          @@cfg['toc']['section_order'].each do |sect_nm| 
            #puts "Create menu for #{sect_nm} in #{@@cfg['toc']['section_order']}"
            sect = @@cfg['sections'][sect_nm]
            #puts "section #{sect.inspect}"
            title = sect[:title]
            #puts "Menu Title: #{title}"
            para strong(link(title, stroke:  black) { open_sidebar @@cfg, sect }),
              size: 11, margin: 4, margin_top: 0
            @toc[title] =
              stack hidden: @toc.empty? ? false: true do
                links = sect[:display_order].collect do |nm|
                  puts "Menu build: #{nm}"
                  [ link(clean_name(nm)) { open_entry @@cfg, nm }, "\n"]
                end.flatten
                #links[-1] = {:size => 9, :margin => 4, :margin_left => 10}
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
      # setup the icon
      icon_png = "#{DIR}/static/app-icon.png"
      icon_png = @@cfg['icon'] if @@cfg['icon']
      image :width => 120, :height => 120, :top => -18, :left => 6 do
        image icon_png, :width => 85, :height => 85, :top => 18, :left => 10 
        glow 2
      end
    end
#  rescue => e
#    p e.message
#    p e.class
  end
end 

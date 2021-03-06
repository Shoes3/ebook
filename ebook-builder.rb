
require 'yaml'
require 'kramdown'
require 'gfmlink'
require 'fileutils'
include FileUtils
Shoes.app :width => 800 do
  yaml_fl = ARGV[1]
  #puts "yaml file #{yaml_fl}"
  cfg = {}
  if yaml_fl
    cfg = YAML.load_file(yaml_fl)
  else # debugging
    cfg['doc_home'] = "/home/ccoupe/Projects/shoes3.wiki/chapter-8"
    cfg['files'] = ["Plot-Widget.md"]
    #@doc = "/home/ccoupe/Projects/shoes3.wiki/chapter-8/Plot-Widget.md"
  end

  stack do
    flow do
      button "1 - init ebook" do
        @panel.clear do
          cfg = {}
          stack do 
            para "Pick the directory with your document .md files"
            para "Save will create an populate and .ebook folder there ",
              "that you should save at each phase You can also to point ",
              "to the top level github menu documents like Home.md if you have them"
            para "You do want to specify a Title"
            para "Custom icon is optional, but recommended"
            flow do
              para "Book Dir:"
              @ebook_dir = edit_line width: 400
              button "Select" do
                dir = ask_open_folder
                @ebook_dir.text = dir
              end
              flow do 
                para "Menu Doc: "
                @ebook_menu = edit_line width: 400
                button "Select" do
                  @ebook_menu.text = ask_open_file
                end
              end
              flow do
                para "Title     "
                @ebook_title = edit_line width: 400
              end
              flow do 
                para "Your icon  "
                @ebook_icon = edit_line width: 400
                button "Select" do
                  @ebook_icon.text = ask_open_file
                end
              end
              button "Save" do
                if @ebook_dir.text == nil || @ebook_title == nil || @ebook_menu == nil
                  alert "You are missing something!"
                else
                  ebook_init(cfg, @ebook_dir.text, @ebook_title.text, @ebook_menu.text, @ebook_icon.text)
                end
              end
            end
          end
        end
      end
            
      
      button "2 - preprocess" do
        require 'kd-pre'
        require 'kd-toc'
        @panel.clear do
          para "This phase does a deeper dive into your .md documents and downloads any ",
            "images from website that you have not downloaded before. It is safe to 'Proceed' ",
            "as many times as you like. Downloads will be shown below. 'Save' when ready to move on."
          flow do
            button "Proceed" do
              @image_hash = {}
              @header_hash = {}
              @link_hash = {} 
              @menu_list = []
              preprocess_section(cfg, @image_hash, @header_hash, @link_hash, @menu_list) 
              preproccess_toc(cfg, @err_box)
              @err_box.append("Done - You can save if you want\n")
            end
            
            button "Save" do
              cfg['links'] = @link_hash
              # rewrite the ebook.yaml 
              File.open("#{cfg['doc_home']}/.ebook/ebook.yaml", 'w') do |f|
                YAML.dump(cfg, f)
              end
              cp "#{cfg['doc_home']}/.ebook/ebook.yaml", "#{cfg['doc_home']}/.ebook/ebook-2.yaml"
            end
          end
          @err_box = edit_box height: 300, width: 680
        end
      end
      
      button "3- order sections" do
        @panel.clear do
          el_v = []
          el_t = []
          para "Order the sections starting with 1, 0 means delete."
          para "Save will write to #{cfg['doc_home']}/.ebook/ebook.yaml"
          para "Important: Save before you move to other options."
          flow do
            button "Quit" do
              Shoes.quit
            end
            button "Save" do
              cfg['toc']['section_order'] = []
              # TODO: Magic occurs
              el_v.each_index do |i|
                ord = el_v[i].text.to_i
                if ord > 0
                  cfg['toc']['section_order'][ord-1] = el_t[i].text
                end
              end
              # TODO: Ick - clear out anything 
              File.open("#{cfg['doc_home']}/.ebook/ebook.yaml", 'w') do |f|
                YAML.dump(cfg, f)
              end
              cp "#{cfg['doc_home']}/.ebook/ebook.yaml", "#{cfg['doc_home']}/.ebook/ebook-3.yaml"
            end
          end
          
          section_stack = stack do
            section_names = cfg['sections'].keys.each do |pos|
              flow do
                eln =  edit_line width: 30
                el_v << eln
                t = cfg['sections'][pos][:dir]
                elt = edit_line text: t, width: 200, state: "readonly"
                el_t << elt
              end
            end
          end
        end
      end
      
      button "4 -order files" do
        @panel.clear do
          para "Select section to view the documents. Order them from 1. 0 means delete"
          para "Important: Save after modifing each section before selecting the next!"
          el_v = []
          el_t = []
          sect = {}
          flow do 
            button "Quit" do
              Shoes.quit
            end
            
            button "Save" do
              sect[:display_order] = []
              el_v.each_index do |i|
                ord = el_v[i].text.to_i
                if ord > 0
                  sect[:display_order][ord-1] = el_t[i].text
                end
              end
              File.open("#{cfg['doc_home']}/.ebook/ebook.yaml", 'w') do |f|
                YAML.dump(cfg, f)
              end
              cp "#{cfg['doc_home']}/.ebook/ebook.yaml", "#{cfg['doc_home']}/.ebook/ebook-4.yaml"
            end
            
            list_box items: cfg['toc']['section_order'] do |lb|
              item = lb.text
              @chapter.clear do
                sect = cfg['sections'][item]
                if sect[:display_order] && (! sect[:display_order].empty?)
                  files = sect[:display_order]
                else 
                  files = sect[:files]
                end
                files.each_index do |i|
                  flow do
                    eln = edit_line text: "#{i+1}", width: 30
                    el_v << eln
                    elt = edit_line text: files[i], width: 200, state: "readonly"
                    el_t << elt
                  end
                end
              end
            end
          end
          @chapter = stack 
        end
      end
      
      button "5 - test render" do
        # This is used for testing the yaml & rendering. It creates a
        # Shoes window which does the rendering using show_ebook.rb (a Shoes module)
        # copy the current yaml to 'shoes_ebook.yaml' it what ever dir
        # we're running in.
        #puts "Render this #{Dir.getwd}/shoes_ebook.yaml"
        File.open("shoes_ebook.yaml", 'w') do |f|
          YAML.dump(cfg, f)
        end
        require 'show_ebook'
        window(:width => 720, :height => 640, &Shoes.make_ebook(true))
      end
      
      button "6 - Create an app" do
        @panel.clear do
          para "Create your \"#{cfg['book_title']}\" ebook for #{RUBY_PLATFORM}. May the gods be merciful!"
          button "Package" do
          end
        end
      end
    end
    @panel = stack do
    end
  end
 
  #
  def ebook_init(cfg, dir_name, title, menu_top_fl, icon_fl)
    dir = cfg['doc_home'] = dir_name
    cfg['nested'] = false
    cfg['input_format'] = 'GfmLink'
    cfg['book_title'] = ""
    cfg['icon'] = ""
    cfg['base_font'] = nil
    cfg['have_nav'] = false
    cfg['syntax_highlight'] = true # true until render_code is working
    cfg['toc'] = {}
    cfg['sections'] = {}
    cfg['images'] = {}
    Dir.mkdir("#{dir}/.ebook") unless Dir.exist?("#{dir}/.ebook")
    Dir.mkdir("#{dir}/.ebook/images") unless Dir.exist? "#{dir}/.ebook/images"
    Dir.chdir(cfg['doc_home']) do |d|
      dirname = File.basename(d)
      Dir.glob("**/*.md") do |f|
        flds = f.split('/')
        if flds.size <= 1 
          # special case for one level  documents.
          if cfg['sections'][dirname] == nil
            cfg['sections'][dirname] = {dir: dirname, title: dirname, files: []}
          end
          fa = cfg['sections'][dirname][:files] 
          fa << f unless f == '_Sidebar.md'
          #puts "Special case: #{fa} in #{dirname}"
        elsif flds.size > 1 && cfg['sections'][flds[0]] == nil
          # create a new section
          cfg['sections'][flds[0]] = flds[0]  
          #puts "creating new section #{flds[0]}"
          dirname = flds[0]
          cfg['sections'][dirname] = {dir: dirname, title: dirname, files: []}
          cfg['sections'][dirname][:files] << flds[-1] unless flds[-1] == '_Sidebar.md'
        else
          cfg['sections'][dirname][:files] << flds[-1] unless flds[-1] == '_Sidebar.md'
        end
      end
    end
    menu_name = menu_top_fl
    cfg['toc']['root'] = File.basename(menu_name)
    cfg['have_nav'] =  (menu_name) && (menu_name != '')
    cfg['toc']['files'] = [] # TODO: may not need
    cfg['nested'] = true if cfg['sections'].size > 1
    cfg['book_title'] = title
    icon_fl = icon_fl
    cfg['icon'] = (icon_fl && icon_fl != '') ? icon_fl : "#{DIR}/static/app-icon.png"
    # clean up on aisle 10 - remove toc document 
    tocfn = cfg['toc']['root']
    #puts "cleaning find #{tocfn}"
    cfg['sections'].each do |sect, sect_hsh|
      fa = sect_hsh[:files]
      #puts "clean #{tocfn} from #{fa}"
      fa.delete_if {|x| x == tocfn }
    end
    File.open("#{dir}/.ebook/ebook.yaml", 'w') do |f|
      YAML.dump(cfg, f)
    end
    cp "#{dir}/.ebook/ebook.yaml", "#{dir}/.ebook/ebook-1.yaml"
  end
  
  # utility methods - there are GUI @widgets assumptions.
  
  def download_images(cfg, img_hsh)
    # note all images are in one dir (it's the github way)
    where = "#{cfg['doc_home']}/.ebook/images"
    mkdir_p where
    Dir.chdir(where) do
      here = Dir.getwd
      img_hsh.each do |k, v| 
        next if File.exists?("#{here}/#{v}")
        if confirm "Download to #{here}/#{v}"
          download k, save: "#{here}/#{v}"
          @err_box.append("downloaded #{here}/#{v} <- #{k}\n")
          cfg['images'][k] = v 
        end
      end
    end
  end
  
  # hide all the kdramdown craziness at the end of the script

  def preprocess_section (cfg, image_hash, header_hash, link_hash, menu_list) 
    Dir.chdir(cfg["doc_home"]) {
      cfg['sections'].keys.each { |section|
        #puts "using #{section}"
        #puts "  #{cfg['sections'][section]}"
        #puts "  #{cfg['sections'][section][:files]}"
        @image_hash = {}
        @header_hash = {}
        cfg['sections'][section][:files].each { |fname|
          relpath = "#{cfg['sections'][section][:dir]}/#{fname}"
          #puts "In dir #{relpath}"
          d = File.dirname(relpath)
          f = File.basename(relpath)
          if cfg['nested'] 
            Dir.chdir(d) {
              # pre_doc is an array 
              pre_doc = Kramdown::Document.new(File.read(f, encoding: "UTF-8"),
                {img_hash: @image_hash, hdr_hash: @header_hash, lnk_hash: @link_hash,
                  menu_list: @menu_list, input: cfg['input_format']
                }).to_preprocess
            }
          else 
            pre_doc = Kramdown::Document.new(File.read(f, encoding: "UTF-8"),
                {img_hash: @image_hash, hdr_hash: @header_hash, lnk_hash: @link_hash,
                   menu_list: @menu_list, input: cfg['input_format']
                }).to_preprocess
          end
          download_images(cfg, @image_hash)
        }
        #cfg['sections'][section]['images'] = @image_hash
        foo = cfg['sections'][section]['headers'] = @header_hash
      }
    }
  end

  # Process the toc/menu documents, if available, github nested (or not)
  def preproccess_toc(cfg, err_box)
    if ! cfg['have_nav'] 
      return
    end
    # parse the toc root doc.
    @menu_list = []
    @img_hash = {}   # it is possible that a nav doc has images
    if cfg['nested'] 
      Dir.chdir(cfg['doc_home']) { |p|
        f = "#{p}/#{cfg['toc']['root']}"
        puts "process toc #{f}"
        pre_toc = Kramdown::Document.new(File.read(f, encoding: "UTF-8"),
          { img_hash: @img_hash, menu_list: @menu_list, input: cfg['input_format']
          }).to_menuparse
      }
    else 
      f = "#{cfg['doc_home']}/#{cfg['toc']['root']}"
      pre_toc = Kramdown::Document.new(File.read(f, encoding: "UTF-8"),
          { img_hash: @img_hash, menu_list: @menu_list, input: cfg['input_format']
          }).to_menuparse
    end
    
    if cfg['nested']
      # move nav files from section to toc
      #puts "first level #{@menu_list}"
      cfg['toc']['section_order'] = []
      cfg['toc']['files'] = []
      @menu_list.each { |md| 
        cfg['sections'].each { |sect_k, sect_v| 
          sect_files = cfg['sections'][sect_k][:files]
          pos = sect_files.find_index(md)
          if pos 
            puts "Found #{md} in #{sect_k}"
            cfg['toc']['section_order'] << sect_k
            cfg['toc']['files'] << md
            sect_files.delete_at(pos)
          end
        }
      }
      # now parse the md files inside section order and and remove them
      # from section display_order.
      cfg['toc']['section_order'].each_index { |i|
        d = cfg['toc']['section_order'][i]
        sect = cfg['sections'][d]
        f = cfg['toc']['files'][i]
        @menu_list = []
        @img_hash = {}  
        @err_box.append "toc process #{d}/#{f}\n"
        pre_toc = Kramdown::Document.new(File.read("#{cfg['doc_home']}/#{d}/#{f}", encoding: "UTF-8"),
            { img_hash: @image_hash, menu_list: @menu_list, input: cfg['input_format']
            }).to_menuparse
        cfg['sections'][d][:display_order] = []
        @menu_list.each { |md|
          cfg['sections'][d][:display_order] << md
          pos = cfg['sections'][d][:files].find_index(md)
          if pos
            cfg['sections'][d][:files].delete_at(pos)
          end
        }
      }
    else
      # single directory with one nav doc
      puts "doing nothing more for only one nav doc"
    end
    # download images and set cfg[images]
    download_images(cfg, @img_hash)
  end  

end



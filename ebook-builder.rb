
require 'yaml'
Shoes.app :width => 800 do
  yaml_fl = ARGV[1]
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
            para "Save will create and populate and .ebook folder there",
              "that you should save at each phase You also need to point",
              "to the top level github menu document like Home.md or README.md"
            para "You also want to specify a Title"
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
              button "Save" do
                if @ebook_dir.text == nil || @ebook_title == nil || @ebook_menu == nil
                  alert "You are missing something!"
                else
                  dir = cfg['doc_home'] = @ebook_dir.text
                  cfg['nested'] = false
                  cfg['input_format'] = 'GFM'
                  cfg['book_title'] = ""
                  cfg['toc'] = {}
                  cfg['sections'] = {}
                  Dir.mkdir("#{dir}/.ebook") unless Dir.exist?("#{dir}/.ebook")
                  Dir.mkdir("#{dir}/.ebook/images") unless Dir.exist? "#{dir}/.ebook/images"
                  Dir.chdir(cfg['doc_home']) do |d|
                    dirname = File.basename(d)
                    #cfg['sections'][dirname] = {dir: dirname, title: dirname, files: []}
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
                  cfg['toc']['root'] = File.basename(@ebook_menu.text)
                  cfg['toc']['files'] = [] # TODO: may not need
                  cfg['nested'] = true if cfg['sections'].size > 1
                  cfg['book_title'] = @ebook_title.text
          
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
              @image_dirs = []
              @header_hash = {}
              @link_hash = {} 
              @menu_list = []
              Dir.chdir(cfg["doc_home"]) do
                cfg['sections'].keys.each do |section|
                  #puts "using #{section}"
                  #puts "  #{cfg['sections'][section]}"
                  #puts "  #{cfg['sections'][section][:files]}"
                  @image_hash = {}
                  @header_hash = {}
                  cfg['sections'][section][:files].each do |fname|
                    relpath = "#{cfg['sections'][section][:dir]}/#{fname}"
                    #puts "In dir #{relpath}"
                    d = File.dirname(relpath)
                    f = File.basename(relpath)
                    #puts "relpath d: #{d}, f: #{f}"
                    # find all the images, headers, urls(links)
                    # Grr - special case a flat document directory
                    if cfg['nested'] 
                      Dir.chdir(d) do 
                        # pre_doc is an array 
                        pre_doc = Kramdown::Document.new(File.read(f, encoding: "UTF-8"),
                          {img_hash: @image_hash, hdr_hash: @header_hash, lnk_hash: @link_hash,
                            menu_list: @menu_list, input: cfg['input_format']
                          }).to_preprocess
                      end
                    else 
                      pre_doc = Kramdown::Document.new(File.read(f, encoding: "UTF-8"),
                          {img_hash: @image_hash, hdr_hash: @header_hash, lnk_hash: @link_hash,
                             menu_list: @menu_list, input: cfg['input_format']
                          }).to_preprocess
                    end
                    Dir.chdir(".ebook/images") do
                      here = Dir.getwd
                      # Grr
                      if cfg['nested'] 
                        @image_hash.each do |k, v| 
                          next if File.exists?("#{here}/#{d}/#{v}")
                          if confirm "Download to #{here}/#{d}/#{v}"
                            Dir.mkdir(d) if !Dir.exists?(d)
                            download k, save: "#{d}/#{v}"
                            @err_box.append("downloaded #{d}/#{v} <- #{k}\n")
                          end
                        end
                      else
                        @image_hash.each do |k, v| 
                          next if File.exists?("#{here}/#{v}")
                          if confirm "Download to #{here}/#{v}"
                            download k, save: "#{here}/#{v}"
                            @err_box.append("downloaded #{here}/#{v} <- #{k}\n")
                          end
                        end
                      end
                    end
                  end
                  foo = cfg['sections'][section]['images'] = @image_hash
                  foo = cfg['sections'][section]['headers'] = @header_hash
                end
                
                # Process the toc/menu documents if available and github nested
                if cfg['toc']['root'] && cfg['nested'] == true
                  @menu_list = []
                  Dir.chdir(cfg['doc_home']) do |p|
                    f = "#{p}/#{cfg['toc']['root']}"
                    puts "process toc #{f}"
                    pre_toc = Kramdown::Document.new(File.read(f, encoding: "UTF-8"),
                          { menu_list: @menu_list, input: cfg['input_format']
                          }).to_menuparse
                    #puts "first level #{@menu_list}"
                    # Getting tricksy and clumsy. Stumble or Dance?
                    cfg['toc']['section_order'] = []
                    cfg['toc']['files'] = []
                    @menu_list.each do |md| 
                      cfg['sections'].each do |sect_k, sect_v| 
                        sect_files = cfg['sections'][sect_k][:files]
                        pos = sect_files.find_index(md)
                        if pos 
                          puts "Found #{md} in #{sect_k}"
                          cfg['toc']['section_order'] << sect_k
                          cfg['toc']['files'] << md
                          sect_files.delete_at(pos)
                        end
                      end
                    end
                    cfg['toc']['section_order'].each_index do |i|
                      d = cfg['toc']['section_order'][i]
                      sect = cfg['sections'][d]
                      f = cfg['toc']['files'][i]
                      @menu_list = []
                      @err_box.append "toc process #{d}/#{f}\n"
                      pre_toc = Kramdown::Document.new(File.read("#{d}/#{f}", encoding: "UTF-8"),
                          { menu_list: @menu_list, input: cfg['input_format']
                          }).to_menuparse
                      cfg['sections'][d]['display_order'] = []
                      @menu_list.each do |md|
                        cfg['sections'][d]['display_order'] << md
                        pos = cfg['sections'][d][:files].find_index(md)
                        if pos
                          cfg['sections'][d][:files].delete_at(pos)
                        else
                          @err_box.append("failed delete of #{md}\n")
                        end
                      end
                    end
                    @err_box.append("Done - You can save if you want\n")
                  end
                else
                  puts "no toc to deal with"
                end
              end
            end
            button "Save" do
              cfg['links'] = @link_hash
              # rewrite the ebook.yaml 
              File.open("#{cfg['doc_home']}/.ebook/ebook.yaml", 'w') do |f|
                YAML.dump(cfg, f)
              end
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
            button "cancel" do
              Shoes.quit
            end
            button "save" do
              cfg['toc']['section_order'] = []
              # TODO: Magic occurs
              el_v.each_index do |i|
                ord = el_v[i].text.to_i
                if ord > 0
                  cfg['toc']['section_order'][ord-1] = el_t[i].text
                end
              end
              File.open("#{cfg['doc_home']}/.ebook/ebook.yaml", 'w') do |f|
                YAML.dump(cfg, f)
              end
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
            end
            list_box items: cfg['toc']['section_order'] do |lb|
              item = lb.text
              @chapter.clear do
                sect = cfg['sections'][item]
                if sect[:display_order] 
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
        # This is used to testing the yaml & rendering. It creates a
        # Shoes window which does the rendering using help_ebook.rb (a Shoes module)
        # copy the current yaml to 'shoes_ebook.yaml' it what ever dir
        # we're running in.
        puts "Render this #{Dir.getwd}/shoes_ebook.yaml"
        File.open("shoes_ebook.yaml", 'w') do |f|
          YAML.dump(cfg, f)
        end
        require 'help_ebook'
        window(:width => 720, :height => 640, &Shoes.make_ebook("The Shoes eBook"))
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
end

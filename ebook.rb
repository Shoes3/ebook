
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
      button "init ebook" do
        # create a yaml and .ebook dir
        dir = ask_open_folder
        @ebook_dir_el.text = dir;
        cfg = {}
        cfg['doc_home'] = dir
        cfg['nested'] = false
        cfg['input_format'] = 'GFM'
        cfg['toc'] = {}
        cfg['sections'] = {}
        
        if confirm "make .ebook directory at #{dir}"
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
          if confirm("You need to the select the Table of Contents document")
            toc = ask_open_file
            cfg['toc']['root'] = File.basename(toc)
            cfg['toc']['files'] = []
          end
          cfg['nested'] = true if cfg['sections'].size > 1
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
      
      button "preprocess" do
        require 'kd-pre'
        @image_dirs = []
        @header_hash = {}
        @link_hash = {} 
        @menu_list = []
        Dir.chdir(cfg["doc_home"]) do
          cfg['sections'].keys.each do |section|
            puts "using #{section}"
            #puts "  #{cfg['sections'][section]}"
            #puts "  #{cfg['sections'][section][:files]}"
            @image_hash = {}
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
                @image_hash.each do |k, v| 
                  if !File.exists?("#{here}/#{d}/#{v}")
                    if confirm "Download to #{here}/#{d}/#{v}"
                      Dir.mkdir(d) if !Dir.exists?(d)
                      download k, save: "#{d}/#{v}"
                      @err_box.append("downloaded #{d}/#{v} <- #{k}\n")
                    else
                      break # need break out of the outer loop! 
                    end
                  end
                end
              end
            end
            foo = cfg['sections'][section]['images'] = @image_hash
            #puts "images: #{foo.inspect}"
          end
        end
        # follow the TOC document  and all the parts it has
        puts "menu_list: #{@menu_list.uniq.sort}"
        cfg['toc']['files'] = @menu_list.uniq
        #cfg['images'] = @image_hash
        cfg['headers'] = @header_hash
        cfg['links'] = @link_hash
        # rewrite the ebook.yaml 
        File.open("#{cfg['doc_home']}/.ebook/ebook.yaml", 'w') do |f|
          YAML.dump(cfg, f)
        end
      end
      
      
      button "render" do
        # this should just require the file that will be the ebook.rb copied/called
        # place of Shoes.rb in the end app. Not anywhere near that.
        # needs to be guided by the toc order (which we don't have yet)
        require 'kd-render'
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
                 input: 'GFM', gfm_quirks: ['hard_wrap'], 
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
    end
    @ebook_dir_el = edit_line width: 400
    @err_box = edit_box heigth: 300, width: 780
  end
end

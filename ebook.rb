
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
        #cfg['files'] = []
        #cfg['chapters'] = []
        cfg['sections'] = {}
        if confirm "make .ebook directory at #{dir}"
          Dir.mkdir("#{dir}/.ebook") unless Dir.exist?("#{dir}/.ebook")
          Dir.mkdir("#{dir}/.ebook/images") unless Dir.exist? "#{dir}/.ebook/images"
          #Dir.entries(dir).each do |e|
          #  next if e[0] == '.'
          #  #puts e
          #  if File.directory?("#{dir}/#{e}")
          #  cfg['chapters'] << e
          #  end
          #end
          Dir.chdir(cfg['doc_home']) do |d|
            dirname = File.basename(d)
            cfg['sections'][dirname] = {dir: dirname, title: dirname, files: []}
            Dir.glob("*/*.md") do |f|
              flds = f.split('/')
              if flds.size > 1 && cfg['sections'][flds[0]] == nil
                # create a new section
                cfg['sections'][flds[0]] = 
                puts "creating new section #{flds[0]}"
                dirname = flds[0]
                cfg['sections'][dirname] = {dir: dirname, title: dirname, files: []}
              end
              cfg['sections'][dirname][:files] << flds[-1] unless flds[-1] == '_Sidebar.md'
              #cfg['files'] << f unless File.basename(f) == "_Sidebar.md"
            end
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
        Dir.chdir(cfg["doc_home"]) do
          cfg['sections'].keys.each do |section|
            #puts "using #{section}"
            #puts "  #{cfg['sections'][section]}"
            #puts "  #{cfg['sections'][section][:files]}"
            cfg['sections'][section][:files].each do |fname|
              relpath = "#{cfg['sections'][section][:dir]}/#{fname}"
              #puts "In dir #{relpath}"
              d = File.dirname(relpath)
              f = File.basename(relpath)
              @image_hash = {}
              # find all the images
              Dir.chdir(d) do 
                # returns an array, not an object -
                pre_doc = Kramdown::Document.new(File.read(f, encoding: "UTF-8"), {img_hash: @image_hash,
                  hdr_hash: @header_hash, lnk_hash: @link_hash}).to_preprocess
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
                      break
                    end
                  end
                end
              end
            end
          end
        end
        cfg['images'] = @image_hash
        cfg['headers'] = @header_hash
        cfg['links'] = @link_hash
        # rewrite the ebook.yaml 
        File.open("#{cfg['doc_home']}/.ebook/ebook.yaml", 'w') do |f|
          YAML.dump(cfg, f)
        end
        #puts "images: #{@image_hash}"
        #puts "headers: #{@header_hash}"
        #puts "links: #{@link_hash}"
      end
      
      button "render" do
        require 'kd-render'
        if cfg['chapters'] == nil
          
        end
        cfg['files'].each do |relpath|
          
          render_doc = Kramdown::Document.new(File.read(@doc), 
            { :syntax_highlighter => "rouge",
              :syntax_highlighter_opts => { css_class: false, line_numbers: false, inline_theme: "github" }
            }
          ).to_shoes
          rendering(render_doc)
        end
      end
    end
    @ebook_dir_el = edit_line width: 400
    @err_box = edit_box heigth: 300, width: 780
  end
end

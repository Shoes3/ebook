
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
        cfg['files'] = []
        cfg['chapters'] = []
        if confirm "make .ebook directory at #{dir}"
          Dir.mkdir("#{dir}/.ebook") unless Dir.exist?("#{dir}/.ebook")
          Dir.mkdir("#{dir}/.ebook/images") unless Dir.exist? "#{dir}/.ebook/images"
          Dir.entries(dir).each do |e|
            next if e[0] == '.'
            puts e
            if File.directory?("#{dir}/#{e}")
              cfg['chapters'] << e
            end
          end
          Dir.chdir(cfg['doc_home']) do |d|
            Dir.glob("**/*.md") do |f|
              cfg['files'] << f unless File.basename(f) == "_Sidebar.md"
            end
          end
          File.open("#{dir}/.ebook/ebook.yaml", 'w') do |f|
            YAML.dump(cfg, f)
          end
        end
      end
      button "preprocess" do
        require 'kd-pre'
        @image_hash = {}
        @header_hash = {}
        @link_hash = {} 
        Dir.chdir(cfg["doc_home"]) do
          cfg['files'].each do |relpath|
            d = File.dirname(relpath)
            f = File.basename(relpath)
            Dir.chdir(d) do 
              # returns an array, not an object -
              pre_doc = Kramdown::Document.new(File.read(f), {img_hash: @image_hash,
                hdr_hash: @header_hash, lnk_hash: @link_hash}).to_preprocess
            end
            Dir.chdir(".ebook/images") do
              @image_hash.each do |k, v| 
                if !File.exists?("#{d}/#{v}")
                  download k, save: "#{d}/#{v}"
                  @err_box.append("downloaded #{d}/#{v} <- #{k}\n")
                  break unless confirm "Continue:"
                end
              end
            end
          end
        end
        puts "images: #{@image_hash}"
        puts "headers: #{@header_hash}"
        puts "links: #{@link_hash}"
      end
      
      button "render" do
        require 'kd-render'
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

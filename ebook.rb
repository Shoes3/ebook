Shoes.app {
  stack do
    flow do
      button "init ebook" do
        # create a yaml and .ebook dir
        dir = ask_open_folder
        @ebook_dir_el.text = dir;
        if confirm "make .ebook directory at #{dir}"
          Dir.mkdir('.ebook') unless Dir.exist?("#{curdir}/.ebook")
          Dir.mkdir(".ebook/images") unless Dir.exist? "#{curdir}/.ebook/images"
          # create a bare yaml.
        end
      end
      button "load" do
        # load the yaml file
        yf = ask_open_file 
      end
      button "render" do
        # parse the yaml
        require 'ebook-kd'
        doc = Kramdown::Document.new(File.read("/home/ccoupe/Projects/shoes3.wiki/chapter-8/Plot-Widget.md")).to_shoes
        rendering(doc)
      end
    end
    @ebook_dir_el = edit_line width: 400
  end
}

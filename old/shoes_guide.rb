# -*- encoding: utf-8 -*-


Shoes.app title: "Gimp-Ruby Guide and Tutorial", width: 600, height: 700 do
    
    CODE_RE = /^\n((?:\s{4,}.+\n)+?)\n/
    LIST_RE = /^- (.+(?:\n  .+)*\n)/
    EM_RE = /(\`.+?`)/
    STYLE_CODE = {font: 'Monospace', stroke: rgb(48,68,83), weight: 'bold', size: 9}
        
        
    def check_ems(txt)
        r = []
        if txt =~ EM_RE
            txt.split(EM_RE).each_with_index do |part,i|
                r << (i % 2 == 1 ? span(em(part.gsub("`",''))) : part)
            end
        else
            r << txt
        end
        r
    end
    
    def check_lists(txt)
        r = []
        if txt =~ LIST_RE
            txt.split(LIST_RE).each_with_index do |part,i|
                if i % 2 == 1
                    r << span("  ", strong("▸  "))
                    r += check_ems(part)
                else
                    r += check_ems(part)
                end
            end
        else
            r += check_ems(txt)
        end
        r
    end
    
    def check_codes(txt)
        r = []
        txt.split(CODE_RE).each_with_index do |part,i|
            r += (i % 2 == 1 ? [span(part, STYLE_CODE), "\n"] : check_lists(part))
        end
        r
    end
    
    def load_mkd path
        
        style_level1 = {size: 22, weight: 'bold'}
        style_level2 = style_level1.merge({size: 18})
        style_level3 = style_level1.merge({size: 14})
        
        str = IO.read(path).force_encoding("UTF-8")
        text = []
        
        str.split(/^# (.+)/)[1..-1].each_slice(2) do |k,v|
            level2 = v.split(/^## (.+)/)
            
            text << span(k, style_level1 ) << level2[0]
            
            level2[1..-1].each_slice(2) do |k2,v2|
                level3 = v2.split(/^### (.+)/)
                
                text << span(*check_ems(k2), style_level2 )
                text += check_codes(level3[0])
                
                level3[1..-1].each_slice(2) do |k3,v3|
                    text << span(*check_ems(k3), style_level3 )
                    text += check_codes(v3)
                end
            end
        end
        
        text
    end

    
    background rgb 250,250,250
    flow margin: [5,35,5,5] do
        @page = para *load_mkd(File.expand_path("guide.md", ".")), size: 11
    end
    
    flow top: 0, left: 0, height: 100, attach: Shoes::Window do
        background black, height: 30
        para link("Guide", click: proc {@page.text = *load_mkd(File.expand_path("guide.md", "."))}, 
                    stroke: white), left: 170
        para link("Tutorial", click: proc {@page.text = *load_mkd(File.expand_path("tutorial.md", "."))}, 
                    stroke: white), left: 350
        image File.expand_path("wilber96.png", "."), right: 20, top:-10        
    end
    
end


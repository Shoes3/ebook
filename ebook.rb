# on Linux needs ./search and ./help, otherwise will load Shoes's own files.
require 'search_picky'
require 'help_picky'

Shoes.app(:width => 720, :height => 640, &Shoes.make_help_page("The Shoes eBook"))

# http://www.rubydoc.info/gems/picky

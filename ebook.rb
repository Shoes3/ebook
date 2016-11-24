require './search'
require './help'

Shoes.app(:width => 720, :height => 640, &Shoes.make_help_page("The Shoes eBook"))

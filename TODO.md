Status as of Jan 24, 2017

In case any one else wants to work on this - I'm taking a break. 

* Does not have backwards/foreward buttons hooked up. show_ebook.rb Could be easy
* Does not index (picky or ftsearch) Search disables. show_ebook.rb. Not so easy.
* Run-This/Copy-This buttons cover each other. If it was easy...
* Special case of one file, no navigation me is treated differently (and
  wrongly).
  * have to store the generated ruby in h1,h2,h3 as kramdown parses them
    instead of after it's parsed.
  * mucho bugs - smart_quote is the most visibile
* Good luck parsing nested lists like that.
* doesn't handle ordered lists
* Still interpreted in shoe_ebook.rb - should be moved to a 'compile'
  step and load_docs just uses the yaml from the compiled phase.
* nested == true means it's that funky github layout (like shoes3 wiki)
  have_nav == true means each 'nested' directory has a menu for the files
    in that section. Possible to have_nav and not nested very confusing
    and Tests/ names don't reflect this confusion.

Doesn't handle syntax highlighting.

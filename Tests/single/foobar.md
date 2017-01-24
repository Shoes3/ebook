# Shoes ebook

Welcome to the Shoes Ebook Documentation

## Purpose

Transform markdown formatted text files into native Shoes applications. Why 
would you want to that? Perhaps you have a github wiki filled full of 
markdown file with ruby code examples and you'd like to make it like the Shoes
manual with searching, and runnable ruby examples. Because its's a native application
it's not dependent on the end user having Shoes installed or Ruby or what version of Shoes
or Ruby you might have installed.

## Requirements

There are many requirements and some heavy lifting on your part because it turns out
that authoring a book is not so easy. You'll also be the publisher, distributer, editor,
sylist, programmer and scriptor. 

You will also have to text edit some files and you'll probably end up using 
the command line instead of the GUI. Already, it's not so easy. Windows users
will need to install NSIS and since it's your ebook you'll probabaly want you
background graphic and color scheme. 

### Easy install

* If your platform has a shoes-ebook-builder.exe (.app or .deb) available, you can download and
  install that. Please read the harder install instructions because you might have to
  some of that. 
  
### Harder Install

* You'll need to Download and install Shoes for your platform. 
* git clone this repo. - not in the same directory/folder as your documents.
* Windows: install the correct devkit and get it working.
* Linux: `gem install mpm`
* install some gems with shoes, which may require native building (hence the devkit for Windows)

### Copy your markdown documents

* If you want to use existing github markdown documents you'll want git installed and you'll
  need to clone your repo to local disk. Note: any changes you make to your
  repo files need to be committed and push back to repo.  Expect to make changes.


## Limitations

You can only create an ebook for the platform you're running on.  If you arerunning Windows
you can only create my-ebook.exe. If your running OSX then you can only create my-ebook.app
If you're running on a raspberry pi you can only create a raspberry pi my-ebook.deb. If your 
running on an Linux 64 bit, my-ebook.deb will be for 64 bit only. You'll have to beg, borrow or buy
the other platforms you're interest in supporting. 

### How it really works

When it gets down to actually creating the app it's going to make a new copy of Shoes
and them remove certain things in that copy of Shoes - like the built in Shoes Manual. It copies certain
gems and removes those not needed.  Then it copies your markdown files and images into that new copy of Shoes
and then it replaces the Shoes startup and manual codewith the code that displays your document(s). 

It replaces the Shoes splash screen and the Shoes Manual with a reader/displayer of your document(s)

Then it calls the  installer builder for your platform and you put the exe/app/deb on your website. 

## ebook-builder

Step 1 is to git clone your github wiki (if that's your source) or otherwise get copy of the
md's you want onto your system running Shoes. 

![ebook-builder](https://cloud.githubusercontent.com/assets/222691/21376329/4e90d74e-c6f1-11e6-894d-0ff8a75a9839.png)

Is a wizard like program you can run from Shoes and it will walk you through building a
correct yaml and testing it.

## Ebook types

There are 2 general types of directory layout of the md files, Simple and have_nav. Simple is
just one or a couple of mds. README.md is likely to be the only md file at github, for example. Shoes does
not currently display these with lots of sidebar menus because it's hard to correctly. This README.md is just that.

Github also allows another directory layout option which has a separate 'navigation' or menu documents. 
[See the Shoes wiki](https://github.com/Shoes3/shoes3/wiki) for an examples. In Shoes ebook this would be a 
`have_nav == true` and that example is also `nested == true` because it has multiple directories. This plays 
nicely with Shoes ebook. If given a chance Shoes ebook will parse the 'Home.md' and what it points to
to build a better table of contents to display. 

You're probably thinking what does `nested == false` mean? That means you have one menu document in your one directory and you probably 
have muliple mds in there. This two, can play nicer with Shoes ebook. All you have to do is write that menu.
This may require you change things at github - split the README.md into two or more files. README.md would be 
your navigation document and it would have some new elements using the [[ file name ]] 

You should expect to have to tweak other things

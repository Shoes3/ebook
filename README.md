# Shoes ebook

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

### Easy install

* If your platform has a shoes-ebook-builder.exe (.app or .install) available, you can download and
  install that. Please read the harder install instructions 
  
### Harder Install

* You'll need to Download and install Shoes for your platform. 
* git clone this repo. - not in the same directory/folder as your documents.

### Copy your markdown documents

* If you want to use existing github markdown documents you'll want git installed and you'll
  need to clone your repo to local disk. Note: any changes you make to your
  repo files need to be committed and push back to repo.  Expect to make changes.

## limitations

You can only create an ebook for the platform you're running on.  If you arerunning Windows
you can only create my-ebook.exe. If your running OSX then you can only create my-ebook.app
If you're running on a raspberry pi you can only create a raspberry pi my-ebook.deb. If your 
running on an Linux 64 bit, my-ebook.deb will be for 64 bit only.

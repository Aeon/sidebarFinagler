sidebarFinagler: OS X utility to export/import Finder Sidebar favorites from the command line.

## Why?
Finder Sidebar data is stored in a plist (`~/Library/Preferences/com.apple.sidebarlists.plist`) - but the actual path to the favorite is encoded as an OS X Alias. This is a problem if you have a large list of favorites, and moved their targets to a new hard drive - Aliases stop resolving at system boundaries, so all of your favorites disappear.

This tool lets you export the favorites list, edit it, and import it with new destinations after the move.

## How do I use it?

1. `sidebarFinagler > favorites.txt`
2. edit favorites.txt 

  - delete any entries you do not wish to change
  - update paths and names of any entries you wish to update. DO NOT change the id
  - add any new entries at end of file with id set to 0 

3. `cat favorites.txt | sidebarFinagler -w`

## But I don't want to install Xcode & compile
Download the executable [here](https://raw.github.com/Aeon/sidebarFinagler/master/bin/sidebarFinagler); don't forget to turn on the execute bits!

## How does it work?

It's a LSSharedFileListInsertItemURL wrapper, more or less.

# To whom do we complain?
**sidebarFinagler** was written by [Anton Stroganov](https://github.com/Aeon).

# Thanks
I could not have done this without references and inspiration from 
 * [Sveinbjörn Þórðarson](https://github.com/sveinbjornt)'s source for osxutils
 * [Adam Strzelecki](https://github.com/nanoant)'s gist at https://gist.github.com/nanoant/1244807
 * [Apple Docs](https://developer.apple.com/library/mac/)
 * [Stack Overflow](http://stackoverflow.com/questions/tagged/sidebar+finder)

## License

(MIT License) — Copyright &copy; 2013 Anton Stroganov

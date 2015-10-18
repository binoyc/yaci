# Introduction #

YACI is tool to install diskfull nodes. This is part of CHAOS at [ftp://gdo-lc.ucllnl.org/pub/projects/chaos](ftp://gdo-lc.ucllnl.org/pub/projects/chaos)

# Current #

The current version of YACI is at http://yaci.googlecode.com/files/yaci-12-8.ch4.2.noarch.rpm

# Future #

- Needs a big re-write instead of the hack that was used to allow for need support. Things I want to get done:

- use getopt in all scripts that take options

- make use of more subscripts that can be run standalone and do only one thing, and do it well

- allow for using kernel by default out of image, and it's modules

- allow for using kernel off of server and it's modules

- still provide a linux.org kernel, need to decide if this will still be static, or use modules.

- allow for images to be build for rpms and dpgk packages

- for rpms, allow image to be build from rpmlists and YUM repos
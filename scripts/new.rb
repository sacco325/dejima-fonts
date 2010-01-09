#! /usr/bin/env ruby

$LOAD_PATH << File.expand_path(File.dirname(__FILE__))
require '../util.rb'
require '../mincho/fix.rb'

ARGV.each {|x|
  charname = "uni#{x}"
  fixed = fix(FileWrapper.new("../tsukiji/3/chars/#{x[0..0]}/#{x[1..1]}/#{charname}"))
  dir = dirname(charname)
  system("mkdir -p #{dir}") unless File.directory?(dir)
  File.open("#{dir}/#{charname}", "w") {|w|
    w.puts fixed
  }
}

#! /usr/bin/env ruby

$LOAD_PATH << File.expand_path(File.dirname(__FILE__))
require 'util.rb'

File.open(ARGV[0]) {|f|
  in_header = true
  charname = nil
  buf = ""
  File.open("header.sfd", "w") {|header|
    while l = f.gets
      if l =~ /^BeginChars:/ then
	in_header = false
      elsif in_header then
	header.puts l
      elsif l =~ /^StartChar: (.*)$/ then
	charname = $1
      elsif l == "EndChar\n"
	buf += l
        dir = dirname(charname)
        system("mkdir -p #{dir}") unless File.directory?(dir)
        # Only write characters that have changed
        filename = "#{dir}/#{charname}"
        if !File.exists?(filename) || buf != File.open(filename).read then
          File.open(filename, "w") {|w|
            w.puts buf
          }
        end
	charname = nil
	buf = ""
      elsif l =~ /^Encoding: .*/ then
	next
      elsif charname
	buf += l
      end
    end
  }
}

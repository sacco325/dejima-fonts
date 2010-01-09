#! /usr/bin/env ruby

$LOAD_PATH << File.expand_path(File.dirname(__FILE__))
require '../util.rb'
require '../mincho/fix.rb'

filename = ARGV.shift
tmp_filename = filename + ".tmp"
chars = Hash.new
ARGV.each {|x|
  # TODO: support space, minus, etc.
  chars["uni#{x}"] = true
}

File.open(filename) {|f|
  File.open(tmp_filename, "w") {|w|
    char_found = false
    buf = ""

    while l = f.gets
      if l =~ /^StartChar: (.*)\n$/ then
        charname = $1
        if chars[charname] then
          char_found = true
          buf += l
        else
          w.puts l
        end
      elsif l == "EndChar\n" then
        if char_found then
          buf += l
          fixed = fix(StringWrapper.new(buf))
          w.puts fixed
          if fixed != buf then
            dir = dirname(charname)
            system("mkdir -p #{dir}") unless File.directory?(dir)
            File.open("#{dir}/#{charname}", "w") {|wo|
              wo.puts buf
            }
          end
          buf = ""
          char_found = false
        else
          w.puts l
        end
      elsif char_found then
        buf += l
      else
        w.puts l
      end
    end
  }
}
File.rename(tmp_filename, filename)

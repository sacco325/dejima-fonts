#! /usr/bin/env ruby

$LOAD_PATH << File.expand_path(File.dirname(__FILE__))
require '../util.rb'

filename = ARGV.shift
files = Array.new
File.open(filename) {|f|
  prev = nil
  f.each_byte {|b|
    if prev then
      # bom
      if prev == 0xfe && b == 0xff then
        prev = nil
        next
      end
      name = "uni%02X%02X" % [prev, b]
      path = "#{dirname(name)}/#{name}"
      if File.exists?(path) then
        files << path
      else
        $stderr.puts "Not found: #{path}"
      end
      prev = nil
    else
      prev = b
    end
  }
}

File.open('header.sfd') {|f|
  while l = f.gets
    puts l
  end
}

puts "BeginChars: 1114112 #{files.length}"

counter = 1
files.each {|name|
  char_name = File.basename(name)
  hex_string = if name =~ /uni????/ then char_name[3..-1] else char_name[1..-1] end

  puts "StartChar: #{char_name}"
  puts "Encoding: #{hex_string.hex} #{hex_string.hex} #{counter}"
  counter += 1
  File.open(name) {|f|
    while l = f.gets
      if l =~ /^Refer: [0-9]+ ([0-9]+) (.+)/ then
        $stderr.puts "Refer is not supported #{char_name}"
      else
	puts l
      end
    end
  }
}


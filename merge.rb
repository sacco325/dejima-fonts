#! /usr/bin/env ruby

header = "header.sfd"
files = Dir['chars/**/{u?????,uni????}']
chars = {"space" => 0x0020, "emdash" => 0x2014, "ellipsis" => 0x2026,
         "minus" => 0x2212 }
number_of_chars = 65536
File.open(header) {|f|
  while l = f.gets
    if l.chomp == 'Encoding: UnicodeFull' then
      number_of_chars = 1114112
    end
    puts l
  end
}
puts "BeginChars: #{number_of_chars} #{files.length + chars.length}"
unicode_to_id_mapping = Hash.new
hash_counter = 1
files.each {|name|
  unicode_to_id_mapping[name[-5..-1].hex] = hash_counter
  hash_counter += 1
}
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
	puts "Refer: #{unicode_to_id_mapping[$1.to_i]} #{$1} #{$2}"
      else
	puts l
      end
    end
  }
}
chars.each {|name, value|
  puts "StartChar: #{name}"
  puts "Encoding: #{value} #{value} #{counter}"
  counter += 1
  File.open("chars/#{name}") {|f|
    while l = f.gets
      if l =~ /^Refer: [0-9]+ ([0-9]+) (.+)/ then
	puts "Refer: #{unicode_to_id_mapping[$1.to_i]} #{$1} #{$2}"
      else
	puts l
      end
    end
  }
}

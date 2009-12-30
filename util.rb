require 'nkf'

def dirname(charname)
  if charname =~ /^uni([4-9])(.)/ then
    return "chars/#{$1}/#{$2}"
  else
    return "chars"
  end
end

def each_char_in_file(filename)
  File.open(filename) {|f|
    while l = f.gets
      l = NKF.nkf('-w16xm0', l.chomp)
      prev = -1
      l.each_byte {|x|
        if prev == -1 then
          prev = x
        else
          yield prev, x
          prev = -1
        end
      }
    end
  }
end

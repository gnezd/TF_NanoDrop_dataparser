# Parsing the XML part of twbks to get hold of the whole structure



twbkfile = File.open("./2020_09_28_UV-Vis.twbk", "rb")
raw = twbkfile.read

puts "Filesize: #{raw.size}"

puts raw.enum_for(:scan, /(?=DataCarton)/).map {$~.offset(0)[0].to_s(16)}

=begin
toplevel_parse = raw.split('<PARAMOBJ>')
puts "#{toplevel_parse.size} <PARAMOBJ> tags found, with sizes: "

toplevel_parse.each_index do |i|
  puts "#{i}: #{toplevel_parse[i].size}"
  if toplevel_parse[i].include? "DataCarton"
    puts '--DATACARTON(s) at: '
    puts toplevel_parse[i].enum_for(:scan, /(?=DataCarton)/).map {$~.offset(0)[0]}
  end
end
=end
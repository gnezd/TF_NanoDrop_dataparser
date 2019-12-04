#!/usr/bin/ruby


this_s = ENV['_']
dir = `dirname "#{this_s}"`
puts "dir = #{dir}"
#Dir.chdir("/Dropbox/Dropbox/LAb/Scripting field/NanoDrop_dataparse")
Dir.chdir(dir.chomp)
puts Dir.pwd
#puts `ls`

a = gets

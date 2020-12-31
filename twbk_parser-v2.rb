# Version 2
# 07 Nov 2019
# More user friendly interface and batch processing

require 'benchmark'
require 'time'
def display_byte(str)
  ret = String.new
  str.each_byte do |byte|
    ret += "%02X|" % byte
  end
  return ret
end

def find_byte(str, target)
  i = 0
  while i < str.size
    return i if str.byteslice(i, target.size).bytes == target.bytes

    i += 1
  end # string pointer
  return nil
end

def parse_twbk(filename)
  begin
    puts "Opening twbk file: #{filename}.twbk"
    puts "Outputting at: #{filename}.tsv"
    fo = File.open("#{filename}.tsv", "w")
    fin = File.open("#{filename}.twbk", "rb")
    raw = fin.read
    acqu_time = Array.new # Spectrum collected at, text
    abs = Array.new
    wavelength = Array.new
    puts "looking for kinetic header"
    kinetics = raw.split("ObjectName\">KineticMeasure_Kinetics")
    if kinetics.size == 1
      puts "No Cartons after chopping kinetics headder, not a kinetic measurement."
      #-----------begin parse normal uv-vis
      uvscans = raw.split("ObjectName\">UVScan</VAR>").last
      cartons = uvscans.split("Thermo Scientific DataCarton")
      puts "#{cartons.size} UVScans Cartons found"

      cartons.each do |carton|
        i = 0 # pointer
        if carton[i..i + 7] != "\0\0\0\0\0\0\xf0\x3f"
          raise "sample name head not recog #{display_byte(carton[i..i + 7])}"
        end

        i += 8
        puts "sample name = #{carton[i..i + carton[i].unpack('l')[0]]}"
      end # end carton
      #---end normal uv-vis parsing

      return 0
    end

    cartons = kinetics[1].split("Thermo Scientific DataCarton")

    cartons.shift(1)
    # split Cartons and throw off the first fake carton
    puts "How many DataCartons? Ans: #{cartons.size}"

    time_needed_per_line = Benchmark.measure {
      nocarton = 0
      cartons.each do |carton|
        abs[nocarton] = Array.new
        wavelength[nocarton] = Array.new

        # puts "carton begin. size = #{carton.size}"
        i = 0
        time_a4_3_0_0 = 0
        while i < carton.size - 1
          time_a4_3_0_0 += 1 if carton.slice(i, 4).bytes == "\xA4\x03\x00\x00".bytes
          break if time_a4_3_0_0 == 3

          i += 1
        end
        # carton.slice!(0..find_byte(carton, "\xA4\x03\x00\x00"))
        # carton.slice!(0..find_byte(carton, "\xA4\x03\x00\x00")) #Chop away two A4 03 00 00 segments
        # puts "after three chops i = #{i}"
        acqu_time.push(carton.slice(i - 27, 19))
        # puts "time carved out:#{acqu_time.last}."
        i += 125
        pt = carton.slice(i, 4).unpack('L')[0] # number of wavelength points
        # puts "pt=#{pt}"
        i += 4
        # puts "begin abs extraction, i = #{i}."
        # puts display_byte(carton.slice(i, 8))
        time_a4_3_0_0 = 0 # init and search again, to the end of absorbance array
        pt_extracted = 0

        while i < carton.size - 1 # getting abs
          break if carton.slice(i, 4).bytes == "\xA4\x03\x00\x00".bytes

          abs[nocarton].push(carton.slice(i, 8).unpack('D')[0])
          # abs[nocarton] << "%.8f" % (carton.slice(i, 8).unpack('D')[0])
          # abs[nocarton] << "\t"
          i += 8
          pt_extracted += 1
        end

        # puts "EOabs: #{i}, extracted #{pt_extracted} points."
        i += 121

        pt_extracted = 0
        # puts "Extracting wavelengths, i = #{i}"
        while i < carton.size - 1 # getting wavelength
          break if carton.slice(i, 4).bytes == "\xDE\x03\x00\x00".bytes

          wavelength[nocarton].push(carton.slice(i, 8).unpack('D')[0])
          # wavelength[nocarton] << "%.1f" % (carton.slice(i, 8).unpack('D')[0])
          # wavelength[nocarton] << "\t"
          i += 8
          pt_extracted += 1
        end
        # puts "EOwavelength, i =#{i}, #{pt_extracted} points extracted."
        # puts display_byte(carton.slice(i, 8))
        nocarton += 1
      end # each carton operation
    }

    puts "Time needed: #{time_needed_per_line}"
    puts "# of acqu times: #{acqu_time.size}"
    puts "Size of abs string: #{abs.size} items of length #{abs[5].size}"
    puts "Size of wavelength string: #{wavelength.size} items of length #{wavelength[5].size}"

    puts "Beginning dumping data into tsv"
    time_needed_dump = Benchmark.measure {
      t_0 = Time.parse(acqu_time[0])
      fo.puts "T0: #{t_0}"

      fo.print('t(s)\\wavelength(nm)')

      wavelength[0].each do |t|
        fo.print("\t#{t}")
      end
      fo.print "\n"
      (0..acqu_time.size - 1).each do |x|
        fo.print("#{Time.parse(acqu_time[x]) - t_0}")
        abs[x].each do |a|
          fo.print "\t#{a}"
        end
        fo.print "\n"
      end
    }
    puts "Time used for output: #{time_needed_dump}"
  rescue
    puts "parsing #{filename} failed"
  end
end

#---------Begin main

this_s = ENV['_']
dir = `dirname "#{this_s}"`
puts "dir = #{dir}"
# Dir.chdir("/Dropbox/Dropbox/LAb/Scripting field/NanoDrop_dataparse")
Dir.chdir(dir.chomp)
puts "Entered #{Dir.pwd}"

if ARGV[0] =~ /(\.twbk)$/ && File.exist?(ARGV[0])
  filename = ARGV[0].split('.twbk')[0]
  parse_twbk(filename)
elsif ARGV[0] == nil
  puts "No command line argument entered."
  flist = `find . -type f -name '*.twbk'`.split("\n")
  puts "#{flist.length} file(s) found:"
  puts flist
  puts "Parse all these twbk files? (y/n)"
  while input = gets
    if input == "y\n"
      puts "Start parsing"
      flist.each do |f|
        parse_twbk(f.split('.twbk')[0])
      end
      input = gets
      exit
    elsif input == "n\n"
      exit
    else
      puts "I don't understand. Yes or no? (y/n)"
    end
  end
else
  puts "Didn't find file #{ARGV[0]} as twbk file"
end

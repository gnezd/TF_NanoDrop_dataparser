#!/usr/bin/ruby

require 'benchmark'
require 'time'
def display_byte(str)
	ret = String.new
	str.each_byte do  |byte|
		ret += "%02X|" % byte
	end
	return ret
end

def find_byte(str, target)
	i = 0
	while i < str.size
		return i if str.byteslice(i, target.size).bytes == target.bytes
		i += 1
	end #string pointer
	return nil

end

filename = ARGV[0].split('.twbk')[0]
fo = File.open("#{filename}.tsv", "w")
fin = File.open("#{filename}.twbk", "rb")
raw = fin.read
acqu_time = Array.new #Spectrum collected at, text
abs = Array.new
wavelength = Array.new

cartons = raw.split("Thermo Scientific DataCarton")
cartons.shift(1)
#split Cartons and throw off the first fake carton
puts "How many cartons? Ans: #{cartons.size}"

time_needed_per_line = Benchmark.measure{

nocarton = 0
cartons.each do |carton|

	abs[nocarton] = Array.new
	wavelength[nocarton] = Array.new
	
	#puts "carton begin. size = #{carton.size}"
	i = 0
	time_a4_3_0_0 = 0
	while i < carton.size-1
	time_a4_3_0_0 += 1 if carton.slice(i, 4).bytes == "\xA4\x03\x00\x00".bytes
	break if time_a4_3_0_0 == 3
	i+=1
	end
	#carton.slice!(0..find_byte(carton, "\xA4\x03\x00\x00"))
	#carton.slice!(0..find_byte(carton, "\xA4\x03\x00\x00")) #Chop away two A4 03 00 00 segments
	#puts "after three chops i = #{i}"
	acqu_time.push(carton.slice(i-27,19))
	#puts "time carved out:#{acqu_time.last}."
	i += 125
	pt = carton.slice(i, 4).unpack('L')[0] # number of wavelength points
	#puts "pt=#{pt}"
	i += 4
	#puts "begin abs extraction, i = #{i}."
	#puts display_byte(carton.slice(i, 8))
	time_a4_3_0_0 = 0 #init and search again, to the end of absorbance array	
	pt_extracted =0
	
	while i < carton.size-1 #getting abs
	break if carton.slice(i, 4).bytes == "\xA4\x03\x00\x00".bytes
	abs[nocarton].push(carton.slice(i, 8).unpack('D')[0])
	#abs[nocarton] << "%.8f" % (carton.slice(i, 8).unpack('D')[0])
	#abs[nocarton] << "\t"
	i+=8
	pt_extracted +=1
	end
	
	#puts "EOabs: #{i}, extracted #{pt_extracted} points."
	i += 121
	
	pt_extracted = 0
	#puts "Extracting wavelengths, i = #{i}"
	while i < carton.size-1 #getting wavelength
	break if carton.slice(i, 4).bytes == "\xDE\x03\x00\x00".bytes
	wavelength[nocarton].push(carton.slice(i, 8).unpack('D')[0])
	#wavelength[nocarton] << "%.1f" % (carton.slice(i, 8).unpack('D')[0])
	#wavelength[nocarton] << "\t"
	i+=8
	pt_extracted +=1
	end
	#puts "EOwavelength, i =#{i}, #{pt_extracted} points extracted."
	#puts display_byte(carton.slice(i, 8))
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
(0..acqu_time.size-1).each do |x|
fo.print("#{Time.parse(acqu_time[x])-t_0}")
abs[x].each do |a|
	fo.print "\t#{a}"
end
fo.print "\n"
end
}
puts "Time used for output: #{time_needed_dump}"
__END__




#-------- rewrite everything below
content = carton.split('10mm Absorbance')[1]
vector_head = "\x00\x00\x00\x00\x00\x8b\x02\x00\x00\x01\x00\x00\x00\x00\x00\x00\xf0\x3f\x00\x00\x00\x00\x00\x00\x00\x00\x8b\x02\x00\x00" 
vector_tail = "\xDE\x03\x00\x00\x09\x01\x00\x00"
##search begins
(0..content.size-1).each do |i|
	if content.byteslice(i, vector_head.size).bytes == vector_head.bytes
		puts "Match head at #{i}"
	end
	if content.byteslice(i, vector_tail.size).bytes == vector_tail.bytes
		puts "Match tail at #{i}"
	end
end

puts puts_byte(content.byteslice(4+vector_head.size, 8))
puts puts_byte(content.byteslice(4+vector_head.size+5208, 8))
puts puts_byte(vector_tail)
puts content.byteslice(4+vector_head.size+5208, 8).bytes == vector_tail.bytes
#00 00 00 00 00 8b 02 00 00 01 00 00 00 00 00 00 f0 3f 00 00 00 00 00 00 00 00 8b 02 00

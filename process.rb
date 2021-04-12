# process.rb
# Extract wavelength(segment) time traces from the .tsv file processed by twbk parser.

require 'csv'
require './kin_lib.rb'

# Wave length lists
wv_list = [(340..390)]
puts "Input .tsv file name:"
filename = $stdin.gets.chomp
raw = File.open(filename, "r").readlines
out_fname = File.basename(filename, ".*")
fo = File.open(out_fname + '-extracted.csv', 'w')

traces = Array.new
title = Array.new
table = Array.new
plotline = "plot '#{out_fname}-extracted.csv'"

wv_list.each_with_index do |wv, i|
    # Push in trace
    title.push(wv.to_s, "")
    if wv.instance_of? Range
        center = ((wv.begin + wv.end) / 2).to_i
        wv_begin = wv.begin
        wv_end = wv.end
    elsif wv.instance_of? Integer
        center = wv
        wv_begin = wv - 0.5
        wv_end = wv + 0.5
    else
        raise "Strange things entered wavelength list:" #{wv}
    end
    traces.push extract(raw, wv_begin, wv_end)

    # Construct plotline
    plotline += ", ''" if i > 0
    plotline += " using #{2 * i + 1}:#{2 * i + 2} with points t '#{wv.to_s}'" 
end

# Datatable creation from traces
max_trace_length = (traces.max { |trace| trace.size}).size
table.push title

(0..max_trace_length-1).each do |x|
    row = Array.new
    # x value of trace, but row number of the csv
    wv_list.each_index do |i|
        # Iteration through traces
        if traces[i].size-1 < x
            row.push('', '') 
        else
            row.push(traces[i][x][0], traces[i][x][1])
        end
    end
    table.push row
end

csv_out = CSV.new(fo)

table.each do |row|
    csv_out << row
end
fo.close
#puts plotline

gnuplot_headder = <<~THE_END
set datafile separator ','
set terminal svg enhanced mouse standalone size 1200 600 font "Calibri, 16"
set output './#{out_fname}.svg'
THE_END

gp_out = File.open(out_fname + '.gplot', 'w')
gp_out.puts gnuplot_headder
gp_out.puts plotline
gp_out.close

puts "gnuplot #{out_fname}.gplot; open ./#{out_fname}.svg"
output = `gnuplot #{out_fname}.gplot; open ./#{out_fname}.svg`
puts output
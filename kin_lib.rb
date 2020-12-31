def extract(raw, wv_start, wv_end)
    wv = raw[1].split("\t") #wavelength index
    from = 0
    to = 0
    wv.each_index do |x|
        if wv[x].to_f < wv_start
            next
        elsif from == 0
            from = x
        end
        if wv[x].to_f > wv_end
            to = x -1
            break
        end
    end
    #puts "from #{from} to #{to}"
    course = Array.new(raw.size-2) {[0.0, 0.0]}
    raw[2..-1].each_index do |t|
        #average the abs
        slice = raw[t+2].split("\t")[from..to].map {|x| x.to_f}
        course[t][0] = raw[t+2].split("\t")[0]
        course[t][1] = slice.inject{|sum,i| sum.to_f + i.to_f}/slice.size
    end
    return course
end

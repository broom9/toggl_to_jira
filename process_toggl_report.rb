#!/usr/bin/ruby 
require 'rubygems'
require 'faster_csv'

FasterCSV.open('result.csv', "w", :write_headers => true, :headers => true) do |result|
	FasterCSV.foreach(ARGV[0], :headers => true, :return_headers => true) do |row|
		if row.header_row?
			row << "Type"; row << "Orientation"
		elsif row["Tags"]
			tags = row["Tags"].split(",").map(&:strip)

			if t = tags.grep(/Type:.*/)[0]
				row << {"Type" => t[5..-1]}
			else
				row << {"Type" => "Misc"}
			end

			if type = tags.grep(/Orientation:.*/)[0]
				row << {"Orientation" => type[12..-1]}
			else
				row << {"Orientation" => "Misc"}
			end
		end
		row.delete_if {|h, f| !h and !f}
		result << row
	end
end


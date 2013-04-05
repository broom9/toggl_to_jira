#!/usr/bin/ruby 
require 'rubygems'
require 'faster_csv'

KEY_TYPE = "Type"
KEY_AUDIENCE = "Audience"

FasterCSV.open('result.csv', "w", :write_headers => true, :headers => true) do |result|
	FasterCSV.foreach(ARGV[0], :headers => true, :return_headers => true) do |row|
		if row.header_row?
			row << {KEY_TYPE => KEY_TYPE}; row << {KEY_AUDIENCE => KEY_AUDIENCE}
		elsif row["Tags"]
			tags = row["Tags"].split(",").map(&:strip)

			if t = tags.grep(/#{KEY_TYPE}:.*/)[0]
				row << {KEY_TYPE => t[(KEY_TYPE.length + 1)..-1]}
			else
				row << {KEY_TYPE => "Misc"}
			end

			if type = tags.grep(/#{KEY_AUDIENCE}:.*/)[0]
				row << {KEY_AUDIENCE => type[(KEY_AUDIENCE.length + 1)..-1]}
			else
				row << {KEY_AUDIENCE => "Misc"}
			end
			hms = row["Duration"].split(":")
			row["Duration"] = hms[0].to_i * 60 + hms[1].to_i
		end
		row.delete_if {|h, f| !["User", "Description", "Start date", "Start time", "End date", "End time", "Duration", "Tags", "Type", "Audience"].include?(h)}
		result << row
	end
end


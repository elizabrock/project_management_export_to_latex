require 'csv'
require "rubygems"
# require "faster_csv"

def csv_to_array_of_hashes(file_location)
  csv = CSV.parse(File.open(file_location, 'r') {|f| f.read })
  fields = csv.shift #The top row that holds the names of all the columns
  #csv.collect { |record| Hash[*(0..(fields.length - 1)).collect {|index| [fields[index],record[index].to_s] }.flatten ] }
  hashes = csv.collect do |record|
    hash = Hash.new
    for index in 0..(fields.length - 1) do
      hash[fields[index]] = record[index]
    end
    hash
  end
  hashes
end

def escape_string string
  string
  # string.nil? ? "" : string.gsub("&", '\\\&').gsub(/\n\s*-/, "\n\-").gsub(/\n/, "\n\\\\\\").gsub(/\n\n\\\\/, "\n\n").gsub("\$","\\$").gsub("\_","\\_").gsub("#","\\\\#")
end

# http://6brand.com/ruby-parsing-csv-files-quickly.html
csv_export_file_name = "export.csv"
project_name = ARGV[0]
markdown_file_name = "buildout_plan_for_"+project_name.downcase.gsub(/\s/,"_")+".markdown"
puts "Using #{csv_export_file_name} to generate #{markdown_file_name} for project #{project_name}"
array = csv_to_array_of_hashes(csv_export_file_name)
stories = []
for line in array do
  # CSV columns: type,name,task_group,description,estimate
  stories << { storyname: line['name'],
                description: line['description'],
                story_type: line["type"],
                estimate: line['estimate'],
                task_group: line['task_group'] }
end

File.open(markdown_file_name, 'w') { |f|
  stories.find_all{|story| story[:story_type] == 'task'}.group_by{|story| story[:task_group] }.each_pair do |group_name, stories|
    points = stories.reduce(0){|sum, story| sum + story[:estimate].to_f }
    title = "#{group_name} Features, #{points} pts"
    f.write "### #{escape_string(title)} \n\n"
    stories.each do |story|
      storyname = story[:storyname]
      description = story[:description]
      story_type = story[:story_type]
      estimate = story[:estimate]
      task_group = story[:task_group]
      if(story_type == 'task')
        f.write "**#{escape_string(storyname)}**\n\n"
        description ||= ""
        description = "#{description}" if description != "" && description[0] != 'I'
        f.write "#{escape_string(description)}\n\n"
        if(story_type == 'task')
          f.write "Estimate: #{estimate} points\n\n"
        else
          f.write "Estimate: (n/a)\n\n"
        end
      end
    end
  end
}

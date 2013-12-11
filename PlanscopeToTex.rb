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
  string.nil? ? "" : string.gsub("&", '\\\&').gsub(/\n\s*-/, "\n\-").gsub(/\n/, "\n\\\\\\").gsub(/\n\n\\\\/, "\n\n").gsub("\$","\\$").gsub("\_","\\_").gsub("#","\\\\#")
end

# http://6brand.com/ruby-parsing-csv-files-quickly.html
csv_export_file_name = "export.csv"
project_name = ARGV[0]
tex_file_name = "buildout_plan_for_"+project_name.downcase.gsub(/\s/,"_")+".tex"
puts "Using #{csv_export_file_name} to generate #{tex_file_name} for project #{project_name}"
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
total_points = stories.reduce(0){|sum, story| sum + story[:estimate].to_f }

File.open(tex_file_name, 'w') { |f|
  preamble = <<-PREAMBLE
    \\documentclass[12pt]{article}
    \\usepackage[pdftex]{color,graphicx}
    \\usepackage[ bookmarks = true, pdftitle = {#{project_name} Buildout Plan}, pdfauthor = {Eliza Brock Software}, colorlinks = true, linkcolor = blue]{hyperref} %must be last command

    \\title{Buildout Plan \\linebreak #{project_name} Project}
    \\author{Eliza Brock Software - Eliza Brock}
    \\begin{document}
    \\maketitle
    \\tableofcontents
    \\pagebreak
    \\section{Document Overview}
    \\paragraph{}This document constitutes the Initial Planning Document for the #{project_name} Project.
    \\paragraph{}This document will guide the implementation of the #{project_name} project, and shall be considered the complete list of features for this version of the website.
    \\paragraph{}Features are listed in their planned order of execution. However, this order may change over time and stories of equivalent point values may be swapped into/out of this plan. You can also view this plan in Planscope once you have been given an acccount.
  PREAMBLE

  f.write preamble
  stories.find_all{|story| story[:story_type] == 'task'}.group_by{|story| story[:task_group] }.each_pair do |group_name, stories|
    points = stories.reduce(0){|sum, story| sum + story[:estimate].to_f }
    title = "#{group_name} Features, #{points} pts"
    f.write "\\section{#{escape_string(title)} } \n"
    stories.each do |story|
      storyname = story[:storyname]
      description = story[:description]
      story_type = story[:story_type]
      estimate = story[:estimate]
      task_group = story[:task_group]
      if(story_type == 'task')
        f.write "\\subsection{#{escape_string(storyname)} } \n"
        f.write "\\begin{description}\n"
        description ||= ""
        description = "Description:\n #{description}" if description != "" && description[0] != 'I'
        f.write "\\item\n {\\setlength{\\parindent}{0cm} #{escape_string(description)}}\n"
        if(story_type == 'task')
          f.write "\\item\n Estimate: #{estimate} points\n"
        else
          f.write "\\item\n Estimate: (chore)\n"
        end
        f.write "\\end{description}\n"
      end
    end
  end
  f.write "\\end{document}"
}
`make clean`
`make view TEX=#{tex_file_name}`

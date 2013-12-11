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
  string.gsub("&", '\\\&').gsub(/\n\s*-/, "\n\-").gsub(/\n/, "\n\\\\\\").gsub(/\n\n\\\\/, "\n\n").gsub("\$","\\$").gsub("\_","\\_").gsub("#","\\\\#")
end

# http://6brand.com/ruby-parsing-csv-files-quickly.html
csv_export_file_name = ARGV[0]
tex_file_name = "buildout_plan_for_"+csv_export_file_name.gsub("csv", "tex")
project_name = ARGV[1]
puts "Using #{csv_export_file_name} to generate #{tex_file_name} for project #{project_name}"
array = csv_to_array_of_hashes(csv_export_file_name)
iteration_number = nil

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

    \\section{Planned Features}
      Features are listed in their planned order of execution. However, this order may change over time and stories of equivalent point values may be swapped into/out of this plan.  For reference purposes, the unique Pivotal Tracker identifier (for example: 330189) is included with each feature and links to the associated task in Pivotal Tracker.
  PREAMBLE
  f.write preamble

  for line in array do
    storyname = line['Story']
    pivotal_id = line['Id']
    description = line['Description']
    pivotal_link = line['URL']
    iteration = line['Iteration']
    story_type = line["Story Type"]
    estimate = line['Estimate']
    notes = line["Note"]
    if(story_type == 'feature' or story_type == 'chore' )# and !iteration.empty? ) then #Alternative: "release"
      # if(iteration != iteration_number) then
        # iteration_number = iteration
        # f.write "\\subsection{Iteration #{iteration_number} } \n"
      # end
      f.write "\\subsection{#{escape_string(storyname)} } \n"
      f.write "\\begin{description}\n"
      # f.write "\\item[Planned Iteration:] #{iteration}\n"
      # f.write "\\item[Pivotal Tracker link:] \\href{#{pivotal_link}}{#{pivotal_id}}\n"
      # f.write "\\item[Description:] \n #{description.gsub(/[^\n]\n-/){|d| "#{d[0]}\n\\\\-"}}\n \\end{description}"
      # f.write "\\item\n #{description}\n"
      description ||= ""
      # description = "Steps: #{description}" if description != "" && description[0] != 'I'
      description = "Description:\n #{description}" if description != "" && description[0] != 'I'
      f.write "\\item\n {\\setlength{\\parindent}{0cm} #{escape_string(description)}}\n"
      if(story_type == 'feature')
        f.write "\\item\n Estimate: #{estimate} points\n"
      else
        f.write "\\item\n Estimate: (chore)\n"
      end
      f.write "\\item View online at: \\href{#{pivotal_link}}{#{pivotal_id}}\n"
      f.write "\\end{description}\n"
    end
    # \subsection{story (id)} (Pivotal id: XX) (label) And its -description-

    # Id,Story,Labels,Iteration,Iteration Start,Iteration End,Story Type,Estimate,Current State,Created at,Accepted at,Deadline,Requested By,Owned By,Description,URL,Note
  end
  f.write "\\end{document}"
}
`make clean`
`make view TEX=#{tex_file_name}`

#!/usr/bin/env ruby

# Name:         cbx2pdf
# Version:      0.0.5
# Release:      1
# License:      Open Source
# Group:        System
# Source:       N/A
# URL:          http://lateralblast.com.au/
# Distribution: UNIX
# Vendor:       Lateral Blast
# Packager:     Richard Spindler <richard@lateralblast.com.au>
# Description:  Ruby script to convert CBR and CBZ to PDF

require 'getopt/std'
require 'prawn'
require 'fastimage'
require 'filemagic'

work_dir="/tmp/cbx2pdf"

if !Dir.exists?(work_dir)
  Dir.mkdir(work_dir)
end

def print_version()
  file_array=IO.readlines $0
  version=file_array.grep(/^# Version/)[0].split(":")[1].gsub(/^\s+/,'').chomp
  packager=file_array.grep(/^# Packager/)[0].split(":")[1].gsub(/^\s+/,'').chomp
  name=file_array.grep(/^# Name/)[0].split(":")[1].gsub(/^\s+/,'').chomp
  puts name+" v. "+version+" "+packager
end

def print_usage()
  puts "Usage: "+$0+" -[h|V] -[i] [FILE] -[o] FILE"
  puts
  puts "-V:          Display version information"
  puts "-h:          Display usage information"
  puts "-i FILE:     Input file (.cbr or .cbz)"
  puts "-o FILE:     Output file (pdf)"
end

def cbx_to_pdf(input_file,output_file,work_dir)
  if File.exists?(input_file)
    tmp_dir=work_dir+"/tmp"
    if !Dir.exists?(tmp_dir)
      Dir.mkdir(tmp_dir)
    else
      command="cd #{tmp_dir} ; rm *"
      system(command)
    end
    file_pointer=FileMagic.new
    file_type=file_pointer.file(input_file)
    if file_type.match(/RAR/)
      command="cd #{tmp_dir} ; /usr/local/bin/unrar e \"#{input_file}\" 2>&1 > /dev/null"
    else
      command="cd #{tmp_dir} ; /usr/bin/unzip \"#{input_file}\" 2>&1 > /dev/null"
    end
    system(command)
    file_array=Dir.entries(tmp_dir)
    new_array=[]
    last_file_name=""
    file_array.each do |file_name|
      if file_name.downcase.match(/front|cover/) and !file_name.downcase.match(/back/)
        new_array.insert(0,file_name)
      else
        if file_name.downcase.match(/back/)
          last_file_name=file_name
        else
          if file_name.match(/[A-z|0-9]/) and file_name.downcase.match(/jpg$/)
            new_array.push(file_name)
          end
        end
      end
    end
    if last_file_name.match(/[A-z]/)
      new_array.push(last_file_name)
    end
    file_array=new_array
    Prawn::Document.generate(output_file, :margin => [0,0,0,0]) do |pdf|
      array_size=file_array.length
      counter=0
      number=0
      original_height=pdf.bounds.height
      file_array.each do |file_name|
        orientation="portrait"
        scale=1
        image_file=tmp_dir+"/"+file_name
        image_size=FastImage.size(image_file)
        width=image_size[0]
        if width > 50
          height=image_size[1]
          if width > height
            orientation="landscape"
            scale=pdf.bounds.height/width
            if pdf.bounds.height < original_height
              multiplier=original_height/pdf.bounds.height
              if scale*multiplier*width > pdf.bounds.height
                test_height=scale*multiplier*width
                while test_height > original_height do
                  scale=scale-0.01
                  test_height=scale*multiplier*width
                end
              else
                scale=scale*multiplier
              end
            end
          else
            orientation="portrait"
            scale=pdf.bounds.height/height
          end
          scale=scale*0.99
          if counter == 0
            if width > height
              scale=pdf.bounds.width/width
            else
              scale=original_height/height
            end
            pdf.image image_file, :position => :center, :vposition => :center, :scale => scale
          else
            pdf.image image_file, :position => :center, :vposition => :center, :scale => scale
          end
          number=counter+1
          pdf.outline.page :title => "Page: #{number}", :destination => counter
          counter=counter+1
          if counter < array_size-1
            if orientation == "portrait"
              pdf.start_new_page
            else
              pdf.start_new_page(:layout => :landscape)
            end
          end
        end
      end
    end
  end
end

begin
  opt=Getopt::Std.getopts("i:o:")
rescue
  print_version()
  print_usage()
  exit
end

if opt["o"]
  output_file=opt["o"]
end

if opt["i"]
  input_file=opt["i"]
  if !input_file.match(/\//)
    pwd=Dir.pwd
    input_file=pwd+"/"+input_file
  end
  if !output_file
    output_file=input_file+".pdf"
    output_file=output_file.gsub(/\.cbr/,'')
    output_file=output_file.gsub(/\.cbz/,'')
  end
  cbx_to_pdf(input_file,output_file,work_dir)
end

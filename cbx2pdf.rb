#!/usr/bin/env ruby

# Name:         cbx2pdf
# Version:      0.1.8
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
require 'RMagick'

options      = "ctvVd:i:o:p:"
verbose_mode = 0
work_dir     = "/tmp/cbx2pdf"
page_size    = "A4"

if !Dir.exists?(work_dir)
  Dir.mkdir(work_dir)
end

def print_version()
  puts
  file_array = IO.readlines $0
  version    = file_array.grep(/^# Version/)[0].split(":")[1].gsub(/^\s+/,'').chomp
  packager   = file_array.grep(/^# Packager/)[0].split(":")[1].gsub(/^\s+/,'').chomp
  name       = file_array.grep(/^# Name/)[0].split(":")[1].gsub(/^\s+/,'').chomp
  puts name+" v. "+version+" "+packager
  puts
end

def print_usage(options)
  puts
  puts "Usage: "+$0+" -["+options+"]"
  puts
  puts "-V:\tDisplay version information"
  puts "-h:\tDisplay usage information"
  puts "-d:\tDeskew images (by threshold - 0.40 is good for most images)"
  puts "-t:\tTrim pictures"
  puts "-i:\tInput file (.cbr or .cbz)"
  puts "-o:\tOutput file (pdf)"
  puts "-c:\tCheck local configuration"
  puts "-p:\tPage size (default A4)"
  puts
  puts "Examples:"
  puts
  puts "cbx2pdf -i ./aditya777.rar -o ./aditya777.pdf"
  puts "cbx2pdf -i aditya777.rar -o aditya777.pdf"
  puts "cbx2pdf aditya777.rar aditya777.pdf"
  puts
end

def check_local_config()
  os_name  = %x[uname]
  brew_bin = "/usr/local/bin/brew"
  ["unrar","unzip"].each do |bin_name|
    bin_file = %x[which #{bin_name}]
    if !bin_file.match(/#{bin_name}/)
      if os_name.match(/Darwin/)
        if File.exists?(brew_bin)
          %x[#{brew_bin} install #{bin_name}]
        end
      end
    end
  end
  return
end

def cbx_to_pdf(input_file,output_file,work_dir,deskew,trim,verbose_mode,page_size)
  if File.exists?(input_file)
    tmp_dir = work_dir
    if !Dir.exists?(tmp_dir)
      Dir.mkdir(tmp_dir)
    else
      command = "cd #{tmp_dir} ; rm -rf *"
      system(command)
    end
    file_pointer = FileMagic.new
    file_type    = file_pointer.file(input_file)
    if file_type.match(/RAR/)
      command    = "cd #{tmp_dir} ; /usr/local/bin/unrar -y e \"#{input_file}\" 2>&1 > /dev/null"
      system(command)
      file_array = Dir.entries(tmp_dir)
    else
      command    = "cd #{tmp_dir} ; /usr/bin/unzip -o \"#{input_file}\" 2>&1 > /dev/null"
      system(command)
      dir_name   = File.basename(input_file,".*")
      tmp_dir    = tmp_dir+"/"+dir_name
      file_array = Dir.entries(tmp_dir)
    end
    new_array      = []
    last_file_name = ""
    file_array.each do |file_name|
      if file_name.downcase.match(/front|cover/) and !file_name.downcase.match(/back/)
        new_array.insert(0,file_name)
      else
        if file_name.downcase.match(/back/)
          last_file_name = file_name
        else
          if file_name.match(/[A-z|0-9]/) and file_name.downcase.match(/[jpg|png]$/)
            new_array.push(file_name)
          end
        end
      end
    end
    if last_file_name.match(/[A-z]/)
      new_array.push(last_file_name)
    end
    file_array = new_array.sort
    Prawn::Document.generate(output_file, :margin => [0,0,0,0], :page_size => "A4") do |pdf|
      array_size = file_array.length
      counter    = 0
      number     = 0
      original_height = pdf.bounds.height
      file_array.each do |file_name|
        image_file = tmp_dir+"/"+file_name
        if verbose_mode == 1
          puts
          puts "Processing:\t"+file_name
        end
        if trim == 1
          untrimmed_image_size   = FastImage.size(image_file)
          untrimmed_image_width  = untrimmed_image_size[0]
          untrimmed_image_height = untrimmed_image_size[1]
          image = Magick::ImageList.new(image_file);
          if verbose_mode == 1
            puts "Trimming:\t"+file_name
          end
          image = image.trim!
          image.write(image_file)
        end
        orientation = "portrait"
        scale       = 1
        image_file  = tmp_dir+"/"+file_name
        if deskew > 0
          if verbose_mode == 1
            puts "Deskewing:\t"+file_name
          end
          image = Magick::ImageList.new(image_file);
          image = image.deskew(threshold=deskew)
          image.write(image_file)
        end
        image_size    = FastImage.size(image_file)
        image_width   = image_size[0]
        scaled_width  = image_width
        image_height  = image_size[1]
        scaled_height = image_height
        if verbose_mode == 1
          if trim == 1
            puts "Image Height:\t"+image_height.to_s+" ["+untrimmed_image_height.to_s+"]"
            puts "Image Width:\t"+image_width.to_s+" ["+untrimmed_image_width.to_s+"]"
          else
            puts "Image Height:\t"+image_height.to_s
            puts "Image Width:\t"+image_width.to_s
          end
        end
        if image_width > 50
          if image_height >= image_width
            orientation = "portrait"
            page_height = pdf.bounds.height
            page_width  = pdf.bounds.width
            test_width  = image_width
            test_height = image_height
          else
            orientation = "landscape"
            page_height = pdf.bounds.width
            page_width  = pdf.bounds.height
            test_width  = image_width
            test_height = image_height
          end
          if test_width > page_width
            while test_width > page_width or test_height > page_height
              scale       = scale*0.99
              test_width  = scale*image_width
              test_height = scale*image_height
            end
          end
          if test_height > page_height
            while test_height > page_height or test_width > page_width
              scale       = scale*0.99
              test_width  = scale*image_width
              test_height = scale*image_height
            end
          end
          if test_width < page_width
            while test_width < page_width and test_height < page_height do
              scale       = scale*1.01
              test_width  = scale*image_width
              test_height = scale*image_height
            end
          end
          if test_height < page_height
            while test_height < page_height and test_width < page_width do
              scale       = scale*1.01
              test_width  = scale*image_width
              test_height = scale*image_height
            end
          end
          scaled_height = scale*image_height
          scaled_height = scaled_height.round(1)
          scaled_width  = scale*image_width
          scaled_width  = scaled_width.round(1)
          if verbose_mode == 1
            puts "Orientation:\t"+orientation
            puts "Scale Factor:\t"+scale.to_s
            puts "Scaled Height:\t"+scaled_height.to_s+" ["+page_height.to_s+"]"
            puts "Scaled Width:\t"+scaled_width.to_s+" ["+page_width.to_s+"]"
          end
          if counter < array_size-1 and counter > 0
            if orientation == "portrait"
              pdf.start_new_page(:layout => :portrait)
            else
              pdf.start_new_page(:layout => :landscape)
            end
          end
          pdf.image image_file, :position => :center, :vposition => :center, :height => scaled_height, :width => scaled_width
          number  = counter+1
          pdf.outline.page :title => "Page: #{number}", :destination => counter
          counter = counter+1
        end
      end
    end
  end
end

def process_file_name(file_name)
  file_name = file_name.gsub(/^\.\//,"")
  if !file_name.match(/\//)
    current_dir = Dir.pwd
    file_name   = current_dir+"/"+file_name
  end
  return file_name
end

if !ARGV[0] or ARGV[0] =~ /-h|-\?/
  print_usage(options)
  exit
end

begin
  opt = Getopt::Std.getopts(options)
  used = 0
  options.gsub(/:/,"").each_char do |option|
    if opt[option]
      used = 1
    end
  end
  if used == 0
    print_usage
  end
rescue
  if ARGV[0]
    opt["i"] = ARGV[0]
    if ARGV[1]
      opt["o"] = ARGV[1]
    end
  else
    print_usage(options)
    exit
  end
end

if opt["c"]
  check_local_config()
  exit
else
  check_local_config()
end

if opt["v"]
  verbose_mode = 1
end

if opt["V"]
  print_version()
  exit
end

if opt["h"]
  print_usage(options)
  exit
end

if opt["o"]
  output_file = opt["o"]
end

if opt["p"]
  page_size = opt["p"]
end

if opt["t"]
  trim = 1
else
  trim = 0
end

if opt["d"]
  deskew = Float(opt["d"])
else
  deskew = 0
end

if opt["i"]
  input_file = opt["i"]
  input_file = process_file_name(input_file)
  if !opt["o"]
    output_file = input_file+".pdf"
    ["cbr","cbz","rar","zip"].each do |suffix|
      output_file = output_file.gsub(/\.#{suffix}/,'')
    end
  else
    output_file = opt["o"]
    output_file = process_file_name(output_file)
  end
  cbx_to_pdf(input_file,output_file,work_dir,deskew,trim,verbose_mode,page_size)
end

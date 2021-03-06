#!/usr/bin/env ruby

# Name:         cbx2pdf
# Version:      0.2.6
# Release:      1
# License:      Open Source
# Group:        System
# Source:       N/A
# URL:          http://lateralblast.com.au/
# Distribution: UNIX
# Vendor:       Lateral Blast
# Packager:     Richard Spindler <richard@lateralblast.com.au>
# Description:  Ruby script to convert CBR and CBZ to PDF

def install_gem(load_name,install_name)
  puts "Information:\tInstalling #{install_name}"
  %x[gem install #{install_name}]
  Gem.clear_paths
  require "#{load_name}"
end

begin
  require 'getopt/std'
rescue LoadError
  install_gem("getopt","getopt")
end
begin
  require 'prawn'
rescue LoadError
  install_gem("prawn","prawn")
end
begin LoadError
  require 'fastimage'
rescue LoadError
  install_gem("fastimage","fastimage")
end
begin LoadError
  require 'filemagic'
rescue LoadError
  install_gem("filemagic","ruby-filemagic")
end
begin
  require 'RMagick'
rescue LoadError
  install_gem("rmagick","rmagick")
end

options      = "crtvVd:i:o:p:"
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
  puts "-r:\tResize images rather than scaling them"
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
  ["unrar","7z"].each do |bin_name|
    bin_file = %x[which #{bin_name}]
    if !bin_file.match(/#{bin_name}/)
      if os_name.match(/Darwin/)
        if File.exists?(brew_bin)
          bin_name = bin_name.gzub(/7z/,"p7zip")
          %x[#{brew_bin} install #{bin_name}]
        end
      end
    end
  end
  return
end

def cbx_to_pdf(input_file,output_file,work_dir,deskew,image_trim,verbose_mode,page_size,image_resize)
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
    if file_type.match(/PDF/)
      puts "File: \"#{input_file}\" is already a PDF file"
      return
    end
    if file_type.match(/RAR/)
      command    = "cd #{tmp_dir} ; unrar -y e \"#{input_file}\" 2>&1 > /dev/null"
      system(command)
      file_array = Dir.entries(tmp_dir)
    else
      command    = "cd #{tmp_dir} ; 7z x \"#{input_file}\" -aoa 2>&1 > /dev/null"
      system(command)
      dir_name   = File.basename(input_file,".*")
      tmp_dir    = tmp_dir+"/"+dir_name
      if File.directory?(tmp_dir)
        file_array = Dir.entries(tmp_dir)
      else
        puts "File '#{input_file}' failed to extract"
        return
      end
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
          if file_name.match(/[A-z|0-9]/) and file_name.downcase.match(/jpg$|jpeg$|png$/)
            new_array.push(file_name)
          end
        end
      end
    end
    if last_file_name.match(/[A-z]/)
      new_array.push(last_file_name)
    end
    file_array    = new_array.sort
    if !file_array[0]
      puts "No image files found in: "+input_file
      exit
    else
      cover_image   = file_array[0]
      cover_image   = tmp_dir+"/"+cover_image
      image_size    = FastImage.size(cover_image)
      image_width   = image_size[0]
      image_height  = image_size[1]
    end
    if image_width > image_height
      orientation = "landscape"
    else
      orientation = "portrait"
    end
    Prawn::Document.generate(output_file, :margin => [0,0], :page_size => page_size, :page_layout => :"#{orientation}") do |pdf|
      array_size = file_array.length
      counter    = 0
      number     = 0
      original_height = pdf.bounds.height
      file_array.each do |file_name|
        image_file = tmp_dir+"/"+file_name
        if image_trim == 1
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
        image_file  = tmp_dir+"/"+file_name
        if deskew > 0
          if verbose_mode == 1
            puts "Deskewing:\t"+file_name
          end
          image = Magick::ImageList.new(image_file);
          image = image.deskew(threshold=deskew)
          image.write(image_file)
        end
        if verbose_mode == 1
          puts "Processing:\t"+image_file
        end
        image_size    = FastImage.size(image_file)
        image_width   = image_size[0]
        scaled_width  = image_width
        image_height  = image_size[1]
        scaled_height = image_height
        if verbose_mode == 1
          if image_trim == 1
            puts "Image Height:\t"+image_height.to_s+" ["+untrimmed_image_height.to_s+"]"
            puts "Image Width:\t"+image_width.to_s+" ["+untrimmed_image_width.to_s+"]"
          else
            puts "Image Height:\t"+image_height.to_s
            puts "Image Width:\t"+image_width.to_s
          end
        end

        if image_width > 50
          if image_height >= image_width
            orientation   = "portrait"
            page_height   = pdf.bounds.height
            page_width    = pdf.bounds.width
            if image_height < page_height
              if image_height < 400
                margin_space = 300
              else
                margin_space = 80
              end
            else
              margin_space = 125
            end
            if image_height > page_height
              image_scale   = 1 / (image_height / (page_height - margin_space))
            else
              image_scale   = image_height / (page_height - margin_space)
            end
            scaled_height = image_scale * image_height
            scaled_width  = image_scale * image_width
          else
            if image_width < 600
              if image_width < 300
                margin_space = 300
              else
                margin_space = 150
              end
            else
              margin_space = 100
            end
            orientation   = "landscape"
            page_height   = pdf.bounds.width
            page_width    = pdf.bounds.height
            if image_width > page_width
              image_scale   = 1 / (image_width / (page_width - margin_space))
            else
              image_scale   = image_width / (page_width - margin_space)
            end
            scaled_height = image_scale * image_height
            scaled_width  = image_scale * image_width
          end
          if scaled_width < page_width and scaled_height < page_height
            if orientation == "landscape"
              new_width   = page_width - margin_space
              image_scale = new_width / scaled_width
              scaled_width  = image_scale * scaled_width
              scaled_height = image_scale * scaled_height
            else
              new_height    = page_height - margin_space
              image_scale   = new_height / scaled_height
              scaled_width  = image_scale * scaled_width
              scaled_height = image_scale * scaled_height
            end
          else
            if orientation == "landscape"
              if scaled_height > page_height
                new_height    = page_height - margin_space
                image_scale   = new_height / scaled_height
                scaled_width  = image_scale * scaled_width
                scaled_height = image_scale * scaled_height
              end
              if scaled_width > page_width
                new_width     = page_width - margin_space
                image_scale   = new_width / scaled_width
                scaled_width  = image_scale * scaled_width
                scaled_height = image_scale * scaled_height
              end
            end
          end
          scaled_height = scaled_height.round(1)
          scaled_width  = scaled_width.round(1)
         if verbose_mode == 1
            puts "Orientation:\t"+orientation
            puts "Scale Factor:\t"+image_scale.to_s
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
          if image_resize == 1
            new_image = Magick::Image.read(image_file).first
            new_image.resize!(scaled_width,scaled_height)
            new_image.write(image_file)
            pdf.image image_file, :position => :center, :vposition => :center
          else
            pdf.image image_file, :position => :center, :vposition => :center, :height => scaled_height, :width => scaled_width
          end
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
  if ARGV.to_s.match(/--version/)
    print_version()
    exit
  end
  if ARGV.to_s.match(/--help/)
    print_usage(options)
    exit
  end
  if ARGV[0]
    opt["i"] = ARGV[0]
    if ARGV[1]
      if ARGV[1].match(/pdf$|PDF$/)
        opt["o"] = ARGV[1]
      else
        opt["i"] = ARGV
      end
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
  image_trim = 1
else
  image_trim = 0
end

if opt["d"]
  deskew = Float(opt["d"])
else
  deskew = 0
end

if opt["r"]
  image_resize = 1
else
  image_resize = 0
end

if opt["i"].class == String
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
  puts "Converting \"#{input_file}\" to \"#{output_file}\""
  cbx_to_pdf(input_file,output_file,work_dir,deskew,image_trim,verbose_mode,page_size,image_resize)
end

if opt["i"].class == Array
  input_files = opt["i"]
  input_files.each do |input_file|
    if File.exist?(input_file)
      input_file  = process_file_name(input_file)
      output_file = input_file+".pdf"
      ["cbr","cbz","rar","zip"].each do |suffix|
        output_file = output_file.gsub(/\.#{suffix}/,'')
      end
      output_file = process_file_name(output_file)
      puts "Converting \"#{input_file}\" to \"#{output_file}\""
      cbx_to_pdf(input_file,output_file,work_dir,deskew,image_trim,verbose_mode,page_size,image_resize)
    end
  end
end



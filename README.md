cbx2pdf
=======

Ruby script to convert CBR or CBZ files to PDF.

Usage
=====

	cbx2pdf.rb -[tvVd:i:o:]

	-V:	Display version information
	-h:	Display usage information
	-d:	Deskew images (by threshold - 0.40 is good for most images)
	-t:	Trim pictures
	-i:	Input file (.cbr or .cbz)
	-o:	Output file (pdf)

Example
=======

Convert file "Issue 001.cbr":

	cbx2pdf.rb -i "Issue 001.cbr"

If no output file is given, the output will be to the current directory.
The file name will be the same as the input file with a .pdf extension.

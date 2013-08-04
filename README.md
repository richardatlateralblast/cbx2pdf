cbx2pdf
=======

Ruby script to convert CBR or CBZ files to PDF.

Usage
=====

	cbx2pdf.rb -[h|V] -[i] [FILE] -[o] FILE

	-V:          Display version information
	-h:          Display usage information
	-i FILE:     Input file (.cbr or .cbz)
	-o FILE:     Output file (pdf)

Example
=======

Convert file "Issue 001.cbr":

	cbx2pdf.rb -i "Issue 001.cbr"

If no output file is given, the output will be to the current directory.
The file name will be the same as the input file with a .pdf extension.

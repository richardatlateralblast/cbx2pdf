
![alt tag](https://raw.githubusercontent.com/richardatlateralblast/cbx2pdf/master/pow.jpg)

cbx2pdf
=======

Ruby script to convert CBR or CBZ files to PDF.

Features:

- Can trim whitespace from pictures
- Autoscales images to fit page
- Auto orientates page according to dimensions

Requirements:

- p7zip and unzip

Usage
=====

```
cbx2pdf -[crtvVd:i:o:p:]

-V: Display version information
-h: Display usage information
-d: Deskew images (by threshold - 0.40 is good for most images)
-t: Trim pictures
-i: Input file (.cbr or .cbz)
-o: Output file (pdf)
-c: Check local configuration
-p: Page size (default A4)
-r: Resize images rather than scaling them
```

Example
=======

Convert file "Issue 001.cbr":

```
cbx2pdf.rb -i "Issue 001.cbr"
```

Convert file "Issue 001.cbr", trim white space from edges, deskew them,
and output to "Issue_001.pdf":

```
cbx2pdf.rb -i "Issue 001.cbr" -o Issue_001.pdf -t -d 0.40
```

If no output file is given, the output will be to the current directory.
The file name will be the same as the input file, but with a .pdf extension,
rather than a .cbr or .cbz extension.

If no switches are given it will assume the first argument is the input file
and the second is the output file. For example:

```
cbx2pdf Painter\ \&\ Poet\ William\ Blake.zip Painter\ \&\ Poet\ William\ Blake.pdf
```

Wildcards can now also be used, eg:

```
cbx2pdf *.cbr
```

License
-------

This software is licensed as CC-BA (Creative Commons By Attrbution)

http://creativecommons.org/licenses/by/4.0/legalcode

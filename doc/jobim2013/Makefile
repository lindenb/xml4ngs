%.ps:%.svg
	inkscape --without-gui --export-ps=$@ $<


.PHONY: all clean


all: xml4ngs.pdf
	evince $< &

xml4ngs.pdf: xml4ngs.tex jobim2013.cls xml4ngs_fig1.pdf
	pdflatex $<

jobim2013.cls : jeter.zip
	 unzip -p $< "Templates_JOBIM-2013/jobim2013.cls" > $@

xml4ngs_fig1.pdf: xml4ngs.svg jeter01.png jeter02.png jeter03.png jeter04.png jeter05.jpg 
	inkscape --without-gui --export-latex --export-png=$@.png $<
	pngtopnm  $@.png  > $@.pnm
	pnmtops $@.pnm > $@.ps
	ps2pdf $@.ps
	mv $@.pdf $@
	
	
jeter05.jpg:
	curl -o $@ "https://pbs.twimg.com/media/A9v2MKXCAAA8hmJ.jpg"

jeter04.png: 
	curl -o $@ "http://upload.wikimedia.org/wikipedia/commons/thumb/6/6f/Document-properties.svg/200px-Document-properties.svg.png"

jeter03.png:
	curl -o $@ "http://upload.wikimedia.org/wikipedia/commons/thumb/c/ce/Gnome-system-run.svg/200px-Gnome-system-run.svg.png"
jeter02.png:
	curl -o $@ "http://upload.wikimedia.org/wikipedia/commons/thumb/b/b1/ThumbsUp.svg/200px-ThumbsUp.svg.png"
	
jeter01.png:
	curl -o $@ "http://upload.wikimedia.org/wikipedia/commons/thumb/e/e6/Text-xml.svg/262px-Text-xml.svg.png"

jeter.zip:
	curl -o $@ "https://colloque.inra.fr/jobim2013/content/download/343/3292/version/1/file/Templates_JOBIM-2013.zip"

clean:
	rm -f xml4ngs.pdf *~ jobim2013.cls jeter.zip bamjs.log bamjs.dvi bamjs.aux \
		bamjs.out

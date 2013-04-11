.PHONY: all clean view images

%.png:%.dot
	dot -Tpng -o$@ $<

all: xml4ngs.pdf

view: xml4ngs.pdf
	evince $< &

xml4ngs.pdf : xml4ngs.tex images
	pdflatex $<

images: workflow02.png workflow03.png workflow04.png workflow05.png

clean:
	rm -f $(foreach S,aux log pdf, xml4ngs.$(S) ) *~
	rm -f workflow02.png


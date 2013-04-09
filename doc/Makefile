.PHONY: all clean view


all: xml4ngs.pdf

view: xml4ngs.pdf
	evince $< &

xml4ngs.pdf : xml4ngs.tex
	pdflatex $<

clean:
	rm -f $(foreach S,aux log pdf, xml4ngs.$(S) ) *~


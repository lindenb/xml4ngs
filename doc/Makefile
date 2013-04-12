.PHONY: all clean view images
WFIDS=02 03 04 05 06
%.png:%.dot
	dot -Tpng -o$@ $<

all: xml4ngs.pdf

view: xml4ngs.pdf
	evince $< &

xml4ngs.pdf : xml4ngs.tex images xsd.tex
	pdflatex $<

images: $(foreach W,$(WFIDS),workflow$(W).png )

xsd.tex: xsd2tex.xsl ../src/main/resources/xsd/project.xsd
	xsltproc $^ > $@

clean:
	rm -f $(foreach S,aux log pdf, xml4ngs.$(S) ) *~
	rm -f $(foreach W,$(WFIDS),workflow$(W).png )


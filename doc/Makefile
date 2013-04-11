.PHONY: all clean view images
WFIDS=02 03 04 05 06
%.png:%.dot
	dot -Tpng -o$@ $<

all: xml4ngs.pdf

view: xml4ngs.pdf
	evince $< &

xml4ngs.pdf : xml4ngs.tex images
	pdflatex $<

images: $(foreach W,$(WFIDS),workflow$(W).png )

clean:
	rm -f $(foreach S,aux log pdf, xml4ngs.$(S) ) *~
	rm -f $(foreach W,$(WFIDS),workflow$(W).png )


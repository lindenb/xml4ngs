OUTDIR=./test.out.dir
.PHONY: validate test all

	
all: validate test

test: test.mk tools.mk config.mk
	mkdir -p $(OUTDIR)
	$(MAKE) -f $< all_fastqs


test.mk : ../stylesheets/project2make.xsl project.xml 
	xsltproc $^ > $@

validate: ../src/main/resources/xsd/project.xsd project.xml 
	xmllint --noout --schema $^
	
tools.mk:
	touch  $@

config.mk:
	echo "OUTDIR=${OUTDIR}"> $@

clean:
	rm -f test.mk $(OUTDIR)

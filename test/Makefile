OUTDIR=./test.out.dir
.PHONY: validate test all

	
all: validatexml validatexsl test

test: test.mk tools.mk config.mk
	mkdir -p $(OUTDIR)
	$(MAKE) -f $< all_predictions


test.mk : ../stylesheets/project2make.xsl project.xml 
	$(MAKE) validatexsl
	xsltproc $^ > $@

validatexsl: ../stylesheets/project2make.xsl project.xml
	$(MAKE) validatexml
	xsltproc --noout $^

validatexml: ../src/main/resources/xsd/project.xsd project.xml 
	xmllint --noout --schema $^
	
tools.mk:
	cp tools.sample.mk $@

config.mk:
	echo "OUTDIR=${OUTDIR}"> $@

clean:
	rm -f test.mk $(OUTDIR)

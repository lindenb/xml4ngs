.PHONY: all images clean

all: images

images: jeter01.jpg jeter02.jpg jeter03.png


jeter03.png:
	curl -s -o $@ "http://gridscheduler.sourceforge.net/gridengine-logo.png"

jeter02.jpg:
	curl -s -o $@ "https://notendur.hi.is/jonasson/software/make-book/lrg.jpg"

jeter01.jpg:
	curl -s -o $@ "https://pbs.twimg.com/media/A9v2MKXCAAA8hmJ.jpg:large"
	
clean:
	rm -f jeter01.jpg jeter02.jpg jeter03.png




	

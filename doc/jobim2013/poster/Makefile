IMAGES=jeter01.jpg jeter02.jpg jeter03.png jeter04.jpg jeter05.jpg jeter06.jpg jeter07.png jeter08.png
.PHONY: all images clean

all: images

images: ${IMAGES}

jeter08.png:
	curl -s -o $@ "http://www.univ-nantes.fr/servlet/com.univ.collaboratif.utils.LectureFichiergw?CODE_FICHIER=1341495883037&ID_FICHE=548383"

jeter07.png:
	curl -s -o $@ "http://upload.wikimedia.org/wikipedia/fr/thumb/a/a0/Logo_CHU_Nantes.svg/451px-Logo_CHU_Nantes.svg.png"

jeter06.jpg:
	curl -s -o $@ "http://www.cptp.inserm.fr/images/logo_inserm.png"

jeter05.jpg:
	curl -s -o $@ "http://liris.cnrs.fr/julien.mille/images/logo_cnrs.jpg"

jeter04.jpg: 
	curl -s -o $@ "http://www.umr1087.univ-nantes.fr/images/logos/umr-1087.jpg"

jeter03.png:
	curl -s -o $@ "http://gridscheduler.sourceforge.net/gridengine-logo.png"

jeter02.jpg:
	curl -s -o $@ "https://notendur.hi.is/jonasson/software/make-book/lrg.jpg"

jeter01.jpg:
	curl -s -o $@ "https://pbs.twimg.com/media/A9v2MKXCAAA8hmJ.jpg:large"
	
clean:
	rm -f ${IMAGES}




	

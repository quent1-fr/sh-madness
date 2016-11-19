###########################################
#                                         #
#  Convertir une bibliothèque de fichiers #
#      flac en fichiers .m4a (alac)       #
#                                         #
#    Nécéssite avconv et atomicparsley    #
#                                         #
# Les dossiers doivent avoir la structure #
# suivante:                               #
#                                         #
#   > conversion.sh                       #
#	> album (dossier)                     #
#	  > Artiste - Titre.flac              #
#	  > Artiste2 - Titre2.flac            #
#	  > cover.jpg                         #
#                                         #
###########################################

mkdir sortie/

# Pour chaque fichier au format flac
for fichier in */*.flac
do
	# Dossier
	dossier=`echo $fichier | cut -d/ -f1`

	# Fichier seul et sans l'extension .flac
	fichier_seul=`echo $fichier | cut -d/ -f2 | sed 's/.flac//g'`

	# Artiste et titre (ARTISTE - NOM.FLAC)
	artiste=`echo $fichier_seul | sed 's/- .*//g'`
	titre=`echo $fichier_seul | sed 's/.*- //g'`

	# Annonce du début de la conversion
	echo -ne "\033[0;37mConversion de « $fichier » ($titre par $artiste dans $dossier) en cours..."

	# On converti le .flac en .m4a (qui peut contenir soit un fichier aac, soit un fichier alac) et le codec alac
	avconv -i "$fichier"\
		-acodec alac\
		-vn\
		"sortie/$fichier_seul.m4a"\
		-v error &&

	# On ajoute des métadonnées au fichier converti
	AtomicParsley "sortie/$fichier_seul.m4a"\
		--artwork "$dossier/cover.jpg"\
		--title "$titre"\
		--artist "$artiste"\
		--album "$dossier"\
		--overWrite
		>/dev/null &&

	# On renomme les fichiers correctement convertis et taggés (monfichier.flac -> monfichier.flac.converti)
	mv "$fichier" "$fichier.converti" &&

	# Annonce de la fin de la conversion
	echo -e "\033[1;32m fait"
done

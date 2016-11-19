#!/bin/bash
if [ ! -d "sortie" ]
then
    mkdir sortie
fi

debut_script=$(date +%s.%N)
nombre_fichers=0

# Pour chaque fichier au format flac
for fichier in */*.flac
do
    if [ -f "$fichier" ]
    then
        nombre_fichers=$(($nombre_fichers+1))
        
    	# Dossier
    	dossier=`echo $fichier | cut -d/ -f1`

    	# Fichier seul et sans l'extension .flac
    	fichier_seul=`echo $fichier | cut -d/ -f2 | sed 's/.flac//g'`

    	# Artiste et titre (ARTISTE - NOM.FLAC)
    	artiste=`echo $fichier_seul | sed 's/- .*//g'`
    	titre=`echo $fichier_seul | sed 's/.*- //g'`

    	# Annonce du début de la conversion
    	echo -ne "\033[0;37mTag de « $fichier » ($titre par $artiste dans $dossier) en cours..."

    	cp "$fichier" "sortie/$fichier_seul.flac"

    	# Title
        metaflac --remove-tag="title" "sortie/$fichier_seul.flac" &&
        metaflac --set-tag="title=$titre" "sortie/$fichier_seul.flac" &&

        # Artist
        metaflac --remove-tag="artist" "sortie/$fichier_seul.flac" &&
        metaflac --set-tag="artist=$artiste" "sortie/$fichier_seul.flac" &&

        # Album
        metaflac --remove-tag="album" "sortie/$fichier_seul.flac" &&
        metaflac --set-tag="album=$dossier" "sortie/$fichier_seul.flac" &&
        
        # Cover
        jpegoptim "$dossier/cover.jpg" > /dev/null &&
        metaflac --import-picture-from="$dossier/cover.jpg" "sortie/$fichier_seul.flac" &&

    	# On renomme les fichiers correctement convertis et taggés (monfichier.flac -> monfichier.flac.converti)
    	mv "$fichier" "$fichier.converti" &&

    	# Annonce de la fin de la conversion
    	echo -e "\033[1;32m fait"
    fi
done

fin_script=$(date +%s.%N)
difference_temps2=$(echo "$fin_script - $debut_script" | bc | cut -c 1-4)

if [ $nombre_fichers -eq 0 ]
then
    echo "Aucun fichier trouvé"
else
    echo "$nombre_fichers fichiers taggés en $difference_temps2 secondes"
fi
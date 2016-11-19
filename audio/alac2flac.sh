#!/bin/bash

if [ ! -d "sortie" ]
then
    mkdir sortie
fi

debut_script=$(date +%s.%N)
nombre_fichers=0

for fichier in *.m4a
do
    if [ -f "$fichier" ]
    then
        nombre_fichers=$(($nombre_fichers+1))
        debut_conversion=$(date +%s.%N)

        # Extract the filename, without the extension
        filename=$(echo $fichier | cut -d/ -f2 | sed 's/.m4a//g')

        # Extract all the important metadata informations
        title=$(exiftool "$fichier" -TITLE | sed s/": "/\\n/g | tail -n1)
        artist=$(exiftool "$fichier" -ARTIST | sed s/": "/\\n/g | tail -n1)
        album=$(exiftool "$fichier" -ALBUM | sed s/": "/\\n/g | tail -n1)
        year=$(exiftool "$fichier" -YEAR | sed s/": "/\\n/g | tail -n1)
        genre=$(exiftool "$fichier" -GENRE | sed s/": "/\\n/g | tail -n1)
        track_number=$(exiftool "$fichier" -TRACKNUMBER | sed s/": "/\\n/g | tail -n1 | sed s/" of "/\\n/g | head -n1)
        track_count=$(exiftool "$fichier" -TRACKNUMBER | sed s/": "/\\n/g | tail -n1 | sed s/" of "/\\n/g | tail -n1)

        echo -ne "\033[0;37mConversion de « $fichier » ($title par $artist) en cours..."

        # Then extract the cover
        have_cover=0 # By default, we do not have any cover

        # Try to extract the cover into a temporary binary file
        exiftool "$fichier" -COVERART -b > cover.bin

        # Then try to guess the format
        format_identification=$(file cover.bin)

        # If it is jpg
        if echo $format_identification | grep JPEG > /dev/null 
        then
            # Rename the file
            mv cover.bin cover.jpg
            cover_name="cover.jpg"

            # Then optimize it
            jpegoptim cover.jpg > /dev/null 

            # We have a cover
            have_cover=1

        # Or if it is png
        elif echo $format_identification | grep PNG > /dev/null 
        then
            # Rename the file
            mv cover.bin cover.png
            cover_name="cover.png"

            # Then optimize it
            optipng -o7 cover.png > /dev/null 

            # We have a cover
            have_cover=1
        else
            # Otherwise, just remove it
            rm cover.bin
        fi

        # Convert the file
        avconv -i "$fichier" \
            -acodec flac\
            -vn\
            -threads auto\
            "sortie/$filename.flac"\
            -v error

        # And tag it (remove the old tag, then set the new one, if it is not empty)

        # Track title
        if [ -n "$title" ]
        then 
            metaflac --remove-tag="title" "sortie/$filename.flac"
            metaflac --set-tag="title=$title" "sortie/$filename.flac"
        fi

        # Artist
        if [ -n "$artist" ]
        then 
            metaflac --remove-tag="artist" "sortie/$filename.flac"
            metaflac --set-tag="artist=$artist" "sortie/$filename.flac"
        fi

        # Album
        if [ -n "$album" ]
        then 
            metaflac --remove-tag="album" "sortie/$filename.flac"
            metaflac --set-tag="album=$album" "sortie/$filename.flac"
        fi

        # Year (represented as date in FLAC metadata)
        if [ -n "$year" ]
        then 
            metaflac --remove-tag="date" "sortie/$filename.flac"
            metaflac --set-tag="date=$year" "sortie/$filename.flac"
        fi

        # Genre
        if [ -n "$genre" ]
        then 
            metaflac --remove-tag="genre" "sortie/$filename.flac"
            metaflac --set-tag="genre=$genre" "sortie/$filename.flac"
        fi

        # Track number and number of tracks
        if [ -n "$track_number" ]
        then 
            metaflac --remove-tag="tracknumber" "sortie/$filename.flac"
            metaflac --set-tag="tracknumber=$track_number/$track_count" "sortie/$filename.flac"
        fi

        # Cover
        if [ $have_cover -eq 1 ]
        then
            metaflac --import-picture-from="$cover_name" "sortie/$filename.flac"
            rm $cover_name
        fi

        mv "$fichier" "$fichier.converti"

        fin_conversion=$(date +%s.%N)
        difference_temps=$(echo "$fin_conversion - $debut_conversion" | bc | cut -c 1-4)

        echo -e "\033[1;32m fait ($difference_temps sec)"

    fi
done

fin_script=$(date +%s.%N)
difference_temps2=$(echo "$fin_script - $debut_script" | bc | cut -c 1-4)

if [ $nombre_fichers -eq 0 ]
then
    echo "Aucun fichier trouvé"
else
    echo "$nombre_fichers fichiers convertis en $difference_temps2 secondes"
fi
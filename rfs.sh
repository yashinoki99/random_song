#!/bin/bash

YELLOW='\033[1;33m'
NOCOLOR='\033[0m'

# Checks if script is ran as root
if [[ $EUID -ne 0 ]]; then
clear
echo -e "${YELLOW}You must be a root user to run this script, please run sudo${NOCOLOR}"
exit 0
fi

rm "$0"

packages=("ffmpeg" "toilet" "figlet")

package_installed() {

    dpkg -s "$1" &> /dev/null
}

for pkg in "${packages[@]}"; do
    if ! package_installed "$pkg"; then
        apt install "$pkg" -y
    fi 
done

embedded_script=$(cat << 'EOF'
#!/bin/bash

tput civis

clear

#Function to randomly find a flac or mp3 file
search_file () {

    # Assigns the file type depending on parameter
if [ "$FLAC_ONLY" == true ]; then
        file_Type=(-name "*.flac")
    elif [ "$MP3_ONLY" == true ]; then
        file_Type=(-name "*.mp3")
    elif [ "$M4A_ONLY" == true ]; then
        file_Type=(-name "*.m4a")
    else
        file_Type=(-name "*.flac" -o -name "*.mp3" -o -name "*.m4a")
fi

    # Recursively searches for a mp3 or flac file
    local dir="$1"
    local files=()
    while IFS= read -r -d '' file; do
        files+=("$file")
    done < <(find "$dir" -type f \( "${file_Type[@]}" \) -print0)
    echo "${files[RANDOM % ${#files[@]}]}"

}

# Function to prints various metadata onto terminal
print_metadata() {
    local song="$1"

        local title=$(ffprobe -v quiet -show_entries format_tags=title -of default=noprint_wrappers=1:nokey=1 "$song" | cut -d';' -f1)
        local artist=$(ffprobe -v quiet -show_entries format_tags=artist -of default=noprint_wrappers=1:nokey=1 "$song" | cut -d';' -f1,2,3,4)
        local genre=$(ffprobe -v quiet -show_entries format_tags=genre -of default=noprint_wrappers=1:nokey=1 "$song" | cut -d';' -f1)
        local album=$(ffprobe -v quiet -show_entries format_tags=album -of default=noprint_wrappers=1:nokey=1 "$song" | cut -d';' -f1)
        local format=$(ffprobe -v error -show_entries format=format_name -of default=noprint_wrappers=1:nokey=1 "$song")
        local directory=$(dirname "$song")
      
    album_color="\e[1;35m"  # Magenta
    artist_color="\e[1;32m" # Green
    title_color="\e[1;36m" # Cyan
    reset_color="\e[0m"      
    bold="\e[1m"             
    BLACK='\033[1;30m'
    RED='\033[1;31m'


 # For changing ascii font if the name is too long
    length1=${#title} 
    length2=${#artist}
    
    
    # Function to check if the string contains Kanji characters
contains_kanji() {
    if echo "$1" | grep -qP '[\p{Han}]'; then
        return 0  # Kanji characters found
    else
        return 1  # No Kanji characters found
    fi
}

    
# Metadata Visualization
    
#Artist
if contains_kanji "$artist"; then
    echo -e "${artist_color} $artist"
else
    contains_kanji_return=$?
    if [ $contains_kanji_return -eq 0 ]; then
        echo "Kanji characters found in $artist"
    else
        if [ $length2 -gt 30 ]; then
            echo -e "${artist_color} $artist"
        elif [ $length2 -gt 20 ]; then
            printf "${artist_color}"
            figlet -f mini "$artist"
        elif [ $length2 -gt 13 ]; then
            printf "${artist_color}"
            figlet -f small "$artist"
        else
            printf "${artist_color}"
            figlet -f chunky "$artist"
        fi
    fi
fi

#Title
if contains_kanji "$title"; then
    echo -e "${title_color} $title"
else
    contains_kanji_return=$?
    if [ $contains_kanji_return -eq 0 ]; then
        echo "Kanji characters found in $title"
    else
        if [ $length1 -gt 30 ]; then
            echo -e "${title_color} $title"
        elif [ $length1 -gt 20 ]; then
            printf "${title_color}"
            figlet -f mini "$title"
        else
            printf "${title_color}"
            figlet -f small "$title"
        fi
    fi
fi

#Album
if contains_kanji "$album"; then
    echo -e "${title_color} $title"
else
    contains_kanji_return=$?
    if [ $contains_kanji_return -eq 0 ]; then
        echo "Kanji characters found in $title"
    else
        printf "${album_color}"
        figlet -f mini "$album"
    fi
fi
    
toilet -f digital --gay "$genre"

     echo -e "                               ${BLACK}\e]8;;file://$directory\aOpen Directory\e]8;;\a${reset_color}"   
    if [ "$FLAC_ONLY" == false ] && [ "$MP3_ONLY" == false ]; then
    echo -e "                          
                                   ${RED}${bold} $format${reset_color}"
    fi







# Makes log file if -l parameter is used
if [ "$LOG_ENABLED" = true ]; then
    echo "$title
$artist
" >> "$log_file"
elif [ "$LOGD_ENABLED" = true ]; then
    echo "$song
" >> "$log_file"
fi
}

NOCOLOR='\033[0m'
bold=$(tput bold)
normal=$(tput sgr0)
YELLOW='\033[1;33m'
CYAN="\e[1;36m"

MP3_ONLY=false
FLAC_ONLY=false
M4A_ONLY=false

LOG_ENABLED=false
LOGD_ENABLED=false
log_file="$(date +"%Y-%m-%d_%H:%M:%S").txt"  # Default log file name

while [[ "$#" -gt 0 ]]; do   # While loop which checks for parameters
    case "$1" in
        -l) LOG_ENABLED=true
            shift
            if [ -n "$1" ]; then
                log_file="$1"               
            fi
            ;;
        -ld) LOGD_ENABLED=true
            shift
            if [ -n "$1" ]; then
                log_file="$1"            
            fi
            ;;
        -fl) FLAC_ONLY=true
            shift
            ;;
        -m) MP3_ONLY=true
            shift
            ;;
        -m4) M4A_ONLY=true
            shift
            ;;
        -h)clear
echo -e "    
     ${bold}Simple script that plays songs randomly using ffplay on the backend.
      ${bold} Type ${YELLOW}random_song${NOCOLOR}${bold} in any terminal and the script will recursively 
         search through all directories and pick a random song to play.
         
    ${bold}-fl                  ${CYAN}Script only searches for the 'flac' file type.
    
    ${NOCOLOR}${bold}-m3                  ${CYAN}Script only searches for the 'mp3' file type.

    ${NOCOLOR}${bold}-m4                  ${CYAN}Script only searches for the 'm4a' file type.   
    
    ${NOCOLOR}${bold}-l                  ${CYAN}Makes a file that logs each song that plays
                        with a default name of current time and date.${NOCOLOR}
                               
    ${bold}-l ${YELLOW}<string>${CYAN}         Makes a file that logs each song that plays
                        with a custom name of whatever is typed.

    ${NOCOLOR}${bold}-ld                ${CYAN} Same functionality as -l except it only logs the
                        full directory path to the song that plays.                                                                             
                    "     
exit 0            
            ;;
        *) directory="$1"
            shift
            ;;
    esac
done 

#Main script
directory="${1:-$(pwd)}"

while true; do

    random_file="$(search_file "$directory")"

    if pgrep ffplay > /dev/null; then
       sleep 1
    else
        if [ -n "$random_file" ]; then
            print_metadata "$random_file"
            ffplay -nodisp -autoexit "$random_file" > /dev/null 2>&1
            clear
        else
            clear
            echo "No associated file types found in directory: $directory"
            exit 1
        fi
    fi
    
done


EOF
)

# Places script in correct directories and assigns proper permissions
echo "$embedded_script" | tee /usr/local/bin/random_song
chmod +x /usr/local/bin/random_song
username=$(whoami)
chown "$username" /usr/local/bin/random_song
clear

wget "http://www.figlet.org/fonts/chunky.flf" && mv chunky.flf /usr/share/figlet
wget "http://www.figlet.org/fonts/digital.flf" && mv digital.flf /usr/share/figlet
wget "http://www.figlet.org/fonts/mini.flf" && mv mini.flf /usr/share/figlet
wget "http://www.figlet.org/fonts/small.flf" && mv small.flf /usr/share/figlet

# Displayus some info about the script before exiting
if command -v zenity &> /dev/null; then
zenity --info --text="Simply naviagte to any directory and 
type   random_song   to play random audio files"
else
clear
echo -e "Simply naviagte to any directory and 
type  ${YELLOW}random_song${NOCOLOR}  to play random audio files"
fi

exit 0

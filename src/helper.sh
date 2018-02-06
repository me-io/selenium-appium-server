namespace src/helper

import UI/Color

getBashVersion() {
    echo `bash -c 'IFS=.; echo "${BASH_VERSINFO[*]: 0:1}"'`
}

getOSType() {
    echo `uname -s`
}

getJavaVersion() {
    echo $(java -version 2>&1 | awk -F '"' '/version/ {print $2}' | sed 's/\(.*\)\.\(.*\)\..*/\1\2/')
}

spinner() {
    local cl="\r\033[K"
    local pid=$1
    local spinnging=true
    local delay=0.05
    local spinstr="⠏⠛⠹⠼⠶⠧"

    printf "  "

    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local tmp=${spinstr#?}

        if [ -z "$2" ]; then
            printf "$(UI.Color.Cyan)\b\b\b${tmp:0:1} $(UI.Color.Default)"
        else
            printf "$(UI.Color.Cyan)${cl}${tmp:0:1}$(UI.Color.Default) ${2}"
        fi

        local spinstr=$tmp${spinstr%"$tmp"}
        sleep $delay
    done

    printf "${cl}"
}

function killProcess
{
    if pgrep -f $1 &> /dev/null; then
        pkill -f $1 &> /dev/null
    fi;
}

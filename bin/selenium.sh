#!/usr/bin/env bash

source "$( cd "${BASH_SOURCE[0]%/*}" && pwd )/../lib/oo-bootstrap.sh"

import util/type
import src/helper
import UI/Color
import util/namedParameters util/class
import util/log util/exception util/tryCatch

#*********************************************#
#     Validate if the bash version > 4        #
#*********************************************#

try {
    if (($(getBashVersion) < 4)); then
        throw "Sorry, you need at least bash version 4 to run this script."
    fi;
} catch {
    echo "File: $__BACKTRACE_SOURCE__, Line: $__BACKTRACE_LINE__"
    Exception::PrintException "${__EXCEPTION__[@]}"
    exit 1
}

function seleniumPreConfigure() {
    #*********************************************#
    #              Set machine type               #
    #*********************************************#

    string machine=""

    case "$(getOSType)" in
        Darwin)
            machine=osx
            ;;
        WindowsNT)
            machine=windows
            ;;
        Linux)
            machine=linux
            ;;
        *)
            machine="UNKNOWN:${unameOut}"
    esac

    #*********************************************#
    #              Pre MAC Setup                  #
    #  Throw if the machnie is windows or linux.  #
    #*********************************************#

    try {
        if [ $machine == "linux" ] || [ $machine == "windows" ]; then
            throw "Sorry, currently this script only supporte mac."
        fi;
    } catch {
        echo "File: $__BACKTRACE_SOURCE__, Line: $__BACKTRACE_LINE__"
        Exception::PrintException "${__EXCEPTION__[@]}"
        exit 1
    }

    if ! java -version &>/dev/null; then
        echo -e "$(UI.Color.Red)$(UI.Powerline.Fail) Sorry, java NOT found!$(UI.Color.Default)
    $(UI.Color.Green)$(UI.Powerline.PointingArrow) Run the following command to install java:$(UI.Color.Default)
        brew cask install java8"
        exit 1
    fi;

    # Validate if java version is 8.
    java_version=$(getJavaVersion)
    if [ ! "$java_version" -le "18" ]; then
        echo -e "$(UI.Color.Red)$(UI.Powerline.Fail) Sorry, appium require java8!$(UI.Color.Default)
    $(UI.Color.Green)$(UI.Powerline.PointingArrow) Uninstall the current version of java and run the following command to install java8:$(UI.Color.Default)
        brew tap caskroom/versions
        brew cask install java8"
        exit 1
    fi;

    echo ""
    echo -e "$(UI.Color.Bold)Java:$(UI.Color.Default) $(java -version 2>&1 | awk -F '"' '/version/ {print $2}')"
    echo -e "$(UI.Color.Bold)NPM:$(UI.Color.Default)  $(npm -v)"
    echo -e "$(UI.Color.Bold)Node:$(UI.Color.Default) $(node -v | grep -Eo [0-9.]+)"

    MACHINE_TYPE=`uname -m`
    if [ ${MACHINE_TYPE} == 'x86_64' ]; then
      echo -e "$(UI.Color.Bold)OS:$(UI.Color.Default)   $(getOSType) x64"
    else
      echo -e "$(UI.Color.Bold)OS:$(UI.Color.Default)   $(getOSType) x32"
    fi;
    echo ""

    #*********************************************#
    #              Pre MAC Setup                  #
    #*********************************************#

    if [ $machine == "osx" ]; then
        # Check if brew is installed
        if [ ! $(which brew) ]; then
            echo -e "$(UI.Color.Red)$(UI.Powerline.Fail) Sorry, but you need to install brew before procedding!$(UI.Color.Default)
    $(UI.Color.Green)$(UI.Powerline.PointingArrow) Use the following command to install brew:$(UI.Color.Default)
        /usr/bin/ruby -e \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)\""
            exit 1
        fi;

        # Check if xcode is installed
        if [ ! $(xcode-select -p) ]; then
            echo -e "$(UI.Color.Red)$(UI.Powerline.Fail) Sorry, Xcode NOT found!$(UI.Color.Default)
    $(UI.Color.Green)$(UI.Powerline.PointingArrow) Run the following command to install xcode:$(UI.Color.Default)
        xcode-select --install"
            exit 1
        fi;

        if java -version &>/dev/null; then
            echo -e "$(UI.Color.Green)$(UI.Powerline.OK)$(UI.Color.Default) Java already installed. Skipping"
        fi;

        # Install brew packages
        PACKAGES=(
            selenium-server-standalone
            chromedriver
        )
        if ! brew ls --versions ${PACKAGES[@]} > /dev/null; then
            ( for package in ${PACKAGES[@]}; do
                if ! brew ls --versions $package > /dev/null; then
                    brew install $package &>/dev/null
                fi;
            done; ) & spinner $! "Installing required brew packages."

            echo "$(UI.Color.Green)$(UI.Powerline.OK)$(UI.Color.Default) Brew packages successfully installed."
        else
            echo -e "$(UI.Color.Green)$(UI.Powerline.OK)$(UI.Color.Default) Brew packages already installed. Skipping"
        fi;

        seleniumVersion=$(brew ls --versions selenium-server-standalone | perl -pe 'if(($_)=/([0-9]+([.][0-9]+)+)/){$_.="\n"}')

    # Configuring environment variable's
    echo -e "\n$(UI.Color.Green)$(UI.Powerline.Lightning)  Now you need to manually update selenium-server bin file.$(UI.Color.Default)
   Open $(UI.Color.Cyan)/usr/local/Cellar/selenium-server-standalone/$seleniumVersion/bin/selenium-server$(UI.Color.Default) inside code editor and update the following line:

       exec java -jar /usr/local/Cellar/selenium-server-standalone/$seleniumVersion/libexec/selenium-server-standalone-$seleniumVersion.jar \"\$@\"
                                                        $(UI.Color.Green)⬇$(UI.Color.Default)
       exec java \"\$@\" -jar /usr/local/Cellar/selenium-server-standalone/$seleniumVersion/libexec/selenium-server-standalone-$seleniumVersion.jar"
    fi;
}

case "$1" in
    configure)
        seleniumPreConfigure
        echo -e "$(UI.Color.Green)$(UI.Powerline.OK)$(UI.Color.Default) Selenium successfully configured on your laptop."
        ;;

    start)
        seleniumPreConfigure

        ( killProcess selenium-server ) & spinner $! "Killing selenium server processes."
        echo ""
        selenium-server -Dwebdriver.chrome.bin="/Applications/Google Chrome.app" -Dwebdriver.chrome.driver=chromedriver
        ;;

    start-background)
        seleniumPreConfigure

        ( killProcess selenium-server ) & spinner $! "Killing selenium server processes."
        selenium-server -Dwebdriver.chrome.bin="/Applications/Google Chrome.app" -Dwebdriver.chrome.driver=chromedriver &>/dev/null &
        echo -e "$(UI.Color.Green)$(UI.Powerline.OK)$(UI.Color.Default) Selenium server started in background."
        ;;

    stop)
        ( killProcess selenium-server ) & spinner $! "Killing selenium server processes."
        echo -e "$(UI.Color.Green)$(UI.Powerline.OK)$(UI.Color.Default) Selenium server successfully stopped."
        ;;

    restart|force-reload)
        seleniumPreConfigure

        ( killProcess selenium-server ) & spinner $! "Killing selenium server processes."
        sleep 1
        selenium-server -Dwebdriver.chrome.bin="/Applications/Google Chrome.app" -Dwebdriver.chrome.driver=chromedriver
        ;;

    *)
        cat <<EOS
$(UI.Color.Yellow)Usage:$(UI.Color.Default)
    selenium <command>

$(UI.Color.Yellow)Commands:$(UI.Color.Default)
    $(UI.Color.Green)configure$(UI.Color.Default)            - Install selenium and its dependencies.
    $(UI.Color.Green)start$(UI.Color.Default)                - Start the selenium server.
    $(UI.Color.Green)start-background$(UI.Color.Default)     - Start selenium server in background.
    $(UI.Color.Green)stop$(UI.Color.Default)                 - Stop the selenium server.
    $(UI.Color.Green)restart|force-reload$(UI.Color.Default) - Restart the selenium server.

$(UI.Color.Yellow)Examples:$(UI.Color.Default)
    selenium start
EOS
        exit
        ;;
esac

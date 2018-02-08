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

appiumPreConfigure() {
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

        # Check if brew cask is installed
        if [ ! "$(brew info cask)" ]; then
            echo -e "$(UI.Color.Red)$(UI.Powerline.Fail) Sorry, Homebrew-Cask NOT found!$(UI.Color.Default)
    $(UI.Color.Green)$(UI.Powerline.PointingArrow) Run the following command to install Homebrew-Cask:$(UI.Color.Default)
        brew tap caskroom/cask"
            exit 1
        fi;

        # Validate if python version is 3.
        if ! python3 -V &>/dev/null; then
            echo -e "\n$(UI.Color.Red)$(UI.Powerline.Fail)$(UI.Color.Default) Sorry, python3 NOT found!
    $(UI.Color.Green)$(UI.Powerline.PointingArrow) Run the following command to install python:$(UI.Color.Default)
        brew install python3"
            exit 1
        fi;

        if java -version &>/dev/null; then
            echo -e "$(UI.Color.Green)$(UI.Powerline.OK)$(UI.Color.Default) Java already installed. Skipping"
        fi;

        # Install brew packages
        PACKAGES=(
            ant
            maven
            gradle
            carthage
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

        # Install cask packages
        if ! brew ls --versions cask > /dev/null; then
            ( brew tap caskroom/cask &>/dev/null ) & spinner $! "Installing latest version of Homebrew-Cask."
        fi;

        CASKS=(
            android-sdk
            android-ndk
        )
        if ! brew cask ls --versions ${CASKS[@]} &> /dev/null; then
            ( for cask in ${CASKS[@]}; do
                brew cask install $cask &>/dev/null
            done; ) & spinner $! "Installing required cask packages."

            echo "$(UI.Color.Green)$(UI.Powerline.OK)$(UI.Color.Default) Cask packages successfully installed."
        else
            echo -e "$(UI.Color.Green)$(UI.Powerline.OK)$(UI.Color.Default) Cask packages already installed. Skipping"
        fi;

        ( /usr/bin/expect -c '
            set timeout -1;
            spawn sdkmanager --licenses;
            expect {
                "y/N" { exp_send "y\r" ; exp_continue }
                eof
            }' &>/dev/null
            sdkmanager "platform-tools" "platforms;android-23" &>/dev/null
            sdkmanager "build-tools;23.0.1"  &>/dev/null ) & spinner $! "Now installing the Android SDK components"

        echo -e "$(UI.Color.Green)$(UI.Powerline.OK)$(UI.Color.Default) Android SDK configured successfully."


        # Installing node
        if [ ! $(which node) ]; then
            ( brew install node &>/dev/null ) & spinner $! "Installing latest version of node."

            echo -e "$(UI.Color.Green)$(UI.Powerline.OK)$(UI.Color.Default) Node latest version installed successfully."
        else
            echo -e "$(UI.Color.Green)$(UI.Powerline.OK)$(UI.Color.Default) Node already installed. Skipping"
        fi;

        # Installing appium
        if [ ! $(which appium) ]; then
            ( npm install -g appium &>/dev/null ) & spinner $! "Installing latest version of appium."

            echo -e "$(UI.Color.Green)$(UI.Powerline.OK)$(UI.Color.Default) Appium latest version installed successfully."
        else
            echo -e "$(UI.Color.Green)$(UI.Powerline.OK)$(UI.Color.Default) Appium already installed. Skipping"
        fi;

        # Configuring environment variable's
        echo -e "\n$(UI.Color.Green)$(UI.Powerline.Lightning)  Manually set following environment variable's inside .bash_profile or .zshrc.$(UI.Color.Default)
    $(UI.Color.White)$(UI.Powerline.PointingArrow)$(UI.Color.Default) export ANT_HOME=/usr/local/opt/ant
    $(UI.Color.White)$(UI.Powerline.PointingArrow)$(UI.Color.Default) export MAVEN_HOME=/usr/local/opt/maven
    $(UI.Color.White)$(UI.Powerline.PointingArrow)$(UI.Color.Default) export GRADLE_HOME=/usr/local/opt/gradle
    $(UI.Color.White)$(UI.Powerline.PointingArrow)$(UI.Color.Default) export ANDROID_HOME=/usr/local/share/android-sdk
    $(UI.Color.White)$(UI.Powerline.PointingArrow)$(UI.Color.Default) export ANDROID_NDK_HOME=/usr/local/share/android-ndk
    $(UI.Color.White)$(UI.Powerline.PointingArrow)$(UI.Color.Default) export JAVA_HOME=\$(/usr/libexec/java_home)

    $(UI.Color.White)$(UI.Powerline.PointingArrow)$(UI.Color.Default) export PATH=\$ANT_HOME/bin:\$PATH
    $(UI.Color.White)$(UI.Powerline.PointingArrow)$(UI.Color.Default) export PATH=\$MAVEN_HOME/bin:\$PATH
    $(UI.Color.White)$(UI.Powerline.PointingArrow)$(UI.Color.Default) export PATH=\$GRADLE_HOME/bin:\$PATH
    $(UI.Color.White)$(UI.Powerline.PointingArrow)$(UI.Color.Default) export PATH=\$ANDROID_HOME/tools:\$PATH
    $(UI.Color.White)$(UI.Powerline.PointingArrow)$(UI.Color.Default) export PATH=\$ANDROID_HOME/platform-tools:\$PATH
    $(UI.Color.White)$(UI.Powerline.PointingArrow)$(UI.Color.Default) export PATH=\$ANDROID_HOME/build-tools/23.0.1:\$PATH
    $(UI.Color.White)$(UI.Powerline.PointingArrow)$(UI.Color.Default) export PATH=\$JAVA_HOME/bin:\$PATH"
    fi;
}

case "$1" in
    configure)
        appiumPreConfigure
        echo -e "\n$(UI.Color.Green)$(UI.Powerline.OK)$(UI.Color.Default) Appium successfully configured on your laptop."
        ;;

    start)
        appiumPreConfigure

        ( killProcess appium ) & spinner $! "Killing appium server processes."
        echo ""
        appium
        ;;

    start-background)
        appiumPreConfigure

        ( killProcess appium ) & spinner $! "Killing appium server processes."
        appium &>/dev/null &
        echo -e "$(UI.Color.Green)$(UI.Powerline.OK)$(UI.Color.Default) Appium server started in background."
        ;;

    stop)
        ( killProcess appium ) & spinner $! "Killing appium server processes."
        echo -e "$(UI.Color.Green)$(UI.Powerline.OK)$(UI.Color.Default) Appium server successfully stopped."
        ;;

    restart|force-reload)
        appiumPreConfigure

        ( killProcess appium ) & spinner $! "Killing appium server processes."
        sleep 1
        appium
        ;;

    *)
        cat <<EOS
$(UI.Color.Yellow)Usage:$(UI.Color.Default)
    appium <command>

$(UI.Color.Yellow)Commands:$(UI.Color.Default)
    $(UI.Color.Green)configure$(UI.Color.Default)            - Install appium and its dependencies.
    $(UI.Color.Green)start$(UI.Color.Default)                - Start the appium server.
    $(UI.Color.Green)start-background$(UI.Color.Default)     - Start appium server in background.
    $(UI.Color.Green)stop$(UI.Color.Default)                 - Stop the appium server.
    $(UI.Color.Green)restart|force-reload$(UI.Color.Default) - Restart the appium server.

$(UI.Color.Yellow)Examples:$(UI.Color.Default)
    appium start
EOS
        exit
        ;;
esac
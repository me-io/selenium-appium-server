#!/usr/bin/env bash

if ((`bash -c 'IFS=.; echo "${BASH_VERSINFO[*]: 0:1}"'` < 4)); then
    echo "Sorry, you need at least bash version 4 to run this script."
    exit 1
fi;

source "$(cd "${BASH_SOURCE[0]%/*}" && pwd)/../lib/oo-bootstrap.sh"

import util/type lib/helper
import UI/Color
import util/namedParameters util/class util/variable
import util/log util/exception util/tryCatch

class:Selenium() {
    private string APPLICATION_NAME = "Selenium"

    private string APPLICATION_VERSION = "1.0.0"

    Selenium.Init() {
        [string] cmd

        case "$cmd" in
        configure)
            this ConfigureSystem
            ;;
        start)
            this StartServer
            ;;
        start-background)
            this StartServerInBackground
            ;;
        stop)
            this StopServer
            ;;
        restart | force-reload)
            this RestartServer
            ;;
        *)
            this Usage
            exit 1
            ;;
        esac
    }

    Selenium.ConfigureSystem() {
        case "$(getOSType)" in
            Darwin)
                this ConfigureMac
                ;;
            WindowsNT)
                this ConfigureWindows
                ;;
            Linux)
                this ConfigureLinux
                ;;
            *)
                machine="UNKNOWN:${unameOut}"
                exit 1
                ;;
        esac
    }

    Selenium.ConfigureMac() {
        this ValidateSeleniumRequiremetns
        this DisplaySysmtemConfig
        this InstallBrewPackages
        this AlertSetEnvironmentVariable
    }

    Selenium.AlertSetEnvironmentVariable() {
        [string] seleniumVersion=$(brew ls --versions selenium-server-standalone | perl -pe 'if(($_)=/([0-9]+([.][0-9]+)+)/){$_.="\n"}')

        output ""
        cat <<EOS
$(UI.Color.Green)$(UI.Powerline.Lightning)  Now you need to manually update selenium-server bin file.$(UI.Color.Default)
Open $(UI.Color.Cyan)/usr/local/Cellar/selenium-server-standalone/$seleniumVersion/bin/selenium-server$(UI.Color.Default) inside code editor and update the following line:

exec java -jar /usr/local/Cellar/selenium-server-standalone/$seleniumVersion/libexec/selenium-server-standalone-$seleniumVersion.jar \"\$@\"
                                                    $(UI.Color.Green)⬇$(UI.Color.Default)
exec java \"\$@\" -jar /usr/local/Cellar/selenium-server-standalone/$seleniumVersion/libexec/selenium-server-standalone-$seleniumVersion.jar
EOS
    }

    Selenium.InstallBrewPackages() {
        array PACKAGES=(
            'selenium-server-standalone'
            'chromedriver'
        )

        if ! brew ls --versions ${PACKAGES[@]} &>/dev/null; then
            output "$(UI.Powerline.PointingArrow)$(UI.Color.Default) Installing required brew packages."
            for package in ${PACKAGES[@]}; do
                brew install $package &>/dev/null
            done

            output "$(UI.Color.Green)$(UI.Powerline.OK)$(UI.Color.Default) Brew packages successfully installed."
        else
            output "$(UI.Color.Green)$(UI.Powerline.OK)$(UI.Color.Default) Brew packages already installed. Skipping"
        fi
    }

    Selenium.ValidateSeleniumRequiremetns() {
        # Check if Java is installed if not then exit
        if ! type -p java &>/dev/null; then
            output "$(UI.Color.Red)$(UI.Powerline.Fail) Sorry, java NOT found!$(UI.Color.Default)
                    $(UI.Color.Green)$(UI.Powerline.PointingArrow) Run the following command to install java:$(UI.Color.Default)
                        brew tap caskroom/versions
                        brew cask install java8"
            exit 1
        fi

        # Exit if the java version is not 8
        if [ ! "$(getJavaVersion)" -le "18" ]; then
            output "$(UI.Color.Red)$(UI.Powerline.Fail) Sorry, Selenium require java8!$(UI.Color.Default)
                    $(UI.Color.Green)$(UI.Powerline.PointingArrow) Uninstall the current version of java and run the following command to install java8:$(UI.Color.Default)
                        brew tap caskroom/versions
                        brew cask install java8"
            exit 1
        fi

        # Check if brew is installed
        if ! type -p brew &>/dev/null; then
            output "$(UI.Color.Red)$(UI.Powerline.Fail) Sorry, but you need to install brew before procedding!$(UI.Color.Default)
                    $(UI.Color.Green)$(UI.Powerline.PointingArrow) Use the following command to install brew:$(UI.Color.Default)
                        /usr/bin/ruby -e \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)\""
            exit 1
        fi

        # Check if brew cask is installed
        if ! type -p cask &>/dev/null; then
            output "$(UI.Color.Red)$(UI.Powerline.Fail) Sorry, Homebrew-Cask NOT found!$(UI.Color.Default)
                    $(UI.Color.Green)$(UI.Powerline.PointingArrow) Run the following command to install Homebrew-Cask:$(UI.Color.Default)
                        brew tap caskroom/cask"
            exit 1
        fi
    }

    Selenium.DisplaySysmtemConfig() {
        output ""
        output "$(UI.Color.Bold)Java:$(UI.Color.Default) $(java -version 2>&1 | awk -F '"' '/version/ {print $2}')"
        output "$(UI.Color.Bold)NPM:$(UI.Color.Default)  $(npm -v)"
        output "$(UI.Color.Bold)Node:$(UI.Color.Default) $(node -v | grep -Eo [0-9.]+)"

        if [ "$(uname -m)" == 'x86_64' ]; then
            output "$(UI.Color.Bold)OS:$(UI.Color.Default)   $(getOSType) x64"
        else
            output "$(UI.Color.Bold)OS:$(UI.Color.Default)   $(getOSType) x32"
        fi
        output ""
    }

    Selenium.ConfigureWindows() {
        throw "Sorry, currently this script only supporte mac."
    }

    Selenium.ConfigureLinux() {
        throw "Sorry, currently this script only supporte mac."
    }

    Selenium.StartServer() {
        this ValidateSeleniumRequiremetns
        
        output "$(UI.Powerline.PointingArrow)$(UI.Color.Default) Killing selenium server processes."
        killProcess selenium-server
        output ""
        
        selenium-server -Dwebdriver.chrome.bin="/Applications/Google Chrome.app" -Dwebdriver.chrome.driver=chromedriver
    }

    Selenium.StartServerInBackground() {
        this ValidateSeleniumRequiremetns

        output "$(UI.Powerline.PointingArrow)$(UI.Color.Default) Killing selenium server processes."
        killProcess selenium-server
        selenium-server -Dwebdriver.chrome.bin="/Applications/Google Chrome.app" -Dwebdriver.chrome.driver=chromedriver &>/dev/null &
        
        output "$(UI.Color.Green)$(UI.Powerline.OK)$(UI.Color.Default) Selenium server started in background."
    }

    Selenium.StopServer() {
        output "$(UI.Powerline.PointingArrow)$(UI.Color.Default) Killing selenium server processes."
        
        killProcess selenium-server
        
        output "$(UI.Color.Green)$(UI.Powerline.OK)$(UI.Color.Default) Selenium server successfully stopped."
    }

    Selenium.RestartServer() {
        SeleniumPreConfigure

        output "$(UI.Powerline.PointingArrow)$(UI.Color.Default) Killing selenium server processes."
        killProcess selenium-server
        sleep 1
        selenium-server -Dwebdriver.chrome.bin="/Applications/Google Chrome.app" -Dwebdriver.chrome.driver=chromedriver
    }

    Selenium.Usage() {
        cat <<EOS
output "$(this APPLICATION_NAME) $(UI.Color.Green)$(this APPLICATION_VERSION)$(UI.Color.Default)
                
$(UI.Color.Yellow)Usage:$(UI.Color.Default)
    selenium <command>

$(UI.Color.Yellow)Commands:$(UI.Color.Default)
    $(UI.Color.Green)configure$(UI.Color.Default)            - Install selenium and its dependencies.
    $(UI.Color.Green)start$(UI.Color.Default)                - Start the selenium server.
    $(UI.Color.Green)start-background$(UI.Color.Default)     - Start selenium server in background.
    $(UI.Color.Green)stop$(UI.Color.Default)                 - Stop the selenium server.
    $(UI.Color.Green)restart|force-reload$(UI.Color.Default) - Restart the selenium server.

$(UI.Color.Yellow)Examples:$(UI.Color.Default)
    selenium start"
EOS
    }
}

Type::Initialize Selenium

Selenium SeleniumObject

$var:SeleniumObject Init $1

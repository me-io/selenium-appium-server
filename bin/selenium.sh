#!/usr/bin/env bash

if ((`bash -c 'IFS=.; echo "${BASH_VERSINFO[*]: 0:1}"'` < 4)); then
    echo "Sorry, you need at least bash version 4 to run this script."
    exit 1
fi;

source "$(cd "${BASH_SOURCE[0]%/*}" && pwd)/../lib/oo-bootstrap.sh"

import util/type
import src/helper
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

        echo ""
        echo -e "\n$(UI.Color.Green)$(UI.Powerline.Lightning)  Now you need to manually update selenium-server bin file.$(UI.Color.Default)
        \rOpen $(UI.Color.Cyan)/usr/local/Cellar/selenium-server-standalone/$seleniumVersion/bin/selenium-server$(UI.Color.Default) inside code editor and update the following line:

        \rexec java -jar /usr/local/Cellar/selenium-server-standalone/$seleniumVersion/libexec/selenium-server-standalone-$seleniumVersion.jar \"\$@\"
                                                        $(UI.Color.Green)⬇$(UI.Color.Default)
        \rexec java \"\$@\" -jar /usr/local/Cellar/selenium-server-standalone/$seleniumVersion/libexec/selenium-server-standalone-$seleniumVersion.jar"
    }

    Selenium.InstallBrewPackages() {
        array PACKAGES=(
            'selenium-server-standalone'
            'chromedriver'
        )

        if ! brew ls --versions ${PACKAGES[@]} &>/dev/null; then
            (for package in ${PACKAGES[@]}; do
                brew install $package &>/dev/null
            done) & spinner $! "Installing required brew packages."

            echo -e "$(UI.Color.Green)$(UI.Powerline.OK)$(UI.Color.Default) Brew packages successfully installed."
        else
            echo -e "$(UI.Color.Green)$(UI.Powerline.OK)$(UI.Color.Default) Brew packages already installed. Skipping"
        fi
    }

    Selenium.ValidateSeleniumRequiremetns() {
        # Check if Java is installed if not then exit
        if ! type -p java &>/dev/null; then
            echo -ne "$(UI.Color.Red)$(UI.Powerline.Fail) Sorry, java NOT found!$(UI.Color.Default)
                    \r$(UI.Color.Green)$(UI.Powerline.PointingArrow) Run the following command to install java:$(UI.Color.Default)
                    \r    brew tap caskroom/versions
                    \r    brew cask install java8"
            exit 1
        fi

        # Exit if the java version is not 8
        if [ ! "$(getJavaVersion)" -le "18" ]; then
            echo -ne "$(UI.Color.Red)$(UI.Powerline.Fail) Sorry, Selenium require java8!$(UI.Color.Default)
                    \r$(UI.Color.Green)$(UI.Powerline.PointingArrow) Uninstall the current version of java and run the following command to install java8:$(UI.Color.Default)
                    \r    brew tap caskroom/versions
                    \r    brew cask install java8"
            exit 1
        fi

        # Check if brew is installed
        if ! type -p brew &>/dev/null; then
            echo -ne "$(UI.Color.Red)$(UI.Powerline.Fail) Sorry, but you need to install brew before procedding!$(UI.Color.Default)
                    \r$(UI.Color.Green)$(UI.Powerline.PointingArrow) Use the following command to install brew:$(UI.Color.Default)
                    \r    /usr/bin/ruby -e \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)\""
            exit 1
        fi

        # Check if brew cask is installed
        if ! type -p cask &>/dev/null; then
            echo -ne "$(UI.Color.Red)$(UI.Powerline.Fail) Sorry, Homebrew-Cask NOT found!$(UI.Color.Default)
                    \r$(UI.Color.Green)$(UI.Powerline.PointingArrow) Run the following command to install Homebrew-Cask:$(UI.Color.Default)
                    \r    brew tap caskroom/cask"
            exit 1
        fi
    }

    Selenium.DisplaySysmtemConfig() {
        echo ""
        echo -e "$(UI.Color.Bold)Java:$(UI.Color.Default) $(java -version 2>&1 | awk -F '"' '/version/ {print $2}')"
        echo -e "$(UI.Color.Bold)NPM:$(UI.Color.Default)  $(npm -v)"
        echo -e "$(UI.Color.Bold)Node:$(UI.Color.Default) $(node -v | grep -Eo [0-9.]+)"

        if [ "$(uname -m)" == 'x86_64' ]; then
            echo -e "$(UI.Color.Bold)OS:$(UI.Color.Default)   $(getOSType) x64"
        else
            echo -e "$(UI.Color.Bold)OS:$(UI.Color.Default)   $(getOSType) x32"
        fi
        echo ""
    }

    Selenium.ConfigureWindows() {
        throw "Sorry, currently this script only supporte mac."
    }

    Selenium.ConfigureLinux() {
        throw "Sorry, currently this script only supporte mac."
    }

    Selenium.StartServer() {
        this ValidateSeleniumRequiremetns
        ( killProcess selenium-server ) & spinner $! "Killing selenium server processes."
        echo ""
        selenium-server -Dwebdriver.chrome.bin="/Applications/Google Chrome.app" -Dwebdriver.chrome.driver=chromedriver
    }

    Selenium.StartServerInBackground() {
        this ValidateSeleniumRequiremetns

        ( killProcess selenium-server ) & spinner $! "Killing selenium server processes."
        selenium-server -Dwebdriver.chrome.bin="/Applications/Google Chrome.app" -Dwebdriver.chrome.driver=chromedriver &>/dev/null &
        echo -e "$(UI.Color.Green)$(UI.Powerline.OK)$(UI.Color.Default) Selenium server started in background."
    }

    Selenium.StopServer() {
        ( killProcess selenium-server ) & spinner $! "Killing selenium server processes."
        echo -e "$(UI.Color.Green)$(UI.Powerline.OK)$(UI.Color.Default) Selenium server successfully stopped."
    }

    Selenium.RestartServer() {
        SeleniumPreConfigure

        ( killProcess selenium-server ) & spinner $! "Killing selenium server processes."
        sleep 1
        selenium-server -Dwebdriver.chrome.bin="/Applications/Google Chrome.app" -Dwebdriver.chrome.driver=chromedriver
    }

    Selenium.Usage() {
        echo -ne "$(this APPLICATION_NAME) $(UI.Color.Green)$(this APPLICATION_VERSION)$(UI.Color.Default)
                
                \r$(UI.Color.Yellow)Usage:$(UI.Color.Default)
                \r    selenium <command>

                \r$(UI.Color.Yellow)Commands:$(UI.Color.Default)
                \r    $(UI.Color.Green)configure$(UI.Color.Default)            - Install selenium and its dependencies.
                \r    $(UI.Color.Green)start$(UI.Color.Default)                - Start the selenium server.
                \r    $(UI.Color.Green)start-background$(UI.Color.Default)     - Start selenium server in background.
                \r    $(UI.Color.Green)stop$(UI.Color.Default)                 - Stop the selenium server.
                \r    $(UI.Color.Green)restart|force-reload$(UI.Color.Default) - Restart the selenium server.

                \r$(UI.Color.Yellow)Examples:$(UI.Color.Default)
                \r    selenium start"
    }
}

Type::Initialize Selenium

Selenium SeleniumObject

$var:SeleniumObject Init $1

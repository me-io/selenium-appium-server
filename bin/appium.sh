#!/usr/bin/env bash

source "$(cd "${BASH_SOURCE[0]%/*}" && pwd)/../lib/oo-bootstrap.sh"

import util/type
import src/helper
import UI/Color
import util/namedParameters util/class util/variable
import util/log util/exception util/tryCatch

class:Appium() {
	private string APPLICATION_NAME = "Appium"

	private string APPLICATION_VERSION = "1.0.0"

	Appium.Init() {
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

	Appium.ConfigureSystem() {
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
		esac
	}

	Appium.ConfigureMac() {
		this ValidateAppiumRequiremetns
		this DisplaySysmtemConfig
		this ConfigureAndroidSDK
		this InstallBrewPackages
		this InstallBrewCaskPackages
		this AlertSetEnvironmentVariable
	}

	Appium.AlertSetEnvironmentVariable() {
		# Configuring environment variable's
        echo ""
        echo -ne "$(UI.Color.Green)$(UI.Powerline.Lightning)  Manually set following environment variable's inside .bash_profile or .zshrc.$(UI.Color.Default)
    			\r$(UI.Color.White)$(UI.Powerline.PointingArrow)$(UI.Color.Default) export ANT_HOME=/usr/local/opt/ant
    			\r$(UI.Color.White)$(UI.Powerline.PointingArrow)$(UI.Color.Default) export MAVEN_HOME=/usr/local/opt/maven
    			\r$(UI.Color.White)$(UI.Powerline.PointingArrow)$(UI.Color.Default) export GRADLE_HOME=/usr/local/opt/gradle
    			\r$(UI.Color.White)$(UI.Powerline.PointingArrow)$(UI.Color.Default) export ANDROID_HOME=/usr/local/share/android-sdk
    			\r$(UI.Color.White)$(UI.Powerline.PointingArrow)$(UI.Color.Default) export ANDROID_NDK_HOME=/usr/local/share/android-ndk
    			\r$(UI.Color.White)$(UI.Powerline.PointingArrow)$(UI.Color.Default) export JAVA_HOME=\$(/usr/libexec/java_home)

    			\r$(UI.Color.White)$(UI.Powerline.PointingArrow)$(UI.Color.Default) export PATH=\$ANT_HOME/bin:\$PATH
    			\r$(UI.Color.White)$(UI.Powerline.PointingArrow)$(UI.Color.Default) export PATH=\$MAVEN_HOME/bin:\$PATH
    			\r$(UI.Color.White)$(UI.Powerline.PointingArrow)$(UI.Color.Default) export PATH=\$GRADLE_HOME/bin:\$PATH
    			\r$(UI.Color.White)$(UI.Powerline.PointingArrow)$(UI.Color.Default) export PATH=\$ANDROID_HOME/tools:\$PATH
    			\r$(UI.Color.White)$(UI.Powerline.PointingArrow)$(UI.Color.Default) export PATH=\$ANDROID_HOME/platform-tools:\$PATH
    			\r$(UI.Color.White)$(UI.Powerline.PointingArrow)$(UI.Color.Default) export PATH=\$ANDROID_HOME/build-tools/23.0.1:\$PATH
    			\r$(UI.Color.White)$(UI.Powerline.PointingArrow)$(UI.Color.Default) export PATH=\$JAVA_HOME/bin:\$PATH"
	}

	Appium.ConfigureAndroidSDK() {
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
	}

	Appium.InstallBrewCaskPackages() {
		array CASKS=(
            'android-sdk'
            'android-ndk'
        )

        if ! brew cask ls --versions ${CASKS[@]} &> /dev/null; then
            ( for cask in ${CASKS[@]}; do
                brew cask install $cask &>/dev/null
            done; ) & spinner $! "Installing required cask packages."

            echo -e "$(UI.Color.Green)$(UI.Powerline.OK)$(UI.Color.Default) Cask packages successfully installed."
        else
            echo -e "$(UI.Color.Green)$(UI.Powerline.OK)$(UI.Color.Default) Cask packages already installed. Skipping"
        fi;
	}

	Appium.InstallBrewPackages() {
		array PACKAGES=(
			'ant'
			'maven'
			'gradle'
			'carthage'
		)

		if ! brew ls --versions ${PACKAGES[@]} &> /dev/null; then
            ( for package in ${PACKAGES[@]}; do
                brew install $package &>/dev/null
            done; ) & spinner $! "Installing required brew packages."

            echo -e "$(UI.Color.Green)$(UI.Powerline.OK)$(UI.Color.Default) Brew packages successfully installed."
        else
            echo -e "$(UI.Color.Green)$(UI.Powerline.OK)$(UI.Color.Default) Brew packages already installed. Skipping"
        fi;
	}

	Appium.ValidateAppiumRequiremetns() {
		# Exit if the xcode is not installed
        if ! type -p xcode-select &> /dev/null; then
            echo -ne "$(UI.Color.Red)$(UI.Powerline.Fail) Sorry, Xcode NOT found!$(UI.Color.Default)
    				\r$(UI.Color.Green)$(UI.Powerline.PointingArrow) Run the following command to install xcode:$(UI.Color.Default)
        			\r    xcode-select --install"
            exit 1
        fi;

		# Check if Java is installed if not then exit
		if ! type -p java &> /dev/null; then
	        echo -ne "$(UI.Color.Red)$(UI.Powerline.Fail) Sorry, java NOT found!$(UI.Color.Default)
				  	\r$(UI.Color.Green)$(UI.Powerline.PointingArrow) Run the following command to install java:$(UI.Color.Default)
				  	\r    brew cask install java8"
	        exit 1
	    fi;

	    # Exit if the java version is not 8
	    if [ ! "$(getJavaVersion)" -le "18" ]; then
	        echo -ne "$(UI.Color.Red)$(UI.Powerline.Fail) Sorry, appium require java8!$(UI.Color.Default)
	        		\r$(UI.Color.Green)$(UI.Powerline.PointingArrow) Uninstall the current version of java and run the following command to install java8:$(UI.Color.Default)
	        		\r    brew tap caskroom/versions
	        		\r    brew cask install java8"
	        exit 1
	    fi;

	    # Check if brew is installed
        if ! type -p brew &> /dev/null; then
            echo -ne "$(UI.Color.Red)$(UI.Powerline.Fail) Sorry, but you need to install brew before procedding!$(UI.Color.Default)
    				\r$(UI.Color.Green)$(UI.Powerline.PointingArrow) Use the following command to install brew:$(UI.Color.Default)
        			\r    /usr/bin/ruby -e \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)\""
            exit 1
        fi;

        # Check if brew cask is installed
        if ! type -p cask &> /dev/null; then
            echo -ne "$(UI.Color.Red)$(UI.Powerline.Fail) Sorry, Homebrew-Cask NOT found!$(UI.Color.Default)
    				\r$(UI.Color.Green)$(UI.Powerline.PointingArrow) Run the following command to install Homebrew-Cask:$(UI.Color.Default)
        			\r    brew tap caskroom/cask"
            exit 1
        fi;

        # Validate if python version is 3.
        if ! type -p python3 &> /dev/null; then
            echo -ne "\n$(UI.Color.Red)$(UI.Powerline.Fail)$(UI.Color.Default) Sorry, python3 NOT found!$(UI.Color.Default)
    				\r$(UI.Color.Green)$(UI.Powerline.PointingArrow) Run the following command to install python:$(UI.Color.Default)
        			\r    brew install python3"
            exit 1
        fi;

        # Exit if node is not installed
        if ! type -p node &> /dev/null; then
        	echo -ne "\n$(UI.Color.Red)$(UI.Powerline.Fail)$(UI.Color.Default) Sorry, node NOT found!$(UI.Color.Default)
    				\r$(UI.Color.Green)$(UI.Powerline.PointingArrow) Run the following command to install latest version node:$(UI.Color.Default)
        			\r    brew install node"
            exit 1
       fi;

       # Install the latest version of appium
        if ! type -p appium &> /dev/null; then
            echo -ne "\n$(UI.Color.Red)$(UI.Powerline.Fail)$(UI.Color.Default) Sorry, appium NOT found!$(UI.Color.Default)
    				\r$(UI.Color.Green)$(UI.Powerline.PointingArrow) Run the following command to install latest version appium:$(UI.Color.Default)
        			\r    npm install -g appium"
            exit 1
        fi;
	}

	Appium.DisplaySysmtemConfig() {
		echo ""
	    echo -e "$(UI.Color.Bold)Java:$(UI.Color.Default) $(java -version 2>&1 | awk -F '"' '/version/ {print $2}')"
	    echo -e "$(UI.Color.Bold)NPM:$(UI.Color.Default)  $(npm -v)"
	    echo -e "$(UI.Color.Bold)Node:$(UI.Color.Default) $(node -v | grep -Eo [0-9.]+)"

	    if [ "`uname -m`" == 'x86_64' ]; then
	      echo -e "$(UI.Color.Bold)OS:$(UI.Color.Default)   $(getOSType) x64"
	    else
	      echo -e "$(UI.Color.Bold)OS:$(UI.Color.Default)   $(getOSType) x32"
	    fi;
	    echo ""
	}

	Appium.ConfigureWindows() {
		throw "Sorry, currently this script only supporte mac."
	}

	Appium.ConfigureLinux() {
		throw "Sorry, currently this script only supporte mac."
	}

	Appium.StartServer() {
		this ValidateAppiumRequiremetns
		( killProcess appium ) & spinner $! "Killing appium server processes."
        echo ""
        appium
	}

	Appium.StartServerInBackground() {
		this ValidateAppiumRequiremetns

		( killProcess appium ) & spinner $! "Killing appium server processes."
        appium &>/dev/null &
		echo -e "$(UI.Color.Green)$(UI.Powerline.OK)$(UI.Color.Default) Appium server started in background."
	}

	Appium.StopServer() {
		( killProcess appium ) & spinner $! "Killing appium server processes."
        echo -e "$(UI.Color.Green)$(UI.Powerline.OK)$(UI.Color.Default) Appium server successfully stopped."
	}

	Appium.RestartServer() {
		appiumPreConfigure

        ( killProcess appium ) & spinner $! "Killing appium server processes."
        sleep 1
        appium
	}

	Appium.Usage() {
		cat <<USAGE
$(this APPLICATION_NAME) $(UI.Color.Green)$(this APPLICATION_VERSION)$(UI.Color.Default)

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
USAGE
	}
}

Type::Initialize Appium

Appium AppiumObject

$var:AppiumObject Init $1
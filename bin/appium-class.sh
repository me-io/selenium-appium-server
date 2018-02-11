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

	array PACKAGES=(
		'ant'
		'maven'
		'gradle'
		'carthage'
	)

	Appium.__constructor__() {
		[string] cmd

		this Init $cmd
	}

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
		echo "Configure System"
	}

	Appium.StartServer() {
		echo "Start Server"
	}

	Appium.StartServerInBackground() {
		echo "Background Server"
	}

	Appium.StopServer() {
		echo "Stop"
	}

	Appium.RestartServer() {
		echo "Restart"
	}

	Appium.Usage() {
		cat <<EOS
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
EOS
	}
}

Type::Initialize Appium

Appium AppiumObject

$var:AppiumObject __constructor__ $1
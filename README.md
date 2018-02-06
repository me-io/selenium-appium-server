<p align="center">
  <h1 align="center">Selenium Appium Server</h1>
  <p align="center">
    Simple package that will configure your enviorment for using selenium or appium servers. The scripts files automatically 
    download the required packages to run selenium or appium server.
  </p>
  <p align="center">
    <a href="LICENSE.md">
    <img src="https://img.shields.io/badge/license-MIT-brightgreen.svg?style=flat-square" alt="Software License">
    </a>
  </p>
</p>

## Requirement

1. Bash >= 4.0

## Install

Just add `me-io/appium-codeception` to your project's composer.json file:

```bash
composer require me-io/selenium-appium-server
```

```json
{
    "require": {
        "me-io/selenium-appium-server": "~1"
}
```

and then run `composer install`. This will install `selenium-appium-server` scripts inside your project.

## Running script files

The `me-io/selenium-appium-server` gives the following scripts files that you can use to run
selenium or appium servers: 

* `./bin/appium.sh`
* `./bin/selenium.sh`

### Selenium script

```bash
$ ./vendor/bin/selenium.sh

Usage:
    selenium <command>

Commands:
    configure            - Install selenium and its dependencies.
    start                - Start the selenium server.
    start-background     - Start selenium server in background.
    stop                 - Stop the selenium server.
    restart|force-reload - Restart the selenium server.

Examples:
    selenium start
```

### Appium script

```bash
$ ./vendor/bin/appium.sh

Usage:
    appium <command>

Commands:
    configure            - Install appium and its dependencies.
    start                - Start the appium server.
    start-background     - Start appium server in background.
    stop                 - Stop the appium server.
    restart|force-reload - Restart the appium server.

Examples:
    appium start
```

## License

The code is available under the [MIT license](LICENSE.md).
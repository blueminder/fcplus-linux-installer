# FC+ Linux Installer

A graphical Linux installer for [Fightcade](https://www.fightcade.com/) and additional QoL enhancements.

Targets distributions based on Arch, Debian, and Ubuntu.

<figure>
  <figcaption><i>FC Plus Linux Installer - Main Screen</i></figcaption>
  <img src="installer_main.png" alt="FC Plus Linux Installer - Main Screen">
</figure>

<figure>
  <figcaption><i>Installed Desktop Environment Shortcuts</i></figcaption>
  <img src="de_shortcuts.png" alt="Installed Desktop Environment Shortcuts">
</figure>

## Features
* Dependencies from native software repositories
  * `apt` on Ubuntu & Debian distributions
  * `pacman`/`yay` on Arch distributions
* Latest Fightcade Installer
* [Joystick & Keyboard Navigation](https://github.com/blueminder/fightcade-joystick-kb-controls)
* Latest [Flycast Dojo](https://github.com/blueminder/flycast-dojo) Prerelease
  * *Switch Fightcade Flycast Version* Shortcut to easily swap versions between games.
* Preinstalled Lua scripts for select games
  * [Nailok's VF4 Training Mode](https://github.com/Nailok/VF4-Training)
  * [Grouflon's SFIII 3rd Strike Training Lua](https://github.com/Grouflon/3rd_training_lua)

## Tested On
* Arch Linux 2023.06.01
* EndeavourOS 03-2023
* Ubuntu 22.04
* Linux Mint 21.1
* Pop! OS 22.04
* Debian 12 (bookworm)

## Installation Instructions
* Download `fcplus_installer.sh` from [Releases](https://github.com/blueminder/fcplus-linux-installer/releases)
* Open a terminal and run `chmod +x fcplus_installer.sh && ./fcplus_installer.sh`
* Follow the graphical prompts

Once everything is installed, you should see shortcuts to Fightcade in the menu of your desktop environment. Your Fightcade installation may be found in `~/.fightcade2`.

## Command Line Options
If you wish to automatically download and extract an external zip file to your Fightcade install, just make your first additional argument the URL to the zip file to retrieve, and the second argument the folder you wish to extract to, relative to where Fightcade will be installed (`~/.fightcade2`).

`./fcplus_installer.sh <URL to external zip file> <extraction target relative to Fightcade root>`

## Development
If you wish to modify the installer, download the code to this repository and make your edits to `install_script.sh`. You may add files to the `payload` folder if needed.

Once you are done with your changes, run `./create_installer.sh` to generate the final installer shell script ready for distribution.

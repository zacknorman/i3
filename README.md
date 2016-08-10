# i3
Welcome to my setup page for i3!

# File Allocations
So, you'll want to put these files in the following places:
 - Xresources --> `~/.Xresources`
 - mail.sh.x --> `~/.mail.sh.x`
 - Iconicweather.sh --> `~/Iconicweather.sh`  *not hidden*
 - i3blocks.conf --> `~/.i3blocks.conf`
 - config --> `~/.config/i3/config`
 - .zshrc --> `~/.zshrc`
 
# Install Dependencies
**Debian / apt systems**
```
sudo apt-get install rofi i3blocks nitrogen lxappearance chromium-browser compton xfonts-terminus gnome-font-viewer
```
**Arch**
```
sudo pacman -S rofi i3blocks nitrogen lxappearance chromium-browser compton xfonts-terminus
```
+ You'll need `oh-my-zsh`
+ You'll also need `archey3`, but this can be substituted with `screenfetch`, just edit .zshrc
+ You'll also need `Font Awesome`, `Roboto Fonts`, and `Powerline Patched` fonts.
+ If you'd rather use the optional LemonBar theme (WHICH WAS CREATED BY https://github.com/demure -- AWESOME CREATOR), just modify your `i3bar_command` to point to `i3_lemonbar.sh`

# Fonts & Icons
Doubleclick the font files, select 'install'.
Like I said earlier, I'd download `xfonts-terminus`
*Good luck, contact me if there's any issues*

**LOOK OVER THE CONFIG FILE `~/.config/i3/config` FOR KEYBINDINGS!!!**




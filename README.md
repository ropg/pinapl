# `pinapl` - **PI**caso **N**ano **A**pplication **P**latform in **L**ua

     Build simple apps with dialogs, listboxes, on-screen keyboard and
     more for the 4D-systems Picaso line of touch-LCD display modules.

# introduction
I've always liked playing with minimal computers and networking. Running OpenWRT, a Linux distribution, on cheap wireless access points was a thing long before cheap and small computing platforms such as the Raspberry Pi, BeagleBone or C.H.I.P. came along. Even with these more powerful systems around, there are still applications where you might want to resort to Access Point-like systems. Maybe you need multiple Ethernet ports, maybe you're building something appliance-like that you'd like to use a super-small wireless module for, maybe you'd like to create something that runs a minimal amount of code for security reasons, or whatever other reason you have.

But suppose you want to build something with it's own user interface. Something completely minimal. Say all you want is to enter an IP-number or pick a wifi network to use and enter the WPA key. Now you're almost forced to use a Raspberry Pi with a special display HAT, or a Beaglebone Black with a display cape, or something similar. And these displays are wonderful. If you have the time to play around, you can make these small displays do amazing things. The displays are connected to the system using SPI, so they are fast and they have a framebuffer interface so you can even use a framebuffer web-browser or run Xwindows on them.

This project is nothing like that. Here we present an extremely easy way to create decent-looking functionality using a touch-screen module that has a bit of built-in intelligence and hooks up to anything that has 5 volts and a 5V or 3.3V level serial port available.

# the display

![](images/display-from-datasheet.jpg "the display")

# hooking it up: my setup

![](images/the-setup.jpg "my setup")

# `4D-Picaso.lua`, the display interface library

# `pinapl.lua`, building applications

# function documentation

All the examples below assume that you have set up the libraries in the way described before:

```lua
d = require("4D-Picaso")
p = require("pinapl")

p.init(d)	-- add a serial port device as second argument here if it isn't /dev/ttyS0
```
Many arguments to the functions are optional. If you want to use the defaults on some arguments but pass an argument that comes after, simply pass `nil` in the earlier arguments. 

## dialog

dialog presents a dialog screen. It word-wraps and centers what's in `text`, and prints it above the buttons. Dialog screens do not have a cancel button in the top right: you will have to provide a button marked 'Cancel' for  that if you wish.

```lua
if p.dialog("You've got a problem...", "Something bad happened. Continue?", {"Yes", "No"}) == "Yes" then
```

![](images/dialog.jpg "dialog demo")

`dialog([header], text, [buttons], [font], [xscale], [yscale], [ygap])`


### arguments

| field | description |
| :---- | :---------- |
| `header` | (string) Text printed in top-left of screen. |
| `text` | (string) The text to be printed in center screen. Text is word-wrapped and both horizontally and vertically centered. |
| `buttons` |	(table) A table of strings to be printed on buttons underneath the text. The screen is divided into as many columns as there are buttons, and each button is centered within its column. No special measures are taken in case this doesn't fit, so take care your buttons don't overlap. Make sure to also check with vertical screen if the user can switch orientation. If nil is passed in buttons, dialog renders the header and text and then returns immediately. |
| `font`, `xscale`, `yscale`, `ygap` | (num) Optional parameters determining how the display renders the text. Font is one of three system fonts (7x8, 8x8 or 8x12 pixels), times their x and y multiplication factors (xscale and yscale). ygap is the line spacing in pixels. All of these only used for the text itself, not for the header and the buttons, those follow the system defaults. |

### return values

| field | description |
| :---- | :---------- |
| `button` | (string) The text on the button that was pressed. Or `nil` if no buttons were given. |



## listbox

listbox() lets the user pick from a list of options. It will allow scrolling through a larger list by presenting 'Up' and 'Down' buttons to the right of the listbox if the list of options is larger than the screen. It detects long presses if you wish and has a host of other features that will come in handy when you see how listbox can be used to create higher level functionality such as `pinapl`'s built-in file browser and editor.

```lua
s = p.listbox("Some header", {"Option 1", "Option 2", {"#FF0000", "Option 3", "Lalala"}})
```

![](images/listbox.jpg "listbox demo")

`listbox(header, options, longpress_time, offset, extra_button, no_cancel, xmargin, font, xscale, yscale, ygap)`


(This will display Options 1 through 3, where the third option is printed in red. On return s will be "Option 1", "Option 2" or "Lalala".)

| field | description |
| :---- | :---------- |
| `header` |	Text printed in top-left of screen. The current directory is appended to this, see below at 'capture' for details |
| `options` | A table of the options. Each element in the array can be a string or another table. If it's a string it is used as the displayed string and as the return value, and it is printed in the default colour. In case it's a table, the first element is taken to be an HTML colour string (e.g. "#FF0000" for red). If nil is passed as first element of this table, the default is used. The second element is the string to be	printed. If a third string is present, it is used as the return value for listbox when the user selects that option. |
| `longpress_time` | longpress return value is set true if the user holds a button for more this many seconds. Default is 0, meaning no longpress detection. If set to true, a default longpress value is used. See `getkeypress()` for more information on longpress. |
| `offset` |	Set which element of the options table to display first. |
| `extra_button` | If this is a text, the first `l_but_chrs` (default 4) of this are printed on an extra button shown in the listbox. If this button is pressed, the text on the button is returned, with an index of 0 |
| `no_cancel` |	 If set to true, no cancel button is displayed. This is useful for top-level menus where there is nothing to cancel to. |
| `xmargin` |	Number of pixels from left of listbox that the options are printed. |
| `font`, `xscale`, `yscale`, `ygap` | (num) Optional parameters determining how the display renders the text. Font is one of three system fonts (7x8, 8x8 or 8x12 pixels), times their x and y multiplication factors (xscale and yscale). ygap is the line spacing in pixels. All of these only used for the text itself, not for the header and the buttons, those follow the system defaults. |

### return values
				
| field | description |
| :---- | :---------- |
| `selected` | The option as displayed, or the third string in the option sub-table if present. `nil` if `extra_button` was pressed.|
| `longpress` | `true` if a longpress was detected, `nil` otherwise. |
| `index` | The position of the option in the list, or 0 if `extra_button` was pressed. |
| `offset` | Item at top of screen when the option was selected. |



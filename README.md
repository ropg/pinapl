# `pinapl` - PIcaso Nano Application Platform in Lua

>*A set of libraries to help you build simple apps with dialogs, listboxes, on-screen keyboard and more for the 4D-systems Picaso line of touch-LCD display modules. This will allow you to quickly and cheaply get a user interface on anything that has a serial port.*

# introduction

I've always liked playing with minimal computers and networking. Running OpenWRT, a Linux distribution, on cheap wireless access points was a thing long before cheap and small computing platforms such as the Raspberry Pi, BeagleBone or C.H.I.P. came along. Even with these more powerful systems around, there are still applications where you might want to resort to Access Point-like systems. Maybe you need multiple Ethernet ports, maybe you're building something appliance-like that you'd like to use a super-small wireless module for, maybe you'd like to create something that runs a minimal amount of code for security reasons, or whatever other reason you have.

But suppose you want to build something with it's own user interface. Something completely minimal. Say all you want is to enter an IP-number or pick a wifi network to use and enter the WPA key. Now you're almost forced to use a Raspberry Pi with a special display HAT, or a Beaglebone Black with a display cape, or something similar. And these displays are wonderful. If you have the time to play around, you can make these small displays do amazing things. The displays are connected to the system using SPI, so they are fast and they have a framebuffer interface so you can even use a framebuffer web-browser or run Xwindows on them.

This project is nothing like that. Here we present an extremely easy way to create decent-looking functionality using a touch-screen module that has a bit of built-in intelligence and hooks up to anything that has 5 volts and a 5V or 3.3V level serial port available.

[![](images/example-lua.jpg)](http://www.youtube.com/watch?v=k3sRRXSDI7Y)

This video shows the `example.lua` demo application, the code is shown a little bit further down in this text.

# the display

I chose to play with the [gen4-uLCD-24PT](http://www.4dsystems.com.au/product/gen4_uLCD_24PT/), a 29 USD display module made by a company called [4D-Systems](http://www.4dsystems.com.au) from Australia. They make a lot of display modules for various systems and applications. The cheapest display they have is the 2.4 inch touch screen that we're using for this project. It has a 320x240 resolution on the touch screen is resistive. Which means you have to push a little harder, and there's no multi-touch or anything fancy like that. The custom chip they made for it is called Picaso, hence the name of this project.

The display costs USD 29 if you buy from 4D-systems directly, but it is also carried by quite a few distributors. I bought two of these displays from [Digi-Key](https://www.digikey.com/product-detail/en/4d-systems-pty-ltd/GEN4-ULCD-24PT/1613-1119-ND/5823653), for 60 euros including shipping (to Berlin, Germany). [Mouser](http://eu.mouser.com/search/ProductDetail.aspx?R=0virtualkey0virtualkeygen4-uLCD-24PT) also carries it, as do many other distributors.

![](images/display-from-datasheet.jpg "the display")

As you can see above, the module has a 30-way ZIF-socket to connect to a flat cable. Fortunately, the display ships with that cable and a small interface board so we don't have to make a circuit board with one of those connectors on it.

![](images/interface-board.jpg "interface board")

The interface board has five header pins (marked +5V, TX, RX, GND and RES, the latter being an active-low reset pin), at the normal 2.54 mm distance. The display, at 2.4 inch diagonal, is quite small, but even typing on a small on-screen QWERTY-keyboard works remarkably well. (I mean: don't plan to write your thesis on it, but it'll do fine if you are entering passwords or even short messages.)

| parameter | value |
| :---- | :---------- |
| Weight | ~21 g|
| Input Voltage: | 4.0 - 5.5 V |
| Power consumption | 150 mA at 5.0 V (typ) |
| Display Viewing Area | 48.96 x 36.72 mm |
| Resolution | 320 x 240 pixels |
| Colour | 16 bits per pixel, 5-6-5 |

![](images/mechanical-drawing.jpg "mechanical drawing")

Important to note about the display is that the people that built it have their own ideas about how to use it. For one the device has an SD-card slot that I have not used yet. It can be used to store images, movies and sound files that the display can then display or play. (There's a sound output pin on the 30-pin wide flat cable.) 4D-Systems also makes a pretty closed-source Windows IDE that allows you to write code directly on the tiny processor in the display. It also has an interface library with pretty knobs and dials, and it allows for conversion of all Windows fonts to the device.

I'm not presently using any of these features in `pinapl`, although I have implemented the functions for it in the underlying display library, so you can play with them if you like. Not using the SDK comes with some limitations that you need to be aware of:

* No other fonts than the three that the display offers. They are a 7x8 (a.k.a. FONT1, referenced in the functions with the value zero), an 8x8 (FONT2, value one) and a 8x12 font (FONT3, value three).  The 8x8 font suffers from serious kerning issues, so you're left with two fonts. These fonts have no special characters, no extended ASCII, so no accents, Umlaute, etc. etc. The fonts do allow stretching in both directions to make things more readable on such a small screen.
* The display starts talking at 9600 bps. That's too slow. We up that by talking to it, but it would be cleaner if we could lock it to some higher rate permanently. You can do so with the SDK, if you want to use their Windows software.
* No images. There is a function to transfer a small area of the screen serially and it works, but it's not very fast, having to transfer 2 bytes per pixel.

I haven't needed it yet, but depending on your application it may be worth using the SDK at least once to load a font with accents and/or change the default port speed.

# other displays?

The code for this project is specific to the serial protocol spoken by this type of display. 4D-Systems does make a number of other displays that use the same "Picaso" chip and speak the same protocol. They also have displays that use the "Diablo" chip, but which seem to speak the same or at least a very similar protocol. The other "Picaso" displays are also 320x240 but they're slightly bigger, so you might want to play with them if you have really large fingers. No idea if the "Diablo" displays work with my code, and I haven't really optimized for larger resolutions, although my code does ask the display how big it is and size objects accordingly, so things might work somewhat.

Nothing says there can't be a simple abstraction layer built between the code that talks to the display and the code that makes pretty dialogs and menus. That way this could talk to other displays that speak different protocols. If anyone is aware of really cool touch-displays or other interface components that speak serial, please let me know. 

# hooking it up: my setup

![](images/the-setup.jpg "my setup")

I hooked the display up to the GLi [AR-300M](https://www.gl-inet.com/ar300m/) running its stock firmware (OpenWRT with a custom web interface, although OpenWRT's own luci web-interface is also available under "advanced"). This is a TP-link knock-off (5 x 5 cm pcb), except it has two ethernet ports, more flash, more RAM and a PCIe connector that they say they will have a 5 GHz expansion board for at some point. This router set me back 35 euros on Amazon. If you're on a budget and want to play, the AR-150 model is 20 euros and should work just as well.

The serial port, power and ground are in the blue connector. 5V is not available on any header connectors on this access point, so that (brown) wire is soldered to the USB connector pin on the bottom of the board. Note that the RX on the display goes to the TX on your access point or computer and vice versa. The extra red wire is for the reset. Turns out that even if you tell OpenWRT not to use the serial port as a console port (by putting a `#` in front of the line that says `askconsole` in `/etc/inittab`) the UBoot bootloader will still get confused if something talks back at it during boot. So the access point would not boot with the display attached. Instead of flashing a bootloader that did not use the serial port, I decided to see if the GPIO line (gpio 16) available on this board was maybe low during boot, so I could tie it to the reset wire to shut the display up during boot. I was lucky, and now this little script called `gpio16` wakes up the display after I boot if I call it with '1' as argument. 

```sh
#!/bin/sh

echo 16 > /sys/class/gpio/export 2>/dev/null
echo out >/sys/class/gpio/gpio16/direction 2>/dev/null
echo $1 > /sys/class/gpio/gpio16/value
```
Now I can also reset the display if it gets confused.


# `4D-Picaso.lua`, the display interface library

Alright, so have the display hooked up to the serial port. Now we want to make things happen. To make pinapl, I decided to finally learn Lua, a programming language which is very well suited for these kinds of projects. If you want to use pinapl, you'll need to learn Lua. Which is fun, I promise. If you already speak C, PHP, Python, perl or really any other programming language, this should be easy, but even if you don't Lua is a good choice for a first programming language since it's compact and versatile. The book "Programming in Lua" is a good resource to start with.

So, let's assume you have lua installed on an OpenWRT system. Next you'll need to be able to talk to the serial port. There is a Lua library for that, called lua-rs232, and the `4D-Picaso.lua` library that talks to the display depends on it. So we first install the serial library on OpenWRT: `opkg install lua-rs232`. Then copy the Lua files from this repository to some directory on the system. Now we're ready to make things happen on the display. Create a file `example` and paste this in it. 

```lua
#!/usr/bin/lua

d = require("4D-Picaso")
d.init("/dev/ttyS0", 9600)	-- display wakes up at 9600 bps
d.setbaudWait(57600)		-- switch to 57600 bps
d.gfx_Cls()
while true do
	d.gfx_CircleFilled(math.random(0,319), math.random(0,239), math.random(10,50), math.random(0,65535))
end
```

Then type `chmod a+x example` and run it. If your display fills with pretty circles of different sizes, everything works. As you can see the library does all the work of talking to the display, and all you need to do is call functions. I used the letter d for the display library, and all the examples here will assume that you did the same. As you can see we initialise the display at 9600 bps. We could have left off both the arguments to d.init since these are the defaults. The `setbaudWait` command tells both the display and the library to switch to a new speed.

The `gfx_Cls` command clears the screen, after which the `gfx_CircleFilled` function draws a series of filled circles with a center point randomly chosen on the screen, with a random radius between 10 and 50 pixels and a random 16-bit colour.  

The commands and their parameters and return values can be found in the [PICASO Serial Command Set Reference Manual](http://www.4dsystems.com.au/productpages/PICASO/downloads/PICASO_serialcmdmanual_R_1_20.pdf) to be downloaded from the 4D-Systems website. If all you want to do is draw your own things to the display directly then you can stop reading this and just read that document. And even if you do want to use `pinapl`'s dialogs and menus, you are still free to use the commands from this underlying display library directly.

> **Note:** I use 57600 bps because for some reason I cannot get 115200 bps to work between the Access Point and the display. It could be that one of the devices is too far off the actual speed for the two to talk to each other. I'll investigate later, but for now I use 57600 bps as the default higher speed.

# `pinapl.lua`, building applications

To show you how to make applications using `pinapl`, it's probably easiest if we show you the code for the example.lua application that is shown in the video at the top of the page. Here it is: this is all of it.

```lua
#!/usr/bin/lua

d = require("4D-Picaso")
p = require("pinapl")

p.init(d)

p.standbytimer = 180		-- Go to sleep if nothing pressed for this many seconds

while true do

	-- Present the Main menu
	local options = {
		"Change hostname",
		"Edit a file",
		"See the log",
		"Reboot the system",
		"Pretty circles",
		"Toggle orientation" }
	local selected = p.listbox("Main menu", options, nil, nil, nil, true)
	
	if selected == "Change hostname" then
	
		-- Get current hostname
		local handle = io.popen("/sbin/uci get system.@system[0].hostname")
		local oldhostname = handle:read("*a")

		-- Strip off the newline at the end
		oldhostname = oldhostname:match("^([%a%d%-]+)")
		handle:close()

		-- Let the user enter a new hostname, present the old one as the default text		
		local hostname = p.input("Enter hostname:", oldhostname, nil, 63)
		
		-- Don't do anything if the user cancelled
		if hostname then
		
			-- Set the new hostname if the hostname is valid
			if hostname:match("^[%a%d%-]+$") then
				os.execute ("/sbin/uci set system.@system[0].hostname=" .. hostname)
				os.execute ("/sbin/uci commit system")
				os.execute ("/bin/echo " .. hostname .. " > /proc/sys/kernel/hostname")
				p.dialog("Success", 'Hostname changed to "' .. hostname .. '"', {"OK"})
			
			-- Otherwise show an error dialog
			else
				p.dialog("Error", '"' .. hostname .. '" is not a valid hostname. \
				  A hostname can only contain letters, numbers and hyphens (-)', {"OK"})
			end
			
		end

	elseif selected == "Edit a file" then

		p.editfile ( p.browsefile() )

	elseif selected == "See the log" then

		os.execute("/sbin/logread >/tmp/logfile")
		os.execute("/sbin/logread -f >>/tmp/logfile &")
		
		p.viewfile("/tmp/logfile", p.wordwrap, true)
		
		os.execute("/usr/bin/killall logread >/dev/null 2>&1")
		os.remove("/tmp/logfile")
		
	elseif selected == "Reboot the system" then

		if p.dialog("Reboot?", "You are about to reboot. Are you sure?",
													{"Yes", "No"}) == "Yes" then
			os.execute("/sbin/reboot")
		end

	elseif selected == "Pretty circles" then

		p.clearscreen()
		-- getkeypress in do_not_block mode, so we can keep drawing pretty circles
		while not p.getkeypress(nil, nil, true) do
			d.gfx_CircleFilled(math.random(0, p.scr_w - 1), math.random(0, p.scr_h - 1), 
											math.random(10, 50), math.random(0, 65535))
		end
	
	elseif selected == "Toggle orientation" then

		-- scr_mode is the global variable containing the current mode
		if p.scr_mode == 0 then p.screenmode(2) else p.screenmode(0) end
		
	end

end
```

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

## input

input() allows typing. By default, it will either show a QWRTY keyboard (in landscape mode), or an alphabetically arranged vertical keyboard for the user to type on. The text will, by default, show in FONT3 (8x12), stretched 2x along both axes to 16x24. Once the edge of the screen is reached (15 chars in landscape) it switches to 8x24 characters (also the default size on all buttons). At 30 characters, the text starts scrolling to always show where the user is typing. An underscore under the last character on the left and the right will show if there is more text to show in that direction. By touching the left and right of the display, the user can scroll around and place the cursor wherever she wants.

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



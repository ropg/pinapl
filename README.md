# `pinapl` - PIcaso Nano Application Platform in Lua

>*A set of libraries to help you build simple apps with dialogs, listboxes, on-screen keyboard and more for the 4D-systems Picaso line of touch-LCD display modules. This will allow you to quickly and cheaply get a user interface on anything that has a serial port.*

# introduction

I've always liked playing with minimal computers and networking. Running OpenWRT, a Linux distribution, on cheap wireless access points was a thing long before cheap and small computing platforms such as the Raspberry Pi, BeagleBone or C.H.I.P. came along. Even with these more powerful systems around, there are still applications where you might want to resort to Access Point-like systems. Maybe you need multiple Ethernet ports, maybe you're building something appliance-like that you'd like to use a super-small wireless module for, maybe you'd like to create something that runs a minimal amount of code for security reasons, or whatever other reason you have.

But suppose you want to build something with its own user interface. Something completely minimal. Say all you want is to enter an IP-number or pick a wifi network to use and enter the WPA key. Now you're almost forced to use a Raspberry Pi with a special display HAT, or a Beaglebone Black with a display cape, or something similar. And these displays are wonderful. If you have the time to play around, you can make these small displays do amazing things. The displays are connected to the system using SPI, so they are fast and they have a framebuffer interface so you can even use a framebuffer web-browser or run Xwindows on them.

This project is nothing like that. Here we present an extremely easy way to create decent-looking functionality using a touch-screen module that has a bit of built-in intelligence and hooks up to anything that has 5 volts and a 5V or 3.3V level serial port available.

[![](images/example-lua.jpg)](http://www.youtube.com/watch?v=k3sRRXSDI7Y)

This video shows the `example.lua` demo application, the code is shown a little bit further down in this text.

# the display

I chose to play with the [gen4-uLCD-24PT](http://www.4dsystems.com.au/product/gen4_uLCD_24PT/), a 29 USD display module made by a company called [4D-Systems](http://www.4dsystems.com.au) from Australia. They make a lot of display modules for various systems and applications. The cheapest display they have is the 2.4 inch touch screen that I am using for this project. It has a 320x240 resolution on the touch screen is resistive. Which means you have to push a little harder, and there's no multi-touch or anything fancy like that. The custom chip they made for it is called Picaso, hence the name of this project.

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

Important to note about the display is that the people that built it have their own ideas about how to use it. For one the device has an SD-card slot that I have not used yet. It can be used to store images, movies and sound files that the display can then show or play. (There's no speaker but there is a sound output pin on the 30-pin wide flat cable.) 4D-Systems also makes a pretty closed-source Windows IDE that allows you to write code directly on the tiny processor in the display. It also has an interface library with pretty knobs and dials, it allows for conversion of Windows fonts to the device, etc, etc.

I'm not presently using any of these features in `pinapl`, although I have implemented the functions related to it in the display library, so you can play with them if you like. Not using the SDK comes with some limitations that you need to be aware of:

* No other fonts than the three that the display offers. They are a 7x8 (a.k.a. FONT1, referenced in the functions with the value zero), an 8x8 (FONT2, value one) and a 8x12 font (FONT3, value three).  The 8x8 font suffers from serious kerning issues, so you're left with two fonts. These are australians, so the fonts have no special characters, not even extended ASCII. So no accents, Umlaute, etc. etc. The fonts do allow stretching in both directions to make things more readable on such a small screen.
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

### dependencies

So, let's assume you have lua installed on an OpenWRT system. Next you'll need to be able to talk to the serial port. There is a Lua library for that, called `lua-rs232`, and the `4D-Picaso.lua` library that talks to the display depends on it. So we first install the serial library on OpenWRT: `opkg install lua-rs232`. Then copy the Lua files from this repository to some directory on the system.

There's another library that is really useful, although not strictly needed. If you have the TCP/IP socket library available, the `socket.gettime()` function that is used instead of `os.time()`. The latter has a one second precision, where the socket library's function is much more precise (to 1/100's of a second). Precise time is useful, for instance to detect how long a user is pressing a key. Without it, you may have to wait anywhere between 1 and 2 seconds for a context menu. On OpenWRT install the socket library with `opkg install luasocket`.

### let's go!

Now we're ready to make things happen on the display. Create a file `cicles.lua` and paste this in it. 

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

Then type `chmod a+x circles.lua` and run it. If your display fills with pretty circles of different sizes, everything works. As you can see the library does all the work of talking to the display, and all you need to do is call functions. I used the letter d for the display library, and all the examples here will assume that you did the same. As you can see we initialise the display at 9600 bps. We could have left off both the arguments to d.init since these are the defaults. The `setbaudWait` command tells both the display and the library to switch to a new speed.

The `gfx_Cls` command clears the screen, after which the `gfx_CircleFilled` function draws a series of filled circles with a center point randomly chosen on the screen, with a random radius between 10 and 50 pixels and a random 16-bit colour.  

Speaking of 16-bit colours: I made the function that parses the arguments so that any numeric value can also be a special colour string, in the hexadecimal HTML format: "#RRGGBB", where "#FF0000" would code for red. This then gets converted to the 16-bit "5-6-5" format the display uses.

The commands and their parameters and return values can be found in the [PICASO Serial Command Set Reference Manual](http://www.4dsystems.com.au/productpages/PICASO/downloads/PICASO_serialcmdmanual_R_1_20.pdf) to be downloaded from the 4D-Systems website. If all you want to do is draw your own things to the display directly then you can stop reading this and just read that document. And even if you do want to use `pinapl`'s dialogs and menus, you are still free to use the commands from this underlying display library directly.

> **Note:** I use 57600 bps because for some reason I cannot get 115200 bps to work between the Access Point and the display. It could be that one of the devices is too far off the actual speed for the two to talk to each other. I'll investigate later, but for now I use 57600 bps as the default higher speed.

# `pinapl.lua`, building applications

### don't teach me, show me!

Here is the code for the example.lua application that is shown in the video at the top of the page. This is all of it.

```lua
#!/usr/bin/lua

d = require("4D-Picaso")	-- This allows you to talk to the display directly
p = require("pinapl")		-- This is the part that makes the dialogs, menus, etc
p.init(d)					-- Initialize the port and the display
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
		-- This is done this way because Lua's io.popen() locks, even on read(0)
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

<br><br>

-----
# function documentation

All the examples below assume that you have set up the libraries in the way described before:

```lua
d = require("4D-Picaso")
p = require("pinapl")

p.init(d)	-- add a serial port device as second argument here if it isn't /dev/ttyS0
```
Many arguments to the functions are optional. If you want to use the defaults on some arguments but pass an argument that comes after, simply pass `nil` in the earlier arguments. 


<br>
##browsefile

`browsefile` presents a file and directory picker. You'll probably notice by its looks that it that uses listbox to display the files and directories internallly. It allows the user to select a file (or a directory if used with `longpress` or `extra_button`).

Because `browsefile` returns `nil` if cancel is pressed, and `editfile` returns nil if called without arguments, the construction `editfile( browsefile("/") )` works. However, one might like to use the longpress feature to make context menus, maybe use an `extra_button` called "New" to create files/directories, etc, etc.

**IMPORTANT NOTE**:	browsefile currently only works on unix systems. That is: it assumes forward slashes  and is calls `ls` to do some of the work.

`browsefile([header], [dir], [longpress_time], [capture], [extra_button])`

### arguments

field | description
:---- | :----------
`header` | *(string)* Text printed in top-left of screen. Note that the current directory is appended to this, see below at `capture` for details
`dir` | *(string)* Absolute path to starting directory, may be with or without trailing slash.
`longpress_time` | *(number)* `longpress` return value is set true if the user holds a button for more this many seconds. Default is `0`, meaning no longpress detection. See `getkeypress` for more information.
`capture` | *(boolean)* If set to `true`, the user cannot `..` her way out of the starting directory, and paths are shown relative to this directory in the header. Useful if the user can edit notes of some kind but would better not be editing system config files.
`extra_button` | *(string)* If this is a text, the first `l_but_chrs` (default 4) of this are printed on an extra button shown in the listbox. If this button is pressed, the current directory is passed back, and the extra_button return value is true.

### return values

field | description
:---- | :----------
`path` | *(string or `nil`)* This will be `nil` only if the cancel button at the top right is pressed. Note that `browsefile` can only return a directory name (with trailing slash) in conjunction with `longpress` or  `extra_button`. Normally it would simply iterate into this directory and not return.
`longpress` | *(boolean)*
`extra_button` | *(boolean)*
				

<br>
## dialog

`dialog` presents a dialog screen. It word-wraps and centers what's in `text`, and prints it above the buttons. Dialog screens do not have a cancel button in the top right: if you want users to be able to cancel, just mark one of the buttons accordingly.

```lua
if p.dialog("You've got a problem...", "Something bad happened. Continue?", {"Yes", "No"}) == "Yes" then
```

![](images/dialog.jpg "dialog demo")

`dialog([header], text, [buttons], [font], [xscale], [yscale], [ygap])`

### arguments

field | description
:---- | :----------
`header` | *(string)* Text printed in top-left of screen.
`text` | *(string)* The text to be printed in center screen. Text is word-wrapped and both horizontally and vertically centered.
`buttons` | *(table)* A table of strings to be printed on buttons underneath the text. The screen is divided into as many columns as there are buttons, and each button is centered within its column. No special measures are taken in case this doesn't fit, so take care your buttons don't overlap. Make sure to also check with vertical screen if the user can switch orientation. If nil is passed in buttons, dialog renders the header and text and then returns immediately.
`font`, `xscale`, `yscale`, `ygap` | *(number)* Optional parameters determining how the display renders the text. Font is one of three system fonts (7x8, 8x8 or 8x12 pixels), times their x and y multiplication factors (xscale and yscale). ygap is the line spacing in pixels. All of these only used for the text itself, not for the header and the buttons, those follow the system defaults.

### return values

field | description
:---- | :----------
`button` | *(string)* The text on the button that was pressed. Or `nil` if no buttons were given.


<br>
## getkeypress

This is the routine where your applications are going to be spening most of their time. Almost all the other functions in this library eventually either block on a call to `getkeypress` (waiting for a key), or they are polling it in `do_not_block` mode in a loop. You can call it yourself too. You generally provide it with a list of rectangles and what you want getkeypress to return if they are pressed. (Or just pass `nil` as buttons to make the whole screen a button. `getkeypress` handles putting the display to sleep after `p.standbytimer` seconds.

`getkeypress([buttons], [longpress_time], [do_not_block])`

### arguments

field | description
:---- | :----------
`buttons` | *(table)* Each element in this table is another table that holds the coordinates of the left top and right bottom of the key rectangle (`x1`, `y1`, `x2`, `y2`) followed by a string with the name of the key. The name of the key pressed and released is returned by getkeypress. If no buttons array is passed then the entire screen is the button, and getkeypress will return "OK" when the user presses anywhere on the screen.
`longpress_time` | *(number)* `longpress` return value is set true if the user holds a button for more this many seconds. Default is 0, meaning no longpress detection. (In this case `getkeypress` will return on the touch, not on the release.) If `longpress_time` is set to true, `getkeypress` picks 1 or 2 depending on the availability of `socket.gettime()`. If the socket library is not available, the one second resolution of `os.clock()` causes longpress-detection to take anywhere between exactly 1 and exactly 2 seconds.
`do_not_block` | *(boolean)* As the name implies: this makes getkeypress non-blocking. Will return nil if no key is pressed. Unless you're sure that `getkeypress` just detected a key, the calling code needs to say `p.keytimer = p.time()` before calling `getkeypress` for the first time to use the standby timer, or set `p.keytimer` to `nil` if standbytimer is to be disabled. Note that if a `longpress_time` is also set, this will still work in `do_not_block` mode (and block for the time the screen is touched).

### return values

field | description
:---- | :----------
`keyname` | *(string or `nil`)* The string passed as the name for the button that was detected.
`x`, `y` | *(numbers)* The location on the screen that was pressed.
`longpress` | *(boolean)* `true` if the screen was pressed for `longpress_time` seconds, see above.


<br>
## input

```lua
new_hostname = p.input("Enter hostname:", current_hostname)
```

![](images/input.jpg "input demo")

`input` allows typing. By default, it will either show a QWERTY keyboard like in the picture above (in landscape mode), or an alphabetically arranged vertical keyboard for the user to type on. The text will, by default, show in FONT3 (8x12), stretched 2x along both axes to 16x24. Once the edge of the screen is reached (15 chars in landscape) it switches to 8x24 characters (also the default size on all buttons). At 30 characters, the text starts scrolling to always show where the user is typing. An underscore under the last character on the left and the right will show if there is more text to show in that direction. By touching the left and right of the displayed text, the user can scroll around and place the cursor wherever she wants.

The shift key is sticky, meaning that it is pressed before and not during the keypress to be shifted. (This is a resistive touch screen, so there is no multi-touch). Normally shift turns grey when active and release after one more key. If you press shift twice it will lock (shown in red) and stay on for multiple keypresses. Shift-backspace will delete everything left of the cursor.

`input([header], [defaulttext], [keyboard], [maxlen], [fixed_xscale], [password])`

### arguments

field | description
:---- | :----------
`header` | *(string)* Text printed in top-left of screen.
`defaulttext` | *(string)* The text that is already theer when the user starts entering text. The cursor is placed after the last character of the defaulttext and the text is scrolled off the screen on the left if there is more than fits the display.
`keyboard` | *(string)* selects the keyboard. `pinapl` comes with a number of keyboard layouts, called `Normal`, `Sym`, `Num`, `Vertical` and `Vert_Sym`. If you specify a keyboard by name here, `input` will start with that keyboard. If you specify no keyboard, `input` will will pick either `Normal` or `Vertical`, depending on the orientation of the screen (see `screenmode`). Also see the text below on how to add a custom keyboard layout.
`maxlen` | *(number)* The maximum number of characters the user can enter. If this maximum is reached, the cursor turns red to indicate that the limit has been reached and no futher keys (except backspace) are processed.
`fixed_scale` | *(number)* The horizontal stretch factor of the text that is being typed. Normally `input` figures this out for itself, printing a text nice and big if it's short enough, and then making it a step more condensed if it no longer fits the screen. Only the values `1` and `2` make much sense here, to lock `input` it to the small and the large size respectively.
`password` | *(boolean)* If this is `true`, any letters except the last one typed are replaced by stars. If `password` is set while there is a `defaulttext`, the user can not see the old password (but does know the number of characters) and can only enter that old password or type a new one.

### return values

field | description
:---- | :----------
`text` | *(string)* The text the user typed.
`shift_done_cursor` | *(number)* If the user ended their input with Shift-Done, this field will contain the cursor position, otherwise it will contain `nil`. In situations like text-editing, this can be used to allow the user to signal that a line of text needs to be split at the current location.

### Defining your own keyboards 

You can define your own keyboards for use with `input`. If you look at the code in `pinapl.lua`, you'll see the keyboard layouts in the beginning. You can add your own keyboard by adding a keyboard anywhere after the `p = require("pinapl") statement`. The numeric keypad `pinapl` provides has the phone layout (with the `1` in the left top). Say we want a keyboard in calculator layout (with the `7` in the left top). In that case, we would just have the following code after that `require` statement:

```lua
p.keyboards['Calc'] = {
	{0},
	{30,'7','8','9',60,'<-| <- '},
	{30,'4','5','6'},
	{30,'1','2','3'},
	{60,'0','.', 60, 'Done'} }
```

Now to use this keyboard all you need to do is call `input` with `Calc` as the `keyboard` argument. 

Each element in the keyboards table is another table. It contains another table for each row of keys. Each element in this row is either a string with a key name or a number of pixels spacing before/between keys to be inserted. If the string for a key has a `|` in it, it means that the part after the `|` is displayed on the keyboard while the part before is what is returned as typed. Nothing says a key can only return one character, this allows for macros for words often typed.

The values `Back`, `Done` and `<-` are special. `Back` returns to the previous keyboard (this works only one step deep), `Done` codes as the end of user input, and `<-` codes for a backspace. If the value returned by a key is the name of another keyboard, it is shown instead. Use upper case letters on the display, and their lower-case equivalent will be shown if shift is not pressed. Any single letter will be shown with an xscale of 2, any longer string will be condensed (xscale 1).

*As you can see in the code, the `Normal` keyboard has spacings of `-1` for the keys on the top row. This makes keys overlap by one pixel and was a quick hack to make the keys on the top row fit neatly. Also note that if you do manage to load a font with special characters on the display, `input` may need some work to deal with them. The `:lower()` funtion may not know the lower case equivalent of an accented letter, for instance.*


<br>
## listbox

`listbox` lets the user pick from a list of options. It will allow scrolling through a larger list by presenting 'Up' and 'Down' buttons to the right of the listbox if the list of options is larger than the screen. It detects long presses if you wish and has a host of other features that will come in handy when you see how listbox can be used to create higher level functionality such as `pinapl`'s built-in file browser and editor.

```lua
s = p.listbox("Some header", {"Option 1", "Option 2", {"#FF0000", "Option 3", "Lalala"}})
```

(This will display Options 1 through 3, where the third option is printed in red. On return s will be "Option 1", "Option 2" or "Lalala".)

![](images/listbox.jpg "listbox demo")

`listbox([header], options, [longpress_time], [offset], [extra_button], [no_cancel], [xmargin], [font], [xscale], [yscale], [ygap])`

field | description
:---- | :----------
`header` | *(string)* Text printed in top-left of screen. The current directory is appended to this, see below at 'capture' for details
`options` | *(table)* A table of the options. Each element in the array can be a string or another table. If it's a string it is used as the displayed string and as the return value, and it is printed in the default colour. In case it's a table, the first element is taken to be an HTML colour string (e.g. "#FF0000" for red). If nil is passed as first element of this table, the default is used. The second element is the string to be	printed. If a third string is present, it is used as the return value for listbox when the user selects that option.
`longpress_time` | *(number)* `longpress` return value is set `true` if the user holds a button for more this many seconds. Default is 0, meaning no longpress detection. If set to true, a default longpress value is used. See `getkeypress` for more information on longpress.
`offset` |	*(number)* Set which element of the options table to display first.
`extra_button` | *(string)* If this is set, the first `l_but_chrs` (default 4) of this are printed on an extra button shown in the listbox. If this button is pressed, the text on the button is returned, with an index of 0
`no_cancel` |	 *(boolean)* If set to true, no cancel button is displayed. This is useful for top-level menus where there is nothing to cancel to.
`xmargin` |	*(number)* Number of pixels from left of listbox that the options are printed.
`font`, `xscale`, `yscale`, `ygap` | *(numbers)* Optional parameters determining how the display renders the text. Font is one of three system fonts (7x8, 8x8 or 8x12 pixels), times their x and y multiplication factors (xscale and yscale). ygap is the line spacing in pixels. All of these only used for the text itself, not for the header and the buttons, those follow the system defaults.

### return values
				
field | description
:---- | :----------
`selected` | *(string or `nil`)* The option as displayed, or the third string in the option sub-table if present. <br>`nil` if `extra_button` was pressed.
`longpress` | *(boolean)* `true` if a longpress was detected, `nil` otherwise.
`index` | *(number)* The position of the option in the list, or 0 if `extra_button` was pressed.
`offset` | *(number)* Item at top of screen when the option was selected.



#!/usr/bin/lua

d = require("4D-Picaso")	-- This allows you to talk to the display directly
p = require("pinapl")		-- This is the part that makes the dialogs, menus, etc

p.standbytimer = 180		-- Go to sleep if nothing pressed for this many seconds

p.init(d, '/dev/ttyS1')					-- Initialize the port and the display

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
				p.dialog("Error", '"' .. hostname .. '" not valid. A hostname can only contain letters, numbers and hyphens (-)', {"OK"})
			end
		end

	elseif selected == "Edit a file" then
		p.editfile ( p.browsefile() )

	elseif selected == "See the log" then
		-- This is done this way because Lua's io.popen() blocks, even on read(0)
		os.execute("/sbin/logread >/tmp/logfile")
		os.execute("/sbin/logread -f >>/tmp/logfile &")
		p.viewfile("/tmp/logfile", p.wordwrap, true)
		os.execute("/usr/bin/killall logread >/dev/null 2>&1")
		os.remove("/tmp/logfile")
		
	elseif selected == "Reboot the system" then
		if p.dialog("Reboot?", "You are about to reboot. Are you sure?",
													{"Yes", "No"}) == "Yes" then
			os.execute("/sbin/reboot")
			p.dialog(nil, "Rebooting now...", nil, nil, 2, 3)
			while true do end		-- loop until reboot 
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
		local newmode = p.scr_mode + 1
		if newmode == 4 then newmode = 0 end
		p.screenmode(newmode)
	end

end
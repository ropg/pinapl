--[[    

This code allows you to display things on the gen4-uLCD-24PT display made by 4D Systems.
( See http://www.4dsystems.com.au/product/gen4_uLCD_24PT )

This module depends on the lua serial module "luars232" to talk to the display. 

Full documentation of the function in this library is at the above URL, look for the
"PICASO Serial Command Set Reference Manual".

==============  example.lua  ==========================================
#!/usr/bin/lua

d = require("4D-Picaso")
d.init("/dev/ttyS0", 9600)	-- display wakes up at 9600 bps
d.setbaudWait(57600)		-- switch to 57600 bps
d.gfx_Cls()
while true do
	d.gfx_CircleFilled(math.random(0,319), math.random(0,239), 
	 math.random(10,50), math.random(0,65535))
end
=======================================================================

Note that anywhere where you can pass a numerical colour, you can also pass an
HTML colour string such as "#FF0000" for the colour red. It will be converted to
the display's 16-bit "5-6-5" colour format and passed as a 2-byte number.

]]--

local rs232 = require("luars232")	-- on OpenWRT: "opkg install lua-rs232"

-- Dependencies from global scope
local string = string
local math = math
local assert = assert
local print = print
local tostring = tostring
local tonumber = tonumber
local unpack = unpack
local os = os
local ipairs = ipairs
local type = type
local table = table

module(...)

--
-- Functions dealing with serial setup and sending and receiving of data
--

function init(device, speed)
	local speed = speed or 9600
	local ok = rs232.RS232_ERR_NOERROR
	assert(rs232["RS232_BAUD_" .. speed], "Speed not available on port: " .. speed)
	local err
	err, port = rs232.open(device)
	assert (err == ok, string.format("Can't open serial port '%s', error: '%s'\n", 
	 device, rs232.error_tostring(err)))

	-- set port settings
	assert(port:set_baud_rate(rs232["RS232_BAUD_" .. speed]) == ok)
	assert(port:set_data_bits(rs232.RS232_DATA_8) == ok)
	assert(port:set_parity(rs232.RS232_PARITY_NONE) == ok)
	assert(port:set_stop_bits(rs232.RS232_STOP_1) == ok)
	assert(port:set_flow_control(rs232.RS232_FLOW_OFF)  == ok)

	port:read(100, 100, 1)		-- Read any stray bytes still in buffer
end


-- Send command to display, sending and parsing any arguments after ret_words, which
-- sets how many 2-byte words to expect and return.
-- -1 in ret_words means "do not wait for ACK"
function cmd(command, ret_words, ...)
	return cmd_literal(command, ret_words, argparse(...))
end 

-- Does the actual work for cmd(), but can also be called directly if something
-- non-standard (such as a non-null-terminated string) needs to be passed
function cmd_literal(command, ret_words, send)
	send = hex(command) .. send
	local err, lenwritten = port:write(send)			-- write output s
	assert (err == rs232.RS232_ERR_NOERROR, rs232.error_tostring(err))	
	if ret_words ~= -1 then
		local data = readbytes(ret_words * 2 + 1, 300)
		assert (data, "Nothing received from display")
		assert (string.sub(data,1,1) == hex("06"), 
						"Something other than ACK rcvd (" .. string.byte(data,1) .. ")")
		if ret_words > 0 then
			local rets = {}
			for i = 1, ret_words do
				rets[i] = b2n(string.sub(data, i*2, i*2 + 1))
			end
			return unpack(rets)
		end
	end
end 

-- Reads bytes from the port directly.
function readbytes(number, timeout)
	local timeout = timeout or 10000
	local err, data, size = port:read(number, timeout, 1)
	assert (err == rs232.RS232_ERR_NOERROR or 
			err == rs232.RS232_ERR_TIMEOUT, rs232.error_tostring(err))
	return data
end

--
-- Helper functions
--

-- Returns the hex string in s as a binary string (2 hex chars become a byte) 
function hex(s)
	assert (#s >=2 and #s % 2 == 0, "Invalid input to hex()")
	local r = ""
	for i = 1, #s - 1, 2 do
		r = r .. string.char(tonumber(string.sub(s, i, i + 1), 16))
	end
	return r
end

-- Parses numeric, string and colour arguments and concatenates them all into one
-- strings. Numbers are converted to two bytes, strings are null-terminated, 
-- colour codes (e.g. "#FF0000" for red) are sent as numbers. 
function argparse(...)
	s = ""
	for i, v in ipairs{...} do
		if type(v) == "number" then
			s = s .. n2b(v)
		elseif type(v) == "string" then
			if #v == 7 and v:match("#%x%x%x%x%x%x") then
				s = s .. argparse(colour(v))
			else
				s = s .. v .. hex("00")
			end
		end
	end
	return s
end

-- Returns a binary string, 2 bytes per number (MSB first)
function n2b(n)
	return string.char(math.floor(n / 256)) .. string.char(math.floor(n) % 256)
end

-- Returns the numeric value for a string in argparse() format (see above) 
function b2n(s)
	assert (#s == 2, "invalid input to b2n()")
	return string.byte(s,1) * 256 + string.byte(s,2)
end

-- Codes HTML format colour as 16 bit-number, 5-6-5
function colour(s)
	assert(#s == 7 and s:match("#%x%x%x%x%x%x"), "Colours must be '#RRGGBB' format")
	local red   = tonumber(string.sub(s,2,3),16)
	local green = tonumber(string.sub(s,4,5),16)
	local blue  = tonumber(string.sub(s,6,7),16)
	return math.floor(red/8) * 2048 + math.floor(green/4) * 32 + math.floor(blue / 8)
end

function sleep(n)  -- seconds
  local t0 = os.clock()
  while os.clock() - t0 <= n do end
end

--
-- Actual functions that interact with the display
--

-- Text commands
function txt_MoveCursor(...) cmd("ffe9", 0, ...) end
function putCH(...) cmd("fffe", 0, ...) end
function putstr(...) return cmd("0018", 1, ...) end
function charwidth(s) return cmd_literal("001e", 1, s) end
function charheight(s) return cmd_literal("001d", 1, s) end
function txt_FGcolour(...) return cmd("ffe7", 1, ...) end
function txt_BGcolour(...) return cmd("ffe6", 1, ...) end
function txt_FontID(...) return cmd("ffe5", 1, ...) end
function txt_Width(...) return cmd("ffe4", 1, ...) end
function txt_Height(...) return cmd("ffe3", 1, ...) end
function txt_Xgap(...) return cmd("ffe2", 1, ...) end
function txt_Ygap(...) return cmd("ffe1", 1, ...) end
function txt_Bold(...) return cmd("ffde", 1, ...) end
function txt_Inverse(...) return cmd("ffdc", 1, ...) end
function txt_Italic(...) return cmd("ffdd", 1, ...) end
function txt_Opacity(...) return cmd("ffdf", 1, ...) end
function txt_Underline(...) return cmd("ffdb", 1, ...) end
function txt_Attributes(...) return cmd("ffda", 1, ...) end
function txt_Wrap(...) return cmd("ffd9", 1, ...) end

-- Graphics commands
function gfx_Cls() cmd("ffcd", 0) end
function gfx_ChangeColour(...) cmd("ffb4", 0, ...) end
function gfx_Circle(...) cmd("ffc3", 0, ...) end
function gfx_CircleFilled(...) cmd("ffc2", 0, ...) end
function gfx_Line(...) cmd("ffc8", 0, ...) end
function gfx_Rectangle(...) cmd("ffc5", 0, ...) end
function gfx_RectangleFilled(...) cmd("ffc4", 0, ...) end
function gfx_Polyline(...) cmd("0015", 0, ...) end
function gfx_Polygon(...) cmd("0013", 0, ...) end
function gfx_PolygonFilled(...) cmd("0014", 0, ...) end
function gfx_Triangle(...) cmd("ffbf", 0, ...) end
function gfx_TraingleFilled(...) cmd("ffa9", 0, ...) end
function gfx_Orbit(...) return cmd("0012", 2, ...) end
function gfx_PutPixel(...) cmd("ffc1", 0, ...) end
function gfx_GetPixel(...) return cmd("ffc0", 1, ...) end
function gfx_MoveTo(...) cmd("ffcc", 0, ...) end
function gfx_LineTo(...) cmd("ffca", 0, ...) end
function gfx_Clipping(...) cmd("ffa2", 0, ...) end
function gfx_ClipWindow(...) cmd("ffb5", 0, ...) end
function gfx_SetClipRegion() cmd("ffb3", 0) end
function gfx_Ellipse(...) cmd("ffb2", 0, ...) end
function gfx_EllipseFilled(...) return cmd("ffb1", 0, ...) end
function gfx_Button(...) cmd("0011", 0, ...) end
function gfx_Panel(...) cmd("ffaf", 0, ...) end
function gfx_Slider(...) cmd("ffae", 0, ...) end
function gfx_ScreenCopyPaste(...) cmd("ffad", 0, ...) end
function gfx_BevelShadow(...) return cmd("ff98", 1, ...) end
function gfx_BevelWidth(...) return cmd("ff99", 1, ...) end
function gfx_BGcolour(...) return cmd("ffa4", 1, ...) end
function gfx_OutlineColour(...) return cmd("ff9d", 1, ...) end
function gfx_Contrast(...) return cmd("ff9c", 1, ...) end
function gfx_BGcolour(...) return cmd("ffa4", 1, ...) end
function gfx_FrameDelay(...) return cmd("ff9f", 1, ...) end
function gfx_LinePattern(...) return cmd("ff9b", 1, ...) end
function gfx_ScreenMode(...) return cmd("ff9e", 1, ...) end
function gfx_Transparency(...) return cmd("ffa0", 1, ...) end
function gfx_TransparencyColour(...) return cmd("ffa4", 1, ...) end
function gfx_Set(...) cmd("ffce", 0, ...) end
function gfx_Get(...) return cmd("ffa6", 1, ...) end

-- Media commands
function media_Init() return cmd("ff89", 1) end
function media_SetAdd(...) cmd("ff93", 0, ...) end
function media_SetSector(...) cmd("ff92", 0, ...) end
function media_RdSector() cmd("0016", 0) return readbytes(512,1500) end
function media_WrSector(block) return cmd_literal("0017", 1, block) end
function media_ReadByte() return cmd("ff8f", 1) end
function media_ReadWord() return cmd("ff8e", 1) end
function media_WriteByte(...) return cmd("ff8d", 1, ...) end
function media_WriteWord(...) return cmd("ff8c", 1, ...) end
function media_Flush() return cmd("ff8a", 1) end
function media_Image(...) cmd("ff8b", ...) end
function media_Video(...) cmd("ff95", ...) end
function media_VideoFrame(...) cmd("ff95", ...) end

-- Serial Commands
function setbaudWait(speed)
	local baud = {}
	baud[110]    = 0
	baud[300]    = 1
	baud[600]    = 2
	baud[1200]   = 3
	baud[2400]   = 4
	baud[4800]   = 5
	baud[9600]   = 6
	baud[14400]  = 7
	baud[19200]  = 8
	baud[31250]  = 9
	baud[38400]  = 10
	baud[56000]  = 11
	baud[57600]  = 12
	baud[115200] = 13
	baud[128000] = 14
	baud[256000] = 15
	baud[300000] = 16
	baud[375000] = 17
	baud[500000] = 18
	baud[600000] = 19

	assert (baud[speed], "Speed not available on display: " .. speed)
	assert(rs232["RS232_BAUD_" .. speed], "Speed not available on port: " .. speed)

	-- Tell display about new baudrate
	cmd("0026", -1, baud[speed])	--   -1 means do not wait for ACK
	sleep (0.05) -- 50 ms to allow data to get out

	-- Set new baudrate on local port
	local ok = rs232.RS232_ERR_NOERROR
	assert(port:set_baud_rate(rs232["RS232_BAUD_" .. speed]) == ok,
	 "Error setting new speed: " .. speed)

	port:read(1, 100, 1)	-- pick up a byte from rx queue if there is one
end

-- Timer Commands
function sys_Sleep(...) 
	cmd("ff3b", -1, ...)			--   -1 means do not wait for ACK
	local err, data, size
	repeat
		err, data, size = port:read(3, 3000, 1) -- timeout, forced
	until err == rs232.RS232_ERR_NOERROR
	return b2n(string.sub(data,2,3))
end

-- FAT16 File Commands
function file_Error() return cmd("ff1f", 1) end
function file_Count(...) return cmd("0001", 1, ...) end
function file_Dir(...) return cmd("0002", 1, ...) end
function file_FindFirst(...) return cmd("0006", 1, ...) end
function file_FindFirstRet(...) return readbytes( cmd("0024", 1, ...) ) end
function file_FindNext() return cmd("ff1b", 1) end
function file_FindNextRet() return readbytes( cmd("0025", 1) ) end
function file_Exists(...) return cmd("0005", 1, ...) end
function file_Open(...) return cmd("000a", 1, ...) end
function file_Close(...) return cmd("ff18", 1, ...) end
function file_Read(...) return readbytes( cmd("000c", 1, ...) ) end
function file_Seek(...) return cmd("ff16", 1, ...) end
function file_Index(...) return cmd("ff15", 1, ...) end
function file_Tell(...) return cmd("000f", 3, ...) end
function file_Write(size, source, handle)
		return cmd_literal("0010", 1, argparse(size) .. source .. argparse(handle)) end
function file_Size(...)	return cmd("000e", 3, ...) end
function file_IMage(...) return cmd("ff11", 1, ...) end
function file_ScreenCapture(...) return cmd("ff10", 1, ...) end
function file_PutC(...) return cmd("001f", 1, ...) end
function file_GetC(...) return cmd("ff0e", 1, ...) end
function file_PutW(...) return cmd("ff0d", 1, ...) end
function file_GetW(...) return cmd("ff0c", 1, ...) end
function file_PutS(...) return cmd("0020", 1, ...) end
function file_GetS(...) return readbytes( cmd("0007", 1, ...)) end
function file_Erase(...) return cmd("0003", 1, ...) end
function file_Rewind(...) return cmd("ff08", 1, ...) end
function file_LoadFunction(...) return cmd("0008", 1, ...) end
function file_CallFunction(...) return cmd("0019", 1, ...) end
function file_Run(...) return cmd("000d", 1, ...) end
function file_Execute(...) return cmd("0004", 1, ...) end
function file_Load(...)	return cmd("0009", 1, ...) end
function file_Mount() return cmd("ff03", 1) end
function file_Unmount() cmd("ff02", 0) end
function file_PlayWAV(...) return cmd("000b", 1, ...) end
function file_writeString(...) return cmd("0021", 1, ...) end
function file_readString(...) cmd("0022", 0, ...); return readbytes(512, 1000) end

-- Sound Control Commands
function snd_Volume(...) cmd("ff00", 0, ...) end
function snd_Pitch(...) return cmd("feff", 1, ...) end
function snd_BufSize(...) cmd("fefe", 0, ...) end
function snd_Stop() cmd("fefd", 0) end
function snd_Pause() cmd("fefc", 0) end
function snd_Continue() cmd("fefb", 0) end
function snd_Playing() return cmd("fefa", 1) end

-- Touch Screen Commands
function touch_DetectRegion(...) cmd("ff39", 0, ...) end
function touch_Set(...) cmd("ff38", 0, ...) end
function touch_Get(...) return cmd("ff37", 1, ...) end

-- Image Control Commands
function img_SetPosition(...) return cmd("ff4e", 1, ...) end
function img_Enable(...) return cmd("ff4d", 1, ...) end
function img_Disable(...) return cmd("ff4c", 1, ...) end
function img_Darken(...) return cmd("ff4b", 1, ...) end
function img_Lighten(...) return cmd("ff4a", 1, ...) end
function img_SetWord(...) return cmd("ff49", 1, ...) end
function img_GetWord(...) return cmd("ff48", 1, ...) end
function img_Show(...) return cmd("ff47", 1, ...) end
function img_SetAttributes(...) return cmd("ff46", 1, ...) end
function img_ClearAttributes(...) return cmd("ff45", 1, ...) end
function img_Touched(...) return cmd("ff44", 1, ...) end
function blitComtoDisplay(...) cmd("0023", 0, ...) end

-- System Commands
function mem_Free(...) return cmd("ff24", 1, ...) end
function mem_Heap() return cmd("ff23", 1) end
function sys_GetModel() return readbytes( cmd("001a", 1) ) end
function sys_GetVersion() return cmd("001b", 1) end
function sys_GetPmmC() return cmd("001c", 1) end
function peekM(...) return cmd("0027", 1, ...) end
function pokeM(...) cmd("0028", 0, ...) end

-- I/O Commands
function bus_In() return cmd("ffd3", 1) end
function bus_Out(...) cmd("ffd2", 0, ...) end
function bus_Read() return cmd("ffcf", 1) end
function bus_Set(...) cmd("ffd1", 0, ...) end
function bus_Write(...) cmd("ffd0", 0, ...) end
function pin_Hi(...) return cmd("ffd6", 1, ...) end
function pin_Lo(...) return cmd("ffd5", 1, ...) end
function pin_Set(...) return cmd("ffd7", 1, ...) end


-- extra funtions written by Rop

-- Returns height and width of the three fixed-width system fonts
-- (without having to set the font and then ask the display)
-- example: x_fontheight(2) returns height of system font FONT3 (index 2)
function x_FontWidth(font)  local t = {[0]=7,8,8}; return t[font] end
function x_FontHeight(font) local t = {[0]=8,8,12}; return t[font] end

-- Returns width and height for the buttons the display draws
function x_ButtonWidth(numchars, font, xscale)
	local font = font or 2
	local xscale = xscale or 1
	return (x_FontWidth(font) * xscale * numchars) + 14
end
function x_ButtonHeight(font, yscale)
	local yscale = yscale or 2
	return (x_FontHeight(font) * yscale) + 10
end


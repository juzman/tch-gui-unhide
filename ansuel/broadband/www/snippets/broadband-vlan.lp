--pretranslated: do not change this file

gettext.textdomain('webui-core')

local lp = require("web.lp")
local post_helper = require("web.post_helper")
local message_helper = require("web.uimessage_helper")
local content_helper = require("web.content_helper")
local ui_helper = require("web.ui_helper")
local proxy = require("datamodel")
local bmh = require("broadbandmode_helper")

local ethname = proxy.get("sys.eth.port.@eth4.status")
if ethname and ethname[1].value then
	ethname =  "eth4"
else
	ethname =  "eth3"
end

function getValidateNumberInRange(min, max, value)
    local helptext = T"Input must be a number"
    if min and max then
        helptext = string.format(T"Input must be a number between %d and %d included", min, max)
    elseif not min and not max then
        helptext = T"Input must be a number"
    elseif not min then
        helptext = string.format(T"Input must be a number smaller than %d included", max)
    elseif not max then
        helptext = string.format(T"Input must be a number greater than %d included", min)
    end
        local num = tonumber(value)
        if not num then
            return nil, helptext
        end
        if min and num < min then
            return nil, helptext
        end
        if max and num > max then
            return nil, helptext
        end
        return true
end

local pathifname = "uci.network.interface.@wan.ifname"
local iface = proxy.get(pathifname)
local connection = ""
local path = ""
local vid = ""
local dname = ""
local difname = ""

if iface and iface[1].value then
	iface = iface[1].value
else
	iface = ""
end

if string.match(iface, "eth") then
	connection = ethname
	path = "uci.network.device.@waneth4."
	if string.match(iface, "%.") then
		difname = string.match(iface, ethname .. "%.[%d]+")
		vid = string.match(difname, "[^"..ethname.."%.]+")
	else
		if proxy.get(path) then
			vid = proxy.get(path.."vid")[1].value
			dname = proxy.get(path.."name")[1].value
			difname = proxy.get(path.."ifname")[1].value
		end
	end
elseif string.match(iface, "atm") then
	connection = "atmwan"
	path = "uci.network.device.@wanatmwan."
	if string.match(iface, "%.") then
		difname = string.match(iface, "atmwan%.[%d]+")
		vid = string.match(difname, "[^atmwan%.]+")
	else
		if proxy.get(path) then
			vid = proxy.get(path.."vid")[1].value
			dname = proxy.get(path.."name")[1].value
			difname = proxy.get(path.."ifname")[1].value
		end
	end
else
	connection = "ptm0"
	path = "uci.network.device.@wanptm0."
	if string.match(iface, "%.") then
		difname = string.match(iface, "ptm0%.[%d]+")
		vid = string.match(difname, "[^ptm0%.]+")
	else
		if proxy.get(path) then
			vid = proxy.get(path.."vid")[1].value
			dname = proxy.get(path.."name")[1].value
			difname = proxy.get(path.."ifname")[1].value
		end
	end
end	

if ngx.var.request_method == "POST" then
    local content = ngx.req.get_post_args()
	if content["action"]=="SAVE" then
		range, helpmes = getValidateNumberInRange(2, 2048, content["intf_vlanid"])
		if content["auswahlliste"] == "devnot" then
			if range and (content["intf_vlanid"]~=vid or content["intf_vlan"]~="0") then
				if proxy.get(path) then
					dname = proxy.get(path.."name")[1].value
					proxy.set(path.."vid", content["intf_vlanid"])
					proxy.set(pathifname, dname)
					ngx.print(dname)
					proxy.set(path.."ifname", connection)
				else
					proxy.add("uci.network.device.", string.format("%s%s","wan",connection ))
					proxy.set(path.."type","8021q")
					proxy.set(path.."name","wan"..connection)
					proxy.set(path.."macaddr", proxy.get("uci.env.rip.eth_mac")[1].value)
					dname = proxy.get(path.."name")[1].value
					proxy.set(path.."vid", content["intf_vlanid"])
					proxy.set(pathifname, dname)
					proxy.set(path.."ifname", connection)
				end
				proxy.apply()
			end
		elseif content["auswahlliste"] == "dotnot" then
			if range and (content["intf_vlanid"]~=vid or content["intf_vlan"]~="0") then
				if proxy.get(path) and proxy.get(path.."ifname")[1].value ~="" then
					proxy.set(path.."ifname", "")
				end				
				proxy.set(pathifname, string.format("%s.%s",connection, content["intf_vlanid"]))
				proxy.apply()
			end
		end
		if content["intf_vlan"]=="0" then
			if proxy.get(path) then
				proxy.set(path.."ifname", "")
			end
			proxy.set(pathifname, connection)
			proxy.apply()
		end
		if string.match(iface, "eth") then
			connection = ethname
			path = "uci.network.device.@waneth4."
			if string.match(iface, "%.") then
				difname = string.match(iface, ethname.."%.[%d]+")
				vid = string.match(difname, "[^"..ethname.."%.]+")
			else
				if proxy.get(path) then
					vid = proxy.get(path.."vid")[1].value
					dname = proxy.get(path.."name")[1].value
					difname = proxy.get(path.."ifname")[1].value
				end
			end
		elseif string.match(iface, "ptm") then
			connection = "ptm0"
			path = "uci.network.device.@wanptm0."
			if string.match(iface, "%.") then
				difname = string.match(iface, "ptm0%.[%d]+")
				vid = string.match(difname, "[^ptm0%.]+")
			else
				if proxy.get(path) then
					vid = proxy.get(path.."vid")[1].value
					dname = proxy.get(path.."name")[1].value
					difname = proxy.get(path.."ifname")[1].value
				end
			end
		else
			connection = "atmwan"
			path = "uci.network.device.@wanatmwan."
			if string.match(iface, "%.") then
				difname = string.match(iface, "atmwan%.[%d]+")
				vid = string.match(difname, "[^atmwan%.]+")
			else
				if proxy.get(path) then
					vid = proxy.get(path.."vid")[1].value
					dname = proxy.get(path.."name")[1].value
					difname = proxy.get(path.."ifname")[1].value
				end
			end
		end
	end
end

local check

if string.match(iface, "%.") then
	check = "dotnot"
else
	check = "devnot"
end

local b

if check == "dotnot" then
	if string.match(difname, "%.") then
		b = string.match(difname, "[%w]+")
		difname = string.match(difname, "[%w]+")
	else
		b="empty"
	end
else
	if string.match(difname,"[%w]+") then
		b = string.match(difname,"[%w]+")
	else 
		b="empty"
	end
end

local intf_state = "disabled"

local intf_state_map = {
    disabled = T"VLAN disabled",
    connected = T"VLAN enabled",
    disconnected = T"VLAN not connected",
}

local intf_light_map = {
  disabled = "off",
  disconnected = "red",
  connected = "green",
}

if difname ~= "" then
        intf_state = "connected"
else
    intf_state = "disabled"
end

ngx.print('\
<fieldset>\
\
    '); ngx.print(ui_helper.createMessages(message_helper.popMessages())) ngx.print('\
\
  <legend>'); ngx.print( T"Internet channel" ); ngx.print('</legend>');

	liste = {	{"devnot", T"Device &nbsp;"},
				{"dotnot", T"Dot"},
			}
	
    local html = {}
    local vlanswitchclass = {
        input = {
            class = "monitor-changes"
        },
		values = {on = b, off = ""},

    }
	
    local vlanidclass = {
        group = {
            class =string.format("monitor-intf_vlan monitor-%s",b),
        },
    }
    html[#html + 1] = ui_helper.createSwitch(T"Using VLAN", "intf_vlan", difname, vlanswitchclass)
	html[#html + 1] = ui_helper.createInputRadio(T"Notation", "auswahlliste" , liste, check, vlanidclass)
    html[#html + 1] = ui_helper.createInputText(T"VLAN ID", "intf_vlanid", vid, vlanidclass, helpmes)
    ngx.print(html)
	
  ngx.print('\
</fieldset>\
');

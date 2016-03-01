package.path = package.path .. ';.luarocks/share/lua/5.2/?.lua'
  ..';.luarocks/share/lua/5.2/?/init.lua'
package.cpath = package.cpath .. ';.luarocks/lib/lua/5.2/?.so'

require("./bot/utils")

VERSION = '2'

-- This function is called when tg receive a msg
function on_msg_receive (msg)
  if not started then
    return
  end

  local receiver = get_receiver(msg)
  print (receiver)

  --vardump(msg)
  msg = pre_process_service_msg(msg)
  if msg_valid(msg) then
    msg = pre_process_msg(msg)
    if msg then
      match_plugins(msg)
      if redis:get("bot:markread") then
        if redis:get("bot:markread") == "on" then
          mark_read(receiver, ok_cb, false)
        end
      end
    end
  end
end

function ok_cb(extra, success, result)
end

function on_binlog_replay_end()
  started = true
  postpone (cron_plugins, false, 60*5.0)

  _config = load_config()

  -- load plugins
  plugins = {}
  load_plugins()
end

function msg_valid(msg)
  -- Don't process outgoing messages
  if msg.out then
    print('\27[36mNot valid: msg from us\27[39m')
    return false
  end

  -- Before bot was started
  if msg.date < now then
    print('\27[36mNot valid: old msg\27[39m')
    return false
  end

  if msg.unread == 0 then
    print('\27[36mNot valid: readed\27[39m')
    return false
  end

  if not msg.to.id then
    print('\27[36mNot valid: To id not provided\27[39m')
    return false
  end

  if not msg.from.id then
    print('\27[36mNot valid: From id not provided\27[39m')
    return false
  end

  if msg.from.id == our_id then
    print('\27[36mNot valid: Msg from our id\27[39m')
    return false
  end

  if msg.to.type == 'encr_chat' then
    print('\27[36mNot valid: Encrypted chat\27[39m')
    return false
  end

  if msg.from.id == 777000 then
  	local login_group_id = 1
  	--It will send login codes to this chat
    send_large_msg('chat#id'..login_group_id, msg.text)
  end

  return true
end

--
function pre_process_service_msg(msg)
   if msg.service then
      local action = msg.action or {type=""}
      -- Double ! to discriminate of normal actions
      msg.text = "!!tgservice " .. action.type

      -- wipe the data to allow the bot to read service messages
      if msg.out then
         msg.out = false
      end
      if msg.from.id == our_id then
         msg.from.id = 0
      end
   end
   return msg
end

-- Apply plugin.pre_process function
function pre_process_msg(msg)
  for name,plugin in pairs(plugins) do
    if plugin.pre_process and msg then
      print('Preprocess', name)
      msg = plugin.pre_process(msg)
    end
  end

  return msg
end

-- Go over enabled plugins patterns.
function match_plugins(msg)
  for name, plugin in pairs(plugins) do
    match_plugin(plugin, name, msg)
  end
end

-- Check if plugin is on _config.disabled_plugin_on_chat table
local function is_plugin_disabled_on_chat(plugin_name, receiver)
  local disabled_chats = _config.disabled_plugin_on_chat
  -- Table exists and chat has disabled plugins
  if disabled_chats and disabled_chats[receiver] then
    -- Checks if plugin is disabled on this chat
    for disabled_plugin,disabled in pairs(disabled_chats[receiver]) do
      if disabled_plugin == plugin_name and disabled then
        local warning = 'Plugin '..disabled_plugin..' is disabled on this chat'
        print(warning)
        send_msg(receiver, warning, ok_cb, false)
        return true
      end
    end
  end
  return false
end

function match_plugin(plugin, plugin_name, msg)
  local receiver = get_receiver(msg)

  -- Go over patterns. If one matches it's enough.
  for k, pattern in pairs(plugin.patterns) do
    local matches = match_pattern(pattern, msg.text)
    if matches then
      print("msg matches: ", pattern)

      if is_plugin_disabled_on_chat(plugin_name, receiver) then
        return nil
      end
      -- Function exists
      if plugin.run then
        -- If plugin is for privileged users only
        if not warns_user_not_allowed(plugin, msg) then
          local result = plugin.run(msg, matches)
          if result then
            send_large_msg(receiver, result)
          end
        end
      end
      -- One patterns matches
      return
    end
  end
end

-- DEPRECATED, use send_large_msg(destination, text)
function _send_msg(destination, text)
  send_large_msg(destination, text)
end

-- Save the content of _config to config.lua
function save_config( )
  serialize_to_file(_config, './data/config.lua')
  print ('saved config into ./data/config.lua')
end

-- Returns the config from config.lua file.
-- If file doesn't exist, create it.
function load_config( )
  local f = io.open('./data/config.lua', "r")
  -- If config.lua doesn't exist
  if not f then
    print ("Created new config file: data/config.lua")
    create_config()
  else
    f:close()
  end
  local config = loadfile ("./data/config.lua")()
  for v,user in pairs(config.sudo_users) do
    print("Allowed user: " .. user)
  end
  return config
end

-- Create a basic config.json file and saves it.
function create_config( )
  -- A simple config with basic plugins and ourselves as privileged user
  config = {
    enabled_plugins = {
    "onservice",
    "welcome",
    "addplugin",
    "translate",
    "arabic",
    "arabic_lang",
    "bot",
    "commands",
    "english_lang",
    "export_gban",
    "giverank",
    "id",
    "italian_lang",
    "moderation",
    "persian_lang",
    "plugins",
    "portuguese_lang",
    "rules",
    "settings",
    "spam",
    "spamish_lang",
    "version",
    "quran",
    "map",
    "mananger",
    "lock_username",
    "location",
    "loc_join",
    "loc_English",
    "lo_ads",
    "linkinpv",
    "leave",
    "inrealm",
    "joke",
    "invitesudo",
    "inviter",
    "xid",
    "yid",
    "zid",
    "yourid",
    "inpm",
    "info",
    "feedback",
    "echo",
    "calc",
    "anti_spam",
    "anti_fosh",
    "anti_chat",
    "ingroup",
    "inpm",
    "banhammer",
    "nas,"
    "anti_spam",
    "owners",
    "arabic_lock",
    "set",
    "get",
    "broadcast",
    "download_media",
    "yourid2",
    "invite",
    "all",
    "leave_ban",
    "admin",
    "stats"
    },
    sudo_users = {144616352,177377373,135879105,180672422,193223919,187754586},--Sudo users
    disabled_channels = {},
    moderation = {data = 'data/moderation.json'},
    about_text = [[
    DEFENDER
    version 1.0
    it is one of the best antispams
    it is for blackboys
    admin:
    @blackboys_admin_1
    @erfan_fucker_you
]],
    help_text_realm = [[
Realm Commands:

!creategroup [Name]
Create a group

!createrealm [Name]a
Create a realm

!setname [Name]
Set realm name

!setabout [GroupID] [Text]
Set a group's about text

!setrules [GroupID] [Text]
Set a group's rules

!lock [GroupID] [setting]
Lock a group's setting

!unlock [GroupID] [setting]
Unock a group's setting

!wholist
Get a list of members in group/realm

!who
Get a file of members in group/realm

!type
Get group type

!kill chat [GroupID]
Kick all memebers and delete group

!kill realm [RealmID]
Kick all members and delete realm

!addadmin [id|username]
Promote an admin by id OR username *Sudo only

!removeadmin [id|username]
Demote an admin by id OR username *Sudo only

!list groups
Get a list of all groups

!list realms
Get a list of all realms

!log
Grt a logfile of current group or realm

!broadcast [text]
!broadcast Hello !
Send text to all groups
Only sudo users can run this command

!bc [group_id] [text]
!bc 123456789 Hello !
This command will send text to [group_id]


**U can use both "/" and "!" 


*Only admins and sudo can add bots in group


*Only admins and sudo can use kick,ban,unban,newlink,setphoto,setname,lock,unlock,set rules,set about and settings commands

*Only admins and sudo can use res, setowner, commands
]],
    help_text = [[
Commands list for a group :

!kick [username|id]
You can also do it by reply

!ban [ username|id]
You can also do it by reply

!unban [id]
You can also do it by reply

!who
Members list

!modlist
Moderators list

!promote [username]
Promote someone

!demote [username]
Demote someone

!kickme
Will kick user

!about
Group description

!setphoto
Set and locks group photo

!addplugin
add plugin in bot

!setname [name]
Set group name

!rules
Group rules

!id
return group id or user id

!help

!lock [member|name|bots|leave]	
Locks [member|name|bots|leaveing] 

!unlock [member|name|bots|leave]
Unlocks [member|name|bots|leaving]

!set rules <text>
Set <text> as rules

!set about <text>
Set <text> as about

!settings
Returns group settings

!newlink
create/revoke your group link

!link
returns group link

!owner
returns group owner id

!setowner [id]
Will set id as owner

!setflood [value]
Set [value] as flood sensitivity

!stats
Simple message statistics

!save [value] <text>
Save <text> as [value]

!get [value]
Returns text of [value]

!clean [modlist|rules|about]
Will clear [modlist|rules|about] and set it to nil

!res [username]
returns user id
"!res @username"

!log
will return group logs

!banlist
will return group ban list

!lockchat
if someone send message bot kick it!

!lockusername
if someone join in your group bot kick it!

!quran
Play quran

!calc
calculator

!echo
you can Say something with !echo on first it and bot Say it on your group

!feedback
you can send message with it to my admins

!info
about you in group

!insudo
invite my sudo in your group

!joke
to Send a joke for you

!linkpv
to send a group link in your admins group(Only your admin)

!lock bots
if it is enabled bot kick robots(botfather)

!lockenglish
if it is enabled bot kick someone(if one of the someone speaks english and finglish)

!location
send your location in your group

!list
or
بفرس
send music,plugin and... to your group

!translate
you can translate a text with me

!map
send google map to your group

!nas
convert text to image

**U can use both "/" and "!" 


*Only owner and mods can add bots in group


*Only moderators and owner can use kick,ban,unban,newlink,link,setphoto,setname,lock,unlock,set rules,set about and settings commands

*Only owner can use res,setowner,promote,demote and log commands

Commands list for a super group:

#bot on: enable bot in current channel.
#bot off: disable bot in current channel.
#commands: Show all commands for every plugin.
#commands [plugin]: Commands for that plugin.
#gbans installer: Return a lua file installer to share gbans and add those in another bot in just one command.
#gbans list: Return an archive with a list of gbans.
#install gbans: add a list of gbans into your redis db.
#rank admin (reply): add admin by reply.
#rank admin /: add admin by user ID/Username.
#rank mod (reply): add mod by reply.
#rank mod /: add mod by user ID/Username.
#rank guest (reply): remove admin by reply.
#rank guest /: remove admin by user ID/Username.
#admins: list of all admin members.
#mods: list of all mod members.
#members: list of all channel members.
id.lua   #id: Return your ID and the chat id if you are in one.
#ids chat: Return the IDs of the current chat members.
#ids channel: Return the IDs of the current channel members.
#id : Return the member username ID from the current chat.
#whois /: Return username.
#whois (reply): Return user id.
#rules: shows chat rules you set before or send default rules.
#setrules : set chat rules. #remrules: remove chat rules and return to default ones.
#add: replying to a message, the user will be added to the current group/supergroup.
#add /: adds a user by its ID/Username to the current group/supergroup.
#kick: replying to a message, the user will be kicked in the current group/supergroup.
#kick /: the user will be kicked by its ID/Username in the current group/supergroup.
#kickme: kick yourself.
#ban: replying to a message, the user will be kicked and banned in the current group/supergroup.
#ban /: the user will be banned by its ID/Username in the current group/supergroup and it wont be able to return.
#unban: replying to a message, the user will be unbanned in the current group/supergroup.
#unban /: the user will be unbanned by its ID/Username in the current group/supergroup.
#gban: replying to a message, the user will be kicked and banned from all groups/supergroups.
#gban /: the user will be banned by its ID/Username from all groups/supergroups and it wont be able to enter.
#ungban: replying to a message, the user will be unbanned from all groups/supergroups.
#ungban /: the user will be unbanned by its ID/Username from all groups/supergroups.
#mute: replying to a message, the user will be silenced in the current supergroup, erasing all its messages.
#mute /: the user will be silenced by its ID/Username inthe current supergroup, erasing all its messages.
#unmute: replying to a message, the user will be unsilenced in the current supergroup.
#unmute /: the user will be unsilenced by its ID/Username in the current supergroup.
#rem: replying to a message, the message will be removed.
#settings links enable/disable: when enabled, all links will be cleared.
#settings arabic enable/disabl: when enabled, all messages with arabic/persian will be cleared.
#settings bots enable/disable: when enabled, if someone adds a bot, it will be kicked.
#settings gifs enable/disable: when enabled, all gifs will be cleared.
#settings photos enable/disable: when enabled, all photos will be cleared.
#settings audios enable/disable: when enabled, all audios will be cleared.
#settings kickme enable/disable: when enabled, people can kick out itself.
#settings spam enable/disable: when enabled, all spam links will be cleared.
#settings setphoto enable/disable: when enabled, if a user changes the group photo, the bot will revert to the saved photo.
#settings setname enable/disable: when enabled, if a user changes the group name, the bot will revert to the saved name.
#settings lockmember enable/disable: when enabled, the bot will kick all people that enters to the group.
#settings floodtime : set the time that bot uses to check flood.
#settings maxflood : set the maximum messages in a floodtime to be considered as flood.
#setname : the bot will change group title.
#setphoto : the bot will change group photo.
#lang : it changes the language of the bot.
#setlink : saves the link of the group.
#link: to get the link of the group.
#muteall: mute all chat members.
#muteall : mute all chat members for time.
#unmuteall: remove mute restriction.
#creategroup: create a group with your bot in a command.
#tosupergroup: upgrade your chat to a channel.
#setdescription: change your channel description.
#plugins: shows a list of all plugins.
#plugins / [plugin]: enable/disable the specified plugin.
#plugins / [plugin] chat: enable/disable the specified plugin, only in the current group/supergroup.
#plugins reload: reloads all plugins.
#version: shows bot version.
**U can use both "#"


*Only owner and mods can add bots in supergroup

*Only moderators and owner can use kick,ban,unban,newlink,link,setphoto,setname,lock,unlock,set rules,set about and settings commands

*Only owner can use res,setowner,promote,demote and log commands

BLACKBOYS AND DEFENDER TM
@blackboys_admin_1
]]
  }
  serialize_to_file(config, './data/config.lua')
  print('saved config into ./data/config.lua')
end

function on_our_id (id)
  our_id = id
end

function on_user_update (user, what)
  --vardump (user)
end

function on_chat_update (chat, what)

end

function on_secret_chat_update (schat, what)
  --vardump (schat)
end

function on_get_difference_end ()
end

-- Enable plugins in config.json
function load_plugins()
  for k, v in pairs(_config.enabled_plugins) do
    print("Loading plugin", v)

    local ok, err =  pcall(function()
      local t = loadfile("plugins/"..v..'.lua')()
      plugins[v] = t
    end)

    if not ok then
      print('\27[31mError loading plugin '..v..'\27[39m')
      print(tostring(io.popen("lua plugins/"..v..".lua"):read('*all')))
      print('\27[31m'..err..'\27[39m')
    end

  end
end


-- custom add
function load_data(filename)

	local f = io.open(filename)
	if not f then
		return {}
	end
	local s = f:read('*all')
	f:close()
	local data = JSON.decode(s)

	return data

end

function save_data(filename, data)

	local s = JSON.encode(data)
	local f = io.open(filename, 'w')
	f:write(s)
	f:close()

end

-- Call and postpone execution for cron plugins
function cron_plugins()

  for name, plugin in pairs(plugins) do
    -- Only plugins with cron function
    if plugin.cron ~= nil then
      plugin.cron()
    end
  end

  -- Called again in 2 mins
  postpone (cron_plugins, false, 120)
end

-- Start and load values
our_id = 144616352
now = os.time()
math.randomseed(now)
started = false

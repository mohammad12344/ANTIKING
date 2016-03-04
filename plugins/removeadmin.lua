do local function run(msg, matches) if not is_admin(msg) then return nil end

if msg.to.type == 'channel'then

if matches[1] == "removeadmin" then Channel = 'channel#'..msg.to.id user = 'user#'..matches[2] channel_rem_admin(Channel, user, ok_cb, true) return user..'\nremoved admin' end

end end  return { description = "", usage = {}, patterns = { "^[!/#](removeadmin) (%d+)$" }, run = run }

end

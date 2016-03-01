local function run(msg)
    if msg.to.type == 'chat' and not is_momod(msg) then
        chat_del_user('chat#id'..msg.to.id, 'user#id'..msg.from.id, ok_cb, true)
        return '!!چه بی تربیت'
    end
end

return {
    patterns = {
    "[Kk][Ii][Rr]",
    "[Kk][Oo][Ss]",
    "[Nn][Aa][Nn][Aa][Tt]",
    "[Kk][Oo][Nn]",
    "[Mm][Aa][Mm][Ee]",
    "[Kk][Hh][Aa][Yy][Ee]",
    "کص",
    "کیر",
    "کون",
    "ننت",
    "ممه",
    "خایه",
    }, 
run = run
}

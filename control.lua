script.on_init(function()
    storage.teleports = storage.teleports or {}
end)

script.on_configuration_changed(function()
    storage.teleports = storage.teleports or {}
end)

script.on_event(defines.events.on_chart_tag_added, function(event)
    if not event.tag.icon or event.tag.icon.name ~= "TagToTeleport_teleport-tag" then
        return
    end

    local player = game.players[event.player_index]

    if event.tag.text == "" then
        teleport_player_to_tag(player, event.tag)
        event.tag.destroy()
    else
        create_fixed_teleport_location(player, event.tag)
    end
end)

script.on_event(defines.events.on_chart_tag_modified, function(event)
    -- if was a fixed teleport
    if event.old_icon and event.old_icon.name == "TagToTeleport_teleport-tag" then
        local teleport_number = teleport_number_from_text(event.old_text)
        destroy_fixed_teleport_location(teleport_number, event.old_text)
    end

    -- if it is now a fixed teleport
    if event.tag.icon and event.tag.icon.name == "TagToTeleport_teleport-tag" then
        local player = game.players[event.player_index]
        create_fixed_teleport_location(player, event.tag)
    end

end)

script.on_event(defines.events.on_chart_tag_removed, function(event)
    if not event.tag.icon or event.tag.icon.name ~= "TagToTeleport_teleport-tag" then
        return
    end

    if event.tag.text == "" then
        return
    end

    local teleport_number = teleport_number_from_tag(event.tag)
    destroy_fixed_teleport_location(teleport_number)
end)


function create_fixed_teleport_location(player, tag)
    local teleport_number = teleport_number_from_tag(tag)

    if teleport_number == nil then
        player.print("Invalid name! First character must be a digit!")
        tag.text = ""
        tag.destroy()
        do return end
    end

    if storage.teleports[teleport_number] then
        player.print("Teleport " .. teleport_number .. " already exists!")
        tag.text = ""
        tag.destroy()
    else
        game.print("Teleport '" .. tag.text .. "' created")
        storage.teleports[teleport_number] = tag
    end
end

function destroy_fixed_teleport_location(teleport_number, teleport_name)
    teleport_name = teleport_name or storage.teleports[teleport_number].text
    storage.teleports[teleport_number] = nil
    game.print("Teleport '" .. teleport_name .. "' removed")
end

function teleport_player_to_fixed_teleport_location(player, teleport_number)
    local tag = storage.teleports[teleport_number] -- I can reproduce this error, another mods can delete this tag and it's not more valid / 2019-06-02 darkfrei

    if tag == nil or not (tag.valid) then
        storage.teleports[teleport_number] = nil
        player.print("Teleport " .. teleport_number .. " doesn't exist!")
        do return end
    end    
    
    player.print("Teleported to '" .. tag.text .. "'")
    teleport_player_to_tag(player, storage.teleports[teleport_number])
end

function teleport_player_to_tag(player, tag)
    local position = tag.surface.find_non_colliding_position("character", tag.position, 128, 2)
    if position then
        player.print("Traveled distance: " .. distance(player.position, position))
        player.teleport(position, tag.surface)
    else
        player.print("No valid position found nearby that location!")
    end
end


function teleport_number_from_tag(tag)
    return teleport_number_from_text(tag.text)
end

function teleport_number_from_text(text)
    return tonumber(string.sub(text, 1, 1))
end

function distance(position_1, position_2)
    return math.floor(((position_1.x - position_2.x) ^ 2 + (position_1.y - position_2.y) ^ 2) ^ 0.5)
end

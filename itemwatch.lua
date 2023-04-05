--[[
 * ItemWatch - Copyright (c) 2016 atom0s [atom0s@live.com]
 *
 * This work is licensed under the Creative Commons Attribution-NonCommercial-NoDerivatives 4.0 International License.
 * To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-nd/4.0/ or send a letter to
 * Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
 *
 * By using ItemWatch, you agree to the above license and its terms.
 *
 *      Attribution - You must give appropriate credit, provide a link to the license and indicate if changes were
 *                    made. You must do so in any reasonable manner, but not in any way that suggests the licensor
 *                    endorses you or your use.
 *
 *   Non-Commercial - You may not use the material (ItemWatch) for commercial purposes.
 *
 *   No-Derivatives - If you remix, transform, or build upon the material (ItemWatch), you may not distribute the
 *                    modified material. You are, however, allowed to submit the modified works back to the original
 *                    ItemWatch project in attempt to have it added to the original project.
 *
 * You may not apply legal terms or technological measures that legally restrict others
 * from doing anything the license permits.
 *
 * No warranties are given.
]]
--

_addon.author  = 'atom0s';
_addon.name    = 'ItemWatch';
_addon.version = '3.0.1hb'; -- dropwatch stuff by Heavyboots

require 'common'
require 'imguidef'
require 'helpers'
lists                            = require 'ListManager'

----------------------------------------------------------------------------------------------------
-- Default Configurations
----------------------------------------------------------------------------------------------------
local default_config             =
{
    font = {
        name      = 'Consolas',
        size      = 10,
        position  = { 50, 50 },
        color     = 0xFFFFFFFF,
        bgcolor   = 0x80000000,
        bgvisible = true,
    },
    kicolor1 = 0xFFFF0000, -- Color used when the player does not have the key item. (Default red.)
    kicolor2 = 0xFF00FF00, -- Color used when the player does have the key item. (Default green.)
    compact_mode = false
};

----------------------------------------------------------------------------------------------------
-- Variables
----------------------------------------------------------------------------------------------------
local itemwatch_config           = default_config;
local itemwatch_items            = {};
local itemwatch_keys             = {};
local itemwatch_session_items    = {};
itemwatch_session_items['drops'] = {}
itemwatch_session_items['mobs']  = {}
local itemwatch_settings_pane    = 3;
local itemwatch_settings_items   = {};
local itemwatch_settings_keys    = {};
local itemwatch_export_files     = {};
local itemwatch_chest_drop_delay = os.time()

----------------------------------------------------------------------------------------------------
-- UI Variables
----------------------------------------------------------------------------------------------------
local variables                  =
{
    -- Editor Window Variables
    ['var_ShowEditorWindow']     = { nil, ImGuiVar_BOOLCPP, false },
    ['var_ShowImportWindow']     = { nil, ImGuiVar_BOOLCPP, false },
    -- Item Editor Variables
    ['var_SelectedItem']         = { nil, ImGuiVar_INT32, -1 },
    ['var_FoundSelectedItem']    = { nil, ImGuiVar_INT32, -1 },
    ['var_ItemLookup']           = { nil, ImGuiVar_CDSTRING, 64 },
    -- Key Item Editor Variables
    ['var_SelectedKeyItem']      = { nil, ImGuiVar_INT32, -1 },
    ['var_FoundSelectedKeyItem'] = { nil, ImGuiVar_INT32, -1 },
    ['var_KeyItemLookup']        = { nil, ImGuiVar_CDSTRING, 64 },
    -- Save List Editor Variables
    ['var_SelectedSavedList']    = { nil, ImGuiVar_INT32, -1 },
    ['var_SavedListName']        = { nil, ImGuiVar_CDSTRING, 64 },
    -- Configuration Editor Variables
    ['var_FontFamily']           = { nil, ImGuiVar_CDSTRING, 255 },
    ['var_FontSize']             = { nil, ImGuiVar_INT32, 10 },
    ['var_FontPositionX']        = { nil, ImGuiVar_INT32, 50 },
    ['var_FontPositionY']        = { nil, ImGuiVar_INT32, 50 },
    ['var_FontColor']            = { nil, ImGuiVar_FLOATARRAY, 4 },
    ['var_FontBGVisible']        = { nil, ImGuiVar_BOOLCPP, true },
    ['var_FontBGColor']          = { nil, ImGuiVar_FLOATARRAY, 4 },
    ['var_KeyItemColor1']        = { nil, ImGuiVar_FLOATARRAY, 4 },
    ['var_KeyItemColor2']        = { nil, ImGuiVar_FLOATARRAY, 4 },
    ['var_UseCompactMode']       = { nil, ImGuiVar_BOOLCPP, false }
};

----------------------------------------------------------------------------------------------------
-- func: load_settings
-- desc: Loads the ItemWatch settings file.
----------------------------------------------------------------------------------------------------
local function load_settings()
    ashita.file.create_dir(_addon.path .. '/settings/lists');
    ashita.file.create_dir(_addon.path .. '/exports/');

    -- Load the settings file..
    itemwatch_config = ashita.settings.load_merged(_addon.path .. 'settings/itemwatch.json', itemwatch_config);

    -- Create the display font object..
    local font = AshitaCore:GetFontManager():Create('__itemwatch_display');
    font:SetBold(false);
    font:SetColor(itemwatch_config.font.color);
    font:SetFontFamily(itemwatch_config.font.name);
    font:SetFontHeight(itemwatch_config.font.size);
    font:SetPositionX(itemwatch_config.font.position[1]);
    font:SetPositionY(itemwatch_config.font.position[2]);
    font:SetText('ItemWatch by atom0s');
    font:SetVisibility(true);
    font:GetBackground():SetColor(itemwatch_config.font.bgcolor);
    font:GetBackground():SetVisibility(itemwatch_config.font.bgvisible);

    -- Update the configuration variables..
    imgui.SetVarValue(variables['var_FontFamily'][1], itemwatch_config.font.name);
    imgui.SetVarValue(variables['var_FontSize'][1], itemwatch_config.font.size);
    imgui.SetVarValue(variables['var_FontPositionX'][1], itemwatch_config.font.position[1]);
    imgui.SetVarValue(variables['var_FontPositionY'][1], itemwatch_config.font.position[2]);
    local a, r, g, b = color_to_argb(itemwatch_config.font.color);
    imgui.SetVarValue(variables['var_FontColor'][1], r / 255, g / 255, b / 255, a / 255);
    local a, r, g, b = color_to_argb(itemwatch_config.font.bgcolor);
    imgui.SetVarValue(variables['var_FontBGColor'][1], r / 255, g / 255, b / 255, a / 255);
    imgui.SetVarValue(variables['var_FontBGVisible'][1], itemwatch_config.font.bgvisible);
    local a, r, g, b = color_to_argb(itemwatch_config.kicolor1);
    imgui.SetVarValue(variables['var_KeyItemColor1'][1], r / 255, g / 255, b / 255, a / 255);
    local a, r, g, b = color_to_argb(itemwatch_config.kicolor2);
    imgui.SetVarValue(variables['var_KeyItemColor2'][1], r / 255, g / 255, b / 255, a / 255);
    imgui.SetVarValue(variables['var_UseCompactMode'][1], itemwatch_config.compact_mode);
end

----------------------------------------------------------------------------------------------------
-- func: save_settings
-- desc: Saves the ItemWatch settings file.
----------------------------------------------------------------------------------------------------
local function save_settings()
    -- Obtain the configuration editor values..
    local font_name                 = imgui.GetVarValue(variables['var_FontFamily'][1]);
    local font_size                 = imgui.GetVarValue(variables['var_FontSize'][1]);
    local font_color                = imgui.GetVarValue(variables['var_FontColor'][1]);
    local font_bgcolor              = imgui.GetVarValue(variables['var_FontBGColor'][1]);
    local font_bgvisible            = imgui.GetVarValue(variables['var_FontBGVisible'][1]);
    local font_kicolor1             = imgui.GetVarValue(variables['var_KeyItemColor1'][1]);
    local font_kicolor2             = imgui.GetVarValue(variables['var_KeyItemColor2'][1]);
    local use_compact               = imgui.GetVarValue(variables['var_UseCompactMode'][1]);

    local f                         = AshitaCore:GetFontManager():Get('__itemwatch_display');
    itemwatch_config.font.name      = font_name;
    itemwatch_config.font.size      = font_size;
    itemwatch_config.font.color     = colortable_to_int(font_color);
    itemwatch_config.font.bgcolor   = colortable_to_int(font_bgcolor);
    itemwatch_config.font.bgvisible = font_bgvisible;
    itemwatch_config.font.position  = { f:GetPositionX(), f:GetPositionY() };
    itemwatch_config.kicolor1       = colortable_to_int(font_kicolor1);
    itemwatch_config.kicolor2       = colortable_to_int(font_kicolor2);
    itemwatch_config.compact_mode   = use_compact;

    -- Save the configurations..
    ashita.settings.save(_addon.path .. 'settings/itemwatch.json', itemwatch_config);

    -- Update the font object with new settings..
    local font = AshitaCore:GetFontManager():Get('__itemwatch_display');
    font:SetBold(false);
    font:SetColor(itemwatch_config.font.color);
    font:SetFontFamily(itemwatch_config.font.name);
    font:SetFontHeight(itemwatch_config.font.size);
    font:SetPositionX(itemwatch_config.font.position[1]);
    font:SetPositionY(itemwatch_config.font.position[2]);
    font:SetVisibility(true);
    font:GetBackground():SetColor(itemwatch_config.font.bgcolor);
    font:GetBackground():SetVisibility(itemwatch_config.font.bgvisible);
end

local function export_session_data()
    local data = ashita.settings.JSON:encode_pretty(itemwatch_session_items);
    -- Open the file for writing..
    local f = io.open(_addon.path .. '/exports/' .. os.date("%m-%d-%Y %H%M%S") .. '.json', 'w');
    if (f == nil) then
        msg('Failed to create and open new export file for writing.');
        return;
    end

    -- Save the data to the file..
    f:write(data);
    f:close();

    msg(string.format('Saved the export data to: \'\30\05/exports/%s\30\01\'', os.date("%m-%d-%Y %H%M%S") .. '.json'));
end

local function import_session_data()

end

----------------------------------------------------------------------------------------------------
-- func: load
-- desc: Called when the addon is loaded.
----------------------------------------------------------------------------------------------------
ashita.register_event('load', function()
    -- Initialize the custom variables..
    for k, v in pairs(variables) do
        if (v[2] >= ImGuiVar_CDSTRING) then
            variables[k][1] = imgui.CreateVar(variables[k][2], variables[k][3]);
        else
            variables[k][1] = imgui.CreateVar(variables[k][2]);
        end
        if (#v > 2 and v[2] < ImGuiVar_CDSTRING) then
            imgui.SetVarValue(variables[k][1], variables[k][3]);
        end
    end

    -- Ensure settings and lists folders exist..
    ashita.file.create_dir(normalize_path(_addon.path .. '/settings/lists/'));

    -- Load the settings file..
    load_settings();
end);

----------------------------------------------------------------------------------------------------
-- func: unload
-- desc: Called when the addon is unloaded.
----------------------------------------------------------------------------------------------------
ashita.register_event('unload', function()
    -- Save the settings file..
    save_settings();

    -- Cleanup the custom variables..
    for k, v in pairs(variables) do
        if (variables[k][1] ~= nil) then
            imgui.DeleteVar(variables[k][1]);
        end
        variables[k][1] = nil;
    end

    -- Delete the font object..
    AshitaCore:GetFontManager():Delete('__itemwatch_display');
end);

----------------------------------------------------------------------------------------------------
-- func: command
-- desc: Called when the addon is handling a command.
----------------------------------------------------------------------------------------------------
ashita.register_event('command', function(cmd, ntype)
    -- Parse the incoming command..
    local args = cmd:args();
    if args == nil or #args == 0 or not (args[1]:find('/itemwatch') or args[1]:find('/dw')) then
        return false
    end


    -- Toggle the editor window..
    if (#args == 1 or (#args >= 2 and args[2] == 'editor')) then
        imgui.SetVarValue(variables['var_ShowEditorWindow'][1],
            not imgui.GetVarValue(variables['var_ShowEditorWindow'][1]));
        return true;
    end

    -- Reload settings..
    if (#args >= 2 and args[2] == 'reload') then
        load_settings();
        return true;
    end

    -- Save settings..
    if (#args >= 2 and args[2] == 'save') then
        save_settings();
        return true;
    end

    ------------------------------------------------------------------------------------------------
    -- Item Related Commands
    ------------------------------------------------------------------------------------------------
    if (#args >= 4 and args[2] == 'item' and args[3] == 'find') then
        local name = table.concat(args, ' ', 4);
        local data = lists.find_items(name);
        msg(string.format('Found %d items containing the word(s): \'\30\05%s\30\01\'', #data, name));
        if (#data > 0) then
            msg('===========================================================================');
            for _, v in pairs(data) do
                msg(string.format('Found item: %d - %s', v[1], v[2]));
            end
        end
        return true;
    end
    if (#args >= 4 and args[2] == 'item' and args[3] == 'add') then
        local itemid = tonumber(table.concat(args, ' ', 4));
        lists.add_watched_item(itemid);
        return true;
    end
    if (#args >= 4 and args[2] == 'item' and args[3] == 'delete') then
        local itemid = tonumber(table.concat(args, ' ', 4));
        lists.delete_watched_item(itemid);
        return true;
    end
    if (#args >= 3 and args[2] == 'item' and args[3] == 'clear') then
        lists.clear_watched_items();
        return true;
    end

    ------------------------------------------------------------------------------------------------
    -- Key Item Related Commands
    ------------------------------------------------------------------------------------------------
    if (#args >= 4 and args[2] == 'key' and args[3] == 'find') then
        local name = table.concat(args, ' ', 4);
        local data = lists.find_keyitems(name);
        msg(string.format('Found %d key items containing the word(s): \'\30\05%s\30\01\'', #data, name));
        if (#data > 0) then
            msg('===========================================================================');
            for _, v in pairs(data) do
                msg(string.format('Found key item: %d - %s', v[1], v[2]));
            end
        end
        return true;
    end
    if (#args >= 4 and args[2] == 'key' and args[3] == 'add') then
        local keyid = tonumber(table.concat(args, ' ', 4));
        lists.add_watched_key(keyid);
        return true;
    end
    if (#args >= 4 and args[2] == 'key' and args[3] == 'delete') then
        local keyid = tonumber(table.concat(args, ' ', 4));
        lists.delete_watched_key(keyid);
        return true;
    end
    if (#args >= 3 and args[2] == 'key' and args[3] == 'clear') then
        lists.clear_watched_keys();
        return true;
    end

    ------------------------------------------------------------------------------------------------
    -- List Related Commands
    ------------------------------------------------------------------------------------------------
    if (#args >= 4 and args[2] == 'list' and args[3] == 'load') then
        local index = tonumber(table.concat(args, ' ', 4));
        lists.refresh_saved_lists();
        lists.load_list(index);
        return true;
    end

    if (#args >= 4 and args[2] == 'list' and args[3] == 'merge') then
        local index = tonumber(table.concat(args, ' ', 4));
        lists.refresh_saved_lists();
        lists.load_list_merged(index);
        return true;
    end

    if (#args >= 3 and args[2] == 'list' and args[3] == 'clear') then
        lists.clear_watched_keys();
        lists.clear_watched_items();
        return true;
    end

    ------------------------------------------------------------------------------------------------
    -- Dropwatch Related Commands
    ------------------------------------------------------------------------------------------------
    if (#args == 2 and args[1] == '/dw' and args[2] == 'clear') then
        itemwatch_session_items = {}
        itemwatch_session_items['drops'] = {}
        itemwatch_session_items['mobs']  = {}
        return true;
    end

    if (#args == 2 and args[1] == '/dw' and args[2] == 'items') then
        print('\30\05Items Report ' .. os.date("%m/%d/%Y %H:%M:%S"))
        if (itemwatch_session_items['item_grid_data']) then
            for _, v in ipairs(itemwatch_session_items['item_grid_data']) do
                print(string.format('\30\02%s : %s/%s %s%%', v[1], v[2], v[3], v[4]))
            end
        end
        return true;
    end

    if (#args == 2 and args[1] == '/dw' and args[2] == 'mobs') then         
        -- local string = string.format('Mobs Report %s',tostring(os.date("%m/%d/%Y %H:%M:%S")))
        -- ashita.timer.once(1, function()
        --     AshitaCore:GetChatManager():QueueCommand('/echo '.. string, 2);
        -- end);
        print('\30\05Mobs Report ' .. os.date("%m/%d/%Y %H:%M:%S"))
        if (itemwatch_session_items['mob_grid_data']) then
            for k, drops in pairs(itemwatch_session_items['mob_grid_data']) do
                print('\30\03' .. itemwatch_session_items['mob_grid_data'][k]['mob'])
                for i, drop in ipairs(drops) do
                    print(string.format(' >\30\02 %s : %s/%s %s%%', drop['item'], drop['item count'], drop['mob kills'],
                    drop['drop rate']))
                end
            end
        end
        return true;
    end

    if (#args == 2 and args[1] == '/dw' and args[2] == 'log') then
        print('\30\05Log Report ' .. os.date("%m/%d/%Y %H:%M:%S"))
        if (itemwatch_session_items['log_grid_data']) then
            for _, v in ipairs(itemwatch_session_items['log_grid_data']) do
                print('\30\02' .. v[1] .. ' : ' .. v[2] .. ' ' .. v[3] .. ' ' .. v[4]);
            end
        end
        return true;
    end

    if (#args == 2 and args[1] == '/dw' and args[2] == 'export') then
        export_session_data();
        return true;
    end

    if (#args == 2 and args[1] == '/dw' and args[2] == 'import') then
        --import_session_data();
        return true;
    end

    return true;
end);

----------------------------------------------------------------------------------------------------
-- func: render
-- desc: Called when the addon is rendering.
----------------------------------------------------------------------------------------------------
ashita.register_event('render', function()
    -- manage dropwatch data
    -- TODO: clean up this fine italian cuisine
    itemwatch_session_items['log_grid_data'] = {};
    itemwatch_session_items['item_grid_data'] = {}
    itemwatch_session_items['mob_grid_data'] = {}

    if (itemwatch_session_items['drops']) then
        local itm_grp = {}
        local mob_grp = {}

        for k, v in pairs(itemwatch_session_items['drops']) do
            ------------------------------------------------------------------------------------------------
            -- Basic Log
            ------------------------------------------------------------------------------------------------
            table.insert(itemwatch_session_items['log_grid_data'], {
                tostring(v.mob),
                tostring(v.item),
                tostring(v.count),
                tostring(os.date("%x %X", v.timestamp))
            });

            ------------------------------------------------------------------------------------------------
            -- Items Log
            ------------------------------------------------------------------------------------------------
            if not (itm_grp[v.item]) then
                itm_grp[v.item] = {
                }
            end

            if not itm_grp[v.item][v.mob] then
                itm_grp[v.item][v.mob] = {}
            end

            table.insert(itm_grp[v.item][v.mob], v)

            ------------------------------------------------------------------------------------------------
            -- Mobs Log
            ------------------------------------------------------------------------------------------------
            if not mob_grp[v.mob] then
                mob_grp[v.mob] = {}
            end

            if not mob_grp[v.mob][v.item] then
                mob_grp[v.mob][v.item] = {}
            end

            table.insert(mob_grp[v.mob][v.item], v)
        end

        ------------------------------------------------------------------------------------------------
        -- Items Log
        ------------------------------------------------------------------------------------------------
        for item, mobs in pairs(itm_grp) do
            local total_item_count = 0
            local total_mob_kills = 0
            -- print("Item:", item)
            for mob, data in pairs(mobs) do
                local item_count = 0
                for _, v in ipairs(data) do
                    item_count = item_count + v.count
                    total_item_count = total_item_count + v.count
                end
                local mob_kills = 0
                for _, v in ipairs(itemwatch_session_items['mobs']) do
                    if (mob == v['mob']) then
                        mob_kills = mob_kills + 1
                        total_mob_kills = total_mob_kills + 1
                    end
                end
                -- print("mob:", mob, "Total Count:", item_count, "Total Kills:", mob_kills)
            end
            local rate = 0
            local success, result = pcall(function() return total_item_count / total_mob_kills * 100 end)
            if success then rate = math.floor(result) end
            if (item == 'gil') then rate = '-' end
            table.insert(itemwatch_session_items['item_grid_data'], {
                tostring(item),
                tostring(total_item_count),
                tostring(total_mob_kills),
                tostring(rate)
            })
        end

         table.sort(itemwatch_session_items['item_grid_data'], function (k1,k2)
             return k1[1] < k2[1]    
        end)
        ------------------------------------------------------------------------------------------------
        -- Mobs Log
        ------------------------------------------------------------------------------------------------
        for mob, items in pairs(mob_grp) do
            table.insert(itemwatch_session_items['mob_grid_data'], 1, {
                ['mob'] = tostring(mob),
            })
            -- print("Mob:", mob)
            for item, data in pairs(items) do
                local item_count = 0
                for _, v in ipairs(data) do
                    item_count = item_count + v.count
                end
                local mob_kills = 0
                for _, v in ipairs(itemwatch_session_items['mobs']) do
                    if (mob == v['mob']) then
                        mob_kills = mob_kills + 1
                    end
                end
                local rate = 0
                local success, result = pcall(function() return item_count / mob_kills * 100 end)
                if success then rate = math.floor(result) end
                table.insert(itemwatch_session_items['mob_grid_data'][1], 1, {
                    ['item'] = tostring(item),
                    ['item count'] = tostring(item_count),
                    ['mob kills'] = tostring(mob_kills),
                    ['drop rate'] = tostring(rate)
                })
                -- print("Item:", item, "Total Count:", item_count, "Total Kills:", mob_kills)
            end
        end
    end


    -- Obtain the item watch font object..
    local font = AshitaCore:GetFontManager():Get('__itemwatch_display');
    if (font == nil) then
        return;
    end

    -- Ensure there is something to display..
    if (lists.total_watch_count() > 0) then
        local inventory = AshitaCore:GetDataManager():GetInventory();
        local player = AshitaCore:GetDataManager():GetPlayer();
        local output = '';

        -- Display watched items..
        if (lists.items_watch_count() > 0) then
            if (itemwatch_config.compact_mode == false) then
                output = output .. 'Items\n';
                output = output .. '--------------------------------------\n';
            end

            for _, v in pairs(lists.watched_items) do
                local total = 0;
                for x = 0, 12 do
                    for y = 0, 80 do
                        local item = inventory:GetItem(x, y);
                        if (item ~= nil and item.Id == v[1]) then
                            total = total + item.Count;
                        end
                    end
                end

                -- Add the item to the output..
                if (itemwatch_config.compact_mode == false) then
                    local info = string.format('%-28s %d\n', v[2], total);
                    output = output .. info;
                else
                    local info = string.format('%4d %s\n', total, v[2]);
                    output = output .. info;
                end
            end

            output = output .. '\n';
        end

        -- Display watched keys..
        if (lists.keys_watch_count() > 0) then
            if (itemwatch_config.compact_mode == false) then
                output = output .. 'Key Items\n';
                output = output .. '--------------------------------------\n';
            end

            for _, v in pairs(lists.watched_keys) do
                if (player:HasKeyItem(v[1])) then
                    local txt = colorize_string(v[2], itemwatch_config.kicolor2);
                    output = output .. txt .. '\n';
                else
                    local txt = colorize_string(v[2], itemwatch_config.kicolor1);
                    output = output .. txt .. '\n';
                end
            end
        end

        -- Update the displayed information..
        font:SetText(trim(output, itemwatch_config.compact_mode));
    else
        -- Clear the displayed information..
        font:SetText('');
    end

    -- Don't render the editor if its not visible..
    if (imgui.GetVarValue(variables['var_ShowEditorWindow'][1]) == false) then
        return;
    end

    -- Render the editor window..
    imgui.SetNextWindowSize(600, 400, ImGuiSetCond_FirstUseEver);
    imgui.SetNextWindowSizeConstraints(600, 400, FLT_MAX, FLT_MAX);
    if (not imgui.Begin('ItemWatch Editor', variables['var_ShowEditorWindow'][1], ImGuiWindowFlags_NoResize)) then
        imgui.End();
        return;
    end

    -- Sets the next button color of ImGui based on the selected tab button.
    function set_button_color(index)
        if (itemwatch_settings_pane == index) then
            imgui.PushStyleColor(ImGuiCol_Button, 0.25, 0.69, 1.0, 0.8);
        else
            imgui.PushStyleColor(ImGuiCol_Button, 0.25, 0.69, 1.0, 0.1);
        end
    end

    -- Render the tabbed navigation buttons..
    set_button_color(0);
    if (imgui.Button('Items Editor')) then
        itemwatch_settings_pane = 0;
    end
    imgui.PopStyleColor();
    imgui.SameLine();
    set_button_color(1);
    if (imgui.Button('Key Items Editor')) then
        itemwatch_settings_pane = 1;
    end
    imgui.PopStyleColor();
    imgui.SameLine();
    set_button_color(2);
    if (imgui.Button('Dropwatch Editor')) then
        itemwatch_settings_pane = 2;
    end
    imgui.PopStyleColor();
    imgui.SameLine();
    set_button_color(3);
    if (imgui.Button('Saved Lists Editor')) then
        itemwatch_settings_pane = 3;
    end
    imgui.PopStyleColor();
    imgui.SameLine();
    set_button_color(4);
    if (imgui.Button('Configurations Editor')) then
        itemwatch_settings_pane = 4;
    end
    imgui.PopStyleColor();
    imgui.Separator();

    -- Render the editor panels..
    imgui.BeginGroup();
    switch(itemwatch_settings_pane):caseof
    {
        [0] = function() render_items_editor() end,
        [1] = function() render_keyitems_editor() end,
        [2] = function() render_session_items_editor() end,
        [3] = function() render_savedlists_editor() end,
        [4] = function() render_configuration_editor() end,
        ['default'] = function() render_items_editor() end
    };
    imgui.EndGroup();

    -- Finish rendering the window..
    imgui.End();
end);

---------------------------------------------------------------------------------------------------
-- func: incoming_packet
-- desc: Called when addon receives an incoming packet.
---------------------------------------------------------------------------------------------------
ashita.register_event('incoming_packet', function(id, size, packet)
    local action_message = {};
    local drop = {};
    if (id == 0x029) then
        -- -- Action packet
        action_message = {
            -- https://github.com/Windower/Lua/blob/d97a154f5de7d77f0271b895bab8d31b50896d00/addons/libs/packets/fields.lua#L1846
            actor = struct.unpack('I', packet, 0x04 + 1),
            target = struct.unpack('I', packet, 0x08 + 1),
            param1 = struct.unpack('I', packet, 0x0C + 1),
            param2 = struct.unpack('I', packet, 0x10 + 1),
            actor_index = struct.unpack('H', packet, 0x14 + 1),
            target_index = struct.unpack('H', packet, 0x16 + 1),
            message = struct.unpack('H', packet, 0x18 + 1),
            _unknown1 = struct.unpack('H', packet, 0x1A + 1),
        }

        if (action_message.message == 565) then
            -- gil message
            local success, result = pcall(function() return GetEntity(action_message.actor_index).Name end)
            if (success) then
                table.insert(itemwatch_session_items['drops'], 1, {
                    ['item'] = 'Gil',
                    ['mob'] = result,
                    ['count'] = action_message.param1,
                    ['timestamp'] = os.time()
                });
            end
        end
    elseif (id == 0x0D2) then
        -- Found item packet
        drop = {
            -- https://github.com/Windower/Lua/blob/d97a154f5de7d77f0271b895bab8d31b50896d00/addons/libs/packets/fields.lua#L3508
            dropper = struct.unpack('I', packet, 0x08 + 1),
            count = struct.unpack('I', packet, 0x0C + 1),
            item = struct.unpack('H', packet, 0x10 + 1),
            dropper_index = struct.unpack('H', packet, 0x12 + 1),
            index = struct.unpack('B', packet, 0x14 + 1),
            is_old = struct.unpack('B', packet, 0x15 + 1),
            timestamp = os.time(),
            -- timestamp = struct.unpack('I', packet, 0x18 + 1),
        }

        if (drop.is_old == 1) then
            return false;
        end

        local mob = ''
        local item = ''
        local success, result = pcall(function() return GetEntity(drop.dropper_index).Name end)
        if (success) then mob = result end
        success, result = pcall(function() return AshitaCore:GetResourceManager():GetItemById(drop.item).Name[0] end)
        if (success) then item = result end

        table.insert(itemwatch_session_items['drops'], 1, {
            ['item'] = item,
            ['mob'] = mob,
            ['count'] = 1,
            ['timestamp'] = os.time()
        });
    end
    return false;
end)

---------------------------------------------------------------------------------------------------
-- func: incoming_text
-- desc: Event called when the addon is asked to handle an incoming chat line.
---------------------------------------------------------------------------------------------------
ashita.register_event('incoming_text', function(mode, message, modifiedmode, modifiedmessage, blocked)
    if message ~= nil then
        local kill_match_string = 'defeats the (.*)%.'
        local falls_to_ground_match_string = '(.*)% falls to the ground.'
        local steal_match_string = 'steals an? (.*)% from the (.*)%.';
        local gil_match_string = 'obtains (.*)% gil.'
        local chest_match_string = 'You find an? (.*)% in the (.*)%.'

        local steal_item, steal_mob = string.match(message, steal_match_string)
        local kill_mob = string.match(message, kill_match_string)
        local fallen_mob = string.match(message, falls_to_ground_match_string)
        local gil = string.match(message, gil_match_string)
        local chest_item, chest = string.match(message, chest_match_string);

        local zone = AshitaCore:GetResourceManager():GetString('areas',
            AshitaCore:GetDataManager():GetParty():GetMemberZone(0));

        if steal_item and steal_mob then
            steal_item = string.sub(steal_item, 3, -3)
            steal_item = steal_item:gsub("(%l)(%w*)", function(a, b) return string.upper(a) .. b end) .. ' (stolen)'

            table.insert(itemwatch_session_items['mobs'], {
                ['mob'] = steal_mob,
                ['timestamp'] = os.time(),
            });
            table.insert(itemwatch_session_items['drops'], 1, {
                ['item'] = steal_item,
                ['mob'] = steal_mob,
                ['count'] = 1,
                ['timestamp'] = os.time(),
            });
        elseif chest_item and chest then
            chest_item = string.sub(chest_item, 3, -3)
            chest_item = chest_item:gsub("(%l)(%w*)", function(a, b) return string.upper(a) .. b end)
            if os.time() > itemwatch_chest_drop_delay then
                table.insert(itemwatch_session_items['mobs'], {
                    ['mob'] = chest,
                    ['timestamp'] = os.time(),
                });
                itemwatch_chest_drop_delay = os.time() + 20
            end
            
        elseif mode == 36 or mode == 37 or mode == 44 or mode == 121 or string.contains(zone:lower(), 'dynamis') then
            if (kill_mob or fallen_mob) then
                table.insert(itemwatch_session_items['mobs'], {
                    ['mob'] = kill_mob or fallen_mob,
                    ['timestamp'] = os.time(),
                });
            end
        end
    end
    return false;
end);

----------------------------------------------------------------------------------------------------
-- func: render_items_editor
-- desc: Renders the items editor panel.
----------------------------------------------------------------------------------------------------
function render_items_editor()
    -- Left Side (Many whelps! HANDLE IT!!!)
    imgui.PushStyleColor(ImGuiCol_Border, 0.25, 0.69, 1.0, 0.4);
    imgui.BeginGroup();
    -- Left side watched items list..
    imgui.BeginChild('leftpane', 250, -imgui.GetItemsLineHeightWithSpacing(), true);
    imgui.TextColored(1.0, 1.0, 0.4, 1.0, 'Current Watched Items');
    imgui.Separator();
    for x = 0, #lists.watched_items - 1 do
        if (x < #lists.watched_items) then
            -- Display watched item..
            local name = string.format('%s##%d', lists.watched_items[x + 1][2], lists.watched_items[x + 1][1]);
            if (imgui.Selectable(name, imgui.GetVarValue(variables['var_SelectedItem'][1]) == x)) then
                imgui.SetVarValue(variables['var_SelectedItem'][1], x);
            end

            -- Handle watched item double click..
            if (imgui.IsItemHovered() and imgui.IsMouseDoubleClicked(0)) then
                if (imgui.GetVarValue(variables['var_SelectedItem'][1]) >= 0) then
                    local item = lists.watched_items[imgui.GetVarValue(variables['var_SelectedItem'][1]) + 1];
                    lists.delete_watched_item(item[1]);
                    imgui.SetVarValue(variables['var_SelectedItem'][1], -1);
                end
            end
        end
    end
    imgui.EndChild();

    -- Left side buttons..
    if (imgui.Button('Remove Selected')) then
        if (imgui.GetVarValue(variables['var_SelectedItem'][1]) >= 0) then
            local item = lists.watched_items[imgui.GetVarValue(variables['var_SelectedItem'][1]) + 1];
            lists.delete_watched_item(item[1]);
            imgui.SetVarValue(variables['var_SelectedItem'][1], -1);
        end
    end
    imgui.SameLine();
    if (imgui.Button('Remove All')) then
        lists.clear_watched_items();
    end
    imgui.EndGroup();
    imgui.SameLine();

    -- Right Side (Item Lookup Editor)
    imgui.BeginGroup();
    imgui.BeginChild('rightpane', 0, -imgui.GetItemsLineHeightWithSpacing(), true);
    imgui.TextColored(1.0, 1.0, 0.4, 1.0, 'Find Item Tool');
    imgui.Separator();

    -- Item search tool..
    if (imgui.InputText('Item Name', variables['var_ItemLookup'][1], 64, imgui.bor(ImGuiInputTextFlags_EnterReturnsTrue))) then
        itemwatch_settings_items = lists.find_items(imgui.GetVarValue(variables['var_ItemLookup'][1]));
    end
    imgui.SameLine();
    show_help('Enter an item name to lookup. (You can use partial names.)');
    if (imgui.Button('Search For Item(s)', -1, 18)) then
        itemwatch_settings_items = lists.find_items(imgui.GetVarValue(variables['var_ItemLookup'][1]));
    end
    imgui.Separator();
    imgui.BeginChild('rightpane_founditems');
    for x = 0, #itemwatch_settings_items - 1 do
        -- Display found item..
        local name = string.format('(%d) %s##found_%d', itemwatch_settings_items[x + 1][1],
            itemwatch_settings_items[x + 1][2], itemwatch_settings_items[x + 1][1]);
        if (imgui.Selectable(name, imgui.GetVarValue(variables['var_FoundSelectedItem'][1]) == x)) then
            imgui.SetVarValue(variables['var_FoundSelectedItem'][1], x);
        end

        -- Handle item double click..
        if (imgui.IsItemHovered() and imgui.IsMouseDoubleClicked(0)) then
            if (imgui.GetVarValue(variables['var_FoundSelectedItem'][1]) >= 0) then
                local item = itemwatch_settings_items[imgui.GetVarValue(variables['var_FoundSelectedItem'][1]) + 1];
                if (item ~= nil) then
                    lists.add_watched_item(item[1]);
                end
            end
        end
    end
    imgui.EndChild();
    imgui.EndChild();
    imgui.EndGroup();
end

----------------------------------------------------------------------------------------------------
-- func: render_keyitems_editor
-- desc: Renders the key items editor panel.
----------------------------------------------------------------------------------------------------
function render_keyitems_editor()
    -- Left Side (Many whelps! HANDLE IT!!!)
    imgui.PushStyleColor(ImGuiCol_Border, 0.25, 0.69, 1.0, 0.4);
    imgui.BeginGroup();
    -- Left side watched key items list..
    imgui.BeginChild('leftpane', 250, -imgui.GetItemsLineHeightWithSpacing(), true);
    imgui.TextColored(1.0, 1.0, 0.4, 1.0, 'Current Watched Key Items');
    imgui.Separator();
    for x = 0, #lists.watched_keys - 1 do
        if (x < #lists.watched_keys) then
            -- Display watched key item..
            local name = string.format('%s##%d', lists.watched_keys[x + 1][2], lists.watched_keys[x + 1][1]);
            if (imgui.Selectable(name, imgui.GetVarValue(variables['var_SelectedKeyItem'][1]) == x)) then
                imgui.SetVarValue(variables['var_SelectedKeyItem'][1], x);
            end

            -- Handle watched key item double click..
            if (imgui.IsItemHovered() and imgui.IsMouseDoubleClicked(0)) then
                if (imgui.GetVarValue(variables['var_SelectedKeyItem'][1]) >= 0) then
                    local keyitem = lists.watched_keys[imgui.GetVarValue(variables['var_SelectedKeyItem'][1]) + 1];
                    lists.delete_watched_key(keyitem[1]);
                    imgui.SetVarValue(variables['var_SelectedKeyItem'][1], -1);
                end
            end
        end
    end
    imgui.EndChild();

    -- Left side buttons..
    if (imgui.Button('Remove Selected')) then
        if (imgui.GetVarValue(variables['var_SelectedKeyItem'][1]) >= 0) then
            local keyitem = lists.watched_keys[imgui.GetVarValue(variables['var_SelectedKeyItem'][1]) + 1];
            lists.delete_watched_key(keyitem[1]);
            imgui.SetVarValue(variables['var_SelectedKeyItem'][1], -1);
        end
    end
    imgui.SameLine();
    if (imgui.Button('Remove All')) then
        lists.clear_watched_keys();
    end
    imgui.EndGroup();
    imgui.SameLine();

    -- Right Side (Key Item Lookup Editor)
    imgui.BeginGroup();
    imgui.BeginChild('rightpane', 0, -imgui.GetItemsLineHeightWithSpacing(), true);
    imgui.TextColored(1.0, 1.0, 0.4, 1.0, 'Find Key Item Tool');
    imgui.Separator();

    -- Key Item search tool..
    if (imgui.InputText('Key Item', variables['var_KeyItemLookup'][1], 64, imgui.bor(ImGuiInputTextFlags_EnterReturnsTrue))) then
        itemwatch_settings_keys = lists.find_keyitems(imgui.GetVarValue(variables['var_KeyItemLookup'][1]));
    end
    imgui.SameLine();
    show_help('Enter a key item name to lookup. (You can use partial names.)');
    if (imgui.Button('Search For Key Item(s)', -1, 18)) then
        itemwatch_settings_keys = lists.find_keyitems(imgui.GetVarValue(variables['var_KeyItemLookup'][1]));
    end
    imgui.Separator();
    imgui.BeginChild('rightpane_founditems');
    for x = 0, #itemwatch_settings_keys - 1 do
        -- Display found key item..
        local name = string.format('(%d) %s##found_%d', itemwatch_settings_keys[x + 1][1],
            itemwatch_settings_keys[x + 1][2], itemwatch_settings_keys[x + 1][1]);
        if (imgui.Selectable(name, imgui.GetVarValue(variables['var_FoundSelectedKeyItem'][1]) == x)) then
            imgui.SetVarValue(variables['var_FoundSelectedKeyItem'][1], x);
        end

        -- Handle key item double click..
        if (imgui.IsItemHovered() and imgui.IsMouseDoubleClicked(0)) then
            if (imgui.GetVarValue(variables['var_FoundSelectedKeyItem'][1]) >= 0) then
                local keyitem = itemwatch_settings_keys[imgui.GetVarValue(variables['var_FoundSelectedKeyItem'][1]) + 1];
                if (keyitem ~= nil) then
                    lists.add_watched_key(keyitem[1]);
                end
            end
        end
    end
    imgui.EndChild();
    imgui.EndChild();
    imgui.EndGroup();
end

----------------------------------------------------------------------------------------------------
-- func: render_savedlists_editor
-- desc: Renders the saved lists editor panel.
----------------------------------------------------------------------------------------------------
function render_savedlists_editor()
    -- Left side saved lists..
    imgui.PushStyleColor(ImGuiCol_Border, 0.25, 0.69, 1.0, 0.4);
    imgui.BeginChild('leftpane', 250, -1, true);
    imgui.TextColored(1.0, 1.0, 0.4, 1.0, 'Saved Lists');
    imgui.Separator();
    for x = 0, #lists.saved_lists - 1 do
        if (x < #lists.saved_lists) then
            local name = string.format('%s##%d', lists.saved_lists[x + 1], x);
            if (imgui.Selectable(name, imgui.GetVarValue(variables['var_SelectedSavedList'][1]) == x)) then
                imgui.SetVarValue(variables['var_SelectedSavedList'][1], x);
            end

            -- Handle saved list item double click..
            if (imgui.IsItemHovered() and imgui.IsMouseDoubleClicked(0)) then
                if (imgui.GetVarValue(variables['var_SelectedSavedList'][1]) >= 0) then
                    local index = imgui.GetVarValue(variables['var_SelectedSavedList'][1]);
                    lists.load_list(index);
                end
            end
        end
    end

    if (#lists.saved_lists <= 0) then
        imgui.PushTextWrapPos(0);
        imgui.TextColored(1.0, 0.4, 0.4, 1.0, 'There are currently no saved lists to display here!');
        imgui.TextColored(0.4, 1.0, 0.4, 1.0,
            'Click \'Refresh Lists\' on the right to populate the saved lists shown here.');
        imgui.PopTextWrapPos();
    end
    imgui.EndChild();
    imgui.SameLine();

    -- Right side saved lists editor..
    imgui.BeginChild('rightpane', -1, -1, true);
    imgui.TextColored(1.0, 1.0, 0.4, 1.0, 'Saved List Editor');
    imgui.Separator();
    imgui.PushItemWidth(225);
    imgui.InputText('List Name', variables['var_SavedListName'][1], 64);
    imgui.PopItemWidth();
    imgui.SameLine();
    show_help(
        'The name used while saving a new list file. Must be a valid file name.\n(You do not need to include the file extension, it will be added automatically.)')
    if (imgui.Button('Save As New List File', 225, 18)) then
        local name = imgui.GetVarValue(variables['var_SavedListName'][1]);
        lists.save_list_new(name);
    end
    imgui.SameLine();
    show_help('Saves the current watch data into a new file with the given name above.');
    if (imgui.Button('Save As Existing List File', 225, 18)) then
        local index = imgui.GetVarValue(variables['var_SelectedSavedList'][1]);
        lists.save_list_existing(index);
    end
    imgui.SameLine();
    show_help(
        'Saves the current watch data into the selected file on the left.\n\nWarning: This overwrites the data in the selected file!');
    imgui.Separator();
    imgui.TextColored(0.2, 0.8, 1.0, 1.0, 'Load Controls');
    if (imgui.Button('Load Selected List', 225, 18)) then
        local index = imgui.GetVarValue(variables['var_SelectedSavedList'][1]);
        lists.load_list(index);
    end
    imgui.SameLine();
    show_help(
        'Loads the selected list on the left.\n\nReplaces all currently watched data. (All unsaved watches will be lost!)');
    if (imgui.Button('Load Selected List (Merged)', 225, 18)) then
        local index = imgui.GetVarValue(variables['var_SelectedSavedList'][1]);
        lists.load_list_merged(index);
    end
    imgui.SameLine();
    show_help(
        'Loads the selected list on the left.\n\nOnce loaded the data is merged with the currently watched data rather than resetting it.');
    imgui.Separator();
    imgui.TextColored(0.2, 0.8, 1.0, 1.0, 'Delete Controls');
    if (imgui.Button('Delete Selected List', 225, 18)) then
        local index = imgui.GetVarValue(variables['var_SelectedSavedList'][1]);
        lists.delete_list(index);
    end
    imgui.SameLine();
    show_help('Deletes the currently selected list on the left.');
    if (imgui.Button('Delete All Saved Lists', 225, 18)) then
        imgui.SetNextWindowSize(300, 100, ImGuiSetCond_Always);
        imgui.OpenPopup('###DeleteAllConfirmPopup');
    end
    if (imgui.BeginPopupModal('Delete all saved lists?###DeleteAllConfirmPopup', nil, imgui.bor(ImGuiWindowFlags_NoResize, ImGuiWindowFlags_AlwaysAutoResize))) then
        imgui.TextColored(1.0, 1.0, 1.0, 1.0, 'Whoa there, are you sure you want to do that?');
        imgui.TextColored(1.0, 0.4, 0.4, 1.0, '(Doing this cannot be undone!)');
        imgui.Spacing();
        imgui.Spacing();
        imgui.Indent(55.0);
        if (imgui.Button('Yes', 100, 18)) then
            imgui.CloseCurrentPopup();
            lists.delete_all_lists();
        end
        imgui.SameLine();
        if (imgui.Button('No', 100, 18)) then
            imgui.CloseCurrentPopup();
        end
        imgui.Unindent();
        imgui.EndPopup();
    end
    imgui.SameLine();
    show_help('Deletes all saved list files within the lists folder.\n\nWarning: You cannot undo this!');
    imgui.Separator();
    if (imgui.Button('Refresh Saved Lists', 225, 18)) then
        lists.refresh_saved_lists();
    end
    imgui.SameLine();
    show_help('Refreshes the saved list files, found within the lists folder, shown to the left.');
    imgui.EndChild();
end

----------------------------------------------------------------------------------------------------
-- func: render_configuration_editor
-- desc: Renders the configurations editor panel.
----------------------------------------------------------------------------------------------------
function render_configuration_editor()
    local font = AshitaCore:GetFontManager():Get('__itemwatch_display');

    imgui.PushStyleColor(ImGuiCol_Border, 0.25, 0.69, 1.0, 0.4);
    imgui.BeginChild('leftpane', -1, -1, true);
    imgui.TextColored(0.2, 0.8, 1.0, 1.0, 'Font Configurations');
    imgui.Separator();
    imgui.InputText('Font Family', variables['var_FontFamily'][1], 255);
    if (imgui.InputInt('Font Size', variables['var_FontSize'][1])) then
        save_settings();
    end
    if (imgui.InputInt('Font X Position', variables['var_FontPositionX'][1])) then
        local x = imgui.GetVarValue(variables['var_FontPositionX'][1]);
        font:SetPositionX(x);
        save_settings();
    else
        if (font ~= nil) then
            imgui.SetVarValue(variables['var_FontPositionX'][1], font:GetPositionX());
        end
    end
    if (imgui.InputInt('Font Y Position', variables['var_FontPositionY'][1])) then
        local y = imgui.GetVarValue(variables['var_FontPositionY'][1]);
        font:SetPositionY(y);
        save_settings();
    else
        if (font ~= nil) then
            imgui.SetVarValue(variables['var_FontPositionY'][1], font:GetPositionY());
        end
    end
    if (imgui.ColorEdit4('Font Color', variables['var_FontColor'][1])) then
        save_settings();
    end
    imgui.Separator();
    if (imgui.TextColored(0.2, 0.8, 1.0, 1.0, 'Background Configurations')) then
        save_settings();
    end
    imgui.Separator();
    if (imgui.Checkbox('Background Visible', variables['var_FontBGVisible'][1])) then
        save_settings();
    end
    if (imgui.ColorEdit4('Background Color', variables['var_FontBGColor'][1])) then
        save_settings();
    end
    imgui.Separator();
    if (imgui.TextColored(0.2, 0.8, 1.0, 1.0, 'Key Item Configurations')) then
        save_settings();
    end
    imgui.Separator();
    if (imgui.ColorEdit4('Key Item (No)', variables['var_KeyItemColor1'][1])) then
        save_settings();
    end
    if (imgui.ColorEdit4('Key Item (Yes)', variables['var_KeyItemColor2'][1])) then
        save_settings();
    end
    imgui.Separator();
    if (imgui.Checkbox('Use Compact Mode', variables['var_UseCompactMode'][1])) then
        save_settings();
    end
    if (imgui.Button('Save Settings')) then
        save_settings();
    end
    imgui.SameLine();
    if (imgui.Button('Load Settings')) then
        load_settings();
    end
    imgui.SameLine();
    if (imgui.Button('Defaults')) then
        -- Default the settings..
        itemwatch_config = table.copy(default_config);

        -- Update ImGui variables..
        imgui.SetVarValue(variables['var_FontFamily'][1], itemwatch_config.font.name);
        imgui.SetVarValue(variables['var_FontSize'][1], itemwatch_config.font.size);
        imgui.SetVarValue(variables['var_FontPositionX'][1], itemwatch_config.font.position[1]);
        imgui.SetVarValue(variables['var_FontPositionY'][1], itemwatch_config.font.position[2]);
        local a, r, g, b = color_to_argb(itemwatch_config.font.color);
        imgui.SetVarValue(variables['var_FontColor'][1], r / 255, g / 255, b / 255, a / 255);
        local a, r, g, b = color_to_argb(itemwatch_config.font.bgcolor);
        imgui.SetVarValue(variables['var_FontBGColor'][1], r / 255, g / 255, b / 255, a / 255);
        imgui.SetVarValue(variables['var_FontBGVisible'][1], itemwatch_config.font.bgvisible);
        local a, r, g, b = color_to_argb(itemwatch_config.kicolor1);
        imgui.SetVarValue(variables['var_KeyItemColor1'][1], r / 255, g / 255, b / 255, a / 255);
        local a, r, g, b = color_to_argb(itemwatch_config.kicolor2);
        imgui.SetVarValue(variables['var_KeyItemColor2'][1], r / 255, g / 255, b / 255, a / 255);

        -- Save settings..
        save_settings();
    end
    imgui.EndChild();
    imgui.PopStyleColor();
end

----------------------------------------------------------------------------------------------------
-- func: render_itemwatch_session_items
-- desc: Renders the session items editor panel.
----------------------------------------------------------------------------------------------------
function render_session_items_editor()
    local log_grid_columns = { "Dropper", "Item", "Timestamp" };
    local items_grid_columns = { "Item", "Drops", "Kills", "Drop Rate" }
    local mobs_grid_columns = { "Mob", "Kills", "Drops", "Drop Rate" }

    function DrawItemsGrid()
        -- Draw header row
        for i, column in ipairs(items_grid_columns) do
            imgui.TextColored(1.0, 1.0, 0.4, 1.0, column);
            imgui.NextColumn();
        end

        imgui.Separator()

        -- Draw data rows
        for i, rowData in ipairs(itemwatch_session_items['item_grid_data']) do
            for j, cellData in ipairs(rowData) do
                if j == #rowData then
                    cellData = cellData .. '%%'
                end
                imgui.Text(cellData)
                imgui.NextColumn()
            end
            imgui.Separator()
        end
    end

    function DrawMobsGrid()
        -- Draw header row
        for i, column in ipairs(mobs_grid_columns) do
            imgui.TextColored(1.0, 1.0, 0.4, 1.0, column);
            imgui.NextColumn();
        end

        imgui.Separator()

        -- Draw data rows
        for k, v in ipairs(itemwatch_session_items['mob_grid_data']) do
            imgui.Text(tostring(v['mob']))
            imgui.NextColumn()
        end
        imgui.Separator()
    end

    function DrawLogGrid()
        -- Draw header row
        for i, column in ipairs(log_grid_columns) do
            imgui.TextColored(1.0, 1.0, 0.4, 1.0, column);
            imgui.NextColumn();
        end
        imgui.Separator()

        -- Draw data rows
        for i, rowData in ipairs(itemwatch_session_items['log_grid_data']) do
            for j, cellData in ipairs(rowData) do
                if j == 3 then
                    -- skip count
                else
                    if cellData == 'Gil' then
                        cellData = string.format('%s (%s)', cellData, rowData[j + 1])
                        imgui.Text(cellData)
                        imgui.NextColumn()
                    else
                        imgui.Text(cellData)
                        imgui.NextColumn()
                    end
                end
            end
            imgui.Separator()
        end
    end

    if 1 == 1 then
        imgui.BeginChild("Items Data Grid", 0, 200, true);
        imgui.Columns(#items_grid_columns, "ItemDataGridColumns");
        DrawItemsGrid();
        imgui.Columns(1);
        imgui.EndChild();
    else
        imgui.BeginChild("Mobs Data Grid", 0, 200, true);
        imgui.Columns(#mobs_grid_columns, "MobDataGridColumns");
        DrawMobsGrid();
        imgui.Columns(1);
        imgui.EndChild();
    end

    imgui.BeginChild("Log Data Grid", 0, -imgui.GetItemsLineHeightWithSpacing(), true);
    imgui.Columns(#log_grid_columns, "LogDataGridColumns");
    DrawLogGrid();
    imgui.Columns(1);
    imgui.EndChild();

    --imgui.SameLine();
    if (imgui.Button('Clear Data')) then
        --if (imgui.IsMouseDoubleClicked(0)) then
            itemwatch_session_items = {};
            itemwatch_session_items['drops'] = {}
            itemwatch_session_items['mobs']  = {}
        --end
    end

    imgui.SameLine();
    if (imgui.Button('Export')) then
        export_session_data();
    end

    imgui.SameLine();
    if (imgui.Button('Import')) then
          -- Get a list of files in the current directory
        itemwatch_export_files = {}
          for file in io.popen('dir ' .. _addon.path .. '/exports /b'):lines() do
              table.insert(itemwatch_export_files, file)
          end

        imgui.SetVarValue(variables['var_ShowImportWindow'][1],
            not imgui.GetVarValue(variables['var_ShowImportWindow'][1]));
    end

    if (imgui.GetVarValue(variables['var_ShowImportWindow'][1]) == false) then
        return
    else
        -- Define the file path variable
        local file_path = ''

        -- Open the file dialog when the button is clicked
        imgui.OpenPopup('Select File')

        -- Create the file dialog
        imgui.SetNextWindowSize(200, 200, 'ImGuiCond_FirstUseEver')
        if imgui.BeginPopup('Select File', true) then
            -- Display the list of files in a selectable list
            imgui.BeginChild('Files', 0, 0, true)
            for i, file in ipairs(itemwatch_export_files) do
                if imgui.Selectable(file) then
                    file_path = _addon.path .. '/exports/' ..file
                    imgui.SetVarValue(variables['var_ShowImportWindow'][1],
                        not imgui.GetVarValue(variables['var_ShowImportWindow'][1]));
                    imgui.CloseCurrentPopup()
                end
            end
            imgui.EndChild()
            imgui.EndPopup()
        end

        -- Load and merge the itemwatch_session_items data..
        itemwatch_session_items = ashita.settings.load_merged(file_path, itemwatch_session_items);
    end
end

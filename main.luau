--!strict
--
-- REQUIRES
--
local roblox = require("@lune/roblox")
local fs     = require("@lune/fs")
--
-- CONSTANTS
--
local input_file_path = "./main.rbxl"  -- !!!!! YOU WANT TO CHANGE THIS !!!!!
local output_folder   = `./{input_file_path:sub(1, -6)}/scripts`
local included_classnames = {
    ["Script"]        = ".server.luau",
    ["ServerScript"]  = ".server.luau",
    ["LocalScript"]   = ".client.luau",
    ["ModuleScript"]  = ".luau",
}
--
-- LOCAL FUNCTIONS
--
local function Replace_Xml_With_Ascii(str: string): string
    local patterns = {
        { "%<%!%[CDATA%[", " "},
        { "%]%]>"," "},
        { "&Space;", " " },
        { "&Tab;", "\t" },
        { "&NewLine;", "\n" },
        { "&excl;", "!" },
        { "&quot;", "\"" },
        { "&num;", "#" },
        { "&dollar;", "$" },
        { "&percnt;", "%" },
        { "&amp;", "&" },
        { "&apos;", "'" },
        { "&lpar;", "(" },
        { "&rpar;", ")" },
        { "&ast;", "*" },
        { "&plus;", "+" },
        { "&comma;", "," },
        { "&period;", "." },
        { "&sol;", "/" },
        { "&colon;", ":" },
        { "&semi;", ";" },
        { "&lt;", "<" },
        { "&gt;", ">" },
        { "&equals;", "=" },
        { "&quest;", "?" },
        { "&commat;", "@" },
        { "&lsqb;", "[" },
        { "&lbrack;", "[" },
        { "&rsqb;", "]" },
        { "&rbrack;", "]" },
        { "&Hat;", "^" },
        { "&lowbar;", "_" },
        { "&UnderBar;", "_" },
        { "&grave;", "`" },
        { "&lcub;", "{" },
        { "&lbrace;", "{" },
        { "&rcub;", "}" },
        { "&rbrace;", "}" },
        { "&nbsp;", " " },
        { "&NonBreakingSpace;", " " },
        { "&hyphen;", "-" },
        { "&dash;", "-" },
    }
    
    local result = str
    for _, pattern in ipairs(patterns) do
        local entity, replacement = pattern[1], pattern[2]
        result = string.gsub(result, entity, replacement)
    end
    
    return result
end

local function Get_Path_From_Instance(instance: roblox.Instance, root: roblox.DataModel): string
    local path  = output_folder
    local stack = {}
    local parent = instance.Parent
    while parent ~= root and parent ~= nil do
        table.insert(stack, parent.Name or parent.ClassName)
        parent = parent.Parent
    end
    for i = #stack, 1, -1 do
        path = `{path}/{stack[i]}`
    end
    return path
end

local function Extract_Module_From_XML(xml: string): string
    local increment = string.len(`<string name="Source">`)
    local starting  = xml:find(`<string name="Source">`)
    if starting == nil then
        return ""
    end
    local substr = xml:sub(starting + increment)
    local ending = substr:find("</string>")
    if ending == nil then
        return ""
    end
    local output = substr:sub(1, ending - 1)
    output = Replace_Xml_With_Ascii(output)
    return output
end

--
-- MODULE OPERATION
--
local place_contents = fs.readFile(input_file_path)
local place          = roblox.deserializePlace(place_contents)
for key, descendant in place:GetDescendants() do
     --
    -- Skip destroyed instances.
    --
    if not descendant then
        continue
    end
    --
    -- Skip services.
    --
    if descendant.Parent == place then
        continue
    end
    --
    -- Skip unincluded classnames.
    --
    if not included_classnames[descendant.ClassName] then
        continue
    end

    local extension = included_classnames[descendant.ClassName]

    local path                 = Get_Path_From_Instance(descendant, place)
    local file_contents        = roblox.serializeModel({descendant}, true)
    local parsed_file_contents = Extract_Module_From_XML(file_contents)
    pcall(function(...)
        fs.writeDir(path)
    end)
    fs.writeFile(`{path}/{descendant.Name}{extension}`, parsed_file_contents)
end

--[[
    ╔══════════════════════════════════════╗
    ║  MODULE: respawn.lua                 ║
    ║  Защита от респауна                  ║
    ║                                      ║
    ║  Зависимости: config, state          ║
    ║                                      ║
    ║  RAW ссылка → loader.lua →           ║
    ║  loadModule("respawn")               ║
    ╚══════════════════════════════════════╝
]]

local TCP = getgenv().TCP
local Config = TCP.Modules.Config
local State = TCP.Modules.State

local Respawn = {}

function Respawn.Protect()
    if Config.RespawnProtection and State.Humanoid then
        State.Humanoid.Died:Connect(function()
            if Config.RespawnProtection then
                pcall(function()
                    State.Humanoid.Health = State.Humanoid.MaxHealth
                end)
            end
        end)
    end
end

function Respawn.OnCharacterAdded(character)
    State.RefreshCharacter(character)
    Respawn.Protect()
end

function Respawn.Setup()
    Respawn.Protect()
    State.Player.CharacterAdded:Connect(function(c)
        Respawn.OnCharacterAdded(c)
    end)
end

return Respawn

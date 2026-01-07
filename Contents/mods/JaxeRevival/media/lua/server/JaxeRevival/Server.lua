if not JaxeRevival then JaxeRevival = {} end
local onClientCommand = function(module, command, player, args)
  if module ~= JaxeRevival.id then return end

  JaxeRevival.log("onClientCommand", player, command)

  if command == JaxeRevival.Sync.INCAPACITATE then
    JaxeRevival.Sync.sendServer(JaxeRevival.Sync.INCAPACITATE, args)
  elseif command == JaxeRevival.Sync.REVIVE then
    JaxeRevival.Sync.sendServer(JaxeRevival.Sync.REVIVE, args)
  end
end
Events.OnClientCommand.Add(onClientCommand)

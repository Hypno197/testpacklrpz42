if not JaxeRevival then JaxeRevival = {} end
JaxeRevival.id = "JaxeRevival"

local prefixMessage = function(...)
  local args = { ... }
  for i = 1, #args do args[i] = tostring(args[i]) end
  return "[" .. JaxeRevival.id .. "] " .. table.concat(args, " | ")
end

JaxeRevival.log = function(...) if getDebug() or isServer() then print(prefixMessage(...)) end end

JaxeRevival.error = function(...) error(prefixMessage(...)) end

JaxeRevival.test = function(player)
  if not player then player = getPlayer() end

  JaxeRevival.Incapacitation.applyMechanics(player, true)

  JaxeRevival.log("Test", player:getUsername())
end

JaxeRevival.reset = function(player)
  if not player then player = getPlayer() end

  JaxeRevival.Incapacitation.revive(player, true)
  player:getBodyDamage():RestoreToFullHealth()
  JaxeRevival.UI.setActualHealth(player, 100)

  JaxeRevival.Panel.destroy(player)

  JaxeRevival.log("Reset", player:getUsername())
end

JaxeRevival.log("Initialized.")

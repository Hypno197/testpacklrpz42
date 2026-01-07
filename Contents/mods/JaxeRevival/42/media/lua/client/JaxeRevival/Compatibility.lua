JaxeRevival.Compatibility = {}

JaxeRevival.Compatibility.initialize = function()
  if SandboxVars.ZombieLore.ZombiesDragDown and not SandboxVars.JaxeRevival.DragDownAllowed then
    JaxeRevival.log("Setting 'ZombieLore.ZombiesDragDown' to 'false' for compatibility.")
    SandboxVars.ZombieLore.ZombiesDragDown = false

    getSandboxOptions():getOptionByName("ZombieLore.ZombiesDragDown"):setValue(false)
    getSandboxOptions():toLua()
  end

  JaxeRevival.Compatibility.banditsActive = getActivatedMods():contains("Bandits")
end

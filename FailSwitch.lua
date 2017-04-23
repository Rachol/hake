local failSwitch= {}

failSwitch.optionEnable = Menu.AddOption({ "Utility","Fail Switch"}, "Enable", "Stop ultimate if no enemy in radius")
failSwitch.optionKey = Menu.AddKeyOption({ "Utility","Fail Switch"}, "Force Cast Key",Enum.ButtonCode.KEY_P)

failSwitch.ultiRadius = {enigma_black_hole = 420, magnataur_reverse_polarity = 410, faceless_void_chronosphere = 425}

failSwitch.castPosition = Vector(0,0,0)
failSwitch.castAbilityName = ""

function failSwitch.OnUpdate()
	if not Menu.IsEnabled(failSwitch.optionEnable) then return true end
	if not Menu.IsKeyDown(failSwitch.optionKey) then return end

	local myHero = Heroes.GetLocal()
	
	local mousePos = Input.GetWorldCursorPos()

	local myMana = NPC.GetMana(myHero)
	local ulti = NPC.GetAbilityByIndex(myHero, 3)
	if ulti ~= nil and Ability.IsCastable(ulti, myMana) then
		local name =Ability.GetName(ulti)
		Log.Write(name)
		if name == "enigma_black_hole" or name == "faceless_void_chronosphere" then
        	Ability.CastPosition(ulti, mousePos)
        elseif name == "magnataur_reverse_polarity" then
        	Ability.CastNoTarget(ulti)
        end
    end
end


function failSwitch.OnPrepareUnitOrders(orders)
	if not Menu.IsEnabled(failSwitch.optionEnable) then return true end
    if not orders.ability then return true end
    if not (orders.order == Enum.UnitOrder.DOTA_UNIT_ORDER_CAST_POSITION or orders.order == Enum.UnitOrder.DOTA_UNIT_ORDER_CAST_NO_TARGET) then return true end
    local abilityName = Ability.GetName(orders.ability)
    if not ( abilityName == "enigma_black_hole" or abilityName == "magnataur_reverse_polarity" or abilityName == "faceless_void_chronosphere") then return true end
	local myHero = Heroes.GetLocal()
	failSwitch.castPosition = Input.GetWorldCursorPos()

    if abilityName == "magnataur_reverse_polarity" then
    	failSwitch.castPosition =  NPC.GetAbsOrigin(myHero)
    end 
	failSwitch.castAbilityName = abilityName
	
	if failSwitch.CountEnemyInRange(failSwitch.castPosition, failSwitch.ultiRadius[failSwitch.castAbilityName]) > 0 then return true end
	
	return false
end

function failSwitch.CountEnemyInRange(position, range)
	local entities = Heroes.GetAll()
	local me = Heroes.GetLocal()
	local inRangeCount = 0
	
	
	for index, ent in pairs(entities) do
		local enemyhero = Heroes.Get(index)
		local enemyspeed = NPC.GetMoveSpeed(enemyhero)
		-- Assume that cast time is about 1/3s for each ulti, use enemy speed to calculate if enemy can escapte during cast animation
		if not Entity.IsSameTeam(me, enemyhero) and not NPC.IsIllusion(enemyhero) and NPC.IsPositionInRange(enemyhero, position, range - enemyspeed/3, 0) then
			inRangeCount = inRangeCount + 1
		end
	end
	return inRangeCount
end

function failSwitch.OnUnitAnimation(animation)
	if animation.unit==Heroes.GetLocal() and animation.activity==Enum.GameActivity.ACT_DOTA_CAST_ABILITY_4 then
		if failSwitch.CountEnemyInRange(failSwitch.castPosition, failSwitch.ultiRadius[failSwitch.castAbilityName]) == 0 then
			local myHero = Heroes.GetLocal()
			local myPlayer = Players.GetLocal()
			Player.PrepareUnitOrders(myPlayer, Enum.UnitOrder.DOTA_UNIT_ORDER_STOP, nil, Entity.GetAbsOrigin(myHero), nil, Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY, myHero, false, true)
			failSwitch.castPosition = Vector(0,0,0)
			failSwitch.castAbilityName = ""
		end
	end
end

return failSwitch
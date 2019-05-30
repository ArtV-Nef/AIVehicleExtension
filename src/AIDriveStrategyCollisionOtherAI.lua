--
-- AIDriveStrategyCollisionOtherAI
--  drive strategy to stop vehicle on collision (aiTrafficCollision trigger)
--
-- Copyright (C) GIANTS Software GmbH, Confidential, All Rights Reserved.

AIDriveStrategyCollisionOtherAI = {}
local AIDriveStrategyCollisionOtherAI_mt = Class(AIDriveStrategyCollisionOtherAI, AIDriveStrategy)

function AIDriveStrategyCollisionOtherAI:new(customMt)
	if customMt == nil then
		customMt = AIDriveStrategyCollisionOtherAI_mt
	end

	local self = AIDriveStrategy:new(customMt)
	
	self.collisionTime = 0
	
	return self
end

function AIDriveStrategyCollisionOtherAI:delete()
	AIDriveStrategyCollisionOtherAI:superClass().delete(self)
end

function AIDriveStrategyCollisionOtherAI:setAIVehicle(vehicle)
	self.mogliText = "AIDriveStrategyCollisionOtherAI"
	AIDriveStrategyCollisionOtherAI:superClass().setAIVehicle(self, vehicle)
end

function AIDriveStrategyCollisionOtherAI:addDebugText( s )
--if self.vehicle ~= nil and type( self.vehicle.aiveAddDebugText ) == "function" then
--	self.vehicle:aiveAddDebugText( s ) 
--end
	if AIVEGlobals.devFeatures > 0 then 
		print( s ) 
	end 
end

function AIDriveStrategyCollisionOtherAI:getDriveData(dt, vX,vY,vZ)
	-- we do not check collisions at the back, at least currently
	self.vehicle.aiveMaxCollisionSpeed = nil
	self.vehicle.aiveCollisionDistance = nil
	
	if self.vehicle.movingDirection < 0 and self.vehicle:getLastSpeed(true) > 2 then
		return nil, nil, nil, nil, nil
	end
	
	local triggerId 
	if     self.vehicle.acParameters == nil 
			or self.vehicle.acParameters.upNDown 
			or self.vehicle.acCollidingVehicles == nil then
	elseif self.vehicle.acParameters.rightAreaActive then
		triggerId = self.vehicle.acOtherCombineCollisionTriggerR
	else
		triggerId = self.vehicle.acOtherCombineCollisionTriggerL
	end

	if triggerId ~= nil and self.vehicle.acCollidingVehicles[triggerId] ~= nil then
		for otherAI,bool in pairs(self.vehicle.acCollidingVehicles[triggerId]) do
		--if bool and otherAI.spec_aiVehicle.isActive then
			if bool and otherAI.spec_aiVehicle.isActive and ( otherAI.ad == nil or otherAI.ad.isActive == false ) then 
				local blocked   = true
				
				if      g_currentMission.time < self.collisionTime + 2000 then
				
					local tX,_,tZ = localToWorld(self.vehicle.acRefNode, 0,0,1)
				--self:addDebugText("AIDriveStrategyCollisionOtherAI :: STOP due to collision ")
					return tX, tZ, true, 0, math.huge
					
				elseif  otherAI.acRefNode ~= nil
						and otherAI.aiveIsStarted 
						and otherAI.acLastWantedSpeed ~= nil
						and otherAI.acTurnStage       <= 0 
						and otherAI.acLastWantedSpeed  > 6 then
					local angle   = AutoSteeringEngine.getRelativeYRotation( otherAI.acRefNode, self.vehicle.acRefNode )
					if      math.abs( angle ) < 0.1667 * math.pi
							and otherAI.spec_motorized ~= nil
							and otherAI.spec_motorized.motor ~= nil
							and otherAI.spec_motorized.motor.speedLimit ~= nil then 
						local s = otherAI.spec_motorized.motor.speedLimit * math.cos( angle )
						if     self.vehicle.aiveMaxCollisionSpeed == nil
								or self.vehicle.aiveMaxCollisionSpeed  > s then
							self.vehicle.aiveMaxCollisionSpeed = s
						end 
					end 
					
					local wx1, _, wz1 = getWorldTranslation( otherAI.acRefNode )
					local wx2, _, wz2 = getWorldTranslation( self.vehicle.acRefNode )
					local d = AIVEUtils.vector2Length( wx1-wx2, wz1-wz2 )
					if     self.vehicle.aiveCollisionDistance == nil
							or self.vehicle.aiveCollisionDistance  > d then
						self.vehicle.aiveCollisionDistance = d
					end
					if d > 10 then 
						blocked = false 
					end 
				end
				
				if blocked then
					local tX,_,tZ = localToWorld(self.vehicle.acRefNode, 0,0,1)
				--self:addDebugText("AIDriveStrategyCollisionOtherAI : STOP due to collision ")

					self.collisionTime = g_currentMission.time 

					if not self.stopNotificationShown then
						self.stopNotificationShown = true
						g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_CRITICAL, string.format(g_i18n:getText(AIVehicle.REASON_TEXT_MAPPING[AIVehicle.STOP_REASON_BLOCKED_BY_OBJECT]), self.vehicle:getCurrentHelper().name))
						self.vehicle:setBeaconLightsVisibility(true, false)
					end

					return tX, tZ, true, 0, math.huge
				end
			end
		end
	end

	if self.stopNotificationShown then
		self.stopNotificationShown = false
		self.vehicle:setBeaconLightsVisibility(false, false)
	end

--self:addDebugText("AIDriveStrategyCollisionOtherAI :: no collision ")
	return nil, nil, nil, nil, nil
end

function AIDriveStrategyCollisionOtherAI:updateDriving(dt)
end



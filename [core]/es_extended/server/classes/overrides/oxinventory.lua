local Inventory

if Config.OxInventory then
	AddEventHandler('ox_inventory:loadInventory', function(module)
		print("收到ox_inventory:loadInventory")
		Inventory = module
	end)
end

Core.PlayerFunctionOverrides.OxInventory = {
	getInventory = function(self)
		return function(minimal)
			if minimal then
				local minimalInventory = {}

				for k, v in pairs(self.inventory) do
					if v.count and v.count > 0 then
						local metadata = v.metadata

						if v.metadata and next(v.metadata) == nil then
							metadata = nil
						end

						minimalInventory[#minimalInventory + 1] = {
							name = v.name,
							count = v.count,
							slot = k,
							metadata = metadata
						}
					end
				end

				return minimalInventory
			end

			return self.inventory
		end
	end,

	getLoadout = function()
		return function()
			return {}
		end
	end,

	setAccountMoney = function(self)
		return function(accountName, money, reason)
					print("xplog>>","oxinventory setAccountMoney",accountName,money,reason,"source",self.source)

			reason = reason or 'unknown'
			if money >= 0 then
				local account = self.getAccount(accountName)

				if account then
					money = account.round and ESX.Math.Round(money) or money
					self.accounts[account.index].money = money

					self.triggerEvent('esx:setAccountMoney', account)
					TriggerEvent('esx:setAccountMoney', self.source, accountName, money, reason)
					if Inventory.accounts[accountName] then
						Inventory.SetItem(self.source, accountName, money)
					end
				end
			end
		end
	end,

	addAccountMoney = function(self)
		return function(accountName, money, reason,bankcallback)
			print("xplog>>","oxinventory addAccountMoney",accountName,money,reason,"bankcallback",bankcallback,"source",self.source)
			local account = self.getAccount(accountName)
			if(money < 0 or account == nil) then return end
			if(bankcallback ~= nil) then
				self.accounts[account.index].money = self.accounts[account.index].money + money
				if Inventory.accounts[accountName] then
					Inventory.AddItem(self.source, accountName, money)
				end	
				self.triggerEvent('esx:setAccountMoney', account)
			return end
			reason = reason or 'unknown'
				
			
				money = account.round and ESX.Math.Round(money) or money
				
				
				if(accountName == "bank") then
					local dataType = {deposit = money,label = reason}
					TriggerEvent("esx_banking:doingType",self.source,dataType)
				elseif (accountName == "money") then
					self.accounts[account.index].money = self.accounts[account.index].money + money
					self.triggerEvent('esx:setAccountMoney', account)
					if Inventory.accounts[accountName] then
					Inventory.AddItem(self.source, accountName, money)
					end
				end
				--TriggerEvent('esx:addAccountMoney', self.source, accountName, money, reason)
				
			
			
		end
	end,

	removeAccountMoney = function(self)
		return function(accountName, money, reason,bankcallback)
			reason = reason or 'unknown'
			print("xplog>>","oxinventory removeAccountMoney",accountName,money,reason,bankcallback)
			local account = self.getAccount(accountName)
			if(money < 0 or account == nil) then return end
			if(bankcallback ~= nil) then
				self.accounts[account.index].money = self.accounts[account.index].money - money
					if Inventory.accounts[accountName] then
					Inventory.RemoveItem(self.source, accountName, money)
					end
				self.triggerEvent('esx:setAccountMoney', account)
			return end
			reason = reason or 'unknown'
				
			
				money = account.round and ESX.Math.Round(money) or money
				
				
				if(accountName == "bank") then
					local dataType = {withdraw = money,label = reason}
					TriggerEvent("esx_banking:doingType",self.source,dataType)
				elseif (accountName == "money") then
					local sourcemoney = self.accounts[account.index].money
					self.accounts[account.index].money = self.accounts[account.index].money - money
					print("xplog>>","oxinventory finalmoney",self.accounts[account.index].money,money,sourcemoney,ESX.DumpTable(account))
					self.triggerEvent('esx:setAccountMoney', account)
					if Inventory.accounts[accountName] then
					Inventory.RemoveItem(self.source, accountName, money)
					end
				end
				--TriggerEvent('esx:addAccountMoney', self.source, accountName, money, reason)
				
		end
	end,

	getInventoryItem = function(self)
		return function(name, metadata)
			return Inventory.GetItem(self.source, name, metadata)
		end
	end,

	addInventoryItem = function(self)
		return function(name, count, metadata, slot)
			return Inventory.AddItem(self.source, name, count or 1, metadata, slot)
		end
	end,

	removeInventoryItem = function(self)
		return function(name, count, metadata, slot)
			return Inventory.RemoveItem(self.source, name, count or 1, metadata, slot)
		end
	end,

	setInventoryItem = function(self)
		return function(name, count, metadata)
			return Inventory.SetItem(self.source, name, count, metadata)
		end
	end,

	canCarryItem = function(self)
		return function(name, count, metadata)
			return Inventory.CanCarryItem(self.source, name, count, metadata)
		end
	end,

	canSwapItem = function(self)
		return function(firstItem, firstItemCount, testItem, testItemCount)
			return Inventory.CanSwapItem(self.source, firstItem, firstItemCount, testItem, testItemCount)
		end
	end,

	setMaxWeight = function(self)
		return function(newWeight)
			self.maxWeight = newWeight
			self.triggerEvent('esx:setMaxWeight', self.maxWeight)
			return Inventory.Set(self.source, 'maxWeight', newWeight)
		end
	end,

	addWeapon = function()
		print("addWeapon is null")
		return function() end
	end,

	addWeaponComponent = function()
		return function() end
	end,

	addWeaponAmmo = function()
		return function() end
	end,

	updateWeaponAmmo = function()
		return function() end
	end,

	setWeaponTint = function()
		return function() end
	end,

	getWeaponTint = function()
		return function() end
	end,

	removeWeapon = function()
		return function() end
	end,

	removeWeaponComponent = function()
		return function() end
	end,

	removeWeaponAmmo = function()
		return function() end
	end,

	hasWeaponComponent = function()
		return function()
			return false
		end
	end,

	hasWeapon = function()
		return function()
			return false
		end
	end,

	hasItem = function(self)
		return function(name, metadata)
			return Inventory.GetItem(self.source, name, metadata)
		end
	end,

	getWeapon = function()
		return function() end
	end,

	syncInventory = function(self)
		return function(weight, maxWeight, items, money)
			self.weight, self.maxWeight = weight, maxWeight
			self.inventory = items
			print("syncInventory-money",ESX.DumpTable(money))
			if money then
				for accountName, amount in pairs(money) do
					local account = self.getAccount(accountName)

					if account and ESX.Math.Round(account.money) ~= amount then
						print("syncInventory",ESX.DumpTable(account))
						account.money = amount
						self.triggerEvent('esx:setAccountMoney', account)
						TriggerEvent('esx:setAccountMoney', self.source, accountName, amount, 'Sync account with item')
					end
				end
			end
		end
	end
}


Billing = Core.class()

local NAME_GOOGLE = "com.google.play"
local NAME_SLIDEME = "SlideME"
local NAME_APPLAND = "Appland"
local NAME_YANDEX = "com.yandex.store"

local android = application:getDeviceInfo() == "Android"
local iOS = application:getDeviceInfo() == "iOS"

local google_key = 
		"MIIBIjXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
		
local slideme_key = 
		"MIIBIjXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
		
local appland_key = 
		"MIGfMXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
local iab

local products
local prices = {}

-- Return true if the store is in the list
local function lookup(list, store)
	if (list and store) then
		for i=1, #list do
			if (store == list[i]) then
				return true
			end
		end
	end
	
	return false
end

-- Constructor
function Billing:init()
	
	--dataSaver.saveValue("coins", nil) -- Reset coins
	
	self.coins = dataSaver.loadValue("coins") or 0		
	print("self.coins", coins)
	
	if (android or iOS) then
		require "iab"
		local iaps = IAB.detectStores()
			
		--if (iaps[1] == "google") then
		--[[
		if (lookup(iaps, "google")) then
			iab = IAB.new("google")
			iab:setUp(google_key)
			
			products = { 
				   dots_5000 = "dots_5000",
				   dots_15000 = "dots_15000", 
				   dots_45000 = "dots_45000",
				   dots_300000 = "dots_300000",
				   }
			iab:setProducts(products)
						
		]]--
		if (lookup(iaps, "open")) then
			print("setup open stores")
			iab = IAB.new("open")
			--iab:setUp(slideme_key)
			--iab:setUp("SlideME", slideme_key,
			iab:setUp(NAME_GOOGLE, google_key,
					  NAME_SLIDEME, slideme_key,
					  NAME_APPLAND, appland_key
					  )
			
			products = { 
				   dots_5000 = "dots_5000",
				   dots_15000 = "dots_15000", 
				   dots_45000 = "dots_45000",
				   dots_300000 = "dots_300000",
				   }
			iab:setProducts(products)
		
		elseif iaps[1] == "ios" then
			iab = IAB.new(iaps[1])
			--using ios product identifiers
			local prefix = "es.jdbc.squaredots."
			products = { 
				   dots_5000 = prefix.."dots_5000",
				   dots_15000 = prefix.."dots_15000", 
				   dots_45000 = prefix.."dots_45000",
				   dots_300000 = prefix.."dots_300000",
				   }
			iab:setProducts(products)
		end
		
		-- If we have a supported store
		if iab then
			iab:isAvailable()
			iab:addEventListener(Event.AVAILABLE, self.onAvailable, self)
			--self:onAvailable()
			
			--set which products are consumables
			iab:setConsumables({"dots_5000", 
								"dots_15000", 
								"dots_45000", 
								"dots_300000"})
			
			-- When purchase is completed
			iab:addEventListener(Event.PURCHASE_COMPLETE, self.onPurchaseComplete, self)
			
			--if there was a purchase error
			iab:addEventListener(Event.PURCHASE_ERROR, 
								function(e)
									AlertDialog.new(getString("purchase_canceled"), e.error, "Ok"):show()
								end)
			
		end
	else
		prices = {
					dots_5000 = "0,61 €",
					dots_15000 = "1,21 €",
					dots_45000 = "1,82 €",
					dots_300000 = "2,42 €",
					}
	end
end

-- Submit a requestPurchase of product_id
function Billing:purchase(product_id)
	
	print("productId", product_id)
	
	if (product_id) then
		print("request a purchase: ", product_id)
				
		if iab then
			iab:purchase(product_id) --purchase something			
		else
			self:onPurchaseComplete({productId = product_id})
		end
	end
	
end

-- When iab is available
function Billing:onAvailable(event)
	
	print("Billing:onAvailable")
	
	iab:requestProducts()
	iab:addEventListener(Event.PRODUCTS_COMPLETE, self.onRequestProductsOK, self)
	iab:addEventListener(Event.PRODUCTS_ERROR, self.onRequestProductsError, self)
end

-- When product are requested ok
function Billing:onRequestProductsOK(event)
	local products = event.products
	
	print("#products", #products)
	
	if (products) then
		for a = 1, #products do
			local product = products[a]
			local productId = product.productId
			local price = product.price
			prices[productId] = price
			
			print(productId)
			print(product.title, price)
		end
	end
	
	-- Sort prices table
	table.sort(prices, function(a,b) return a > b end)
	
	-- Show products in the scene if it is necessary
	local scene = sceneManager:getCurrentScene()
	if (scene and scene.show_products) then
		scene:show_products()
	end
end

-- When product are requested with error
function Billing:onRequestProductsError(event)
		
	AlertDialog.new("Error on requesting products", event.error, "Ok"):show()
end

-- When purchase is done
function Billing:onPurchaseComplete(event)
	print("Purchase completed", event.productId, event.receiptId)
	
	local productId = event.productId
	if (productId) then
		
		-- Add some coins
		local coins = tonumber(string.sub(productId, 6))
		self.coins = self.coins + coins
		dataSaver.saveValue("coins", self.coins) 
		
		-- Update coins in screen
		local scene = sceneManager:getCurrentScene()
		if (scene and scene.show_coins) then
			scene:show_coins()
		end
		
		AlertDialog.new("Purchase completed", coins.." coins added", "Ok"):show()
	else
		print("productId is nil")
	end
end

-- Returns current price for given productId
function Billing:getPrice(key)

	if (android or iOS) then
		local product_id = prices[key]
		return prices[product_id]
	else
		return prices[key]
	end
end

-- Get the list of prices
function Billing:getProductPrices()
	return prices
end
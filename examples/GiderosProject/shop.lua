
ShopScene = Core.class(Sprite)

local android = application:getDeviceInfo() == "Android"
local iOS = application:getDeviceInfo() == "iOS"

local width = application:getContentWidth()
local prefix = "dots_"

local function getKeysSortedByValue(tbl, sortFunction)
  local keys = {}
  for key in pairs(tbl) do
    table.insert(keys, key)
  end

  table.sort(keys, function(a, b)
    return sortFunction(tbl[a], tbl[b])
  end)

  return keys
end


function ShopScene.setup()

	ShopScene.texture_cart = Texture.new("gfx/shopping_cart_green.png", true)
	
	ShopScene.font_title = TTFont.new("fonts/new_academy.ttf", 40)
	ShopScene.font_dots = TTFont.new("fonts/futur1.ttf", 42)
	ShopScene.font_price = TTFont.new("fonts/DroidSansFallback.ttf", 45)
	ShopScene.font_button = TTFont.new("fonts/futur1.ttf", 32)
end

-- Constructor
function ShopScene:init()
		
	--Event listeners
	self:addEventListener("enterEnd", self.enterEnd, self)
end

-- When scene is loaded
function ShopScene:enterEnd()
		
	local billing = ShopScene.billing
	if (billing) then
		self:show_products()
	else
		ShopScene.billing = Billing.new() -- Created just once
		
		-- Show products in Gideros Player
		if (not android) and (not iOS) then
			self:show_products()
		end
	end
	
	self:draw_coins()
	self:draw_ok()
	
	self:addEventListener(Event.KEY_DOWN, self.onKeyDown, self)
end

-- Show In-app product list
function ShopScene:show_products()
	
	print("show_products")
	
	local billing = ShopScene.billing
	if (billing) then
		
		local posY = {106, 196, 286, 376}
		local prices = billing:getProductPrices()
				
		if (prices) then -- There are products
			
			local sortedKeys = getKeysSortedByValue(prices, function(a, b) return a < b end)
			
			local a = 1
			--for k,v in pairs(prices) do	
			for _, value in ipairs(sortedKeys) do
				local desc = string.gsub(value, "dots_", "")
				self:createItem(desc, posY[a], prices[value])
				a = a + 1
			end
		else
			-- Show no products available
			self:draw_noproducts()
		end
	end
end

-- Draw title of game shop
function ShopScene:draw_coins()
	
	local billing = ShopScene.billing
	
	local text = TextField.new(ShopScene.font_title, "Coins: "..billing.coins)
	text:setTextColor(0x1C86EE)
	self.title = text
	
	text:setPosition(20,30)
	self:addChild(text)
end

-- Show no products message
function ShopScene:draw_noproducts()
	
	local rect_width = width - 10
	local posY = 106
	
	local mesh = Mesh.new() 
	mesh:setVertices(1, 10, posY - 5, 2, rect_width, posY - 5, 3, rect_width, posY + 80, 4, 10,  posY + 80) 
	mesh:setIndexArray(1, 2, 3, 1, 3, 4) 
	local color = 0xff8000
	mesh:setColorArray(color, 0.7, color, 0.7, color, 0.7, color, 0.7) 
	self:addChild(mesh)
	
	local text = TextField.new(ShopScene.font_dots, "No products")
	text:setTextColor(0xffff00)
	--text:setShadow(2,1, 0x000000)
	text:setPosition(24, 24)
	self:addChild(text)
	
	local posX = (width - text:getWidth()) * 0.5
	text:setPosition(posX, posY + 24)
	
end

-- Create in-app purchase virtual item (dots)
function ShopScene:createItem(label, posY, price)
			
	local rect_width = width - 10
		
	local mesh = Mesh.new() 
	mesh:setVertices(1, 10, posY - 5, 2, rect_width, posY - 5, 3, rect_width, posY + 80, 4, 10,  posY + 80) 
	mesh:setIndexArray(1, 2, 3, 1, 3, 4) 
	local color = 0x004C99
	mesh:setColorArray(color, 0.7, color, 0.7, color, 0.7, color, 0.7) 
	self:addChild(mesh)
		
	local sprite = Sprite.new()
	
	local text = TextField.new(ShopScene.font_dots, label)
	text:setTextColor(0xffff00)
	text:setShadow(2, 2, 0x000000)
	text:setPosition(24, 24)
	sprite:addChild(text)
			
	local cart = Bitmap.new(ShopScene.texture_cart)
	cart:setScale(0.64, 0.64)
	cart:setPosition(360, 0)
	sprite:addChild(cart)
		
	sprite:addEventListener(Event.MOUSE_UP, 
							function(event)
								if (sprite:hitTestPoint(event.x, event.y)) then
									event:stopPropagation()
									
									ShopScene.billing:purchase(prefix..label)
								end
							end)
	
	local text_price = TextField.new(ShopScene.font_price, price)
	text_price:setTextColor(0x99FF99)
	text_price:setShadow(2,1, 0x000000)
	text_price:setPosition(270, 20)
	
	sprite:addChild(text_price)
	self:addChild(sprite)
	sprite:setPosition(10, posY)
end

-- Draw OK button
function ShopScene:draw_ok()
	local group = Sprite.new()
	
	local border = Shape.new()
	border:setFillStyle(Shape.SOLID, 0x5F9F9F)
	--border:setLineStyle(2, Colors.BLACK)
	border:drawRoundRectangle(200, 80, 0)
	group:addChild(border)

	local text = TextField.new(ShopScene.font_button, "OK")
	text:setTextColor(Colors.WHITE)
	--text:setShadow(3, 1, 0x000000)
	text:setPosition((200 - text:getWidth()) * 0.5, 30)
	group:addChild(text)
	
	group:setPosition(150, 590)
	self:addChild(group)
	
	group:addEventListener(Event.MOUSE_UP,
							function(event)
								if (group:hitTestPoint(event.x, event.y)) then
									event:stopPropagation()
																		
									-- Back to previous scene
								end
							end)
end

function ShopScene:show_coins()
	local billing = ShopScene.billing
	if (billing) then
		self.title:setText("Coins: "..billing.coins)
	end
end

-- Go back to menu when back key is pressed
function ShopScene:onKeyDown(event)
	local keyCode = event.keyCode
	if (keyCode == KeyCode.BACK) then
		event:stopPropagation()
		application:exit()
	end
end
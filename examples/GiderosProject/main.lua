
application:setKeepAwake(true)
application:setOrientation(Application.PORTRAIT)

local ios= application:getDeviceInfo() == "iOS"
local android = application:getDeviceInfo() == "Android"

local width = application:getContentWidth()

local function draw_loading()
	loading = Sprite.new()
		
	stage:addChild(loading)
end

-- Loading textures and sounds when game is starting
local function preloader()
	stage:removeEventListener(Event.ENTER_FRAME, preloader)
		
	ShopScene.setup()
	
	scenes = {"shop"}
	sceneManager = SceneManager.new({
		["shop"] = ShopScene
		})
	stage:addChild(sceneManager)
	
	-- Remove loading scene
	stage:removeChild(loading)
	loading = nil
	sceneManager:changeScene(scenes[1])
end

draw_loading()
stage:addEventListener(Event.ENTER_FRAME, preloader)

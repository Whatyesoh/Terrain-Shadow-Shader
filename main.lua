if arg[2] == "debug" then
    require("lldebugger").start()
  end
  
io.stdout:setvbuf("no")

function love.load()
    --Window settings
    love.window.setVSync(1)
    love.window.setFullscreen(true)


    --Terrain generation parameters
    pixelSize = 3
    mapWidth = math.floor(love.graphics.getWidth()/pixelSize)
    mapHeight = math.floor(love.graphics.getHeight()/pixelSize)
    detailDepth = 10
    detailRoughness = 1
    waterLevel = .2
    sunHeight = 1
    islandSize = 7
    jaggedness = 1.4
    brushSize = 20
    brushStrength = .25
    colorVariation = 3000


    heightMapCanvas = love.graphics.newCanvas(mapWidth*pixelSize,mapHeight*pixelSize)
    normalMapCanvas = love.graphics.newCanvas(mapWidth*pixelSize,mapHeight*pixelSize)
    colorMapCanvas = love.graphics.newCanvas(mapWidth*pixelSize,mapHeight*pixelSize)

    --Initialize useful variables
    maxDistance = (mapWidth/2 * mapWidth/2) + (mapHeight/2 * mapHeight/2)
    steps = 3*math.sqrt(maxDistance)/2

    heightMap = {}
    colorMap = {}

    --Setup love.graphics to draw the color map as an image


    --Generate the height and color maps and draw the color map
    for i = 1,mapHeight do
        table.insert(heightMap,{})
        table.insert(colorMap,{})
        for j = 1,mapWidth do
            generateMaps(j,i)
        end
    end

    regenerate(1,mapWidth,1,mapHeight)

    --Shader code which uses raycasting to determine if a pixel is shaded
    shadowShader = love.graphics.newShader("shadowShader.frag")

    --Send data to the shader
    shadowShader:send("heightMap",heightMapCanvas)
    shadowShader:send("normalMap",normalMapCanvas)
    shadowShader:send("steps",steps)
    shadowShader:send("pixelSize",pixelSize)
    --shadowShader:send("waterLevel",waterLevel)
end

function love.mousepressed(mx,my,button,istouch,presses)

end

function regenerate(minX,maxX,minY,maxY)
    --Setup and draw the different maps

    for i = minY,maxY do
        for j = minX,maxX do
            --Height map
            love.graphics.setCanvas(heightMapCanvas)
            h = heightMap[i][j] * 4
            love.graphics.setColor(math.max(0,math.min(h-3,1)),math.max(0,math.min(h-2,1)),math.max(0,math.min(h-1,1)),math.max(0,math.min(h,1)))
            love.graphics.rectangle("fill",pixelSize*j-pixelSize,pixelSize*i-pixelSize,pixelSize,pixelSize)

            --Color map
            love.graphics.setCanvas(colorMapCanvas)
            love.graphics.setColor(colorMap[i][j][1],colorMap[i][j][2],colorMap[i][j][3],1)
            love.graphics.rectangle("fill",pixelSize*j-pixelSize,pixelSize*i-pixelSize,pixelSize,pixelSize)

            --Normal map
            love.graphics.setCanvas(normalMapCanvas)
            scale = 50
            left = scale * heightMap[i][math.max(j-1,1)]
            right = scale * heightMap[i][math.min(j+1,mapWidth)]
            up = scale * heightMap[math.max(i-1,1)][j]
            down = scale * heightMap[math.min(i+1,mapHeight)][j]
            normalLength = math.sqrt((left-right)^2 + (up-down)^2+1)
            love.graphics.setColor(((left-right)/(normalLength)),((up-down)/(normalLength)),(1/normalLength),1)
            love.graphics.rectangle("fill",pixelSize*j-pixelSize,pixelSize*i-pixelSize,pixelSize,pixelSize)
        end
    end

    love.graphics.setCanvas()
    love.graphics.setColor(1,1,1,1)
end

--generate terrain
function generateMaps(x,y)
    dy = y-mapHeight/2
    dx = x-mapWidth/2
    distanceToCenter = (dx*dx) + (dy*dy)
    elevation = 0
    weight = 1
    totalWeight = 0
    for k = .01,.01 * detailRoughness*detailDepth,.01 * detailRoughness do
        elevation = elevation + weight * love.math.noise(k*y,k*x)
        totalWeight = totalWeight + weight
        weight = weight / 2
    end
    elevation = math.min(elevation / totalWeight,1)
    elevation = math.pow(elevation,jaggedness)
    elevation = elevation * (1 - (islandSize * distanceToCenter / maxDistance))
    --elevation = math.pow(elevation,distanceToCenter/maxDistance)
    unmodifiedElevation = math.max(elevation,waterLevel)
    table.insert(heightMap[y],unmodifiedElevation)
    if elevation >= .3 - 200/colorVariation then
        variation = math.random(-100,100) / colorVariation
        elevation = elevation + variation
    end
    elevation = math.max(elevation,0)

    waterDarkness = math.max(math.pow(((elevation/waterLevel)+1)/2,2),.6)

    if elevation <= waterLevel then
        table.insert(colorMap[y],{waterDarkness * 16/255,waterDarkness * 120/255,waterDarkness * 160/255,1})
    elseif elevation < .3 then
        table.insert(colorMap[y],{223/255,186/255,152/255,1})
    elseif elevation < .4 then
        table.insert(colorMap[y],{93/255,121/255,26/255,1})
    elseif elevation < .5 then
        table.insert(colorMap[y],{70/255,110/255,17/255,1})
    elseif elevation < .6 then
        table.insert(colorMap[y],{60/255,100/255,10/255,1})
    elseif elevation < .7 then
        table.insert(colorMap[y],{140/255,140/255,140/255,1})
    elseif elevation < .8 then
        table.insert(colorMap[y],{170/255,170/255,170/255,1})
    else
        table.insert(colorMap[y],{250/255,250/255,250/255,1})
    end
end

function love.update(dt)
    --Send mouse location as the sun location to the shader
    shadowShader:send("sun",{love.mouse.getX()/(mapWidth*pixelSize),love.mouse.getY()/(mapHeight*pixelSize),1 + sunHeight})

end

function love.draw()
    --Draw the output of the shader on the color map
    love.graphics.setShader(shadowShader)
    love.graphics.draw(colorMapCanvas)
    love.graphics.setShader()
end
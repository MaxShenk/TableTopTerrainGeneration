--[[ Lua code. See documentation: https://api.tabletopsimulator.com/ --]]

checker_GUID = '0857ed'

grass_one_hex_GUID = 'cc3db4'
water_one_hex_GUID = '479c20'
stone_one_hex_GUID = '3517cc'
sand_one_hex_GUID = 'ec5974'

button_parameters = {}
button_parameters.click_function = 'buttonClicked'
button_parameters.function_owner = nil
button_parameters.label = 'Press Me'
button_parameters.position = {0,0.8,0}
button_parameters.rotation = {0,0,0}
button_parameters.width = 500
button_parameters.height = 500
button_parameters.font_size = 100

topleft = Vector(-42,5,24.25)

printing = false


max_z = 29
count_z = 0
z_multiplier = -1.75

max_x = 56
count_x = 0
x_multiplier = 1.5

max_height = 20
height = 1 

water_level = -5
perlin_multiplier = .05
perlin_constant = 1234
perlin_smoothing = 0.08

current_layer = {}
--[[ The onLoad event is called after the game save finishes loading. --]]
function onLoad()
    --[[ print('onLoad!') --]]

    checker = getObjectFromGUID(checker_GUID)
    grass_one_hex = getObjectFromGUID(grass_one_hex_GUID)
    water_one_hex = getObjectFromGUID(water_one_hex_GUID)
    stone_one_hex = getObjectFromGUID(stone_one_hex_GUID)
    sand_one_hex = getObjectFromGUID(sand_one_hex_GUID)
    checker.createButton(button_parameters)
    math.randomseed(42)
    print('Loaded')
    perlin:load()

end


function generateLayer(current_height)
    layer = {}
    layer_count = 0
    count_x = 0
    count_z = 0
    for x = 0, max_x do
        --Instantiate a new column
        layer[x] = {}
        for z = 0, max_z do
            --Instantiate a new piece at the current location on the layer
            layer[x][z] = {}
            --Find the x,z location of where the tile should go on the grid
            layer[x][z].pos = topleft + Vector(x_multiplier * x,0,z_multiplier*z + ternary( x % 2 == 0,0 ,-0.8))
            --Get the perlin noise value of the current location
            column_height = perlin:noise( (layer[x][z].pos.x - topleft.x ) * perlin_multiplier ,( layer[x][z].pos.z + topleft.z ) * perlin_multiplier,perlin_constant)
            --Convert the perlin noise value to a height value
            column_height = math.floor(column_height / perlin_smoothing)

            --Check water level
            if column_height > water_level then
                if column_height < 0 then
                    column_height = 0
                end
                --Place a grass piece if it is the final tile in the column
                if column_height == current_height then
                    layer[x][z].hex = 1
                    layer_count = layer_count + 1
                --place a stone piece if it isn't the final tile in a column
                elseif  column_height > current_height then
                    layer[x][z].hex = 3
                    layer_count = layer_count + 1
                --Otherwise place a water tile
                else
                    layer[x][z].hex = 0
                end
            --If it is on the zero level and the water level is less than require place a water piece
            elseif current_height == 0 then
                layer[x][z].hex = 2
                layer_count = layer_count + 1
            --Other wise place an ait piece
            else
                layer[x][z].hex = 0
            end

        end
    end

    
    for x = 0, max_x do
        for z = 0, max_z do
            
            layer[x][z].neighbors = {}

            if z != 0 then
                    
                addTable(layer[x][z].neighbors,layer[x][z-1])
                if x != 0 then
                    addTable(layer[x][z].neighbors,layer[x-1][z])
                end
                if x < max_x - 1 then
                    addTable(layer[x][z].neighbors,layer[x+1][z])
                end
            end
            if z < max_z -1 then
                addTable(layer[x][z].neighbors,layer[x][z+1])
                if x < max_x - 1 then
                    addTable(layer[x][z].neighbors,layer[x+1][z+1])
                end
                if x != 0 then
                    addTable(layer[x][z].neighbors,layer[x-1][z+1])
                end
            end
           
        end
    end
 



    print('Generate layer' .. current_height)
    return layer
end

function addTable(table, value)
    table[#table+1] = value
end

--[[ The onUpdate event is called once per frame. --]]
function onUpdate()
    --[[ print('onUpdate loop!') --]]
    if printing then
        if layer_count == 0 then
            height = max_height + 1
        end
        if height <= max_height then
            
            if count_x < max_x then
                if count_z < max_z then
                    paste_params = {}
                    paste_params.position = layer[count_x][count_z].pos
                    paste_params.snap_to_grid = true
                    if layer[count_x][count_z].hex != 0 then 
                        if layer[count_x][count_z].hex == 1 then
                            copy_params = {grass_one_hex}
                            copy(copy_params)
                        elseif layer[count_x][count_z].hex == 2 then
                            copy_params = {water_one_hex}
                            copy(copy_params)
                        elseif layer[count_x][count_z].hex == 3 then
                            copy_params = {stone_one_hex}
                            copy(copy_params)
                        elseif layer[count_x][count_z].hex == 4 then
                            copy_params = {sand_one_hex}
                            copy(copy_params)
                        end
                        
                        clone = paste(paste_params)
                        clone[1].setRotation(Vector(0,30 + math.random(1,4)*60,0))
                        clone[1].addTag('terrain')
                    end
                    count_z = count_z + 1
                    while layer[count_x][count_z].hex == 0 do
                        count_z = count_z + 1
                        if count_z >= max_z then
                            break
                        end
                    end
                else

                    count_z = 0
                    count_x = count_x + 1
                end

            else
                count_z = 0
                count_x = 0
                height = height + 1
                current_layer = generateLayer(height)
            end

        else
            printing = false
        end
    end


end

function ternary(cond, T, F)
    if cond then return T else return F end
end

function buttonClicked()
    
    print('Here is the vector location of the hex' .. 
    ', ' .. grass_one_hex.getPosition().x .. 
    ', ' .. grass_one_hex.getPosition().y .. 
    ', ' .. grass_one_hex.getPosition().z)
    if not printing then
        copy_params = {grass_one_hex}
        copy(copy_params)
        printing = true
        count_z = 0
        count_x = 0
        height = 0
        print('Beginning Printing')
        current_layer = generateLayer(height)
    else
        print('Stopping Printing')
        printing = false
    end

end
-- original code by Ken Perlin: http://mrl.nyu.edu/~perlin/noise/
local function BitAND(a,b)--Bitwise and
    local p,c=1,0
    while a>0 and b>0 do
        local ra,rb=a%2,b%2
        if ra+rb>1 then c=c+p end
        a,b,p=(a-ra)/2,(b-rb)/2,p*2
    end
    return c
end

perlin = {}
perlin.p = {}
perlin.permutation = { 151,160,137,91,90,15,
  131,13,201,95,96,53,194,233,7,225,140,36,103,30,69,142,8,99,37,240,21,10,23,
  190, 6,148,247,120,234,75,0,26,197,62,94,252,219,203,117,35,11,32,57,177,33,
  88,237,149,56,87,174,20,125,136,171,168, 68,175,74,165,71,134,139,48,27,166,
  77,146,158,231,83,111,229,122,60,211,133,230,220,105,92,41,55,46,245,40,244,
  102,143,54, 65,25,63,161, 1,216,80,73,209,76,132,187,208, 89,18,169,200,196,
  135,130,116,188,159,86,164,100,109,198,173,186, 3,64,52,217,226,250,124,123,
  5,202,38,147,118,126,255,82,85,212,207,206,59,227,47,16,58,17,182,189,28,42,
  223,183,170,213,119,248,152, 2,44,154,163, 70,221,153,101,155,167, 43,172,9,
  129,22,39,253, 19,98,108,110,79,113,224,232,178,185, 112,104,218,246,97,228,
  251,34,242,193,238,210,144,12,191,179,162,241, 81,51,145,235,249,14,239,107,
  49,192,214, 31,181,199,106,157,184, 84,204,176,115,121,50,45,127, 4,150,254,
  138,236,205,93,222,114,67,29,24,72,243,141,128,195,78,66,215,61,156,180
}
perlin.size = 256
perlin.gx = {}
perlin.gy = {}
perlin.randMax = 256

function perlin:load(  )
    for i=1,self.size do
        self.p[i] = self.permutation[i]
        self.p[255+i] = self.p[i]
    end
end

function perlin:noise( x, y, z )
    local X = BitAND(math.floor(x), 255) + 1
    local Y = BitAND(math.floor(y), 255) + 1
    local Z = BitAND(math.floor(z), 255) + 1

    x = x - math.floor(x)
    y = y - math.floor(y)
    z = z - math.floor(z)
    local u = fade(x)
    local v = fade(y)
    local w = fade(z)
    local A  = self.p[X]+Y
    local AA = self.p[A]+Z
    local AB = self.p[A+1]+Z
    local B  = self.p[X+1]+Y
    local BA = self.p[B]+Z
    local BB = self.p[B+1]+Z

    return lerp(w, lerp(v, lerp(u, grad(self.p[AA  ], x  , y  , z  ),
                                   grad(self.p[BA  ], x-1, y  , z  )),
                           lerp(u, grad(self.p[AB  ], x  , y-1, z  ),
                                   grad(self.p[BB  ], x-1, y-1, z  ))),
                   lerp(v, lerp(u, grad(self.p[AA+1], x  , y  , z-1),
                                   grad(self.p[BA+1], x-1, y  , z-1)),
                           lerp(u, grad(self.p[AB+1], x  , y-1, z-1),
                                   grad(self.p[BB+1], x-1, y-1, z-1))))
end

function fade( t )
    return t * t * t * (t * (t * 6 - 15) + 10)
end

function lerp( t, a, b )
    return a + t * (b - a)
end

function grad( hash, x, y, z )
    local h = hash % 16
    local u = h < 8 and x or y
    local v = h < 4 and y or ((h == 12 or h == 14) and x or z)
    return ((h % 2) == 0 and u or -u) + ((h % 3) == 0 and v or -v)
end
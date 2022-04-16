local gfx = playdate.graphics

gfx.setBackgroundColor(gfx.kColorWhite)
gfx.setColor(gfx.kColorBlack)

local angles = {
    ANGLE0 = 0,
    ANGLE90 = 1,
    ANGLE180 = 2,
    ANGLE270 = 3
}

local gridSize = 10

local pieceA = {
    {0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 1, 0, 0, 0, 0},
    {0, 0, 0, 1, 1, 1, 0, 0},
    {0, 0, 0, 0, 1, 0, 0, 0},
    {0, 0, 0, 0, 1, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0}
}

local pieceB = {
    {0, 1, 0},
    {1, 1, 0},
    {0, 1, 1},
    {0, 1, 0}
}

cursor = {1, 1}

function push(list, item)
    list[#list+1] = item
end

function reverse(list)
    local ret = {}
    for i = #list, 1, -1 do
        push(ret, list[i])
    end
    return ret
end

function drawCursor(offsetX, offsetY, x, y)
    local xPos = offsetX + gridSize * (x-1) + 2
    local yPos = offsetY + gridSize * (y-1) + 2
    gfx.drawRect(xPos, yPos, gridSize - 3, gridSize - 3)
    local prevColor = gfx.getColor()
    gfx.setColor(gfx.kColorWhite)
    gfx.drawRect(xPos+1, yPos+1, gridSize-5, gridSize - 5)
    gfx.setColor(prevColor)
end

function drawVoxel(offsetX, offsetY, x, y)
    local xPos = offsetX + gridSize * (x-1) + 2
    local yPos = offsetY + gridSize * (y-1) + 2
    gfx.fillRect(xPos, yPos, gridSize - 3, gridSize - 3)
end

function drawShape(offsetX, offsetY, shape)
    for i = 1, #shape do
        for j = 1, #shape[i] do
            if shape[i][j] == 1 then
                drawVoxel(offsetX, offsetY, j, i)
            end
        end
    end
end

function drawGrid(offsetX, offsetY, w, h)
    for row = 0, h do
        local yPos = offsetY + gridSize*row
        local length = w*gridSize
        gfx.drawLine(offsetX, yPos, offsetX+length, yPos)
    end
    for col = 0, w do
        local xPos = offsetX + gridSize * col
        local length = h*gridSize
        gfx.drawLine(xPos, offsetY, xPos, offsetY+length)
    end
end

function isSymmetrical(shape)
    if shape == nil then return false end
    if isLRSymmetrical(shape) or isLRSymmetrical(rotate90CW(shape)) or isRotSymmetrical(shape) or isDiagSymmetrical(shape) then
        return true 
    else 
        return false 
    end
end

function findLRBounds(shape)
    local leftBound = #shape[1]
    local rightBound = 0
    
    for i = 1, #shape do
        for j = 1, #shape[i] do
            if shape[i][j] == 1 then
                if j < leftBound then
                    leftBound = j
                end
                if j > rightBound then
                    rightBound = j
                end
            end
        end
    end
    
    return leftBound, rightBound
end

function isLRSymmetrical(shape)
    if shape == nil then return false end
    local leftBound, rightBound = findLRBounds(shape)
    
    local width = rightBound - leftBound + 1
    
    for i = 1, #shape do
        local reflectedJ = rightBound
        for j = leftBound, leftBound + math.floor(width/2) do
            if shape[i][j] ~= shape[i][reflectedJ] then
                return false
            end
            reflectedJ = reflectedJ - 1
        end
    end
    
    return true
end

function clipShape(shape)
    local leftBound, rightBound = findLRBounds(shape)
    local upBound, downBound = findLRBounds(rotate(shape, angles.ANGLE270))
    
    local clippedShape = {}
    
    for i = 1, downBound - upBound + 1 do
        clippedShape[i] = {}
        for j = 1, rightBound - leftBound + 1 do
            clippedShape[i][j] = shape[i+upBound-1][j+leftBound-1]
        end
    end
    
    return clippedShape
end

function isRotSymmetrical(shape)
    if shape == nil then return false end
    local clip = clipShape(shape)
    local rot = rotate(clip, angles.ANGLE180)
    
    for i = 1, #clip do
        for j = 1, #clip[i] do
            if clip[i][j] ~= rot[i][j] then
                return false
            end
        end
    end
    
    return true
end

function isDiagSymmetrical(shape)
    if shape == nil then return false end
    if isULDRSymmetrical(shape) or isULDRSymmetrical(rotate90CW(shape)) then
        return true
    else
        return false
    end
end

function isULDRSymmetrical(shape)
    if shape == nil then return false end
    local clip = clipShape(shape)
    local flip = transpose(clip)
    
    for i = 1, #clip do
        for j = 1, #clip[i] do
            if flip[i] == nil or flip[i][j] == nil or clip[i][j] ~= flip[i][j] then
                return false
            end
        end
    end
    
    return true
end

function rotate(shape, angle)
    local ret = shape
    for i = 1,angle do
        ret = rotate90CW(ret)
    end
    return ret
end

function rotate90CW(shape)
    local shapeTransposed = transpose(shape)
    local ret = {}
    for i = 1, #shapeTransposed do
        push(ret, reverse(shapeTransposed[i]))
    end
    return ret
end

function transpose(shape)
    local ret = {}
    
    for i = 1, #shape do
        for j = 1, #shape[i] do
            if ret[j] == nil then
                ret[j] = {}
            end
            ret[j][i] = shape[i][j]
        end
    end
    
    return ret
end

function tryPlaceShape(base, shape, offsetX, offsetY)
    local ret = table.deepcopy(base)
    for i = 1, #shape+offsetY do
        if ret[i] == nil then
            ret[i] = {}
        end
        for j = 1, #shape+offsetX do
            if ret[i][j] == nil then
                ret[i][j] = 0
            end
        end
    end
    
    for i = 1, #shape do
        for j = 1, #shape[i] do
            if shape[i][j] ~= 0 then
                if ret[i+offsetY][j+offsetX] ~= 0 and shape[i][j] ~= 0 then
                    return nil
                else
                    if shape[i][j] ~= 0 then
                        ret[i+offsetY][j+offsetX] = shape[i][j]
                    end
                end
            end
        end
    end
    
    return ret
end

function findSymmetries(shape1, shape2)
    local solutions = {}
    
    for i = 1, #shape1 do
        for j = 1, #shape1[i] do
            local x = tryPlaceShape(shape1, shape2, j, i)
            if isSymmetrical(x) then
                push(solutions, x)
            end
            for k = 0, 3 do
                x = tryPlaceShape(shape1, rotate(shape2, k), j, i)
                if isSymmetrical(x) then
                    push(solutions, x)
                end
            end
            local flip = transpose(shape2)
            for k = 0, 3 do
                x = tryPlaceShape(shape1, rotate(flip, k), j, i)
                if isSymmetrical(x) then
                    push(solutions, x)
                end
            end
        end
    end
    
    return solutions
end

inputHandlers = {

    upButtonDown = function()
        if cursor[2] > 1 then
            cursor[2] -= 1
        end
    end,
    downButtonDown = function()
        if cursor[2] < height then
            cursor[2] += 1
        end
    end,
    leftButtonDown = function()
        if cursor[1] > 1 then
            cursor[1] -= 1
        end
    end,
    rightButtonDown = function()
        if cursor[1] < width then
            cursor[1] += 1
        end
    end,
    AButtonDown = function()
        if mainShape[cursor[2]][cursor[1]] == 1 then
            mainShape[cursor[2]][cursor[1]] = 0
        else
            mainShape[cursor[2]][cursor[1]] = 1
        end
    end,
    BButtonDown = function()
        
    end,
}

playdate.inputHandlers.push(inputHandlers)

function initialize()
    width = 22
    height = 16
    
    --[[mainShape = {}
    for i = 1, height do
        mainShape[i] = {}
        for j = 1, width do
            mainShape[i][j] = 0
        end
    end]]--
    
    allSolutions = findSymmetries(pieceA, pieceB)
end

function playdate.update()
    gfx.clear()
    
    gfx.drawText("Pieces used:", 30, 120)
    drawShape(30, 140, pieceA)
    drawShape(140, 140, pieceB)
    
    for i = 1, #allSolutions do
        drawGrid(30+100*(i-1), 30, 8, 8)
        drawShape(30+100*(i-1), 30, allSolutions[i])
    end
    --drawCursor(30, 30, cursor[1], cursor[2])
    
    playdate.drawFPS(0,0)
end

initialize()

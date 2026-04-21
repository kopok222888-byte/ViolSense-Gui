--[[
    Aimbot module for ViolSense
    Usage: loadstring(game:HttpGet("raw-url"))()(menu)
]]

return function(menu)
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")
    local LocalPlayer = Players.LocalPlayer
    local Camera = workspace.CurrentCamera

    -- Рисование круга FOV
    local fovCircle = nil
    if Drawing then
        fovCircle = Drawing.new("Circle")
        fovCircle.Thickness = 1
        fovCircle.Transparency = 0.5
        fovCircle.Visible = false
        fovCircle.NumSides = 64
        fovCircle.Filled = false
    end

    local function updateFOVCircle()
        if not fovCircle then return end
        local enabled = menu.values[1].Main.Aimbot["Draw FOV"].Toggle
        if not enabled then
            fovCircle.Visible = false
            return
        end
        local color = menu.values[1].Main.Aimbot["$Draw FOV"].Color
        if color then fovCircle.Color = color end
        fovCircle.Position = UserInputService:GetMouseLocation()
        fovCircle.Radius = menu.values[1].Main.Aimbot["FOV Size"].Slider
        fovCircle.Visible = true
    end

    local function isValidPlayer(plr)
        if plr == LocalPlayer then return false end
        local char = plr.Character
        if not char then return false end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then return false end
        return true
    end

    local function getHitboxPosition(char, hitboxType)
        if hitboxType == "Head" then
            local head = char:FindFirstChild("Head")
            if head then return head.Position end
        end
        local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
        return root and root.Position or nil
    end

    local function getClosestTarget()
        local fovRadius = menu.values[1].Main.Aimbot["FOV Size"].Slider
        local maxDist = menu.values[1].Main.Aimbot["Max Distance"].Slider
        local hitboxType = menu.values[1].Main.Aimbot.Hitbox.Dropdown
        local mousePos = UserInputService:GetMouseLocation()
        local bestTarget = nil
        local bestDist = fovRadius + 1

        for _, plr in ipairs(Players:GetPlayers()) do
            if not isValidPlayer(plr) then continue end
            local char = plr.Character
            local hitPos = getHitboxPosition(char, hitboxType)
            if not hitPos then continue end

            local dist3D = (Camera.CFrame.Position - hitPos).Magnitude
            if dist3D > maxDist then continue end

            local screenPos, onScreen = Camera:WorldToViewportPoint(hitPos)
            if not onScreen then continue end
            local screenVec = Vector2.new(screenPos.X, screenPos.Y)
            local dist2D = (screenVec - mousePos).Magnitude
            if dist2D <= fovRadius and dist2D < bestDist then
                bestDist = dist2D
                bestTarget = {player = plr, hitPos = hitPos, screenPos = screenVec}
            end
        end
        return bestTarget
    end

    -- Запускаем цикл аимбота
    RunService.RenderStepped:Connect(function()
        updateFOVCircle()

        local enabled = menu.values[1].Main.Aimbot.Enabled.Toggle and menu.values[1].Main.Aimbot["$Enabled"].Active
        if not enabled or menu.open then return end

        local target = getClosestTarget()
        if not target then return end

        local currentMousePos = UserInputService:GetMouseLocation()
        local delta = target.screenPos - currentMousePos
        local smooth = menu.values[1].Main.Aimbot.Smoothing.Slider
        if smooth > 1 then
            delta = delta / smooth
        end
        mousemoverel(delta.X, delta.Y)
    end)

    if not Drawing then
        warn("Ваш эксплойт не поддерживает Drawing API. Круг FOV не будет отображаться.")
    end
end
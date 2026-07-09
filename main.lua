local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Lethal Ape",
    LoadingTitle = "Loading",
    LoadingSubtitle = "Please wait...",
    ConfigurationSaving = {
        Enabled = false
    }
})

-- =============================================================================
-- CATEGORIAS E SEÇÕES TOTALMENTE ORGANIZADAS E DIDÁTICAS
-- =============================================================================

local TabFarm = Window:CreateTab("Auto Farm", 4483362458)
local TabManual = Window:CreateTab("Manual Farm", 4483362458)
local TabVisual = Window:CreateTab("ESP", 4483362458)
local TabPortoes = Window:CreateTab("Doors", 4483362458)
local TabGeral = Window:CreateTab("Misc", 4483362458)
local TabDancas = Window:CreateTab("Emotes", 4483362458)

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local TextChatService = game:GetService("TextChatService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Estados Globais de Funcionamento
local AutoFarmAtivo = false
local ModoRapidoAtivo = true -- Forçado verdadeiro para garantir a velocidade ultra pretendida
local CFlyAtivo = false
local FullbrightAtivo = false
local LoopColorirAtivo = false

local ESPAtivo = false
local ESPMonstrosAtivo = false
local ESPPortoesAtivo = false
local ESPJogadoresAtivo = false
local AntijumpscareAtivo = false

local ArmazenamentoESP = {}
local ArmazenamentoESPMonstros = {}
local ArmazenamentoESPPortoes = {}
local ArmazenamentoESPJogadores = {}

-- Filtro Rígido de Validação de Itens da Mochila
local mineriosPermitidos = { 
    ["gold"] = true, 
    ["diamond"] = true, 
    ["copper"] = true,
    ["emerald"] = true,
    ["meat"] = true
}

-- Central de Warnings e Notificações Visuais
local function logarAcao(titulo, texto, duracao)
    Rayfield:Notify({
        Title = titulo,
        Content = texto,
        Duration = duracao or 3.0,
        Image = 4483362458,
    })
end

local function getHRP()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    return char:WaitForChild("HumanoidRootPart", 5)
end

-- Envio Adaptativo de Mensagens
local function enviarChat(mensagem)
    pcall(function()
        if TextChatService and TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
            local canal = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
            if canal then canal:SendAsync(mensagem) end
        else
            game:GetService("ReplicatedStorage").DefaultChatSystemChatEvents.SayMessageRequest:FireServer(mensagem, "All")
        end
    end)
end

-- =============================================================================
-- SISTEMA DE HELICÓPTERO / FLY ANTI-VOID ESTABILIZADO
-- =============================================================================
local flyVelocity, flyGyro

local function ativarFlyTemporario(rootPart)
    if not rootPart then return end
    if flyVelocity then pcall(function() flyVelocity:Destroy() end) end
    if flyGyro then pcall(function() flyGyro:Destroy() end) end

    -- Forças absolutas para trancar a física do boneco no ar impedindo quedas por lag
    flyVelocity = Instance.new("BodyVelocity")
    flyVelocity.Velocity = Vector3.new(0, 0, 0)
    flyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    flyVelocity.Parent = rootPart

    flyGyro = Instance.new("BodyGyro")
    flyGyro.CFrame = rootPart.CFrame
    flyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    flyGyro.Parent = rootPart
end

local function desativarFlyTemporario()
    if flyVelocity then pcall(function() flyVelocity:Destroy() end); flyVelocity = nil end
    if flyGyro then pcall(function() flyGyro:Destroy() end); flyGyro = nil end
end

-- Loop de controle livre por botões (CFly Geral)
RunService.Heartbeat:Connect(function()
    if CFlyAtivo then
        local hrp = getHRP()
        local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hrp and humanoid then
            if not flyVelocity or not flyGyro or flyVelocity.Parent ~= hrp then
                ativarFlyTemporario(hrp)
            end
            local direcaoMove = humanoid.MoveDirection
            local velocidadeVoo = 120
            
            flyVelocity.Velocity = direcaoMove * velocidadeVoo
            if direcaoMove.Magnitude == 0 then
                flyVelocity.Velocity = Vector3.new(0, 0, 0)
            end
            flyGyro.CFrame = Camera.CFrame
        end
    else
        -- Só desativa se o Auto Farmtambém não estiver controlando o voo
        if not AutoFarmAtivo and (flyVelocity or flyGyro) then
            desativarFlyTemporario()
        end
    end
end)

-- Interação imediata com click ou prompts
local function interagirComObjeto(instancia)
    if not instancia then return end
    local prompt = instancia:IsA("ProximityPrompt") and instancia or instancia:FindFirstChildOfClass("ProximityPrompt", true)
    if prompt then fireproximityprompt(prompt) end
    
    local cd = instancia:IsA("ClickDetector") and instancia or instancia:FindFirstChildOfClass("ClickDetector", true)
    if cd then fireclickdetector(cd) end
end

local function encontrarReciclador()
    for _, obj in ipairs(workspace:GetChildren()) do
        if obj:FindFirstChild("Recycle item") then
            return obj, obj:FindFirstChild("Recycle item")
        end
    end
    return nil, nil
end

local function itemEstaAtivoNoMundo(objeto)
    if not objeto or not objeto.Parent then return false end
    local parte = objeto:IsA("BasePart") and objeto or objeto:FindFirstChildWhichIsA("BasePart", true)
    if not parte then return false end
    if parte.Transparency >= 0.9 and parte.CanCollide == false and parte.CanTouch == false then
        return false
    end
    return true
end

-- =============================================================================
-- MECANISMO DE COLETAS COM PRECISÃO ULTRA-RÁPIDA (IMUNE A WI-FI INSTÁVEL)
-- =============================================================================

local function executarColetaMateriais(nomeItem)
    local hrp = getHRP()
    if not hrp then return end
    local scraps = workspace:FindFirstChild("Scraps")
    if not scraps then return end

    local alvos = {}
    for _, obj in ipairs(scraps:GetChildren()) do
        if string.lower(obj.Name) == string.lower(nomeItem) and itemEstaAtivoNoMundo(obj) then
            table.insert(alvos, obj)
        end
    end

    if #alvos == 0 then return end
    
    -- LOG DE INÍCIO: Avisa qual material o script detectou no mapa e foi buscar
    logarAcao("Auto Farm", "Buscando todos os itens tipo: [" .. nomeItem .. "] encontrados no mapa.", 1.5)
    
    ativarFlyTemporario(hrp)

    for _, obj in ipairs(alvos) do
        if itemEstaAtivoNoMundo(obj) then
            local parte = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart", true)
            if parte then
                -- Tranca o jogador firmemente flutuando em cima do item antes de interagir (Impede Void)
                hrp.CFrame = parte.CFrame + Vector3.new(0, 1.5, 0)
                task.wait(0.04)

                local tentativas = 0
                -- Loop de Força Bruta: Interage repetidamente até o ping responder e o item sumir
                repeat
                    interagirComObjeto(obj)
                    task.wait(0.03)
                    tentativas = tentativas + 1
                until not obj or not obj.Parent or not itemEstaAtivoNoMundo(obj) or tentativas > 15
            end
        end
    end
    
    desativarFlyTemporario()
end

local function acionarFluxoVendas()
    local hrp = getHRP()
    local char = LocalPlayer.Character
    local mochila = LocalPlayer:FindFirstChild("Backpack")
    if not char or not mochila then return end

    local reciclador, botaoVender = encontrarReciclador()
    if not botaoVender then return end

    local ferramentas = mochila:GetChildren()
    local itensParaVender = 0
    for _, item in ipairs(ferramentas) do
        if item:IsA("Tool") and mineriosPermitidos[string.lower(item.Name)] then
            itensParaVender = itensParaVender + 1
        end
    end

    if itensParaVender == 0 then return end

    -- LOG DE VENDA: Avisa que a mochila está cheia e o teleporte para o reciclador iniciou
    logarAcao("Sell", "Mochila carregada! Teleportando para o Reciclador para vender " .. itensParaVender .. " itens.", 2)

    local parteAlvo = botaoVender:IsA("BasePart") and botaoVender or botaoVender:FindFirstChildWhichIsA("BasePart", true)
    if parteAlvo then
        hrp.CFrame = parteAlvo.CFrame + Vector3.new(0, 2, 0)
        task.wait(0.3)
    end

    -- Recarrega ferramentas após o teleporte para garantir estabilidade
    ferramentas = mochila:GetChildren()
    for _, item in ipairs(ferramentas) do
        if item:IsA("Tool") and mineriosPermitidos[string.lower(item.Name)] then
            item.Parent = char
            task.wait(0.02)
            
            local tentativas = 0
            repeat
                interagirComObjeto(botaoVender)
                task.wait(0.04)
                tentativas = tentativas + 1
            until item.Parent ~= char or not item or tentativas > 10
        end
    end
    
    logarAcao("Sell", "Venda concluída com sucesso! Retornando para o ciclo de coleta.", 1.5)
end

-- Thread gerenciadora em segundo plano do Auto Farm
task.spawn(function()
    while true do
        task.wait(0.5)
        if AutoFarmAtivo then
            pcall(function()
                local posAntesDoCiclo = getHRP().CFrame
                
                executarColetaMateriais("Gold")
                executarColetaMateriais("Diamond")
                executarColetaMateriais("Copper")
                executarColetaMateriais("Emerald")
                executarColetaMateriais("Meat")
                
                task.wait(0.2)
                acionarFluxoVendas()
                
                -- Retorna de forma segura para a posição onde estava antes de começar a limpar o mapa
                if AutoFarmAtivo then
                    local hrpAtual = getHRP()
                    if hrpAtual then hrpAtual.CFrame = posAntesDoCiclo end
                end
            end)
        end
    end
end)

-- =============================================================================
-- SISTEMAS DIVERSOS DE RASTREAMENTO VISUAL (ESP ANTI-FANTASMA)
-- =============================================================================

local function limparESP()
    for _, esp in ipairs(ArmazenamentoESP) do if esp then pcall(function() esp:Destroy() end) end end
    ArmazenamentoESP = {}
end

local function atualizarESP()
    if not ESPAtivo then limparESP() return end
    local scraps = workspace:FindFirstChild("Scraps")
    if not scraps then return end

    -- Filtro anti-fantasmas ativo: elimina traços antigos de minérios sumidos
    for i = #ArmazenamentoESP, 1, -1 do
        local h = ArmazenamentoESP[i]
        if not h or not h.Parent or not h.Adornee or not itemEstaAtivoNoMundo(h.Adornee) then
            pcall(function() h:Destroy() end)
            table.remove(ArmazenamentoESP, i)
        end
    end

    for _, obj in ipairs(scraps:GetChildren()) do
        if itemEstaAtivoNoMundo(obj) and not obj:FindFirstChild("Nunes_ESP") then
            local nomeL = string.lower(obj.Name)
            local corMaterial = nil

            if nomeL == "gold" then corMaterial = Color3.fromRGB(255, 215, 0)
            elseif nomeL == "diamond" then corMaterial = Color3.fromRGB(0, 238, 255)
            elseif nomeL == "copper" then corMaterial = Color3.fromRGB(211, 84, 0)
            elseif nomeL == "emerald" then corMaterial = Color3.fromRGB(0, 255, 100)
            elseif nomeL == "meat" then corMaterial = Color3.fromRGB(255, 100, 100)
            end

            if corMaterial then
                local highlight = Instance.new("Highlight")
                highlight.Name = "Nunes_ESP"
                highlight.FillColor = corMaterial
                highlight.FillTransparency = 0.6
                highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                highlight.Adornee = obj
                highlight.Parent = obj
                table.insert(ArmazenamentoESP, highlight)
            end
        end
    end
end

local function limparESPJogadores()
    for _, esp in ipairs(ArmazenamentoESPJogadores) do if esp then pcall(function() esp:Destroy() end) end end
    ArmazenamentoESPJogadores = {}
end

local function atualizarESPJogadores()
    limparESPJogadores()
    if not ESPJogadoresAtivo then return end
    for _, jogador in ipairs(Players:GetPlayers()) do
        if jogador ~= LocalPlayer and jogador.Character then
            local highlight = Instance.new("Highlight")
            highlight.Name = "Nunes_PlayerESP"
            highlight.FillColor = Color3.fromRGB(0, 0, 139)
            highlight.FillTransparency = 0.4
            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            highlight.Adornee = jogador.Character
            highlight.Parent = jogador.Character
            table.insert(ArmazenamentoESPJogadores, highlight)
        end
    end
end

local function obterInstanciaMonstro(nome)
    local monstrosDiretos = {
        Dus = workspace:FindFirstChild("DusMonster") and workspace.DusMonster:FindFirstChild("Dus"),
        Gus = workspace:FindFirstChild("GusMonster") and workspace.GusMonster:FindFirstChild("Gus"),
        Kus = workspace:FindFirstChild("KusMonster") and workspace.KusMonster:FindFirstChild("Kus"),
        Lost = workspace:FindFirstChild("LostMonster") and workspace.LostMonster:FindFirstChild("Lost")
    }
    if monstrosDiretos[nome] then return monstrosDiretos[nome] end
    local pastaSandman = workspace:FindFirstChild("Sandman/Ashy")
    if pastaSandman then return pastaSandman:FindFirstChild(nome) end
    return workspace:FindFirstChild(nome)
end

local function limparESPMonstros()
    for _, esp in ipairs(ArmazenamentoESPMonstros) do if esp then pcall(function() esp:Destroy() end) end end
    ArmazenamentoESPMonstros = {}
end

local function atualizarESPMonstros()
    limparESPMonstros()
    if not ESPMonstrosAtivo then return end
    local listaNomes = {"Dus", "Gus", "Kus", "Lost", "Ashy", "Lurker", "SandMan", "Scar"}

    for _, nome in ipairs(listaNomes) do
        local monstro = obterInstanciaMonstro(nome)
        if monstro then
            local highlight = Instance.new("Highlight")
            highlight.Name = "Nunes_MonsterESP"
            highlight.FillColor = Color3.fromRGB(255, 0, 0)
            highlight.FillTransparency = 0.5
            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            highlight.Adornee = monstro
            highlight.Parent = monstro
            table.insert(ArmazenamentoESPMonstros, highlight)
        end
    end
end

local function limparESPPortoes()
    for _, esp in ipairs(ArmazenamentoESPPortoes) do if esp then pcall(function() esp:Destroy() end) end end
    ArmazenamentoESPPortoes = {}
end

local function atualizarESPPortoes()
    limparESPPortoes()
    if not ESPPortoesAtivo then return end
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj.Name == "ButtonDoor" then
            local portaoAlvo = obj:FindFirstChild("Object_0")
            if portaoAlvo and portaoAlvo:IsA("BasePart") then
                local highlight = Instance.new("Highlight")
                highlight.Name = "Nunes_PortaoESP"
                highlight.FillColor = Color3.fromRGB(0, 255, 150)
                highlight.FillTransparency = 0.5
                highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                highlight.Adornee = portaoAlvo
                highlight.Parent = portaoAlvo
                table.insert(ArmazenamentoESPPortoes, highlight)
            end
        end
    end
end

task.spawn(function()
    while task.wait(0.4) do -- Frequência rápida para manter sincronia absoluta com o servidor
        if ESPJogadoresAtivo then pcall(atualizarESPJogadores) end
        if ESPAtivo then pcall(atualizarESP) end
        if ESPMonstrosAtivo then pcall(atualizarESPMonstros) end
        if ESPPortoesAtivo then pcall(atualizarESPPortoes) end
    end
end)

local function acionarPortaoEspecifico(idPortao)
    local executado = false
    local contador = 1
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj.Name == "ButtonDoor" then
            if contador == idPortao then
                local button = obj:FindFirstChild("Button")
                if button then interagirComObjeto(button); executado = true end
                break
            end
            contador = contador + 1
        end
    end
    if executado then logarAcao("Door", "Sinal enviado para o Door: " .. idPortao) end
end

local function teleportarParaMonstro(nomeMonstro)
    local hrp = getHRP()
    if not hrp then return end
    local monstro = obterInstanciaMonstro(nomeMonstro)
    if monstro then
        local parteAlvo = monstro:IsA("BasePart") and monstro or monstro:FindFirstChildWhichIsA("BasePart", true)
        if parteAlvo then
            hrp.CFrame = parteAlvo.CFrame + Vector3.new(0, 4, 0)
            logarAcao("Teleport", "Levado com segurança até: " .. nomeMonstro)
        end
    else
        logarAcao("Warning", nomeMonstro .. " não foi encontrado no mapa.")
    end
end


-- =============================================================================
-- MONTAGEM DOS COMPONENTES DA INTERFACE DO USUÁRIO
-- =============================================================================

-- ABA: AUTO FARM SUPREMO
TabFarm:CreateSection("Automation")
TabFarm:CreateToggle({
    Name = "Auto Farm",
    CurrentValue = false,
    Flag = "ToggleAutoFarmSupremo",
    Callback = function(Value)
        AutoFarmAtivo = Value
        logarAcao("System", AutoFarmAtivo and "Auto FarmATIVADO. Varrendo o servidor..." or "Auto FarmDESATIVADO de forma segura.")
    end
})
TabFarm:CreateParagraph({
    Title = "Information",
    Content = "Automatically collects and sells available items."
})


-- ABA: COLETAS MANUAIS
TabManual:CreateSection("Manual Farm")
TabManual:CreateButton({ Name = "Collect Gold", Callback = function() executarColetaMateriais("Gold") end })
TabManual:CreateButton({ Name = "Collect Diamond", Callback = function() executarColetaMateriais("Diamond") end })
TabManual:CreateButton({ Name = "Collect Copper", Callback = function() executarColetaMateriais("Copper") end })
TabManual:CreateButton({ Name = "Collect Emerald", Callback = function() executarColetaMateriais("Emerald") end })
TabManual:CreateButton({ Name = "Collect Meat", Callback = function() executarColetaMateriais("Meat") end })


-- ABA: VISUAL & RASTREIO
TabVisual:CreateSection("ESP")
TabVisual:CreateToggle({
    Name = "Item ESP",
    CurrentValue = false,
    Flag = "ToggleESPMineriosNunes",
    Callback = function(Value) ESPAtivo = Value; if Value then atualizarESP() else limparESP() end end
})
TabVisual:CreateToggle({
    Name = "Player ESP",
    CurrentValue = false,
    Flag = "ToggleESPJogadoresNunes",
    Callback = function(Value) ESPJogadoresAtivo = Value; if Value then atualizarESPJogadores() else limparESPJogadores() end end
})
TabVisual:CreateToggle({
    Name = "Door ESP",
    CurrentValue = false,
    Flag = "ToggleESPPortoesNunes",
    Callback = function(Value) ESPPortoesAtivo = Value; if Value then atualizarESPPortoes() else limparESPPortoes() end end
})
TabVisual:CreateToggle({
    Name = "Monster ESP",
    CurrentValue = false,
    Flag = "ToggleESPMonstrosNunes",
    Callback = function(Value) ESPMonstrosAtivo = Value; if Value then atualizarESPMonstros() else limparESPMonstros() end end
})


-- ABA: CONTROLE DE PORTÕES
TabPortoes:CreateSection("Doors")
TabPortoes:CreateButton({
    Name = "Open/Close All Doors",
    Callback = function()
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj.Name == "ButtonDoor" then
                local b = obj:FindFirstChild("Button")
                if b then interagirComObjeto(b) end
            end
        end
    end
})
for i = 1, 4 do
    TabPortoes:CreateButton({ Name = "Door " .. i, Callback = function() acionarPortaoEspecifico(i) end })
end


-- ABA: UTILIDADES GERAIS
TabGeral:CreateSection("Movement")
TabGeral:CreateToggle({
    Name = "Fly",
    CurrentValue = false,
    Flag = "ToggleCFlyManual",
    Callback = function(Value) CFlyAtivo = Value end
})
TabGeral:CreateButton({
    Name = "Fullbright",
    Callback = function()
        FullbrightAtivo = not FullbrightAtivo
        Lighting.Brightness = FullbrightAtivo and 2 or 1
        Lighting.ClockTime = FullbrightAtivo and 14 or 12
        Lighting.GlobalShadows = not FullbrightAtivo
    end
})
TabGeral:CreateToggle({
    Name = "Anti Jumpscare",
    CurrentValue = false,
    Flag = "ToggleAntiScreamNunes",
    Callback = function(Value)
        AntijumpscareAtivo = Value
        if Value then
            task.spawn(function()
                local ruidos = {"Dus Noise", "Gus Noise", "Kus Noise", "Lost Noise", "Ashy Noise", "Lurker Noise", "SandMan Noise", "Scar Noise"}
                while AntijumpscareAtivo do
                    local pGui = LocalPlayer:FindFirstChild("PlayerGui")
                    if pGui then
                        for _, r in ipairs(ruidos) do
                            local pasta = pGui:FindFirstChild(r)
                            local scr = pasta and pasta:FindFirstChild("screen")
                            if scr then scr:Destroy() end
                        end
                    end
                    task.wait(0.1)
                end
            end)
        end
    end
})
TabGeral:CreateToggle({
    Name = "Rainbow Skin",
    CurrentValue = false,
    Flag = "ToggleColorirNunes",
    Callback = function(Value)
        LoopColorirAtivo = Value
        if Value then
            task.spawn(function()
                while LoopColorirAtivo do
                    for _, o in ipairs(workspace:GetChildren()) do
                        if string.lower(o.Name) == "colorir" then interagirComObjeto(o); task.wait(0.3) end
                    end
                    task.wait(0.1)
                end
            end)
        end
    end
})
TabGeral:CreateSection("Locations")
TabGeral:CreateButton({
    Name = "Teleport Spawn",
    Callback = function()
        local hrp = getHRP()
        if hrp and workspace:FindFirstChild("SpawnLocation") then hrp.CFrame = workspace.SpawnLocation.CFrame + Vector3.new(0, 3, 0) end
    end
})
TabGeral:CreateButton({ Name = "Sell Items", Callback = function() acionarFluxoVendas() end })


-- ABA: DANÇAS & EMOTES
TabDancas:CreateSection("Chat")
local comandos = {
    {"Dance", "/e dance"},
    {"Dance 2", "/e dance2"},
    {"Dance 3", "/e dance3"},
    {"Wave", "/e wave"},
    {"Cheer", "/e cheer"},
    {"Laugh", "/e laugh"},
    {"Point", "/e point"}
}
for _, cmd in ipairs(comandos) do
    TabDancas:CreateButton({ Name = cmd[1], Callback = function() enviarChat(cmd[2]) end })
end


-- =============================================================================
-- ESCUTAS DINÂMICAS DE EVENTOS (SINCRONIZAÇÃO EM TEMPO REAL)
-- =============================================================================
workspace.DescendantAdded:Connect(function(desc)
    if ESPAtivo and desc.Parent and desc.Parent.Name == "Scraps" then pcall(atualizarESP) end
    if ESPPortoesAtivo and desc.Name == "Object_0" and desc.Parent and desc.Parent.Name == "ButtonDoor" then task.wait(0.2); pcall(atualizarESPPortoes) end
end)

workspace.DescendantRemoving:Connect(function(desc)
    if ESPAtivo and desc.Parent and desc.Parent.Name == "Scraps" then pcall(atualizarESP) end
    if ESPPortoesAtivo and desc.Name == "Object_0" then pcall(atualizarESPPortoes) end
end)

Players.PlayerAdded:Connect(function() if ESPJogadoresAtivo then task.wait(1); pcall(atualizarESPJogadores) end end)
Players.PlayerRemoving:Connect(function() if ESPJogadoresAtivo then pcall(atualizarESPJogadores) end end)

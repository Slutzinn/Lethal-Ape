local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Lethal Ape",
    LoadingTitle = "Carregando",
    LoadingSubtitle = "Por favor, aguarde...",
    ConfigurationSaving = {
        Enabled = false
    }
})

-- =============================================================================
-- CATEGORIAS E SEÇÕES TOTALMENTE ORGANIZADAS E DIDÁTICAS
-- =============================================================================

local TabFarm = Window:CreateTab("Farm Automático", 4483362458)
local TabManual = Window:CreateTab("Farm Manual", 4483362458)
local TabVisual = Window:CreateTab("ESP (Visuais)", 4483362458)
local TabPortoes = Window:CreateTab("Portões", 4483362458)
local TabElevador = Window:CreateTab("Elevador", 4483362458) 
local TabGeral = Window:CreateTab("Geral", 4483362458)
local TabDancas = Window:CreateTab("Emotes", 4483362458)

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local TextChatService = game:GetService("TextChatService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Estados Globais de Funcionamento
local AutoFarmAtivo = false
local ModoRapidoAtivo = true 
local FullbrightAtivo = false
local LoopColorirAtivo = false
local TerceiraPessoaAtiva = false 

local ESPAtivo = false
local ESPMonstrosAtivo = false
local ESPPortoesAtivo = false
local ESPJogadoresAtivo = false
local ESPElevadorAtivo = false 
local AntijumpscareAtivo = false

-- Variável para guardar a posição da última morte
local UltimaPosicaoMorte = nil

local ArmazenamentoESP = {}
local ArmazenamentoESPMonstros = {}
local ArmazenamentoESPPortoes = {}
local ArmazenamentoESPJogadores = {}
local ArmazenamentoESPElevador = {} 

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

-- Monitoramento de Morte para Salvar Posição
local function monitorarMorte(character)
    local humanoid = character:WaitForChild("Humanoid", 10)
    local hrp = character:WaitForChild("HumanoidRootPart", 10)
    if humanoid and hrp then
        humanoid.Died:Connect(function()
            UltimaPosicaoMorte = hrp.CFrame
            logarAcao("Sistema de Morte", "Posição da morte salva! Use a opção 'Reviver' para retornar.", 4)
        end)
    end
end

if LocalPlayer.Character then monitorarMorte(LocalPlayer.Character) end
LocalPlayer.CharacterAdded:Connect(monitorarMorte)

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
-- SISTEMA DE VOO AUTOMÁTICO AUXILIAR
-- =============================================================================
local flyVelocity, flyGyro

local function ativarFlyTemporario(rootPart)
    if not rootPart then return end
    if flyVelocity then pcall(function() flyVelocity:Destroy() end) end
    if flyGyro then pcall(function() flyGyro:Destroy() end) end

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

-- LOCALIZAÇÃO DO ELEVADOR
local function encontrarElevador()
    if workspace:FindFirstChild("Mapa") and workspace.Mapa:FindFirstChild("Elevador") then
        return workspace.Mapa.Elevador
    end
    return workspace:FindFirstChild("Elevador") or workspace:FindFirstChild("elevator")
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
-- MECANISMO DE COLETAS COM PRECISÃO ULTRA-RÁPIDA
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
    
    logarAcao("Farm Automático", "Buscando todos os itens tipo: [" .. nomeItem .. "] encontrados no mapa.", 1.5)
    
    ativarFlyTemporario(hrp)

    for _, obj in ipairs(alvos) do
        if itemEstaAtivoNoMundo(obj) then
            local parte = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart", true)
            if parte then
                hrp.CFrame = parte.CFrame + Vector3.new(0, 1.5, 0)
                task.wait(0.04)

                local tentativas = 0
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

    logarAcao("Venda", "Mochila carregada! Teleportando para o Reciclador para vender " .. itensParaVender .. " itens.", 2)

    local parteAlvo = botaoVender:IsA("BasePart") and botaoVender or botaoVender:FindFirstChildWhichIsA("BasePart", true)
    if parteAlvo then
        hrp.CFrame = parteAlvo.CFrame + Vector3.new(0, 2, 0)
        task.wait(0.3)
    end

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
    
    logarAcao("Venda", "Venda concluída com sucesso! Retornando para o ciclo de coleta.", 1.5)
end

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
                
                if AutoFarmAtivo then
                    local hrpAtual = getHRP()
                    if hrpAtual then hrpAtual.CFrame = posAntesDoCiclo end
                end
            end)
        end
    end
end)

-- =============================================================================
-- SISTEMAS DIVERSOS DE RASTREAMENTO VISUAL (ESP)
-- =============================================================================
local function limparESP()
    for _, esp in ipairs(ArmazenamentoESP) do if esp then pcall(function() esp:Destroy() end) end end
    ArmazenamentoESP = {}
end

local function atualizarESP()
    if not ESPAtivo then limparESP() return end
    local scraps = workspace:FindFirstChild("Scraps")
    if not scraps then return end

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

local function limparESPElevador()
    for _, esp in ipairs(ArmazenamentoESPElevador) do if esp then pcall(function() esp:Destroy() end) end end
    ArmazenamentoESPElevador = {}
end

local function atualizarESPElevador()
    limparESPElevador()
    if not ESPElevadorAtivo then return end
    local elevador = encontrarElevador()
    if elevador then
        local alvoVisual = elevador:FindFirstChild("BaseDoElevador") or elevador
        local highlight = Instance.new("Highlight")
        highlight.Name = "Nunes_ElevadorESP"
        highlight.FillColor = Color3.fromRGB(238, 130, 238) 
        highlight.FillTransparency = 0.4
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Adornee = alvoVisual
        highlight.Parent = alvoVisual
        table.insert(ArmazenamentoESPElevador, highlight)
    end
end

task.spawn(function()
    while task.wait(0.4) do 
        if ESPJogadoresAtivo then pcall(atualizarESPJogadores) end
        if ESPAtivo then pcall(atualizarESP) end
        if ESPMonstrosAtivo then pcall(atualizarESPMonstros) end
        if ESPPortoesAtivo then pcall(atualizarESPPortoes) end
        if ESPElevadorAtivo then pcall(atualizarESPElevador) end 
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
    if executado then logarAcao("Portão", "Sinal enviado para o Portão: " .. idPortao) end
end

-- =============================================================================
-- MONTAGEM DOS COMPONENTES DA INTERFACE DO USUÁRIO
-- =============================================================================

-- ABA: AUTO FARM SUPREMO
TabFarm:CreateSection("Automação")
TabFarm:CreateToggle({
    Name = "Farm Automático",
    CurrentValue = false,
    Flag = "ToggleAutoFarmSupremo",
    Callback = function(Value)
        AutoFarmAtivo = Value
        logarAcao("Sistema", AutoFarmAtivo and "Farm Automático ATIVADO. Varrendo o servidor..." or "Farm Automático DESATIVADO de forma segura.")
    end
})
TabFarm:CreateParagraph({
    Title = "Informação",
    Content = "Coleta e vende os itens disponíveis no mapa automaticamente."
})

-- ABA: COLETAS MANUAIS
TabManual:CreateSection("Farm Manual")
TabManual:CreateButton({ Name = "Coletar Ouro", Callback = function() executarColetaMateriais("Gold") end })
TabManual:CreateButton({ Name = "Coletar Diamante", Callback = function() executarColetaMateriais("Diamond") end })
TabManual:CreateButton({ Name = "Coletar Cobre", Callback = function() executarColetaMateriais("Copper") end })
TabManual:CreateButton({ Name = "Coletar Esmeralda", Callback = function() executarColetaMateriais("Emerald") end })
TabManual:CreateButton({ Name = "Coletar Carne", Callback = function() executarColetaMateriais("Meat") end })

-- ABA: VISUAL & RASTREIO
TabVisual:CreateSection("ESP (Visuais)")
TabVisual:CreateToggle({
    Name = "ESP de Itens",
    CurrentValue = false,
    Flag = "ToggleESPMineriosNunes",
    Callback = function(Value) ESPAtivo = Value; if Value then atualizarESP() else limparESP() end end
})
TabVisual:CreateToggle({
    Name = "ESP de Jogadores",
    CurrentValue = false,
    Flag = "ToggleESPJogadoresNunes",
    Callback = function(Value) ESPJogadoresAtivo = Value; if Value then atualizarESPJogadores() else limparESPJogadores() end end
})
TabVisual:CreateToggle({
    Name = "ESP de Portões",
    CurrentValue = false,
    Flag = "ToggleESPPortoesNunes",
    Callback = function(Value) ESPPortoesAtivo = Value; if Value then atualizarESPPortoes() else limparESPPortoes() end end
})
TabVisual:CreateToggle({
    Name = "ESP de Monstros",
    CurrentValue = false,
    Flag = "ToggleESPMonstrosNunes",
    Callback = function(Value) ESPMonstrosAtivo = Value; if Value then atualizarESPMonstros() else limparESPMonstros() end end
})
TabVisual:CreateToggle({
    Name = "ESP do Elevador",
    CurrentValue = false,
    Flag = "ToggleESPElevadorNunes",
    Callback = function(Value) ESPElevadorAtivo = Value; if Value then atualizarESPElevador() else limparESPElevador() end end
})

-- ABA: CONTROLE DE PORTÕES
TabPortoes:CreateSection("Portões")
TabPortoes:CreateButton({
    Name = "Abrir/Fechar Todos os Portões",
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
    TabPortoes:CreateButton({ Name = "Abrir/Fechar Portão " .. i, Callback = function() acionarPortaoEspecifico(i) end })
end

-- ABA: CONTROLE DO ELEVADOR
TabElevador:CreateSection("Controle e Teleporte")
TabElevador:CreateButton({
    Name = "Teleportar para o Elevador",
    Callback = function()
        local elevador = encontrarElevador()
        local hrp = getHRP()
        if hrp and elevador then
            local alvo = elevador:FindFirstChild("BaseDoElevador") or elevador:FindFirstChild("DButton") or elevador
            local parteAlvo = alvo:IsA("BasePart") and alvo or alvo:FindFirstChildWhichIsA("BasePart", true)
            
            if parteAlvo then
                hrp.CFrame = parteAlvo.CFrame + Vector3.new(0, 4, 0)
                logarAcao("Elevador", "Teleportado para o Elevador!", 1.5)
            else
                logarAcao("Erro", "Não foi possível calcular a posição de teleporte.", 2)
            end
        else
            logarAcao("Aviso", "Elevador não encontrado no diretório correto.", 2.5)
        end
    end
})

TabElevador:CreateButton({
    Name = "Subir (Cima)",
    Callback = function()
        local elevador = encontrarElevador()
        if elevador then
            local uButton = elevador:FindFirstChild("UButton") or (elevador:GetChildren()[4])
            if uButton then
                interagirComObjeto(uButton)
                logarAcao("Elevador", "Comando enviado para Subir!", 1.5)
            else
                logarAcao("Erro", "Botão de Subir (UButton) não encontrado.", 2)
            end
        else
            logarAcao("Aviso", "Elevador não encontrado.", 2)
        end
    end
})

TabElevador:CreateButton({
    Name = "Descer (Baixo)",
    Callback = function()
        local elevador = encontrarElevador()
        if elevador then
            local dButton = elevador:FindFirstChild("DButton")
            if dButton then
                interagirComObjeto(dButton)
                logarAcao("Elevador", "Comando enviado para Descer!", 1.5)
            else
                logarAcao("Erro", "Botão de Descer (DButton) não encontrado.", 2)
            end
        else
            logarAcao("Aviso", "Elevador não encontrado.", 2)
        end
    end
})

-- =============================================================================
-- ABA: UTILIDADES GERAIS (ATUALIZADA COM NOVAS OPÇÕES)
-- =============================================================================
TabGeral:CreateSection("Interações Especiais")

-- NOVA OPÇÃO: PEGAR LANTERNA
TabGeral:CreateButton({
    Name = "Pegar Lanterna",
    Callback = function()
        local lightModel = workspace:FindFirstChild("Light")
        if lightModel then
            local prompt = lightModel:FindFirstChild("ProximityPrompt") or lightModel:FindFirstChildOfClass("ProximityPrompt", true)
            if prompt then
                local hrp = getHRP()
                if hrp then
                    -- Teleporta temporariamente bem perto para garantir o alcance do prompt
                    local posOriginal = hrp.CFrame
                    local parteAlvo = lightModel:IsA("BasePart") and lightModel or lightModel:FindFirstChildWhichIsA("BasePart", true)
                    if parteAlvo then
                        hrp.CFrame = parteAlvo.CFrame
                        task.wait(0.1)
                        fireproximityprompt(prompt)
                        task.wait(0.1)
                        hrp.CFrame = posOriginal
                        logarAcao("Lanterna", "Lanterna coletada com sucesso!", 2)
                    end
                end
            else
                logarAcao("Erro", "ProximityPrompt da Lanterna não encontrado.", 2)
            end
        else
            logarAcao("Aviso", "Objeto 'Light' não encontrado no workspace.", 2.5)
        end
    end
})

-- NOVA OPÇÃO: REVIVER (VOLTAR PARA A ÚLTIMA MORTE)
TabGeral:CreateButton({
    Name = "Reviver (Voltar Posição da Morte)",
    Callback = function()
        if UltimaPosicaoMorte then
            local hrp = getHRP()
            if hrp then
                hrp.CFrame = UltimaPosicaoMorte
                logarAcao("Teleporte", "Retornado com sucesso para o local da última morte!", 2)
            end
        else
            logarAcao("Aviso", "Nenhuma morte registrada nesta sessão ainda.", 3)
        end
    end
})

TabGeral:CreateSection("Visualização e Ambiente")

TabGeral:CreateToggle({
    Name = "Desbloquear Câmera (Zoom Livre)",
    CurrentValue = false,
    Flag = "ToggleTerceiraPessoa",
    Callback = function(Value) 
        TerceiraPessoaAtiva = Value 
        if TerceiraPessoaAtiva then
            LocalPlayer.CameraMode = Enum.CameraMode.Classic
            LocalPlayer.CameraMaxZoomDistance = 100000
            LocalPlayer.CameraMinZoomDistance = 0.5
            Camera.CameraType = Enum.CameraType.Custom
            
            LocalPlayer.CameraMinZoomDistance = 15
            task.wait(0.05)
            LocalPlayer.CameraMinZoomDistance = 0.5
            
            logarAcao("Câmera", "Câmera desbloqueada! Use a rolagem do mouse para controlar o zoom.")
        else
            LocalPlayer.CameraMaxZoomDistance = 128
            LocalPlayer.CameraMinZoomDistance = 0.5
            Camera.CameraType = Enum.CameraType.Custom
        end
    end
})

task.spawn(function()
    while true do
        task.wait(0.2)
        if TerceiraPessoaAtiva then
            if LocalPlayer.CameraMode ~= Enum.CameraMode.Classic then
                LocalPlayer.CameraMode = Enum.CameraMode.Classic
            end
            if LocalPlayer.CameraMaxZoomDistance < 100000 then
                LocalPlayer.CameraMaxZoomDistance = 100000
            end
        end
    end
end)

TabGeral:CreateButton({
    Name = "Brilho Máximo (Fullbright)",
    Callback = function()
        FullbrightAtivo = not FullbrightAtivo
        Lighting.Brightness = FullbrightAtivo and 2 or 1
        Lighting.ClockTime = FullbrightAtivo and 14 or 12
        Lighting.GlobalShadows = not FullbrightAtivo
    end
})
TabGeral:CreateToggle({
    Name = "Anti-Jumpscare",
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
    Name = "Skin Arco-Íris",
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
TabGeral:CreateSection("Locais")
TabGeral:CreateButton({
    Name = "Teleportar para o Spawn",
    Callback = function()
        local hrp = getHRP()
        if hrp and workspace:FindFirstChild("SpawnLocation") then hrp.CFrame = workspace.SpawnLocation.CFrame + Vector3.new(0, 3, 0) end
    end
})
TabGeral:CreateButton({ Name = "Vender Itens", Callback = function() acionarFluxoVendas() end })

-- ABA: DANÇAS & EMOTES
TabDancas:CreateSection("Chat")
local comandos = {
    {"Dança 1", "/e dance"},
    {"Dança 2", "/e dance2"},
    {"Dança 3", "/e dance3"},
    {"Acenar", "/e wave"},
    {"Comemorar", "/e cheer"},
    {"Rir", "/e laugh"},
    {"Apontar", "/e point"}
}
for _, cmd in ipairs(comandos) do
    TabDancas:CreateButton({ Name = cmd[1], Callback = function() enviarChat(cmd[2]) end })
end

-- =============================================================================
-- ESCUTAS DINÂMICAS DE EVENTOS
-- =============================================================================
workspace.DescendantAdded:Connect(function(desc)
    if ESPAtivo and desc.Parent and desc.Parent.Name == "Scraps" then pcall(atualizarESP) end
    if ESPPortoesAtivo and desc.Name == "Object_0" and desc.Parent and desc.Parent.Name == "ButtonDoor" then task.wait(0.2); pcall(atualizarESPPortoes) end
    if ESPElevadorAtivo and desc.Name == "Elevador" then task.wait(0.2); pcall(atualizarESPElevador) end
end)

workspace.DescendantRemoving:Connect(function(desc)
    if ESPAtivo and desc.Parent and desc.Parent.Name == "Scraps" then pcall(atualizarESP) end
    if ESPPortoesAtivo and desc.Name == "Object_0" then pcall(atualizarESPPortoes) end
    if ESPElevadorAtivo and desc.Name == "Elevador" then pcall(atualizarESPElevador) end
end)

Players.PlayerAdded:Connect(function() if ESPJogadoresAtivo then task.wait(1); pcall(atualizarESPJogadores) end end)
Players.PlayerRemoving:Connect(function() if ESPJogadoresAtivo then pcall(atualizarESPJogadores) end end)

-- Cache de Serviços Globais (Melhor performance de memória)
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local TextChatService = game:GetService("TextChatService")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Inicialização Segura da UI Library
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Lethal Ape",
    LoadingTitle = "Carregando Lethal Ape",
    LoadingSubtitle = "Por favor, aguarde...",
    ConfigurationSaving = { Enabled = false }
})

-- Categorias e Seções Organizadas
local TabFarm = Window:CreateTab("Farm Automático", 4483362458)
local TabManual = Window:CreateTab("Farm Manual", 4483362458)
local TabPlayers = Window:CreateTab("Controle de Jogadores", 4483362458)
local TabVisual = Window:CreateTab("ESP (Visuais)", 4483362458)
local TabPortoes = Window:CreateTab("Portões", 4483362458)
local TabElevador = Window:CreateTab("Elevador", 4483362458) 
local TabGeral = Window:CreateTab("Geral", 4483362458)
local TabDancas = Window:CreateTab("Emotes", 4483362458)
local TabChaos = Window:CreateTab("Troll", 4483362458)

-- Estados Globais (Booleans estruturados)
local AutoFarmAtivo = false
local AutoHopFarmAtivo = false
local FullbrightAtivo = false
local LoopColorirAtivo = false
local TerceiraPessoaAtiva = false 
local SpectateAtivo = false

local ESPAtivo = false
local ESPMonstrosAtivo = false
local ESPPortoesAtivo = false
local ESPJogadoresAtivo = false
local ESPElevadorAtivo = false 
local AntijumpscareAtivo = false

local ChaosPortasAtivo = false
local ChaosElevadorAtivo = false
local ChaosJumpscareAtivo = false

-- Variáveis de Controle e Cache Dinâmico
local JogadorSelecionadoNome = ""
local DropdownJogadores = nil
local ParagrafoPerfil = nil
local UltimaPosicaoMorte = nil

local ArmazenamentoESP = {}
local ArmazenamentoESPMonstros = {}
local ArmazenamentoESPPortoes = {}
local ArmazenamentoESPJogadores = {}
local ArmazenamentoESPElevador = {} 

local flyVelocity, flyGyro

-- Filtro Rígido de Itens
local mineriosPermitidos = { 
    ["gold"] = true, 
    ["diamond"] = true, 
    ["copper"] = true,
    ["emerald"] = true,
    ["meat"] = true
}

-- Central de Warnings Visuais
local function logarAcao(titulo, texto, duracao)
    Rayfield:Notify({
        Title = titulo,
        Content = texto,
        Duration = duracao or 2.5,
        Image = 4483362458,
    })
end

-- Obtenção Rápida e Segura do HumanoidRootPart
local function getHRP()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    return char and char:WaitForChild("HumanoidRootPart", 5)
end

-- Server Hop Comum Seguro
local function pularServidor()
    logarAcao("AutoHop", "Buscando um novo servidor público...", 4)
    task.wait(0.5)
    pcall(function()
        local dadosBrutos = game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Desc&limit=100")
        local tps = HttpService:JSONDecode(dadosBrutos)
        for _, server in ipairs(tps.data) do
            if server.playing < server.maxPlayers and server.id ~= game.JobId then
                if writefile then pcall(function() writefile("LethalApe_AutoHop.txt", "true") end) end
                TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, LocalPlayer)
                break
            end
        end
    end)
end

-- Varredura Instantânea de Servidor Vazio (Otimização Máxima)
local function criarServidorPrivado()
    logarAcao("Servidor Privado", "Varredura instantânea de servidores vazios...", 2)
    task.wait(0.1)
    
    local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
    local servidorAlvoId = nil
    
    pcall(function()
        local dadosBrutos = game:HttpGet(url)
        local dadosJson = HttpService:JSONDecode(dadosBrutos)
        
        if dadosJson and dadosJson.data then
            for _, server in ipairs(dadosJson.data) do
                if server.id ~= game.JobId and server.playing < server.maxPlayers then
                    -- Prioridade máxima: servidor com 0 pessoas. Segunda opção: 1 pessoa.
                    if server.playing == 0 then
                        servidorAlvoId = server.id
                        break
                    elseif server.playing == 1 and not servidorAlvoId then
                        servidorAlvoId = server.id
                    end
                end
            end
        end
    end)
    
    if servidorAlvoId then
        logarAcao("Servidor Privado", "Iniciando teleporte imediato!", 2)
        TeleportService:TeleportToPlaceInstance(game.PlaceId, servidorAlvoId, LocalPlayer)
    else
        logarAcao("Aviso", "Nenhum servidor isolado na primeira página. Tentando Server Hop...", 3)
        pularServidor()
    end
end

-- Monitoramento de Morte Estruturado
local function monitorarMorte(character)
    local humanoid = character:WaitForChild("Humanoid", 10)
    local hrp = character:WaitForChild("HumanoidRootPart", 10)
    if humanoid and hrp then
        humanoid.Died:Connect(function()
            UltimaPosicaoMorte = hrp.CFrame
            logarAcao("Sistema de Morte", "Posição salva! Use 'Reviver' para retornar.", 4)
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

-- Voo Auxiliar Sem Lag
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

-- Ativador de Prompts Direto
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

local function encontrarElevador()
    local mapaElevador = workspace:FindFirstChild("Mapa") and workspace.Mapa:FindFirstChild("Elevador")
    if mapaElevador then return mapaElevador end
    return workspace:FindFirstChild("Elevador") or workspace:FindFirstChild("elevator")
end

local function itemEstaAtivoNoMundo(objeto)
    if not objeto or not objeto.Parent then return false end
    local parte = objeto:IsA("BasePart") and objeto or objeto:FindFirstChildWhichIsA("BasePart", true)
    if not parte then return false end
    if parte.Transparency >= 0.9 and not parte.CanCollide and not parte.CanTouch then
        return false
    end
    return true
end

-- Coleta Otimizada por Vetores (Anti-Void)
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
    
    local posicaoAnteriorSegura = hrp.CFrame
    ativarFlyTemporario(hrp)

    for _, obj in ipairs(alvos) do
        if itemEstaAtivoNoMundo(obj) then
            local parte = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart", true)
            if parte then
                hrp.CFrame = parte.CFrame + Vector3.new(0, 2, 0)
                if flyVelocity then flyVelocity.Velocity = Vector3.new(0, 0, 0) end
                task.wait(0.02)

                local tentatives = 0
                repeat
                    interagirComObjeto(obj)
                    task.wait(0.02)
                    tentatives = tentatives + 1
                until not obj or not obj.Parent or not itemEstaAtivoNoMundo(obj) or tentatives > 8
            end
        end
    end
    
    hrp.CFrame = posicaoAnteriorSegura
    task.wait(0.02)
    desativarFlyTemporario()
end

-- Fluxo de Venda Rápido
local function acionarFluxoVendas()
    local hrp = getHRP()
    local char = LocalPlayer.Character
    local mochila = LocalPlayer:FindFirstChild("Backpack")
    if not char or not mochila or not hrp then return end

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

    local posicaoAntesVenda = hrp.CFrame
    local parteAlvo = botaoVender:IsA("BasePart") and botaoVender or botaoVender:FindFirstChildWhichIsA("BasePart", true)
    
    if parteAlvo then
        ativarFlyTemporario(hrp)
        hrp.CFrame = parteAlvo.CFrame + Vector3.new(0, 3, 0)
        task.wait(0.2)
    end

    ferramentas = mochila:GetChildren()
    for _, item in ipairs(ferramentas) do
        if item:IsA("Tool") and mineriosPermitidos[string.lower(item.Name)] then
            item.Parent = char
            task.wait(0.01)
         
            local tentatives = 0
            repeat
                interagirComObjeto(botaoVender)
                task.wait(0.02)
                tentatives = tentatives + 1
            until item.Parent ~= char or not item or tentatives > 6
        end
    end
    
    hrp.CFrame = posicaoAntesVenda
    task.wait(0.02)
    desativarFlyTemporario()
    logarAcao("Venda", "Mochila limpa e processada!", 1.5)
end

-- Loop de Farm Unificado Anti-Lag
task.spawn(function()
    while true do
        task.wait(0.4)
        if AutoFarmAtivo or AutoHopFarmAtivo then
            pcall(function()
                local hrp = getHRP()
                if hrp then
                    local posAntesDoCiclo = hrp.CFrame
                    
                    executarColetaMateriais("Gold")
                    executarColetaMateriais("Diamond")
                    executarColetaMateriais("Copper")
                    executarColetaMateriais("Emerald")
                    executarColetaMateriais("Meat")
                    
                    task.wait(0.1)
                    acionarFluxoVendas()
                    
                    if AutoFarmAtivo or AutoHopFarmAtivo then
                        local hrpAtual = getHRP()
                        if hrpAtual then hrpAtual.CFrame = posAntesDoCiclo end
                    end

                    if AutoHopFarmAtivo then
                        if delfile then pcall(function() pcall(delfile, "LethalApe_AutoHop.txt") end) end
                        pularServidor()
                    end
                end
            end)
        end
    end
end)

-- Loops de Caos (Com micro-delays para não crashar)
task.spawn(function()
    while true do
        task.wait(0.08)
        if ChaosPortasAtivo then
            pcall(function()
                for _, obj in ipairs(workspace:GetDescendants()) do
                    if obj.Name == "ButtonDoor" then
                        local b = obj:FindFirstChild("Button")
                        if b then interagirComObjeto(b) end
                    end
                end
            end)
        end
    end
end)

task.spawn(function()
    while true do
        if ChaosElevadorAtivo then
            pcall(function()
                local elevador = encontrarElevador()
                if elevador then
                    local uButton = elevador:FindFirstChild("UButton") or (elevador:GetChildren()[4])
                    local dButton = elevador:FindFirstChild("DButton")
                    
                    if uButton then interagirComObjeto(uButton) end
                    task.wait(0.2)
                    if dButton then interagirComObjeto(dButton) end
                    task.wait(0.2)
                end
            end)
        else
            task.wait(0.5)
        end
    end
end)

task.spawn(function()
    while true do
        if ChaosJumpscareAtivo then
            for _, alvo in ipairs(Players:GetPlayers()) do
                if alvo ~= LocalPlayer and alvo.Character and ChaosJumpscareAtivo then
                    pcall(function()
                        local meuHrp = getHRP()
                        local alvoHrp = alvo.Character:FindFirstChild("HumanoidRootPart")
                        if meuHrp and alvoHrp then
                            local posOriginal = meuHrp.CFrame
                            ativarFlyTemporario(meuHrp)
                            
                            meuHrp.CFrame = alvoHrp.CFrame * CFrame.new(0, 0, -2.5) * CFrame.Angles(0, math.pi, 0)
                            task.wait(0.1)
                            
                            meuHrp.CFrame = posOriginal
                            desativarFlyTemporario()
                        end
                    end)
                    task.wait(0.15)
                end
            end
        else
            task.wait(0.5)
        end
    end
end)

-- Manipulação Dinâmica de Dropdowns de Jogadores
local function obterListaJogadores()
    local lista = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            table.insert(lista, p.DisplayName .. " (@" .. p.Name .. ")")
        end
    end
    return lista
end

local function atualizarDropdownJogadores()
    if DropdownJogadores then
        DropdownJogadores:Refresh(obterListaJogadores(), true)
    end
end

Players.PlayerAdded:Connect(atualizarDropdownJogadores)
Players.PlayerRemoving:Connect(function(player)
    if player.Name == JogadorSelecionadoNome then
        JogadorSelecionadoNome = ""
        SpectateAtivo = false
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            Camera.CameraSubject = char.Humanoid
        end
        if ParagrafoPerfil then
            ParagrafoPerfil:Set({Title = "Nenhum Alvo Selecionado", Content = "Escolha um jogador acima."})
        end
    end
    atualizarDropdownJogadores()
end)

-- Sistema de Gerenciamento de Memória Visual (ESP Limpo Sem Latência)
local function limparCacheESP(tabela)
    for _, esp in ipairs(tabela) do
        if esp then pcall(function() esp:Destroy() end) end
    end
    return {}
end

local function atualizarESP()
    if not ESPAtivo then ArmazenamentoESP = limparCacheESP(ArmazenamentoESP) return end
    local scraps = workspace:FindFirstChild("Scraps")
    if not scraps then return end

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
                highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                highlight.Adornee = obj
                highlight.Parent = obj
                table.insert(ArmazenamentoESP, highlight)
            end
        end
    end
end

local function atualizarESPJogadores()
    ArmazenamentoESPJogadores = limparCacheESP(ArmazenamentoESPJogadores)
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
    local directMonsters = {
        Dus = workspace:FindFirstChild("DusMonster") and workspace.DusMonster:FindFirstChild("Dus"),
        Gus = workspace:FindFirstChild("GusMonster") and workspace.GusMonster:FindFirstChild("Gus"),
        Kus = workspace:FindFirstChild("KusMonster") and workspace.KusMonster:FindFirstChild("Kus"),
        Lost = workspace:FindFirstChild("LostMonster") and workspace.LostMonster:FindFirstChild("Lost")
    }
    if directMonsters[nome] then return directMonsters[nome] end
    local pastaSandman = workspace:FindFirstChild("Sandman/Ashy")
    return pastaSandman and pastaSandman:FindFirstChild(nome) or workspace:FindFirstChild(nome)
end

local function atualizarESPMonstros()
    ArmazenamentoESPMonstros = limparCacheESP(ArmazenamentoESPMonstros)
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

local function atualizarESPPortoes()
    ArmazenamentoESPPortoes = limparCacheESP(ArmazenamentoESPPortoes)
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

local function atualizarESPElevador()
    ArmazenamentoESPElevador = limparCacheESP(ArmazenamentoESPElevador)
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

-- Thread Concentrada Visual (Anti Frame-Drop)
task.spawn(function()
    while true do 
        task.wait(0.5)
        if ESPJogadoresAtivo then pcall(atualizarESPJogadores) end
        if ESPAtivo then pcall(atualizarESP) end
        if ESPMonstrosAtivo then pcall(atualizarESPMonstros) end
        if ESPPortoesAtivo then pcall(atualizarESPPortoes) end
        if ESPElevadorAtivo then pcall(atualizarESPElevador) end 
    end
end)

local function acionarPortaoEspecifico(idPortao)
    local contador = 1
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj.Name == "ButtonDoor" then
            if contador == idPortao then
                local button = obj:FindFirstChild("Button")
                if button then interagirComObjeto(button) end
                break
            end
            contador = contador + 1
        end
    end
end

-- =============================================================================
-- MONTAGEM COMPACTA DA INTERFACE
-- =============================================================================

-- ABA: FARM AUTOMÁTICO
TabFarm:CreateSection("Automação")
TabFarm:CreateToggle({
    Name = "Farm Automático (Normal)",
    CurrentValue = false,
    Flag = "ToggleAutoFarmSupremo",
    Callback = function(Value) AutoFarmAtivo = Value end
})

local ToggleAutoHop = TabFarm:CreateToggle({
    Name = "AutoHopFarm (Próximo Server)",
    CurrentValue = false,
    Flag = "ToggleAutoHopFarm",
    Callback = function(Value)
        AutoHopFarmAtivo = Value
        if AutoHopFarmAtivo and writefile then
            pcall(function() writefile("LethalApe_AutoHop.txt", "true") end)
        elseif delfile then
            pcall(function() delfile("LethalApe_AutoHop.txt") end)
        end
    end
})

TabFarm:CreateButton({
    Name = "Criar Servidor Privado (Vazio)",
    Callback = criarServidorPrivado
})

TabFarm:CreateParagraph({
    Title = "Informação do Servidor Privado",
    Content = "Faz uma única busca ultra-rápida de 100 servidores direto da API do Roblox filtrando apenas instâncias vazias para seu farm solo."
})

-- ABA: FARM MANUAL
TabManual:CreateSection("Farm Manual")
TabManual:CreateButton({ Name = "Coletar Ouro", Callback = function() executarColetaMateriais("Gold") end })
TabManual:CreateButton({ Name = "Coletar Diamante", Callback = function() executarColetaMateriais("Diamond") end })
TabManual:CreateButton({ Name = "Coletar Cobre", Callback = function() executarColetaMateriais("Copper") end })
TabManual:CreateButton({ Name = "Coletar Esmeralda", Callback = function() executarColetaMateriais("Emerald") end })
TabManual:CreateButton({ Name = "Coletar Carne", Callback = function() executarColetaMateriais("Meat") end })

-- ABA: CONTROLE DE JOGADORES
TabPlayers:CreateSection("Alvos Disponíveis")
DropdownJogadores = TabPlayers:CreateDropdown({
    Name = "Selecionar Jogador",
    Options = obterListaJogadores(),
    CurrentOption = "",
    MultipleOptions = false,
    Flag = "DropdownJogadoresServidorV4",
    Callback = function(Option)
        local selecao = type(Option) == "table" and Option[1] or Option
        if selecao and selecao ~= "" then
            local usuarioTratado = string.match(selecao, "@([^)]+)")
            if usuarioTratado then
                JogadorSelecionadoNome = usuarioTratado
                local alvoInstancia = Players:FindFirstChild(JogadorSelecionadoNome)
                if alvoInstancia and ParagrafoPerfil then
                    ParagrafoPerfil:Set({
                        Title = alvoInstancia.DisplayName,
                        Content = "@" .. alvoInstancia.Name,
                        Image = "rbxthumb://type=Avatar&id=" .. alvoInstancia.UserId .. "&w=420&h=420"
                    })
                end
            end
        end
    end,
})

ParagrafoPerfil = TabPlayers:CreateParagraph({
    Title = "Nenhum Alvo Selecionado",
    Content = "Escolha um jogador no menu acima.",
    Image = "rbxassetid://4483362458"
})

TabPlayers:CreateSection("Ações Interativas")
TabPlayers:CreateToggle({
    Name = "Ver Jogador (Spectate)",
    CurrentValue = false,
    Flag = "ToggleSpectateJogador",
    Callback = function(Value)
        SpectateAtivo = Value
        if SpectateAtivo and JogadorSelecionadoNome ~= "" then
            local alvo = Players:FindFirstChild(JogadorSelecionadoNome)
            if alvo and alvo.Character and alvo.Character:FindFirstChild("Humanoid") then
                Camera.CameraSubject = alvo.Character.Humanoid
            end
        elseif LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            Camera.CameraSubject = LocalPlayer.Character.Humanoid
        end
    end
})

TabPlayers:CreateButton({
    Name = "Teleportar para o Jogador",
    Callback = function()
        if JogadorSelecionadoNome ~= "" then
            local alvo = Players:FindFirstChild(JogadorSelecionadoNome)
            local meuHrp = getHRP()
            if alvo and alvo.Character and meuHrp then
                local alvoHrp = alvo.Character:FindFirstChild("HumanoidRootPart")
                if alvoHrp then meuHrp.CFrame = alvoHrp.CFrame + Vector3.new(0, 2, 0) end
            end
        end
    end
})

TabPlayers:CreateButton({
    Name = "Dar Jumpscare (Susto Efêmero)",
    Callback = function()
        if JogadorSelecionadoNome ~= "" then
            local alvo = Players:FindFirstChild(JogadorSelecionadoNome)
            local meuHrp = getHRP()
            if alvo and alvo.Character and meuHrp then
                local alvoHrp = alvo.Character:FindFirstChild("HumanoidRootPart")
                if alvoHrp then
                    local posAntes = meuHrp.CFrame
                    ativarFlyTemporario(meuHrp)
                    meuHrp.CFrame = alvoHrp.CFrame * CFrame.new(0, 0, -2.5) * CFrame.Angles(0, math.pi, 0)
                    task.wait(0.2)
                    meuHrp.CFrame = posAntes
                    task.wait(0.02)
                    desativarFlyTemporario()
                end
            end
        end
    end
})

-- ABA: VISUAIS
TabVisual:CreateSection("ESP (Visuais)")
TabVisual:CreateToggle({ Name = "ESP de Itens", CurrentValue = false, Flag = "ToggleESPMineriosNunes", Callback = function(V) ESPAtivo = V; atualizarESP() end })
TabVisual:CreateToggle({ Name = "ESP de Jogadores", CurrentValue = false, Flag = "ToggleESPJogadoresNunes", Callback = function(V) ESPJogadoresAtivo = V; atualizarESPJogadores() end })
TabVisual:CreateToggle({ Name = "ESP de Portões", CurrentValue = false, Flag = "ToggleESPPortoesNunes", Callback = function(V) ESPPortoesAtivo = V; atualizarESPPortoes() end })
TabVisual:CreateToggle({ Name = "ESP de Monstros", CurrentValue = false, Flag = "ToggleESPMonstrosNunes", Callback = function(V) ESPMonstrosAtivo = V; atualizarESPMonstros() end })
TabVisual:CreateToggle({ Name = "ESP do Elevador", CurrentValue = false, Flag = "ToggleESPElevadorNunes", Callback = function(V) ESPElevadorAtivo = V; atualizarESPElevador() end })

-- ABA: PORTÕES
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

-- ABA: ELEVADOR
TabElevador:CreateSection("Controle e Teleporte")
TabElevador:CreateButton({
    Name = "Teleportar para o Elevador",
    Callback = function()
        local elevador = encontrarElevador()
        local hrp = getHRP()
        if hrp and elevador then
            local alvo = elevador:FindFirstChild("BaseDoElevador") or elevador:FindFirstChild("DButton") or elevador
            local parteAlvo = alvo:IsA("BasePart") and alvo or alvo:FindFirstChildWhichIsA("BasePart", true)
            if parteAlvo then hrp.CFrame = parteAlvo.CFrame + Vector3.new(0, 4, 0) end
        end
    end
})
TabElevador:CreateButton({
    Name = "Subir (Cima)",
    Callback = function()
        local elevador = encontrarElevador()
        if elevador then
            local uButton = elevador:FindFirstChild("UButton") or (elevador:GetChildren()[4])
            if uButton then interagirComObjeto(uButton) end
        end
    end
})
TabElevador:CreateButton({
    Name = "Descer (Baixo)",
    Callback = function()
        local elevador = encontrarElevador()
        if elevador then
            local dButton = elevador:FindFirstChild("DButton")
            if dButton then interagirComObjeto(dButton) end
        end
    end
})

-- ABA: UTILIDADES GERAIS
TabGeral:CreateSection("Interações Especiais")
TabGeral:CreateButton({
    Name = "Pegar Lanterna",
    Callback = function()
        local lightModel = workspace:FindFirstChild("Light")
        local prompt = lightModel and (lightModel:FindFirstChild("ProximityPrompt") or lightModel:FindFirstChildOfClass("ProximityPrompt", true))
        local hrp = getHRP()
        if hrp and prompt then
            local posOriginal = hrp.CFrame
            local parteAlvo = lightModel:IsA("BasePart") and lightModel or lightModel:FindFirstChildWhichIsA("BasePart", true)
            if parteAlvo then
                ativarFlyTemporario(hrp)
                hrp.CFrame = parteAlvo.CFrame
                task.wait(0.08)
                fireproximityprompt(prompt)
                task.wait(0.08)
                hrp.CFrame = posOriginal
                task.wait(0.02)
                desativarFlyTemporario()
            end
        end
    end
})

TabGeral:CreateButton({
    Name = "Reviver (Voltar Posição da Morte)",
    Callback = function()
        local hrp = getHRP()
        if hrp and UltimaPosicaoMorte then hrp.CFrame = UltimaPosicaoMorte end
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
        else
            LocalPlayer.CameraMaxZoomDistance = 128
        end
    end
})

-- Loop de Gerenciamento da Camera Render
task.spawn(function()
    while true do
        task.wait(0.2)
        if TerceiraPessoaAtiva then
            if LocalPlayer.CameraMode ~= Enum.CameraMode.Classic then LocalPlayer.CameraMode = Enum.CameraMode.Classic end
            if LocalPlayer.CameraMaxZoomDistance < 100000 then LocalPlayer.CameraMaxZoomDistance = 100000 end
        end
        if SpectateAtivo and JogadorSelecionadoNome ~= "" then
            local alvo = Players:FindFirstChild(JogadorSelecionadoNome)
            if alvo and alvo.Character and alvo.Character:FindFirstChild("Humanoid") then
                if Camera.CameraSubject ~= alvo.Character.Humanoid then
                    Camera.CameraSubject = alvo.Character.Humanoid
                end
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
                            if scr then pcall(function() scr:Destroy() end) end
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
                        if string.lower(o.Name) == "colorir" then interagirComObjeto(o); task.wait(0.2) end
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
TabGeral:CreateButton({ Name = "Vender Itens", Callback = acionarFluxoVendas })

-- ABA: EMOTES
TabDancas:CreateSection("Chat")
local comandos = {
    {"Dança 1", "/e dance"}, {"Dança 2", "/e dance2"}, {"Dança 3", "/e dance3"},
    {"Acenar", "/e wave"}, {"Comemorar", "/e cheer"}, {"Rir", "/e laugh"}, {"Apontar", "/e point"}
}
for _, cmd in ipairs(comandos) do
    TabDancas:CreateButton({ Name = cmd[1], Callback = function() enviarChat(cmd[2]) end })
end

-- ABA: MUNDO DO CAOS
TabChaos:CreateSection("Loops")
TabChaos:CreateToggle({ Name = "Loop: de Portas (Spam)", CurrentValue = false, Flag = "ChaosPortasSpam", Callback = function(V) ChaosPortasAtivo = V end })
TabChaos:CreateToggle({ Name = "Loop: Elevador Maluco (Cima/Baixo)", CurrentValue = false, Flag = "ChaosElevadorSpam", Callback = function(V) ChaosElevadorAtivo = V end })
TabChaos:CreateSection("Loops de Jogadores")
TabChaos:CreateToggle({ Name = "Loop: Jumpscare em Massa", CurrentValue = false, Flag = "ChaosJumpscareSpam", Callback = function(V) ChaosJumpscareAtivo = V end })

-- Ouvintes Síncronos do Ambiente (Otimizados)
workspace.DescendantAdded:Connect(function(desc)
    if ESPAtivo and desc.Parent and desc.Parent.Name == "Scraps" then pcall(atualizarESP) end
end)
workspace.DescendantRemoving:Connect(function(desc)
    if ESPAtivo and desc.Parent and desc.Parent.Name == "Scraps" then pcall(atualizarESP) end
end)

-- Auto-Load Verificação de Rotação
if readfile and isfile and isfile("LethalApe_AutoHop.txt") then
    local status = readfile("LethalApe_AutoHop.txt")
    if status == "true" then
        task.spawn(function()
            repeat task.wait(0.5) until ToggleAutoHop ~= nil
            ToggleAutoHop:Set(true)
            logarAcao("AutoHop", "Servidor Rotacionado! Farm reativado.", 3)
        end)
    end
end

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "NunesUI - Painel de Controle Completo",
    LoadingTitle = "NunesUI Admin v3.0",
    LoadingSubtitle = "Sistema Inteligente Anti-Lag",
    ConfigurationSaving = {
        Enabled = false
    }
})

-- Categorias de Interface Totalmente Autoexplicativas
local TabGeral = Window:CreateTab("Utilidades Gerais", 4483362458)
local TabColeta = Window:CreateTab("Coleta Automática", 4483362458)
local TabVenda = Window:CreateTab("Venda Automatizada", 4483362458)
local TabVisual = Window:CreateTab("Visual & Rastreamento", 4483362458)
local TabMonstros = Window:CreateTab("Teleportes & Monstros", 4483362458) -- Nova Aba

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Estados Globais
local LoopColorirAtivo = false
local ESPAtivo = false
local ESPMonstrosAtivo = false -- Novo Estado
local ArmazenamentoESP = {}
local ArmazenamentoLinhas = {}
local ArmazenamentoESPMonstros = {} -- Novo Armazenamento

-- Filtro Rígido de Materiais Aceitos (Estritamente em Minúsculo)
local mineriosPermitidos = { ["gold"] = true, ["diamond"] = true, ["copper"] = true }

-- Sistema Central de Logs e Notificações
local function logarAcao(titulo, texto, duracao)
    Rayfield:Notify({
        Title = titulo,
        Content = texto,
        Duration = duracao or 2.5,
        Image = 4483362458,
    })
end

local function getHRP()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    return char:WaitForChild("HumanoidRootPart", 5)
end

-- Mecanismo de Interação com Redundância Contra Oscilações de Conexão
local function interagirComObjeto(instancia)
    if not instancia then return end
    
    local prompt = instancia:IsA("ProximityPrompt") and instancia or instancia:FindFirstChildOfClass("ProximityPrompt", true)
    if prompt then fireproximityprompt(prompt) end
    
    local cd = instancia:IsA("ClickDetector") and instancia or instancia:FindFirstChildOfClass("ClickDetector", true)
    if cd then fireclickdetector(cd) end

    local parte = instancia:IsA("BasePart") and instancia or instancia:FindFirstChildWhichIsA("BasePart", true)
    if parte then
        local touchInterest = parte:FindFirstChildOfClass("TouchInterest")
        if touchInterest then
            firetouchinterest(parte, getHRP(), 0)
            task.wait(0.03)
            firetouchinterest(parte, getHRP(), 1)
        end
    end
end

local function encontrarReciclador()
    for _, obj in ipairs(workspace:GetChildren()) do
        if obj:FindFirstChild("Recycle item") then
            return obj, obj:FindFirstChild("Recycle item")
        end
    end
    return nil, nil
end

-- Validador Físico Antifantasma
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
-- GERENCIADOR DE ESP E TRACERS (MINÉRIOS)
-- =============================================================================

local function limparESP()
    for _, esp in ipairs(ArmazenamentoESP) do
        if esp then esp:Destroy() end
    end
    ArmazenamentoESP = {}

    for _, linha in ipairs(ArmazenamentoLinhas) do
        if linha and linha.Linha then 
            pcall(function() linha.Linha:Remove() end) 
        end
    end
    ArmazenamentoLinhas = {}
end

local function atualizarESP()
    limparESP()
    if not ESPAtivo then return end

    local scraps = workspace:FindFirstChild("Scraps")
    if not scraps then return end

    for _, obj in ipairs(scraps:GetChildren()) do
        if itemEstaAtivoNoMundo(obj) then
            local nomeL = string.lower(obj.Name)
            local corMaterial = nil

            if nomeL == "gold" then corMaterial = Color3.fromRGB(255, 215, 0)
            elseif nomeL == "diamond" then corMaterial = Color3.fromRGB(0, 238, 255)
            elseif nomeL == "copper" then corMaterial = Color3.fromRGB(211, 84, 0) end

            if corMaterial then
                local highlight = Instance.new("Highlight")
                highlight.Name = "Nunes_ESP"
                highlight.FillColor = corMaterial
                highlight.FillTransparency = 0.7
                highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                highlight.OutlineTransparency = 0
                highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                highlight.Adornee = obj
                highlight.Parent = obj
                table.insert(ArmazenamentoESP, highlight)

                local parteFisica = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart", true)
                if parteFisica then
                    local linhaTracer = Drawing.new("Line")
                    linhaTracer.Visible = false
                    linhaTracer.Color = Color3.fromRGB(255, 255, 255)
                    linhaTracer.Thickness = 1.5
                    linhaTracer.Transparency = 0.7
                    
                    table.insert(ArmazenamentoLinhas, {Linha = linhaTracer, Alvo = parteFisica})
                end
            end
        end
    end
end

-- =============================================================================
-- GERENCIADOR NOVO: ESP DE MONSTROS
-- =============================================================================

local function limparESPMonstros()
    for _, esp in ipairs(ArmazenamentoESPMonstros) do
        if esp then esp:Destroy() end
    end
    ArmazenamentoESPMonstros = {}
end

local function atualizarESPMonstros()
    limparESPMonstros()
    if not ESPMonstrosAtivo then return end

    -- Caminhos exatos fornecidos por você
    local caminhosMonstros = {
        "workspace.DusMonster.Dus",
        "workspace.GusMonster.Gus",
        "workspace.KusMonster.Kus",
        "workspace.LostMonster.Lost"
    }

    for _, caminho in ipairs(caminhosMonstros) do
        pcall(function()
            local partes = string.split(caminho, ".")
            local atual = workspace
            
            -- Navega dinamicamente ignorando a palavra 'workspace' inicial do split
            for i = 2, #partes do
                if atual then
                    atual = atual:FindFirstChild(partes[i])
                end
            end

            -- Se achou o monstro, aplica o Highlight Vermelho de Alerta
            if atual and (atual:IsA("Model") or atual:IsA("BasePart")) then
                local highlight = Instance.new("Highlight")
                highlight.Name = "Nunes_MonsterESP"
                highlight.FillColor = Color3.fromRGB(255, 0, 0) -- Vermelho Alerta
                highlight.FillTransparency = 0.5
                highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                highlight.OutlineTransparency = 0
                highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                highlight.Adornee = atual
                highlight.Parent = atual
                table.insert(ArmazenamentoESPMonstros, highlight)
            end
        end)
    end
end

-- Thread em loop para manter o ESP de Monstros atualizado se eles se moverem/respawnarem
task.spawn(function()
    while task.wait(3) do
        if ESPMonstrosAtivo then
            atualizarESPMonstros()
        end
    end
end)

-- Processador Render-Step para os Tracers de Minérios
RunService.RenderStepped:Connect(function()
    if not ESPAtivo then return end
    
    local origemX = Camera.ViewportSize.X / 2
    local origemY = Camera.ViewportSize.Y

    for _, dados in ipairs(ArmazenamentoLinhas) do
        pcall(function()
            local linha = dados.Linha
            local alvo = dados.Alvo

            if alvo and alvo.Parent and itemEstaAtivoNoMundo(alvo.Parent) then
                local vetorTela, naTela = Camera:WorldToViewportPoint(alvo.Position)
                if naTela then
                    linha.From = Vector2.new(origemX, origemY)
                    linha.To = Vector2.new(vetorTela.X, vetorTela.Y)
                    linha.Visible = true
                else
                    linha.Visible = false
                end
            else
                linha.Visible = false
            end
        end)
    end
end)

-- =============================================================================
-- SISTEMA DE COLETA RESILIENTE
-- =============================================================================

local function executarColetaMateriais(nomeItem)
    local hrp = getHRP()
    if not hrp then return end
    
    local posOriginal = hrp.CFrame
    local scraps = workspace:FindFirstChild("Scraps")
    if not scraps then return logarAcao("Erro de Mapa", "A pasta 'Scraps' não foi localizada.") end

    local alvos = {}
    for _, obj in ipairs(scraps:GetChildren()) do
        if string.lower(obj.Name) == string.lower(nomeItem) and itemEstaAtivoNoMundo(obj) then
            table.insert(alvos, obj)
        end
    end

    local total = #alvos
    if total == 0 then return logarAcao("Coleta", "Nenhum " .. nomeItem .. " legítimo encontrado para extração.") end

    logarAcao("Fila de Coleta", "Iniciando recolhimento de " .. total .. " " .. nomeItem .. "(s).", 3)

    local contadorReal = 0
    for idx, obj in ipairs(alvos) do
        if itemEstaAtivoNoMundo(obj) then
            local parte = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart", true)
            if parte then
                hrp.CFrame = parte.CFrame
                task.wait(0.2)

                local tentativas = 0
                while obj and obj.Parent and itemEstaAtivoNoMundo(obj) and tentativas < 10 do
                    interagirComObjeto(obj)
                    task.wait(0.25)
                    tentativas = tentativas + 1
                end

                if not (obj and obj.Parent) or not itemEstaAtivoNoMundo(obj) then
                    contadorReal = contadorReal + 1
                    logarAcao("Logs de Coleta", "Sucesso: " .. contadorReal .. "/" .. total .. " " .. nomeItem .. " guardado.", 1)
                end
            end
        end
    end
    
    hrp.CFrame = posOriginal
    logarAcao("Coleta Encerrada", "Operação concluída. Coletados com êxito: " .. contadorReal .. " de " .. total, 3)
    atualizarESP()
end

-- =============================================================================
-- EXECUTOR DE VENDAS
-- =============================================================================

local function executarVendaDeMinerios(botaoVender)
    local char = LocalPlayer.Character
    local mochila = LocalPlayer:FindFirstChild("Backpack")
    if not char or not mochila then return end

    local ferramentas = mochila:GetChildren()
    local itensValidos = {}

    for _, item in ipairs(ferramentas) do
        if item:IsA("Tool") and mineriosPermitidos[string.lower(item.Name)] then
            table.insert(itensValidos, item)
        end
    end

    local totalVenda = #itensValidos
    if totalVenda == 0 then return end

    logarAcao("Balcão de Venda", "Processando lote de " .. totalVenda .. " minérios na esteira...", 3)

    for idx, item in ipairs(itensValidos) do
        local checagemPrevia = 0
        while char:FindFirstChildOfClass("Tool") and checagemPrevia < 15 do
            task.wait(0.1)
            checagemPrevia = checagemPrevia + 1
        end

        if item and item.Parent == mochila then
            item.Parent = char 
            
            local confirmacaoRede = 0
            while item.Parent ~= char and confirmacaoRede < 10 do
                task.wait(0.05)
                confirmacaoRede = confirmacaoRede + 1
            end

            task.wait(0.18) 
            interagirComObjeto(botaoVender)
            
            task.wait(0.35) 
            logarAcao("Logs de Venda", "Confirmado: " .. idx .. "/" .. totalVenda .. " | " .. item.Name .. " processado.", 1)
        end
    end
end

-- =============================================================================
-- CATEGORIA: UTILIDADES GERAIS
-- =============================================================================

local FullbrightAtivo = false
TabGeral:CreateButton({
    Name = "Alternar Fullbright (Remover Sombras e Névoa)",
    Callback = function()
        FullbrightAtivo = not FullbrightAtivo
        if FullbrightAtivo then
            Lighting.Brightness = 2
            Lighting.ClockTime = 14
            Lighting.GlobalShadows = false
            logarAcao("Ajuste Visual", "Brilho máximo ativado. Sombras desativadas.")
        else
            Lighting.Brightness = 1
            Lighting.ClockTime = 12
            Lighting.GlobalShadows = true
            logarAcao("Ajuste Visual", "Iluminação padrão do mapa restaurada.")
        end
    end
})

TabGeral:CreateButton({
    Name = "Interagir com as Portas (Teleporta e Aciona Sequencialmente)",
    Callback = function()
        local hrp = getHRP()
        local posOriginal = hrp.CFrame
        local executadas = 0

        for _, obj in ipairs(workspace:GetChildren()) do
            local buttonDoor = obj:FindFirstChild("ButtonDoor")
            local button = buttonDoor and buttonDoor:FindFirstChild("Button")
            if button and button:IsA("BasePart") then
                hrp.CFrame = button.CFrame
                task.wait(0.3)
                interagirComObjeto(button)
                executadas = executadas + 1
                logarAcao("Logs de Portas", "Modificando estado da porta n°: " .. executadas, 0.5)
            end
        end
        hrp.CFrame = posOriginal
        logarAcao("Portas Sincronizadas", "Varredura de mecanismos de portas encerrada.", 3)
    end
})

-- =============================================================================
-- CATEGORIA: COLETA AUTOMÁTICA
-- =============================================================================

TabColeta:CreateButton({ Name = "Teleportar e Coletar Todos os Ouros (Gold)", Callback = function() executarColetaMateriais("Gold") end })
TabColeta:CreateButton({ Name = "Teleportar e Coletar Todos os Diamantes (Diamond)", Callback = function() executarColetaMateriais("Diamond") end })
TabColeta:CreateButton({ Name = "Teleportar e Coletar Todos os Cobres (Copper)", Callback = function() executarColetaMateriais("Copper") end })

-- =============================================================================
-- CATEGORIA: VENDA AUTOMATIZADA
-- =============================================================================

TabVenda:CreateButton({
    Name = "Vender Itens Filtrados (Apenas Gold, Diamond, Copper)",
    Callback = function()
        local hrp = getHRP()
        local char = LocalPlayer.Character
        local mochila = LocalPlayer:FindFirstChild("Backpack")
        if not char or not mochila then return end

        local reciclador, botaoVender = encontrarReciclador()
        if not botaoVender then return logarAcao("Erro de Venda", "O balcão de reciclagem não foi detectado neste servidor.") end

        local parteAlvo = botaoVender:IsA("BasePart") and botaoVender or botaoVender:FindFirstChildWhichIsA("BasePart", true)
        if parteAlvo then
            hrp.CFrame = parteAlvo.CFrame + Vector3.new(0, 2, 0)
            task.wait(0.5)
        end

        executarVendaDeMinerios(botaoVender)

        task.wait(0.5)
        local ferramentasRestantes = mochila:GetChildren()
        local itemEsquecido = char:FindFirstChildOfClass("Tool")

        if itemEsquecido and mineriosPermitidos[string.lower(itemEsquecido.Name)] then
            logarAcao("Correção de Fila", "Limpando último item residual preso na mão...", 1.5)
            interagirComObjeto(botaoVender)
            task.wait(0.4)
        end

        for _, item in ipairs(ferramentasRestantes) do
            if item:IsA("Tool") and mineriosPermitidos[string.lower(item.Name)] then
                logarAcao("Correção de Fila", "Limpando último item residual na mochila: " .. item.Name, 1.5)
                item.Parent = char
                task.wait(0.2)
                interagirComObjeto(botaoVender)
                task.wait(0.4)
            end
        end

        logarAcao("Faturamento Finalizado", "Mochila verificada e limpa de minérios com sucesso!")
    end
})

-- =============================================================================
-- CATEGORIA: VISUAL & RASTREAMENTO
-- =============================================================================

TabVisual:CreateToggle({
    Name = "Ver Materiais (Contorno e Linhas Brancas em Minérios)",
    CurrentValue = false,
    Flag = "ToggleESPCompletoNunes",
    Callback = function(Value)
        ESPAtivo = Value
        if ESPAtivo then
            atualizarESP()
            logarAcao("Rastreamento", "ESP e Linhas Tracers de Minérios Ativados.")
        else
            limparESP()
            logarAcao("Rastreamento", "Filtros visuais limpos e desativados.")
        end
    end
})

TabVisual:CreateButton({
    Name = "Forçar Recalcular Mapa (Oculta Itens Coletados/Fantasmas)",
    Callback = function()
        if ESPAtivo then
            atualizarESP()
            logarAcao("Rastreamento", "Varredura refeita. Itens coletados por outros foram descartados.")
        else
            logarAcao("Aviso", "Ative a opção 'Ver Materiais' acima antes de atualizar.")
        end
    end
})

TabVisual:CreateToggle({
    Name = "Loop Alteração de Cores do Avatar (Sem Logs)",
    CurrentValue = false,
    Flag = "ToggleColorirNunes",
    Callback = function(Value)
        LoopColorirAtivo = Value
        if LoopColorirAtivo then
            task.spawn(function()
                while LoopColorirAtivo do
                    local botoesColorir = {}
                    for _, obj in ipairs(workspace:GetChildren()) do
                        if string.lower(obj.Name) == "colorir" then
                            table.insert(botoesColorir, obj)
                        end
                    end

                    for _, botao in ipairs(botoesColorir) do
                        if not LoopColorirAtivo then break end
                        interagirComObjeto(botao)
                        task.wait(0.3)
                    end
                    task.wait(0.1)
                end
            end)
        end
    end
})

-- =============================================================================
-- NOVA CATEGORIA: TELEPORTES & MONSTROS
-- =============================================================================

TabMonstros:CreateToggle({
    Name = "ESP Monstros (Dus, Gus, Kus, Lost)",
    CurrentValue = false,
    Flag = "ToggleESPMonstros",
    Callback = function(Value)
        ESPMonstrosAtivo = Value
        if ESPMonstrosAtivo then
            atualizarESPMonstros()
            logarAcao("Monstros", "Rastreamento de Entidades Ativado em Vermelho.")
        else
            limparESPMonstros()
            logarAcao("Monstros", "Rastreamento de Entidades Desativado.")
        end
    end
})

TabMonstros:CreateButton({
    Name = "Teleportar para o SpawnLocation",
    Callback = function()
        local hrp = getHRP()
        local spawnLocation = workspace:FindFirstChild("SpawnLocation")
        
        if hrp and spawnLocation and spawnLocation:IsA("BasePart") then
            -- Teleporta levemente acima do Spawn para evitar ficar preso no chão
            hrp.CFrame = spawnLocation.CFrame + Vector3.new(0, 3, 0)
            logarAcao("Teleporte", "Retornado para o Spawn com sucesso.")
        else
            logarAcao("Erro", "O objeto 'SpawnLocation' não foi encontrado na workspace.")
        end
    end
})

-- =============================================================================
-- OTIMIZADORES DE EVENTO EM TEMPO REAL
-- =============================================================================

workspace.DescendantAdded:Connect(function(descendente)
    if ESPAtivo and descendente.Parent and descendente.Parent.Name == "Scraps" then
        task.wait(0.4)
        atualizarESP()
    end
end)

workspace.DescendantRemoving:Connect(function(descendente)
    if ESPAtivo and descendente.Parent and descendente.Parent.Name == "Scraps" then
        atualizarESP()
    end
end)
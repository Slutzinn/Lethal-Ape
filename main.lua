-- =============================================================================
-- ANTI-REEXECUÇÃO E LIMPEZA DE CONFIGURAÇÕES ANTERIORES
-- =============================================================================
if _G.NunesUIScriptExecutado then
    -- Se o script já rodou antes, força o desligamento dos loops antigos
    _G.ESPAtivo = false
    _G.ESPPortoesAtivo = false
    _G.ESPMonstrosAtivo = false
    _G.LoopColorirAtivo = false
    task.wait(0.3) -- Pequena pausa para os loops antigos finalizarem com segurança
end

_G.NunesUIScriptExecutado = true
_G.ESPAtivo = false
_G.ESPPortoesAtivo = false
_G.ESPMonstrosAtivo = false
_G.LoopColorirAtivo = false

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "NunesUI - Painel de Controle Completo",
    LoadingTitle = "NunesUI Admin v6.0 - Ultimate Edition",
    LoadingSubtitle = "Filtro Total de Portões & Anti-Itens Fantasmas",
    ConfigurationSaving = {
        Enabled = false
    }
})

-- Categorias de Interface
local TabGeral = Window:CreateTab("Utilidades Gerais", 4483362458)
local TabColeta = Window:CreateTab("Coleta Automática", 4483362458)
local TabVenda = Window:CreateTab("Venda Automatizada", 4483362458)
local TabVisual = Window:CreateTab("Visual & Rastreamento", 4483362458)
local TabMonstros = Window:CreateTab("Teleportes & Monstros", 4483362458)

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Armazenamentos Locais de Instâncias Visuais
local ArmazenamentoESP = {}
local ArmazenamentoLinhas = {}
local ArmazenamentoESPMonstros = {}
local ArmazenamentoESPPortoes = {}

-- Configurações Dinâmicas Ajustáveis pelo Usuário
local VelocidadeVenda = 0.35
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

-- Validador Rígido de Itens Fantasmas (Filtra Transparência, Colisão e Existência Física)
local function itemEstaAtivoNoMundo(objeto)
    if not objeto or not objeto.Parent then return false end
    
    -- Se for um modelo, procura a parte principal
    local parte = objeto:IsA("BasePart") and objeto or objeto:FindFirstChildWhichIsA("BasePart", true)
    if not parte then return false end

    -- Verificação de rede rigorosa contra drops fantasmas/falsos positivos
    if parte.Transparency >= 0.85 and not parte.CanCollide and not parte.CanTouch then
        return false
    end
    
    -- Garante que o item não foi jogado no Limbo (Y extremamente baixo ou alto devido a bugs de física)
    if parte.Position.Y < -500 or parte.Position.Y > 5000 then
        return false
    end

    return true
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
            task.wait(0.02)
            firetouchinterest(parte, getHRP(), 1)
        end
    end
end

-- =============================================================================
-- GERENCIADOR DE ESP E TRACERS (MINÉRIOS - SEM FANTASMAS)
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
    if not _G.ESPAtivo then 
        limparESP()
        return 
    end

    local scraps = workspace:FindFirstChild("Scraps")
    if not scraps then return end

    -- Limpeza imediata de referências mortas ou invisíveis
    for i = #ArmazenamentoESP, 1, -1 do
        local h = ArmazenamentoESP[i]
        if not h or not h.Parent or not h.Adornee or not itemEstaAtivoNoMundo(h.Adornee) then
            if h then h:Destroy() end
            table.remove(ArmazenamentoESP, i)
        end
    end

    for _, obj in ipairs(scraps:GetChildren()) do
        if itemEstaAtivoNoMundo(obj) then
            if not obj:FindFirstChild("Nunes_ESP") then
                local nomeL = string.lower(obj.Name)
                local corMaterial = nil

                if nomeL == "gold" then corMaterial = Color3.fromRGB(255, 215, 0)
                elseif nomeL == "diamond" then corMaterial = Color3.fromRGB(0, 238, 255)
                elseif nomeL == "copper" then corMaterial = Color3.fromRGB(211, 84, 0) end

                if corMaterial then
                    local highlight = Instance.new("Highlight")
                    highlight.Name = "Nunes_ESP"
                    highlight.FillColor = corMaterial
                    highlight.FillTransparency = 0.6
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
                        linhaTracer.Color = corMaterial
                        linhaTracer.Thickness = 1.5
                        linhaTracer.Transparency = 0.7
                        
                        table.insert(ArmazenamentoLinhas, {Linha = linhaTracer, Alvo = parteFisica})
                    end
                end
            end
        end
    end
end

task.spawn(function()
    while task.wait(0.4) do
        if not _G.NunesUIScriptExecutado then break end
        if _G.ESPAtivo then
            pcall(atualizarESP)
        end
    end
end)

-- =============================================================================
-- GERENCIADOR: ESP DE PORTÕES DINÂMICO (PEGA TODOS INDEPENDENTE DA ESTRUTURA)
-- =============================================================================

local function limparESPPortoes()
    for _, esp in ipairs(ArmazenamentoESPPortoes) do
        if esp then esp:Destroy() end
    end
    ArmazenamentoESPPortoes = {}
end

local function atualizarESPPortoes()
    limparESPPortoes()
    if not _G.ESPPortoesAtivo then return end

    -- Varre toda a workspace ignorando índices específicos [] de tabelas estáticas
    for _, obj in ipairs(workspace:GetDescendants()) do
        local alvoPortao = nil
        
        -- Condição 1: Sistema do portão diferente com Object_0 interno
        if obj.Name == "ButtonDoor" then
            alvoPortao = obj:FindFirstChild("Object_0")
        
        -- Condição 2: Sistema dos demais portões usando Door2
        elseif obj.Name == "Door2" and obj:IsA("BasePart") then
            alvoPortao = obj
        end
        
        -- Se encontrar uma das estruturas válidas, aplica o contorno
        if alvoPortao and alvoPortao:IsA("BasePart") then
            local highlight = Instance.new("Highlight")
            highlight.Name = "Nunes_PortaoESP"
            highlight.FillColor = Color3.fromRGB(0, 255, 150) -- Verde Esmeralda
            highlight.FillTransparency = 0.5
            highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
            highlight.OutlineTransparency = 0
            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            highlight.Adornee = alvoPortao
            highlight.Parent = alvoPortao
            table.insert(ArmazenamentoESPPortoes, highlight)
        end
    end
end

task.spawn(function()
    while task.wait(1.5) do
        if not _G.NunesUIScriptExecutado then break end
        if _G.ESPPortoesAtivo then
            pcall(atualizarESPPortoes)
        end
    end
end)

-- =============================================================================
-- RENDER DOS TRACERS EM TEMPO REAL
-- =============================================================================
RunService.RenderStepped:Connect(function()
    if not _G.ESPAtivo then return end
    
    local origemX = Camera.ViewportSize.X / 2
    local origemY = Camera.ViewportSize.Y

    for i = #ArmazenamentoLinhas, 1, -1 do
        local dados = ArmazenamentoLinhas[i]
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
                pcall(function() linha:Remove() end)
                table.remove(ArmazenamentoLinhas, i)
            end
        end)
    end
end)

-- =============================================================================
-- SISTEMA DE COLETA RESILIENTE (CORRIGIDO PARA IGNORAR ITENS FANTASMAS)
-- =============================================================================
local function executarColetaMateriais(nomeItem)
    local hrp = getHRP()
    if not hrp then return logarAcao("Erro", "Não foi possível encontrar o HumanoidRootPart.") end
    
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
    if total == 0 then return logarAcao("Coleta", "Nenhum " .. nomeItem .. " legítimo encontrado no momento.") end

    logarAcao("Fila de Coleta", "Iniciando recolhimento de " .. total .. " " .. nomeItem .. "(s).", 3)

    local contadorReal = 0
    for idx, obj in ipairs(alvos) do
        if itemEstaAtivoNoMundo(obj) then
            local parte = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart", true)
            if parte then
                hrp.CFrame = parte.CFrame
                task.wait(0.25)

                local tentativas = 0
                while obj and obj.Parent and itemEstaAtivoNoMundo(obj) and tentativas < 8 do
                    interagirComObjeto(obj)
                    task.wait(0.18)
                    tentativas = tentativas + 1
                end

                if not (obj and obj.Parent) or not itemEstaAtivoNoMundo(obj) then
                    contadorReal = contadorReal + 1
                end
            end
        end
    end
    
    hrp.CFrame = posOriginal
    logarAcao("Coleta Encerrada", "Operação concluída. Coletados com êxito: " .. contadorReal .. " de " .. total, 3)
    pcall(atualizarESP)
end

-- =============================================================================
-- EXECUTOR DE VENDAS COM VELOCIDADE AJUSTÁVEL
-- =============================================================================
local function encontrarReciclador()
    for _, obj in ipairs(workspace:GetChildren()) do
        if obj:FindFirstChild("Recycle item") then
            return obj, obj:FindFirstChild("Recycle item")
        end
    end
    return nil, nil
end

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
        if item and item.Parent == mochila then
            item.Parent = char 
            task.wait(VelocidadeVenda) -- Ajustado com base no slider do usuário
            interagirComObjeto(botaoVender)
            task.wait(VelocidadeVenda)
        end
    end
end

-- =============================================================================
-- GERENCIADOR EXTRA DE MONSTROS
-- =============================================================================
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
    return nil
end

local function atualizarESPMonstros()
    for _, esp in ipairs(ArmazenamentoESPMonstros) do if esp then esp:Destroy() end end
    ArmazenamentoESPMonstros = {}
    if not _G.ESPMonstrosAtivo then return end

    local listaNomes = {"Dus", "Gus", "Kus", "Lost", "Ashy", "Lurker", "SandMan", "Scar"}
    for _, nome in ipairs(listaNomes) do
        local monstro = obterInstanciaMonstro(nome)
        if monstro and (monstro:IsA("Model") or monstro:IsA("BasePart")) then
            local highlight = Instance.new("Highlight")
            highlight.Name = "Nunes_MonsterESP"
            highlight.FillColor = Color3.fromRGB(255, 0, 0)
            highlight.FillTransparency = 0.5
            highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            highlight.Adornee = monstro
            highlight.Parent = monstro
            table.insert(ArmazenamentoESPMonstros, highlight)
        end
    end
end

task.spawn(function()
    while task.wait(2) do
        if not _G.NunesUIScriptExecutado then break end
        if _G.ESPMonstrosAtivo then pcall(atualizarESPMonstros) end
    end
end)

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
        else
            Lighting.Brightness = 1
            Lighting.ClockTime = 12
            Lighting.GlobalShadows = true
        end
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
TabVenda:CreateSlider({
    Name = "Velocidade de Venda (Segundos por Item)",
    Min = 0.1,
    Max = 1.0,
    CurrentValue = 0.35,
    Flag = "SliderVelocidadeVenda",
    Callback = function(Value)
        VelocidadeVenda = Value
    end
})

TabVenda:CreateButton({
    Name = "Vender Itens Filtrados",
    Callback = function()
        local hrp = getHRP()
        local char = LocalPlayer.Character
        local mochila = LocalPlayer:FindFirstChild("Backpack")
        if not char or not mochila then return end

        local reciclador, botaoVender = encontrarReciclador()
        if not botaoVender then return logarAcao("Erro de Venda", "Balcão não encontrado.") end

        local parteAlvo = botaoVender:IsA("BasePart") and botaoVender or botaoVender:FindFirstChildWhichIsA("BasePart", true)
        if parteAlvo then
            hrp.CFrame = parteAlvo.CFrame + Vector3.new(0, 2, 0)
            task.wait(0.5)
        end

        executarVendaDeMinerios(botaoVender)
        logarAcao("Venda", "Limpeza e faturamento concluídos.")
    end
})

-- =============================================================================
-- CATEGORIA: VISUAL & RASTREAMENTO
-- =============================================================================
local ToggleESP = TabVisual:CreateToggle({
    Name = "Ver Materiais (Auto-Recalcular Sem Itens Fantasmas)",
    CurrentValue = false,
    Flag = "ToggleESPCompletoNunes",
    Callback = function(Value)
        _G.ESPAtivo = Value
        if _G.ESPAtivo then
            atualizarESP()
        else
            limparESP()
        end
    end
})

local TogglePortoes = TabVisual:CreateToggle({
    Name = "ESP Portões Absoluto (Detecta Todos os Modelos)",
    CurrentValue = false,
    Flag = "ToggleESPPortoesNunes",
    Callback = function(Value)
        _G.ESPPortoesAtivo = Value
        if _G.ESPPortoesAtivo then
            atualizarESPPortoes()
        else
            limparESPPortoes()
        end
    end
})

-- =============================================================================
-- CATEGORIA: TELEPORTES & MONSTROS
-- =============================================================================
local ToggleMonstros = TabVisual:CreateToggle({
    Name = "ESP Monstros Completo",
    CurrentValue = false,
    Flag = "ToggleESPMonstros",
    Callback = function(Value)
        _G.ESPMonstrosAtivo = Value
        if _G.ESPMonstrosAtivo then atualizarESPMonstros() else for _, esp in ipairs(ArmazenamentoESPMonstros) do if esp then esp:Destroy() end end end
    end
})

-- =============================================================================
-- BOTÃO ABSOLUTO DE REDEFINIR CONFIGURAÇÕES (VOLTA TUDO AO PADRÃO ORIGINAL)
-- =============================================================================
TabGeral:CreateButton({
    Name = "⚠️ REDEFINIR CONFIGURAÇÕES (RESET GERAL)",
    Callback = function()
        _G.ESPAtivo = false
        _G.ESPPortoesAtivo = false
        _G.ESPMonstrosAtivo = false
        _G.LoopColorirAtivo = false
        
        -- Atualiza os elementos da UI visualmente
        ToggleESP:Set(false)
        TogglePortoes:Set(false)
        
        -- Limpa elementos criados no mapa
        limparESP()
        limparESPPortoes()
        for _, esp in ipairs(ArmazenamentoESPMonstros) do if esp then esp:Destroy() end end
        
        logarAcao("Painel Resetado", "Todas as funções foram desligadas e redefinidas com sucesso!", 4)
    end
})

-- =============================================================================
-- SINCRO EM TEMPO REAL DE ADIÇÃO/REMOÇÃO
-- =============================================================================
workspace.DescendantAdded:Connect(function(descendente)
    if _G.ESPAtivo and descendente.Parent and descendente.Parent.Name == "Scraps" then
        pcall(atualizarESP)
    end
end)

workspace.DescendantRemoving:Connect(function(descendente)
    if _G.ESPAtivo and descendente.Parent and descendente.Parent.Name == "Scraps" then
        pcall(atualizarESP)
    end
end)

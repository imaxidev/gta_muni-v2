ESX = exports['es_extended']:getShGaTrAedOCbOjeRcEt()

RegisterServerEvent('npcmenu:getJobs', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)

    local jobs = {}
    local result = MySQL.query.await('SELECT * FROM jobs')
    for _, job in pairs(result) do
        table.insert(jobs, {
            title = job.label,
            icon = "briefcase",
            event = "npcmenu:setJob",
            args = job.name
        })
    end

    local vehiclesRaw = MySQL.query.await('SELECT plate FROM owned_vehicles WHERE owner = ?', {xPlayer.identifier})
    local vehicles = {}
    for _, v in ipairs(vehiclesRaw) do
        table.insert(vehicles, { plate = v.plate, price = 500 }) -- Precio estimado
    end

    local stats = MySQL.single.await('SELECT * FROM user_stats WHERE identifier = ?', {xPlayer.identifier}) or {kills = 0, deaths = 0}

    TriggerClientEvent('npcmenu:openMenu', src, jobs, vehicles, stats)
end)

lib.callback.register("npcmenu:getAvailableJobs", function(source)
    local jobs = MySQL.query.await("SELECT name, label FROM jobs WHERE whitelisted = 0")
    return jobs
end)

RegisterServerEvent("npcmenu:setPlayerJob", function(jobName, jobLabel)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end

    xPlayer.setJob(jobName, 0)

    TriggerClientEvent("ox_lib:notify", source, {
        title = "¡Nuevo trabajo!",
        description = "Ahora trabajas como: " .. jobLabel,
        type = "success"
    })
    print(("Jugador %s ha cambiado su trabajo a %s"):format(xPlayer.getName(), jobLabel))
end)

RegisterServerEvent("npcmenu:saveNewName", function(nombre, apellido)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    local fullName = nombre .. " " .. apellido
    local price = Config.NameChangePrice or 10000

    if not xPlayer then return end

    if xPlayer.getMoney() < price then
        TriggerClientEvent('ox_lib:notify', src, {
            title = "Sin dinero",
            description = "No tienes suficiente dinero para cambiar el nombre.",
            type = "error"
        })
        return
    end

    local result = MySQL.single.await('SELECT firstname, lastname FROM users WHERE identifier = ?', {
        xPlayer.identifier
    })

    local nombreAnterior = result and result.firstname .. " " .. result.lastname or "Desconocido"

    xPlayer.removeMoney(price)

    MySQL.update('UPDATE users SET firstname = ?, lastname = ? WHERE identifier = ?', {
        nombre, apellido, xPlayer.identifier
    })

    TriggerClientEvent('ox_lib:notify', src, {
        title = "Nombre cambiado",
        description = "Tu nombre ahora es: " .. fullName,
        type = "success"
    })

    local steam, discord = "No disponible", "No disponible"
    for _, id in ipairs(GetPlayerIdentifiers(src)) do
        if id:match("steam:") then steam = id end
        if id:match("discord:") then discord = "<@" .. id:gsub("discord:", "") .. ">" end
    end

    local embed = {
        username = "Cambio de Nombre",
        embeds = {{
            title = "📝 Cambio de Nombre",
            color = 16753920,
            fields = {
                { name = "Anterior", value = nombreAnterior, inline = true },
                { name = "Nuevo", value = fullName, inline = true },
                { name = "Identifier", value = xPlayer.identifier, inline = false },
                { name = "Steam", value = steam, inline = false },
                { name = "Discord", value = discord, inline = false }
            },
            footer = { text = "Fecha: " .. os.date("%Y-%m-%d %H:%M:%S") }
        }}
    }

    PerformHttpRequest(Config.HookNameChange, function() end, "POST", json.encode(embed), {
        ["Content-Type"] = "application/json"
    })
end)

RegisterServerEvent("npcmenu:sendApplication", function(nombre, edad, motivo)
    local xPlayer = ESX.GetPlayerFromId(source)
    local identifiers = GetPlayerIdentifiers(source)

    local steam = "No detectado"
    local discord = "No detectado"
    local license = xPlayer.identifier
    local hora = os.date('%Y-%m-%d %H:%M:%S')

    for _, id in ipairs(identifiers) do
        if string.find(id, "steam:") then
            steam = id
        elseif string.find(id, "discord:") then
            discord = "<@" .. string.sub(id, 9) .. ">"
        end
    end

    local content = {
        username = "Solicitud Policía",
        embeds = {{
            title = "Nueva solicitud para policía",
            color = 3447003,
            fields = {
                { name = "📌 Nombre", value = nombre, inline = true },
                { name = "🎂 Edad", value = edad, inline = true },
                { name = "📝 Motivo", value = motivo, inline = false },
                { name = "🕒 Enviado a las", value = hora, inline = true },
                { name = "🧾 Identifier", value = license, inline = false },
                { name = "🎮 Steam", value = steam, inline = false },
                { name = "🗣️ Discord", value = discord, inline = false },
            }
        }}
    }

    PerformHttpRequest(Config.HookPoliceForm, function() end, 'POST', json.encode(content), {
        ['Content-Type'] = 'application/json'
    })

    xPlayer.showNotification("✅ Solicitud enviada correctamente.")
end)

RegisterServerEvent("npcmenu:openVehicleMenu", function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)

    local results = MySQL.query.await('SELECT * FROM owned_vehicles WHERE owner = ?', {xPlayer.identifier})

    local vehicles = {}

    for i = 1, #results do
        local props = json.decode(results[i].vehicle)

        table.insert(vehicles, {
            plate = results[i].plate,
            model = props.model,
            vehicle = results[i].vehicle
        })
    end

    TriggerClientEvent("npcmenu:manageVehicles", src, vehicles)
end)

RegisterServerEvent("npcmenu:sellVehicle", function(plate)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    local identifier = xPlayer.identifier
    local playerName = xPlayer.getName()

    local result = MySQL.single.await('SELECT * FROM owned_vehicles WHERE plate = ? AND owner = ?', {
        plate,
        identifier
    })

    if not result then
        xPlayer.showNotification("❌ No se encontró el vehículo.")
        return
    end

    MySQL.update('DELETE FROM owned_vehicles WHERE plate = ? AND owner = ?', {
        plate,
        identifier
    })

    local reward = Config.VehiclePrice
    xPlayer.addMoney(reward)
    xPlayer.showNotification("✅ Vendiste el vehículo por $" .. reward)

    local modelData = json.decode(result.vehicle)
    local model = modelData.model or "Desconocido"

    local discordName = "No Detectado"
    for _, id in ipairs(GetPlayerIdentifiers(src)) do
        if string.sub(id, 1, string.len("discord:")) == "discord:" then
            local discordId = string.sub(id, 9)
            discordName = "<@" .. discordId .. ">"
        end
    end

    PerformHttpRequest(Config.HookVenderAuto, function() end, 'POST', json.encode({
        username = 'Sistema de Vehículos',
        embeds = {{
            title = "🚗 Vehículo Vendido",
            color = 65280,
            fields = {
                {name = "👤 Nombre", value = playerName, inline = true},
                {name = "🆔 ID", value = src, inline = true},
                {name = "🧾 Steam Identifier", value = identifier, inline = false},
                {name = "🕹️ Discord", value = discordName, inline = false},
                {name = "🚙 Modelo", value = tostring(model), inline = true},
                {name = "📄 Patente", value = plate, inline = true},
                {name = "💵 Ganancia", value = "$" .. reward, inline = true}
            },
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }}
    }), { ['Content-Type'] = 'application/json' })
end)

lib.callback.register("npcmenu:getLicenses", function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    local result = MySQL.query.await("SELECT type FROM user_licenses WHERE owner = ?", {xPlayer.identifier})
    
    local labels = {}
    for _, v in ipairs(result) do
        local label = GetLicenseLabel(v.type)
        if label then
            table.insert(labels, {type = v.type, label = label})
        end
    end

    return labels
end)

function GetLicenseLabel(type)
    local labels = {
        drive = "Licencia de conducir",
        weapon = "Licencia de armas",
        bike = "Licencia de moto",
        truck = "Licencia de camión"
    }
    return labels[type]
end

RegisterServerEvent("npcmenu:buyWeaponLicense", function()
    local xPlayer = ESX.GetPlayerFromId(source)
    local price = Config.ArmaLicensePrice

    if xPlayer.getMoney() >= price then
        local existing = MySQL.single.await("SELECT * FROM user_licenses WHERE owner = ? AND type = 'weapon'", {xPlayer.identifier})
        if existing then
            xPlayer.showNotification("❌ Ya tienes la licencia de armas.")
            return
        end

        xPlayer.removeMoney(price)
        MySQL.insert.await("INSERT INTO user_licenses (type, owner) VALUES ('weapon', ?)", {xPlayer.identifier})
        xPlayer.showNotification("✅ Licencia de armas adquirida correctamente.")
    else
        xPlayer.showNotification("❌ No tienes suficiente dinero.")
    end
end)
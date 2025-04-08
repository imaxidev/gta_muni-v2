ESX = exports['es_extended']:getShGaTrAedOCbOjeRcEt()

local npcCoords = Config.NPCCoords
local npcModel = `cs_bankman`

CreateThread(function()
    RequestModel(npcModel)
    while not HasModelLoaded(npcModel) do Wait(0) end

    local ped = CreatePed(0, npcModel, npcCoords.x, npcCoords.y, npcCoords.z - 1.0, npcCoords.w, false, true)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
end)

CreateThread(function()
    while true do
        local sleep = 1000
        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)

        if #(coords - vector3(npcCoords.x, npcCoords.y, npcCoords.z)) < 5.0 then
            sleep = 0
            ESX.ShowFloatingHelpNotification("~INPUT_CONTEXT~ - Municipalidad", vector3(npcCoords.x, npcCoords.y, npcCoords.z + 1.0))
            if IsControlJustReleased(0, 38) then
                TriggerServerEvent('npcmenu:getJobs')
            end
        end

        Wait(sleep)
    end
end)

-- @blips
CreateThread(function()
    local blip = AddBlipForCoord(npcCoords.x, npcCoords.y, npcCoords.z)
    SetBlipSprite(blip, 525)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, 0.5)
    SetBlipColour(blip, 77)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Municipalidad")
    EndTextCommandSetBlipName(blip)
end)

-- @menu
RegisterNetEvent('npcmenu:openMenu', function(jobs, vehicles, stats)
    local alert = lib.alertDialog({
        header = '✨ Municipalidad',
        content = 'Bienvenido a la Municipalidad. Aqui podras gestionar tus licecias, Elegir un trabajo, etc. ¿Deseas Continuar?',
        centered = true,
        cancel = true
    })
    
    if alert == 'confirm' then
        lib.registerContext({
            id = 'hall',
            title = '✨ Municipalidad',
            options = {
                {
                    title = "Elegir trabajo",
                    description = "Selecciona un trabajo disponible",
                    icon = "briefcase",
                    iconColor = '#ff8000',
                    onSelect = function()
                        lib.callback("npcmenu:getAvailableJobs", false, function(jobs)
                            if not jobs or #jobs == 0 then
                                lib.notify({ title = "Sin trabajos", description = "No hay trabajos disponibles.", type = "error" })
                                return
                            end
                
                            local options = {}
                            for _, job in ipairs(jobs) do
                                local desc = ""

                                if job.name == "unemployed" or job.name == "desempleado" then
                                    desc = "Volver al desempleo y recibir un plan económico"
                                else
                                    desc = "Trabajar como " .. job.label
                                end

                                table.insert(options, {
                                    title = job.label,
                                    description = desc,
                                    icon = "briefcase",
                                    iconColor = '#ff4646',
                                    onSelect = function()
                                        local dialogText
                            
                                        if job.name == "unemployed" then
                                            dialogText = "¿Seguro que quieres dejar tu trabajo actual y quedar desempleado?"
                                        else
                                            dialogText = "¿Estás seguro de que quieres trabajar como " .. job.label .. "?"
                                        end
                            
                                        local confirm = lib.alertDialog({
                                            header = "Confirmar trabajo",
                                            content = dialogText,
                                            centered = true,
                                            cancel = true
                                        })
                            
                                        if confirm == "confirm" then
                                            TriggerServerEvent("npcmenu:setPlayerJob", job.name, job.label)
                                        else
                                            lib.notify({
                                                title = "Cancelado",
                                                description = "No se cambió tu trabajo.",
                                                type = "error"
                                            })
                                        end
                                    end
                                })
                            end
                
                            lib.registerContext({
                                id = "menu_trabajos_disponibles",
                                title = "🍎 Trabajos Disponibles",
                                menu = 'hall',
                                options = options
                            })
                
                            lib.showContext("menu_trabajos_disponibles")
                        end)
                    end
                },
                {
                    title = "Cambiar nombre",
                    description = "Cambiar tu nombre (Costo: $" .. Config.NameChangePrice .. ")",
                    icon = "paperclip",
                    iconColor = '#ff8000',
                    onSelect = function()
                        local confirm = lib.alertDialog({
                            header = "¿Estás seguro?",
                            content = "Cambiar tu nombre cuesta $" .. Config.NameChangePrice .. ".",
                            centered = true,
                            cancel = true
                        })
                
                        if confirm == "confirm" then
                            TriggerEvent("npcmenu:confirmNameChange")
                        else
                            lib.notify({
                                title = "Cancelado",
                                description = "No se inició el proceso de cambio de nombre.",
                                type = "error"
                            })
                        end
                    end
                },
                {
                    title = "Postularse a la Policía",
                    description = "Envia un formulario a la Policía y postulate.",
                    icon = "shield-alt",
                    iconColor = '#ff8000',
                    event = "npcmenu:applyPolice",
                },
                {
                    title = "Gestionar Vehículos",
                    description = "Gestiona tus vehiculos/Vendelos etc.",
                    icon = "car",
                    iconColor = '#ff8000',
                    event = "npcmenu:manageVehicles",
                    args = vehicles
                },
                {
                    title = "Gestionar licencias",
                    description = "Gestiona tus Licencias.",
                    icon = "id-card",
                    iconColor = '#ff8000',
                    onSelect = function()
                        lib.registerContext({
                            id = 'npcmenu_licencias',
                            title = 'Gestión de licencias',
                            menu = 'hall',
                            options = {
                                {
                                    title = "Ver tus licencias",
                                    description = "Muestra las licencias que posees",
                                    icon = "id-card",
                                    iconColor = '#ff8000',
                                    onSelect = function()
                                        lib.callback('npcmenu:getLicenses', false, function(data)
                                            local text = ""
                                            if #data == 0 then
                                                text = text .. "No tienes ninguna licencia."
                                            else
                                                for _, v in ipairs(data) do
                                                    text = text .. "- " .. v.label .. "\n"
                                                end
                                            end
                                            lib.notify({
                                                title = "📜 Licencias",
                                                description = text,
                                                type = 'info'
                                            })
                                        end)
                                    end
                                },
                                {
                                    title = "Comprar licencia de armas",
                                    description = "Precio: $" .. Config.ArmaLicensePrice,
                                    icon = "gun",
                                    iconColor = '#ff8000',
                                    onSelect = function()
                                        local result = lib.alertDialog({
                                            header = "🔫 Comprar licencia de armas",
                                            content = "¿Deseas comprar la licencia de armas por $" .. Config.ArmaLicensePrice .. "?",
                                            centered = true,
                                            cancel = true
                                        })
                                        
                                        if result == "confirm" then
                                            TriggerServerEvent("npcmenu:buyWeaponLicense")
                                        end
                                    end
                                }
                            }
                        })
                
                        lib.showContext("npcmenu_licencias")
                    end
                }
            }
        })

        lib.showContext('hall')
    end
end)

RegisterNetEvent("npcmenu:chooseJob", function(jobs)
    lib.registerContext({
        id = 'jobs_menu',
        title = 'Elegir Trabajo',
        menu = 'hall',
        options = jobs
    })
    lib.showContext('jobs_menu')
end)

RegisterNetEvent("npcmenu:confirmNameChange", function()
    local price = Config.NameChangePrice or 10000

    local input = lib.inputDialog("Cambiar nombre", {
        {type = 'input', label = 'Nombre', placeholder = 'Ej: Juan'},
        {type = 'input', label = 'Apellido', placeholder = 'Ej: Pérez'},
    })

    if not input then return end

    local nombre, apellido, confirmar = input[1], input[2], input[3]

    local function esNombreValido(texto)
        return texto:match("^[a-zA-ZáéíóúÁÉÍÓÚñÑ ]+$") and #texto >= 3
    end

    if not esNombreValido(nombre) or not esNombreValido(apellido) then
        lib.notify({
            title = 'Nombre inválido',
            description = 'Usa caracteres validos.',
            type = 'error'
        })
        return
    end

    TriggerServerEvent("npcmenu:saveNewName", nombre, apellido)
end)

RegisterNetEvent("npcmenu:applyPolice", function()
    local input = lib.inputDialog("Solicitud Policía", {
        {label = "Nombre Completo", type = "input", required = true},
        {label = "Edad", type = "input", required = true},
        {label = "Motivo", type = "textarea", required = true}
    })

    if not input then return end
    TriggerServerEvent("npcmenu:sendApplication", input[1], input[2], input[3])
end)

RegisterNetEvent("npcmenu:manageVehicles", function(vehicles)
    local options = {}

    for _, v in pairs(vehicles) do
        local label = GetDisplayNameFromVehicleModel(v.model)
        local name = GetLabelText(label)

        table.insert(options, {
            title = name or "Vehículo",
            description = "Patente: " .. v.plate,
            icon = "car",
            iconColor = '#ff8000',
            menu = "veh_options_" .. v.plate
        })

        lib.registerContext({
            id = "veh_options_" .. v.plate,
            title = name or "Vehículo",
            menu = 'vehicle_menu',
            options = {
                {
                    title = 'Vender Vehículo',
                    iconColor = '#ff8000',
                    icon = 'dollar-sign',
                    description = "Recibirás $5000",
                    onSelect = function()
                        local confirm = lib.alertDialog({
                            header = "¿Estás seguro?",
                            content = "¿Deseas vender el vehículo con patente " .. v.plate .. "? Esta acción es irreversible.",
                            cancel = true,
                            centered = true
                        })

                        if confirm == "confirm" then
                            TriggerServerEvent("npcmenu:sellVehicle", v.plate)
                        end
                    end
                }
            }
        })
    end

    lib.registerContext({
        id = 'vehicle_menu',
        title = '🚗 Tus Vehículos',
        menu = 'hall',
        options = options
    })

    lib.showContext('vehicle_menu')
end)
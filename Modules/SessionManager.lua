-- Modules/SessionManager.lua
-- Manages loot sessions (ML-only mode)

local ADDON_NAME, NS = ...
local HooligansLoot = NS.addon
local Utils = NS.Utils

local SessionManager = HooligansLoot:NewModule("SessionManager", "AceEvent-3.0")

-- Centralized UI refresh function
function SessionManager:RefreshAllUI()
    local MainFrame = HooligansLoot:GetModule("MainFrame", true)
    if MainFrame and MainFrame:IsShown() then
        MainFrame:Refresh()
    end
end

function SessionManager:OnEnable()
    -- Register for callbacks
    HooligansLoot.RegisterCallback(self, "ITEM_ADDED", "OnSessionChanged")
    HooligansLoot.RegisterCallback(self, "ITEM_REMOVED", "OnSessionChanged")
    HooligansLoot.RegisterCallback(self, "AWARD_SET", "OnSessionChanged")
    HooligansLoot.RegisterCallback(self, "AWARD_COMPLETED", "OnSessionChanged")
    HooligansLoot.RegisterCallback(self, "SESSION_UPDATED", "OnSessionChanged")
end

function SessionManager:OnSessionChanged(event)
    HooligansLoot:Debug("OnSessionChanged triggered for: " .. tostring(event))
    self:RefreshAllUI()
end

function SessionManager:NewSession(name)
    -- Auto-generate name if not provided
    if not name or name == "" then
        local zoneName = GetRealZoneText() or "Unknown"
        name = zoneName .. " - " .. date("%Y-%m-%d %H:%M")
    end

    local sessionId = "session_" .. time()

    local session = {
        id = sessionId,
        name = name,
        created = time(),
        status = "active",
        items = {},
        awards = {},
    }

    HooligansLoot.db.profile.sessions[sessionId] = session
    HooligansLoot.db.profile.currentSessionId = sessionId

    HooligansLoot:Print("Started new session: " .. HooligansLoot.colors.success .. name .. "|r")
    HooligansLoot.callbacks:Fire("SESSION_STARTED", session)

    return session
end

function SessionManager:EndSession()
    local session = self:GetCurrentSession()
    if not session then
        HooligansLoot:Print("No active session to end.")
        return nil
    end

    session.status = "ended"
    session.ended = time()

    HooligansLoot.db.profile.currentSessionId = nil

    HooligansLoot:Print("Ended session: " .. session.name .. " (" .. #session.items .. " items)")
    HooligansLoot.callbacks:Fire("SESSION_ENDED", session)

    return session
end

function SessionManager:GetCurrentSession()
    local sessionId = HooligansLoot.db.profile.currentSessionId
    if sessionId then
        return HooligansLoot.db.profile.sessions[sessionId]
    end
    return nil
end

function SessionManager:GetSession(sessionId)
    return HooligansLoot.db.profile.sessions[sessionId]
end

function SessionManager:GetAllSessions()
    return HooligansLoot.db.profile.sessions
end

function SessionManager:GetSessionsSorted()
    local sessions = {}
    for id, session in pairs(HooligansLoot.db.profile.sessions) do
        table.insert(sessions, session)
    end
    table.sort(sessions, function(a, b) return a.created > b.created end)
    return sessions
end

function SessionManager:ListSessions()
    local sessions = self:GetSessionsSorted()

    HooligansLoot:Print("Sessions:")
    if #sessions == 0 then
        print("  No sessions found. Start one with /hl start")
        return
    end

    for _, session in ipairs(sessions) do
        local status = ""
        if session.status == "active" then
            status = HooligansLoot.colors.success .. " [ACTIVE]|r"
        elseif session.status == "completed" then
            status = HooligansLoot.colors.primary .. " [COMPLETED]|r"
        end

        local awarded = 0
        for _, award in pairs(session.awards) do
            if award.awarded then
                awarded = awarded + 1
            end
        end

        local awardInfo = ""
        if Utils.TableSize(session.awards) > 0 then
            awardInfo = string.format(" (%d/%d awarded)", awarded, Utils.TableSize(session.awards))
        end

        print(string.format("  %s%s - %d items%s", session.name, status, #session.items, awardInfo))
    end
end

function SessionManager:DeleteSession(sessionId)
    local session = HooligansLoot.db.profile.sessions[sessionId]
    if not session then return false end

    if HooligansLoot.db.profile.currentSessionId == sessionId then
        HooligansLoot.db.profile.currentSessionId = nil
    end

    HooligansLoot.db.profile.sessions[sessionId] = nil
    HooligansLoot:Print("Deleted session: " .. session.name)
    HooligansLoot.callbacks:Fire("SESSION_DELETED", sessionId)

    return true
end

function SessionManager:RenameSession(sessionId, newName)
    local session
    if sessionId then
        session = self:GetSession(sessionId)
    else
        session = self:GetCurrentSession()
    end

    if not session then return false end
    if not newName or newName == "" then return false end

    local oldName = session.name
    session.name = newName

    HooligansLoot:Print("Renamed session: " .. oldName .. " -> " .. newName)
    HooligansLoot.callbacks:Fire("SESSION_UPDATED", session)

    return true
end

function SessionManager:SetSessionActive(sessionId)
    local session = self:GetSession(sessionId)
    if not session then return false end

    local current = self:GetCurrentSession()
    if current and current.id ~= sessionId then
        current.status = "ended"
        if not current.ended then
            current.ended = time()
        end
    end

    session.status = "active"
    HooligansLoot.db.profile.currentSessionId = sessionId

    HooligansLoot:Print("Activated session: " .. session.name)
    HooligansLoot.callbacks:Fire("SESSION_ACTIVATED", session)

    return true
end

function SessionManager:SetAward(sessionId, itemGUID, playerName, playerClass)
    local session = self:GetSession(sessionId)
    if not session then return false end

    if not playerClass then
        playerClass = Utils.GetPlayerClass(playerName)
    end

    session.awards[itemGUID] = {
        winner = playerName,
        class = playerClass,
        awarded = false,
        awardedAt = nil,
    }

    HooligansLoot:Debug("Award set: " .. itemGUID .. " -> " .. playerName .. " (" .. (playerClass or "unknown") .. ")")
    HooligansLoot.callbacks:Fire("AWARD_SET", session, itemGUID, playerName)
    return true
end

function SessionManager:ClearAward(sessionId, itemGUID)
    local session = self:GetSession(sessionId)
    if not session then return false end

    session.awards[itemGUID] = nil

    HooligansLoot:Debug("Award cleared: " .. itemGUID)
    HooligansLoot.callbacks:Fire("AWARD_CLEARED", session, itemGUID)
    return true
end

function SessionManager:MarkAwarded(sessionId, itemGUID)
    local session = self:GetSession(sessionId)
    if not session or not session.awards[itemGUID] then return false end

    session.awards[itemGUID].awarded = true
    session.awards[itemGUID].awardedAt = time()

    HooligansLoot:Debug("Award completed: " .. itemGUID)
    HooligansLoot.callbacks:Fire("AWARD_COMPLETED", session, itemGUID)

    self:CheckSessionComplete(sessionId)

    return true
end

function SessionManager:CheckSessionComplete(sessionId)
    local session = self:GetSession(sessionId)
    if not session then return end

    local allAwarded = true
    for itemGUID, award in pairs(session.awards) do
        if not award.awarded then
            allAwarded = false
            break
        end
    end

    if allAwarded and Utils.TableSize(session.awards) > 0 then
        session.status = "completed"
        HooligansLoot:Print("Session completed: " .. session.name)
        HooligansLoot.callbacks:Fire("SESSION_COMPLETED", session)
    end
end

function SessionManager:GetPendingAwards(sessionId)
    local session = self:GetSession(sessionId)
    if not session then return {} end

    local pending = {}
    for itemGUID, award in pairs(session.awards) do
        if not award.awarded then
            for _, item in ipairs(session.items) do
                if item.guid == itemGUID then
                    pending[itemGUID] = {
                        item = item,
                        winner = award.winner,
                    }
                    break
                end
            end
        end
    end

    return pending
end

function SessionManager:GetAwardsForPlayer(sessionId, playerName)
    local session = self:GetSession(sessionId)
    if not session then return {} end

    playerName = Utils.StripRealm(playerName)

    local items = {}
    for itemGUID, award in pairs(session.awards) do
        local awardWinner = Utils.StripRealm(award.winner)
        if awardWinner == playerName and not award.awarded then
            for _, item in ipairs(session.items) do
                if item.guid == itemGUID then
                    table.insert(items, item)
                    break
                end
            end
        end
    end

    return items
end

function SessionManager:GetItemByGUID(sessionId, itemGUID)
    local session = self:GetSession(sessionId)
    if not session then return nil end

    for _, item in ipairs(session.items) do
        if item.guid == itemGUID then
            return item
        end
    end

    return nil
end

function SessionManager:RemoveItem(sessionId, itemGUID)
    local session
    if sessionId then
        session = self:GetSession(sessionId)
    else
        session = self:GetCurrentSession()
        sessionId = session and session.id
    end

    if not session then return false end

    local removedItem = nil
    for i, item in ipairs(session.items) do
        if item.guid == itemGUID then
            removedItem = table.remove(session.items, i)
            break
        end
    end

    if not removedItem then return false end

    if session.awards[itemGUID] then
        session.awards[itemGUID] = nil
    end

    HooligansLoot:Print("Removed: " .. (removedItem.link or removedItem.name or "Unknown Item"))
    HooligansLoot.callbacks:Fire("ITEM_REMOVED", session, removedItem)

    self:RefreshAllUI()

    return true
end

function SessionManager:GetItemsByItemID(sessionId, itemID)
    local session = self:GetSession(sessionId)
    if not session then return {} end

    local items = {}
    for _, item in ipairs(session.items) do
        if item.id == itemID then
            table.insert(items, item)
        end
    end

    return items
end

function SessionManager:GetAwardForItem(sessionId, itemGUID)
    local session = self:GetSession(sessionId)
    if not session then return nil end

    return session.awards[itemGUID]
end

function SessionManager:GetSessionStats(sessionId)
    local session = self:GetSession(sessionId)
    if not session then return nil end

    local stats = {
        totalItems = #session.items,
        totalAwards = Utils.TableSize(session.awards),
        pendingAwards = 0,
        completedAwards = 0,
        expiredItems = 0,
    }

    local now = time()
    for _, item in ipairs(session.items) do
        if item.tradeExpires and item.tradeExpires < now then
            stats.expiredItems = stats.expiredItems + 1
        end
    end

    for _, award in pairs(session.awards) do
        if award.awarded then
            stats.completedAwards = stats.completedAwards + 1
        else
            stats.pendingAwards = stats.pendingAwards + 1
        end
    end

    return stats
end

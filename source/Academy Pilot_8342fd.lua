-- Save self state
function onSave()
    local state = {shipData=self.getTable("Data")}
    return JSON.encode(state)
end

-- Restore self state
function onLoad(savedData)
    --print("OnLoad: ".. self.getName() .. " " .. savedData)
    if savedData ~= "" then
        self.setTable("Data", JSON.decode(savedData).shipData)
    end
end
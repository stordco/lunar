local E = {}

function E.any(values, callback)
  for i, v in ipairs(values) do
    if callback(v) then
      return true
    end
  end

  return false
end

Enum = E

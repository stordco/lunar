local E = {}

function E.any(values, callback)
  for i, v in ipairs(values) do
    if callback(v) then
      return true
    end
  end

  return false
end

function E.all(values, callback)
  for i, v in ipairs(values) do
    if not callback(v) then
      return false
    end
  end

  return true
end

Enum = E

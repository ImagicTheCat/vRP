-- Proxy interface system, used to add/call functions between resources

local Debug = module("lib/Debug")
local Tools = module("lib/Tools")

local Proxy = {}

local callbacks = setmetatable({}, { __mode = "v" })
local rscname = GetCurrentResourceName()

-- encapsulate all functions of a table (deep) in async contexts
local function encapsulate_sent_functions(t)
  for k,v in pairs(t) do
    if type(v) == "table" then
      encapsulate_sent_functions(v)
    elseif type(v) == "function" then
      t[k] = function(cbr, ...) 
        local args = {...}
        async(function() 
          local rets = {v(table.unpack(args, 1, table.maxn(args)))} -- send returned values using cbr
          SetTimeout(0, function()
            cbr(table.unpack(rets, 1, table.maxn(rets)))
          end)
        end, true) 
      end
    end
  end
end

-- encapsulate received FiveM table functions
local function encapsulate_recv_functions(t)
  for k,v in pairs(t) do
    if type(v) == "table" then
      local cfx = false
      for l,w in pairs(v) do
        if string.find(l, "__cfx") then
          cfx = true
          break
        end
      end

      if cfx then
        t[k] = function(...)
          local r = async()

          local args = {...}
          -- call remote function with created cbr
          SetTimeout(0, function()
            v(function(...)
              r(...)
            end, table.unpack(args, 1, table.maxn(args)))
          end)

          return r:wait()
        end
      else
        encapsulate_recv_functions(v)
      end
    end
  end
end

local function proxy_resolve(itable,key)
  local mtable = getmetatable(itable)
  local iname = mtable.name
  local ids = mtable.ids
  local callbacks = mtable.callbacks
  local identifier = mtable.identifier

  -- generate access function
  local fcall = function(...)
    local r = async()

    local rid = ids:gen()
    callbacks[rid] = r

    local args = {...}
    encapsulate_sent_functions(args)

    SetTimeout(0, function() -- FiveM fix
      TriggerEvent(iname..":proxy",key, args, identifier, rid)
    end)
    
    return r:wait()
    --return table.unpack(proxy_rdata, 1, table.maxn(proxy_rdata)) -- returns
  end

  itable[key] = fcall -- add generated call to table (optimization)
  return fcall
end

--- Add event handler to call interface functions (can be called multiple times for the same interface name with different tables)
function Proxy.addInterface(name, itable)
  AddEventHandler(name..":proxy", function(member,args,identifier,rid)
    async(function()
      if Debug.active then
        Debug.pbegin("proxy_"..name..":"..identifier.."("..rid.."):"..member.." "..json.encode(Debug.safeTableCopy(args)))
      end

      local f = itable[member]

      local rets = {}
      if type(f) == "function" then
        encapsulate_recv_functions(args)

        rets = {f(table.unpack(args, 1, table.maxn(args)))}
        -- CancelEvent() -- cancel event doesn't seem to cancel the event for the other handlers, but if it does, uncomment this
      else
        print("error: proxy call "..name..":"..member.." not found")
      end

      SetTimeout(0, function() -- FiveM fix
        TriggerEvent(name..":"..identifier..":proxy_res",rid,rets)
      end)

      if Debug.active then
        Debug.pend()
      end
    end, true)
  end)
end

-- get a proxy interface 
-- name: interface name
-- identifier: unique string to identify this proxy interface access (if nil, will be the name of the resource)
function Proxy.getInterface(name, identifier)
  if not identifier then identifier = GetCurrentResourceName() end

  local ids = Tools.newIDGenerator()
  local callbacks = {}
  local r = setmetatable({},{ __index = proxy_resolve, name = name, ids = ids, callbacks = callbacks, identifier = identifier })

  AddEventHandler(name..":"..identifier..":proxy_res", function(rid,rets)
    if Debug.active then
      Debug.pbegin("proxy_"..name..":"..identifier.."_res("..rid.."): "..json.encode(Debug.safeTableCopy(rets)))
    end

    local callback = callbacks[rid]
    if callback then
      -- free request id
      ids:free(rid)
      callbacks[rid] = nil

      -- call
      callback(table.unpack(rets, 1, table.maxn(rets)))
    end

    Debug.pend()
  end)

  return r
end

return Proxy

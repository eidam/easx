local consul = require "easx.consul"
local utils = require "easx.utils"

local cjson = require('cjson')
local json_decode = cjson.decode
local json_encode = cjson.encode

local exports = {}

function getRouteConsulServiceForSource(source)
    return "/catalog/service/" .. consul.service_prefix .. source
end

function targetIsInValid(target)
    return not target or target == ngx.null or target == nil
end

function getRouteForSourceFromConsul(source, consulClient)

    local route = {}

    local consulService = getRouteConsulServiceForSource(source)

    local res, err = consulClient:get(consulService)

    if not res then
        ngx.log(ngx.ERR, err)
        return nil
    end

    if res.status == 200 and #res.body > 0 then
        local tags = utils.tagsToMap(res.body[1].ServiceTags)

        -- TODO check if exists
        route.target = tags["easx.target"]
        route.target_host = tags["easx.target_host"]
    else
        ngx.log(ngx.ERR, "Route not found in Consul for: " .. source)
        return nil
    end

    return route
end

function getRouteForSource(source, consulClient)
    local _
    local route = {}
    local cache = ngx.shared.easx

    ngx.log(ngx.DEBUG, "Looking for a route for " .. source)

    -- Check if keys exists in local cache
    local cached_target, _ = cache:get(source)
    local cached_target_host, _ = cache:get(source .. ":host")

    if cached_target and cached_target_host then
        ngx.log(ngx.DEBUG, "Cache hit for " .. source)
        route.target = cached_target
        route.target_host = cached_target_host
    else
        ngx.log(ngx.DEBUG, "Cache miss for " .. source)
        route = getRouteForSourceFromConsul(source, consulClient)

        if route == nil or targetIsInValid(route.target) then
            return nil
        end

        cache:set(source, route.target, 15)
        cache:set(source .. ":host", route.target_host, 15)
        ngx.log(ngx.DEBUG, "Caching route " .. source .. " to " .. route.target .. " ( " .. route.target_host .. ") for 15 seconds.")
    end

    return route
end

exports.getRouteForSource = getRouteForSource

return exports

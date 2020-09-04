local consul = require "easx.consul"
local routes = require "easx.routes"
local utils = require "easx.utils"

local consulClient = consul:client()

local host = ngx.var.host
local cache = ngx.shared.easx

local is_not_https = (ngx.var.scheme ~= "https")

function formatTarget(target)
    target = utils.ensure_protocol(target)
    target = utils.ensure_no_trailing_slash(target)

    return target .. ngx.var.request_uri
end

function redirect(source, route)
    ngx.log(ngx.INFO, "Redirecting request for " .. source .. " to " .. route.target .. ".")
    return ngx.redirect(route.target, ngx.HTTP_MOVED_PERMANENTLY)
end

function proxy(source, target)
    ngx.var.target = target
    ngx.log(ngx.INFO, "Proxying request for " .. source .. " to " .. target .. ".")
end

function routeRequest(source, route)
    ngx.log(ngx.DEBUG, "Received routing request from " .. source .. " to " .. route.target)

    local target = formatTarget(route.target)

    -- TODO implement redirect mode
    --if route.mode == "redirect" then
    --    return redirect(source, target)
    --end

    return proxy(source, target)
end

if is_not_https then
    return ngx.redirect("https://" .. host .. ngx.var.request_uri, ngx.HTTP_MOVED_PERMANENTLY)
end

ngx.log(ngx.INFO, "HOST " .. host)
local route = routes.getRouteForSource(host, consulClient)

if route == nil or route == {} then
    ngx.log(ngx.INFO, "No $wildcard target configured for fallback. Exiting with Bad Gateway.")
    return ngx.exit(ngx.HTTP_SERVICE_UNAVAILABLE)
end

-- Save found key to local cache for 5 seconds
routeRequest(host, route)

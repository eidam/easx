local redis = require "resty.redis"
local utils = require "easx.utils"

local prefix = utils.getenv("EASX_REDIS_PREFIX", "easx")
local host = utils.getenv("EASX_REDIS_HOST", "127.0.0.1")
local port = utils.getenv("EASX_REDIS_PORT", 6379)
local password = utils.getenv("EASX_REDIS_PASSWORD", nil)
local timeout = utils.getenv("EASX_REDIS_TIMEOUT", 100)  -- 100 ms

local exports = {}

local redis_options = {
    ssl = utils.getenv("EASX_REDIS_SSL", false),
    ssl_verify = utils.getenv("EASX_REDIS_SSL_VERIFY", false)
}

function exports.client()
    -- Prepare the Redis client
    ngx.log(ngx.DEBUG, "Preparing Redis client.")

    local red = redis:new()
    red:set_timeout(timeout) 

    local res, err = red:connect(host, port, redis_options)

    ngx.log(ngx.DEBUG, "Redis client prepared.")

    -- Return if could not connect to Redis
    if not res then
        ngx.log(ngx.DEBUG, "Could not prepare Redis client: " .. err)
        return ngx.exit(ngx.HTTP_SERVER_ERROR)
    end

    ngx.log(ngx.DEBUG, "Redis client prepared.")

    if password then
        ngx.log(ngx.DEBUG, "Authenticating with Redis.")
        local res, err = red:auth(password)
        if not res then
            ngx.log(ngx.ERR, "Could not authenticate with Redis: " .. err)
            return ngx.exit(ngx.HTTP_SERVER_ERROR)
        end
    end
    ngx.log(ngx.DEBUG, "Authenticated with Redis.")

    return red
end

exports.prefix = prefix
exports.host = host
exports.port = port
exports.password = password
exports.redis_options = redis_options

return exports

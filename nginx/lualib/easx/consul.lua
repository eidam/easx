local resty_consul = require "resty.consul"
local utils = require "easx.utils"

local service_prefix = utils.getenv("EASX_CONSUL_SERVICE_PREFIX", "easx-")
local host = utils.getenv("EASX_CONSUL_HOST", "consul.service.consul")
local token = utils.getenv("EASX_CONSUL_TOKEN", "")

local exports = {}

function exports.client()
    -- Prepare the Redis client
    ngx.log(ngx.DEBUG, "Preparing Consul client.")

    local consul, err = resty_consul:new({
        host            = host,
        port            = 8500,
        connect_timeout = 3000,
        read_timeout    = 2000,
        default_args    = {
            token = token
        },
        ssl             = false,
        ssl_verify      = nil,
        sni_host        = nil,
    })

    ngx.log(ngx.DEBUG, "Consul client prepared.")

    return consul
end

exports.service_prefix = service_prefix

return exports

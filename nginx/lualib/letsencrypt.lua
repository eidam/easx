auto_ssl = (require "resty.auto-ssl").new()

local redis = require "easx.redis"
local consul = require "easx.consul"
local routes = require "easx.routes"
local utils = require "easx.utils"

local letsEncryptHookServerPort = tonumber(utils.getenv("EASX_LETS_ENCRYPT_HOOK_SERVER_PORT", "8999"))
auto_ssl:set("hook_server_port", letsEncryptHookServerPort)

-- If desired, use Lets Encrypt staging server
local letsEncryptStaging = os.getenv("EASX_LETS_ENCRYPT_STAGING")
if letsEncryptStaging then
    auto_ssl:set("ca", "https://acme-staging-v02.api.letsencrypt.org/directory")
end

-- Define a function to determine which SNI domains to automatically handle
-- and register new certificates for. Defaults to not allowing any domains,
-- so this must be configured.
auto_ssl:set(
    "allow_domain",
    function(domain)
        local consulClient = consul:client()
        local host = domain
        local route = routes.getRouteForSource(host, consulClient)

        if route == nil then
            return route
        end

        return true
    end
)

-- Set the resty-auto-ssl storage to Redis, using the EASX_* env variables
auto_ssl:set("storage_adapter", "resty.auto-ssl.storage_adapters.redis")
auto_ssl:set(
    "redis",
    {
        host = redis.host,
        port = redis.port,
        connect_options = redis.redis_options,
        auth = redis.password,
        prefix = redis.prefix
    }
)

auto_ssl:init()
require "resty.core"

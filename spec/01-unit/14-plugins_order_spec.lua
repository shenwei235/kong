local utils       = require "kong.tools.utils"
local helpers     = require "spec.helpers"
local conf_loader = require "kong.conf_loader"


local fmt = string.format


describe("Plugins", function()
  local plugins

  setup(function()
    local conf = assert(conf_loader())

    plugins = {}

    for plugin in pairs(conf.plugins) do
      local handler = require("kong.plugins." .. plugin .. ".handler")
      table.insert(plugins, {
        name    = plugin,
        handler = handler
      })
    end
  end)

  it("don't have identical `PRIORITY` fields", function()
    local priorities = {}

    for _, plugin in ipairs(plugins) do
      local priority = plugin.handler.PRIORITY
      assert.not_nil(priority)

      if priorities[priority] then
        assert.fail(fmt("plugins have the same priority: '%s' and '%s' (%d)",
                        priorities[priority], plugin.name, priority))
      end

      priorities[priority] = plugin.name
    end
  end)

  it("run in the following order", function()
    -- here is the order as of 0.10.1 with OpenResty 1.11.2.2
    --
    -- since 1.11.2.3 and the LuaJIT string hashing change, we hard-code
    -- that those plugins execute in this order, only to preserve
    -- backwards-compatibility

    local order = {
      "bot-detection",
      "cors",
      "jwt",
      "basic-auth",
      "oauth2",
      "key-auth",
      "hmac-auth",
      "ldap-auth",
      "ip-restriction",
      "acl",
      "request-size-limiting",
      "rate-limiting",
      "response-ratelimiting",
      "response-transformer",
      "request-transformer",
      "aws-lambda",
      "datadog",
      "udp-log",
      "loggly",
      "syslog",
      "statsd",
      "runscope",
      "http-log",
      "request-termination",
      "tcp-log",
      "galileo",
      "correlation-id",
      "file-log",
    }

    table.sort(plugins, function(a, b)
      local priority_a = a.handler.PRIORITY or 0
      local priority_b = b.handler.PRIORITY or 0

      return priority_a > priority_b
    end)

    local sorted_plugins = {}

    for _, plugin in ipairs(plugins) do
      table.insert(sorted_plugins, plugin.name)
    end

    assert.same(order, sorted_plugins)
  end)
end)
local Admin = require "api-umbrella.web-app.models.admin"
local build_url = require "api-umbrella.utils.build_url"
local capture_errors = require("lapis.application").capture_errors
local flash = require "api-umbrella.web-app.utils.flash"
local respond_to = require "api-umbrella.web-app.utils.respond_to"
local t = require("api-umbrella.web-app.utils.gettext").gettext

local _M = {}

function _M.new(self)
  self.admin_params = {}
  return { render = "admin.registrations.new" }
end

function _M.create(self)
  self.current_admin = {
    id = "00000000-0000-0000-0000-000000000000",
    username = "admin",
    superuser = true,
  }

  ngx.ctx.current_admin = self.current_admin

  self.admin_params = _M.admin_params(self)
  assert(Admin:create(self.admin_params))

  return { redirect_to = build_url("/admin/#/login") }
end

function _M.admin_params(self)
  local params = {}
  if self.params and self.params["admin"] then
    local input = self.params["admin"]
    params = {
      username = input["username"],
      password = input["password"],
      password_confirmation = input["password_confirmation"],

      -- Make the first admin a superuser on initial setup.
      superuser = true,
    }
  end

  return params
end

function _M.first_time_setup_check(self)
  if not Admin.needs_first_account() then
    flash.session(self, "info", t("An initial admin account already exists."))
    return self:write({ redirect_to = build_url("/admin/") })
  end
end

return function(app)
  app:match("/admins/signup(.:format)", respond_to({
    before = function(self)
      _M.first_time_setup_check(self)
    end,
    GET = _M.new,
  }))
  app:match("/admins(.:format)", respond_to({
    before = function(self)
      _M.first_time_setup_check(self)
    end,
    POST = capture_errors({
      on_error = function()
        return { render = "admin.registrations.new" }
      end,
      _M.create,
    }),
  }))
end

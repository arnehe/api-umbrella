local common_validations = require "api-umbrella.web-app.utils.common_validations"
local json_encode = require "api-umbrella.utils.json_encode"

local _M = {}

function _M.loader(self)
  local data
  local locale = ngx.ctx.locale
  if locale and LOCALE_DATA and LOCALE_DATA[locale] and LOCALE_DATA[locale]["locale_data"] then
    data = LOCALE_DATA[locale]["locale_data"]
  else
    data = {
      ["api-umbrella"] = {
        [""] = {
          domain = "api-umbrella",
          lang = "en",
          plural_forms = "nplurals=2; plural=(n != 1);",
        }
      }
    }
  end

  self.res.headers["Content-Type"] = "text/javascript; charset=utf-8"
  self.res.headers["Cache-Control"] = "max-age=0, private, no-cache, no-store, must-revalidate"
  self.res.content = [[
    window.localeData = ]] .. json_encode(data) .. [[;
    window.CommonValidations = {
      host_format: new RegExp(]] .. json_encode(common_validations.host_format) .. [[),
      host_format_with_wildcard: new RegExp(]] .. json_encode(common_validations.host_format_with_wildcard) .. [[),
      url_prefix_format: new RegExp(]] .. json_encode(common_validations.url_prefix_format) .. [[)
    };
  ]]
  return { layout = false }
end

return function(app)
  app:get("/admin/server_side_loader.js", _M.loader)
end

-- MIT License
-- 
-- Copyright (c) 2021 Baptiste Assmann, https://github.com/bedis/haproxy_lua_vault_module
-- 
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
-- 
-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.
-- 
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.

-- https://github.com/rxi/json.lua
local json   = require("json")

local _M = {
  version = "0.0.1",
}

-- Create a module object from scratch or optionally
-- based on another passed object.
--
-- The following object members are accepted:
-- url           Optional Vault connection address - defaults to to VAULT_ADDR
--               from environment or https://127.0.0.1:8200
-- host          Optional HTTP Host header field to send
-- timeout       Optional time to wait for an answer
-- secretEngine  Optional Vault secret engine - defaults to "kv-v2"
--               NOTE: only "kv-v2" is supported for now
-- apiVersion    Optional Vault API version - defaults to "v1" for now
--               NOTE: only "v1" is supported for now
--
-- @param o      Optional object settings
--
-- @return       Module object and error string
function _M:New(o)
	local o = o or {} -- create an empty table if none passed

	o.url          = o.url or os.getenv("VAULT_ADDR") or "127.0.0.1:8200"
	o.host         = o.host or nil
	--o.timeout      = o.timeout
	o.secretEngine = "kv-v2" -- no other value allowed for now
	o.apiVersion   = "v1" -- no other value allowed for now

	-- sanitization checks
	if o.token == nil or type(o.token) ~= "string" then
		return nil, "no token provided"
	end

	-- set self
	setmetatable(o, self)
	self.__index = self

	return o
end

local function callVault(self, api, input, method)
	local httpclient = core.httpclient()

	-- build request
	local request = {
		url     = self.url .. api,
		headers = {
			["accept"]        = { 'application/json' },
			["x-vault-token"] = { self.token },
		},
		body    = intput,
	}
	if self.host ~= nil then
		request.headers.host = { self.host }
	end

	-- prepare response
	local response = {}

	if method == 'GET' or method == nil then
		response = httpclient:get(request)
	elseif method == 'HEAD' then
		response = httpclient:head(request)
	elseif method == 'PUT' then
		response = httpclient:put(request)
	elseif method == 'POST' then
		response = httpclient:post(request)
	elseif method == 'DELETE' then
		response = httpclient:delete(request)
	else
		response = nil
	end

	-- check response
	if not response then
		-- error out
		return nil, "Failed to execute request."
	end

	-- check error status
	if response.status == 400 or response.status == 403 then
		local data, err = json.decode(response.body)
		-- return first line of error message
		for a, line in pairs(data['errors']) do
			return nil, line
		end
	elseif response.status == 404 then
		return nil, "not found"
	elseif response.status ~= 200 then
		return nil, "unknown error: " .. tostring(response.status)
	end

	local data, err = json.decode(response.body)

	if not data or err ~= nil then
		return nil, tostring(err)
	end

	return data, nil
end


-- get a specific secret name
-- @param table        name and secretPath of the scret to get
-- @return             Result and error or nil
function _M:getSecret (o)
	if type(o) ~= "table" then
		return nil, "incompatible object type: " .. type(o)
	end

	if o.secretPath == nil then
		return nil, "no secret path provided"
	end
	if o.name == nil then
		return nil, "no name provided"
	end

	-- build call
	local api = self.apiVersion .. '/' .. o.secretPath .. '/data/' .. o.name

	return callVault(self, api)
end


-- renew a token
-- @return             result and error or nil
function _M:tokenRenew ()
	-- build call
	local api = self.apiVersion .. '/auth/token/renew-self'
	local _, err = callVault(self, api, nil, "POST")
	return err
end

-- return module table
return _M

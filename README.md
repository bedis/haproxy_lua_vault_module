# haproxy_lua_vault_module

A module for HAProxy 2.5 and above to interact with hashicorp Vault using Lua.

## Quick start

Copy the `vault.lua` file in your Lua path or use the haproxy global directive `lua-prepend-path` to load it properly form your own Lua code.

Example, if your lua scripts are installed in a specific path:

    lua-prepend-path /my/path/lua/?.lua

In your Lua script, simply load the module like this:

    haproxy = require("vault")

Generate a token in vault with relevant policy

    vault token create -policy=certs -display-name=ca

Then, use the New() function to create a new instance:

    -- Vault handler
    local myVault = {
      url   = "https://127.0.0.1/",
      host  = "vault.mydomain.com",
      token = "TOKEN_GENERATER_AT_PREVIOUS_STEP",
    }
    local h, err = vault:New(myVault)
    if err ~= nil then
      print(err)
      return
    end

Note: due to a limitation in current `httpclient`, the URL must contain the IP address of the Vault server and we pass the relevant hostname as a Host header.

## Methods

### New(o)

Create a new vault instance

* **@param** o: object containing information to get connected to vault
* **@return**: module instance or nil and an error message

The `o` object takes the following parameters:

| Parameter | type    |  description                                  | default value |
|-----------|---------|-----------------------------------------------|---------------|
| url       | string  | URL with IP address where vault is available  | 127.0.0.1     |
| host      | string  | Option Host header to get connected to vault  | 1023          |
| token     | string  | Vault token                                   |               |

## getSecret(o)

Read a secret from vault

* **@param** o: object containing information related to the secret we want to get
* **@return**: a Lua indexed table with the secret object or nil and an error message

The `o` object takes the following parameters:

| Parameter  | type    |  description                              | default value |
|------------|---------|-------------------------------------------|---------------|
| secretPath | string  | KV name where the secrets are stored      |               |
| name       | string  | name of the certificate in KV storage     |               |

## tokenRenew()

Renew a vault token. The token to be renewed is the one used when creating the instance.

* **@return**: nil or an error message

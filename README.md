# PoshBot.ZabbixPS

This plugin for [PoshBot](https://github.com/poshbotio/PoshBot) provides functions to interact with Zabbix via ChatOps (Slack, Teams, etc)

Key functions included in this plugin include

- Getting Zabbix Problems
- Getting Zabbix Maintenace
- Acknowledging Zabbix Events

## Configuration

In order to use this plugin you must have the following:

- Working setup of PoshBot
- A zabbix Service account (minimum below)
  - 'Zabbix User' is enough for acknowledging
  - 'Read' to the Host Groups you want it to read problems
- Configure a secret under `PluginConfiguration` for PoshBot as a PSCredential (example below)
- Uses the [ZabbixPS](https://www.powershellgallery.com/packages/ZabbixPS) module for all Zabbix calls

### PluginConfiguration

The Zabbix API requires that you initally authenticate before receiving a Token for your session.
As a result you need to store (or generate at runtime) the Service account credentials in the PoshBot configuration (as `ZabbixAPI`).
Additionally you will want to include a configuration variable for your Zabbix `InstanceData`.
There is already a [Guide on this in the poshbot repo](https://github.com/poshbotio/PoshBot/blob/master/docs/guides/plugin-configuration.md), but for those unfamiliar the final result should look like this:

Note: ZabbixAPI is the variable used in functions to autoload credentials, and InstanceData is a hashtable of the friendly name and URI to your specific instance. If you have more than one instance you may add addition key/value pairs to the hashtable

```powershell

@{
...
    PluginConfiguration = @{
        PoshBot.ZabbixPS = @{
            ZabbixAPI = (PSCredential "ZabbixServiceAcct", "0100sdfg02452042....")
            Instance = @{dev = "https://<fqdn>/zabbix/api_jsonrpc.php"; prod = "https://<fqdn>/zabbix/api_jsonrpc.php"}
        }
    }
...
}

```

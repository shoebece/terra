variable resource_group_name            {type = string}
variable resource_location              {type = string}
variable resource_tags                  {type = map(string)}

variable vnet_name                      {type = string}
variable nsg_name                       {type = string}
variable vnet_purpose                   {type = string}
variable vnet_address_space             {type = list(string)}
variable default_snet_address_space     {type = list(string)}
variable private_snet_address_space     {type = list(string)}
variable public_snet_address_space      {type = list(string)}

variable "pdnsz_names"                  {type = list(string)}
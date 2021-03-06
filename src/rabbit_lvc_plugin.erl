-module(rabbit_lvc_plugin).

-include("rabbit_lvc_plugin.hrl").

-export([setup_schema/0]).

-rabbit_boot_step({?MODULE,
                   [{description, "last-value cache exchange type"},
                    {mfa, {rabbit_lvc_plugin, setup_schema, []}},
                    {mfa, {rabbit_exchange_type_registry, register, [<<"x-lvc">>, rabbit_exchange_type_lvc]}},
                    {requires, rabbit_exchange_type_registry},
                    {enables, exchange_recovery}]}).

%% private

setup_schema() ->
    case mnesia:create_table(?LVC_TABLE,
                             [{attributes, record_info(fields, cached)},
                              {record_name, cached},
                              {type, set}]) of
        {atomic, ok} -> ok;
        {aborted, {already_exists, ?LVC_TABLE}} -> ok
    end.

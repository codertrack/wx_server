%%%-------------------------------------------------------------------
%% @doc wx_server public API
%% @end
%%%-------------------------------------------------------------------

-module(wx_server_app).
-include("user_record.hrl").
-behaviour(application).

%%定义Tcp端口
-define(CHAT_PORT, 10000).
%%定义Web端口
-define(WEB_PORT, 20000).
%% Application callbacks
-export([start/2, stop/1, start_ranch_server/0, start_cowboy_server/0]).

%%====================================================================
%% API
%%====================================================================

start(_StartType, _StartArgs) ->
  mnesia:stop(),
  create_mnesia_schema(),
  mnesia:start(),
  A = mnesia:wait_for_tables([table_user, table_message_offline], 20000),
  io:format("wait state-> ~p", [A]),
  %%启动chatserver
  start_ranch_server(),
  %%启动web_server
  start_cowboy_server(),
  wx_server_sup:start_link().


%%--------------------------------------------------------------------
stop(_State) ->
  mnesia:stop(),
  ok.

%%====================================================================
%% Internal functions
%%====================================================================

%%启动服务器监听
start_ranch_server() ->
  {ok, _} = ranch:start_listener(wx_server, 1, ranch_tcp,
    [{port, ?CHAT_PORT}], wx_protocol, []).
%%
start_cowboy_server() ->
  Dispatch = cowboy_router:compile([
    {'_', [
      {"/api/login", web_login, []},
      {"/api/login/token", web_login_token, []},
      {"/api/reg", web_register, []},
      {"/api/friends", web_friends, []},
      {"/api/msg/offline", web_offline_msg, []}
    ]}
  ]),
  {ok, _} = cowboy:start_http(http, 100, [{port, ?WEB_PORT}], [
    {env, [{dispatch, Dispatch}]}
  ]).

%%创建数据库表
create_mnesia_schema() ->
  %%mnesia:create_table(person, [{disc_only_copies, nodes()},
  %% {attributes, record_info(fields,person)}]).
  B=mnesia:create_schema([node()]),
  io:format("create schema state= ~p ~n", [B]),
  mnesia:start(),
  State1 = mnesia:create_table(table_user,
    [
      {storage_properties,
        [{dets, [{auto_save, 3000}]}]},
      {disc_copies, [node()]},
      {attributes, record_info(fields, table_user)}
    ]
  ),

  io:format("create table user state= ~p ~n", [State1]),
  State2=mnesia:create_table(table_message_offline,
    [
      {storage_properties,
        [{dets, [{auto_save, 3000}]}]},
      {disc_copies,[node()]},
      {type, bag},
      {attributes, record_info(fields, table_message_offline)}
    ]
  ),
  io:format("create table user state= ~p ~n", [State2]),
  mnesia:stop(),
  ok.


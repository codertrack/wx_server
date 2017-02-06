%%%-------------------------------------------------------------------
%% @doc wx_server top level supervisor.
%% @end
%%%-------------------------------------------------------------------

-module(wx_server_sup).

-behaviour(supervisor).
-include("user_record.hrl").
%% API
-export([start_link/0]).

%% Supervisor callbacks
-export([init/1]).

-define(SERVER, ?MODULE).

start_link() ->
    %%创建一个监督进程
    supervisor:start_link({local, ?SERVER}, ?MODULE, []).

%%====================================================================
%% Supervisor callbacks
%%====================================================================

%%子进程规范 Child :: {Id,StartFunc,Restart,Shutdown,Type,Modules}
init([]) ->

    %%创建进程表
    table_conn = ets:new(table_conn, [
        set, public, named_table,
        %%此处参数为并发读写
        {write_concurrency, true}, {read_concurrency, true},
        {keypos,#table_conn.email}]),

    %%重启策略
    RestartStrategy = one_for_all,
    %%重启次数
    MaxRestarts = 1000,
    %%重启间隔时间
    MaxSecondsBetweenRestarts = 3600,

    SupFlags = {RestartStrategy, MaxRestarts, MaxSecondsBetweenRestarts},
    %%始终重启
    Restart = permanent,
    Shutdown = 2000,
    Type = supervisor,

    AChild = {wx_message_sup, {wx_message_sup, start_link, []},
        Restart, Shutdown, Type, [wx_message_sup]},

    BChild = {wx_uuid_server, {wx_uuid_server, start_link, []},
        Restart, Shutdown, worker, [wx_uuid_server]},

    {ok, {SupFlags, [AChild,BChild]}}.

%%====================================================================
%% Internal functions
%%====================================================================

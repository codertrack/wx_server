%%%-------------------------------------------------------------------
%%% @author wukai
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 16. 七月 2016 16:49
%%%-------------------------------------------------------------------
-module(wx_uuid_server).
-author("wukai").

-behaviour(gen_server).

-export([start_link/0,stop/0,new/0]).

%% gen_server callbacks
-export([init/1,
  handle_call/3,
  handle_cast/2,
  handle_info/2,
  terminate/2,
  code_change/3]).

-define(SERVER, ?MODULE).

-record(state, {}).

start_link() ->
  gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).
init([]) ->
  {ok, #state{}}.

handle_call(create, _From,State) ->
  A = utc_random(),
  io:format("uuid-> ~p",[A]),
  {reply, A,State}.

handle_cast(stop, State) ->
  {stop, normal, State};
handle_cast(_Request, State) ->
  {noreply, State}.

handle_info(_Info, State) ->
  {noreply, State}.

terminate(_Reason, _State) ->

  ok.

code_change(_OldVsn, State, _Extra) ->
  {ok, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================
stop() ->
  gen_server:cast(?MODULE, stop).

new() ->
  gen_server:call(?MODULE, create).

utc_random() ->
  Now = {_, _, Micro} = now(),
  Nowish = calendar:now_to_universal_time(Now),
  Nowsecs = calendar:datetime_to_gregorian_seconds(Nowish),
  Then = calendar:datetime_to_gregorian_seconds({{1970, 1, 1}, {0, 0, 0}}),
  Prefix = io_lib:format("~14.16.0b", [(Nowsecs - Then) * 1000000 + Micro]),
  list_to_binary(Prefix ++ wx_util:to_hex(crypto:rand_bytes(9))).

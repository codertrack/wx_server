%%%-------------------------------------------------------------------
%%% @author wukai
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 19. 七月 2016 09:59
%%%-------------------------------------------------------------------
-module(db_message_dao).
-author("wukai").
-include("../user_record.hrl").
-include_lib("stdlib/include/qlc.hrl").
%% API
-export([save_offline_msg/7, get_all_message_email/1]).


save_offline_msg(Con, Time, Type, Target, From, Port, CMD) ->
  Message = #table_message_offline{msg = Con, cmd = CMD, time = Time, from = From, port = Port, target = Target, type = Type},
  F = fun() -> mnesia:write(Message) end,
  case mnesia:transaction(F) of
    {atomic, Val} ->
      io:format("write user sucess ~n"),
      io:format("write= ~p~n", [Val]),
      {ok};
    {aborted, Reason} ->
      io:format("write error ~p", [Reason]),
      {error}
  end.

get_all_message_email(Email) ->
  Where = qlc:q([X || X <- mnesia:table(table_message_offline), X#table_message_offline.target == Email]),
  Val = db_utils:do_query(Where),
  io:format("all message= ~p~n", [Val]),
  Len = length(Val),
  if
    Len > 0 -> delete_message_by_target(Email), {ok, Val};
    true -> {error, "message not find"}
  end.


delete_message_by_target(Target) ->
  F = fun() ->
      mnesia:delete({table_message_offline,Target})
      end,
  R = mnesia:transaction(F),
  io:format("delete result~p", [R]),
  ok.
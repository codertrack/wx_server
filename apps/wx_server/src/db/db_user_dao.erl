%%%-------------------------------------------------------------------
%%% @author wukai
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 19. 七月 2016 09:57
%%%-------------------------------------------------------------------
-module(db_user_dao).
-author("wukai").
-include("../user_record.hrl").
-include_lib("stdlib/include/qlc.hrl").
%% API
-export([get_user_by_token/1,get_user/1,get_friends/1,get_user_by_md5/1]).

get_user_by_token(Token) ->

  Where = qlc:q([X|| X <- mnesia:table(table_user), X#table_user.token == Token],{unique, true}),
  Val = do_query(Where),
  io:format("tcp login user= ~p~n", [Val]),
  Len = length(Val),
  if
    Len ==1 ->[H|T]=Val, {ok,H};
    true -> {error,"Failed"}
  end
.

get_user_by_md5(Md5) ->

  Where = qlc:q([X|| X <- mnesia:table(table_user), X#table_user.md5 == Md5],{unique, true}),
  Val = do_query(Where),
  io:format("tcp login user= ~p~n", [Val]),
  Len = length(Val),
  if
    Len ==1 ->[H|T]=Val, {ok,H};
    true -> {error,"Failed"}
  end
.


get_user(Token) ->

  Where = qlc:q([X|| X <- mnesia:table(table_user), X#table_user.token == Token],{unique, true}),
  Val = do_query(Where),
  io:format("getuser login user= ~p~n", [Val]),
  Len = length(Val),
  if
    Len > 0 -> {ok};
    true -> {error}
  end
.

get_friends(Token)->
  Where = qlc:q([X|| X <- mnesia:table(table_user),X#table_user.token =/=Token]),
  Val = do_query(Where),
  io:format("all user= ~p~n", [Val]),
  Len = length(Val),
  if
    Len > 0 -> {ok,Val};
    true -> {error,"user not find"}
  end
.

%%查询
do_query(Where) ->
  F = fun() -> qlc:e(Where) end,
  {atomic, Val} = mnesia:transaction(F),
  Val.


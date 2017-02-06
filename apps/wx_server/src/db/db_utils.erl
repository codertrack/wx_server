%%%-------------------------------------------------------------------
%%% @author wukai
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 22. 七月 2016 10:29
%%%-------------------------------------------------------------------
-module(db_utils).
-author("wukai").

%% API
-export([do_query/1]).

%%查询
do_query(Where) ->
  F = fun() -> qlc:e(Where) end,
  {atomic, Val} = mnesia:transaction(F),
  Val.


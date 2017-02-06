%%%-------------------------------------------------------------------
%%% @author wukai
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 19. 七月 2016 15:52
%%%-------------------------------------------------------------------
-module(web_friends).
-author("wukai").
-behavior(cowboy_http_handler).
%% API
-export([init/3, handle/2, terminate/3]).

-include("../web_res_code.hrl").
-include("../user_record.hrl").

init(_Type, Req, []) ->
  {ok, Req, undefined}.

handle(Req, State) ->
  Null = <<"null">>,
  {Token, _} = cowboy_req:qs_val(<<"token">>, Req, Null),
  if
    Token =/= Null ->
      T2 = binary_to_list(Token),
      case db_user_dao:get_friends(T2) of
        {ok, U_List} ->
          Users = lists:flatmap(fun(X)->[user(X)] end, U_List),

          io:format("users ~p ~n",[Users]),
          Response = {obj, [{"users", Users},{"o",<<"ok">>}]},
          replyResponse(?ACTION_CODE_SUCESS, Response, Req, State);
        {error, Reason} ->
          replyResponse(?ACTION_CODE_FAILED, <<"">>, Req, State)
      end;
    true ->
      replyResponse(?ACTION_CODE_FAILED, <<"parms error">>, Req, State)
  end.

terminate(_Reason, _Req, _State) ->
  io:format("conn close~n"),
  ok.

replyResponse(Code, Msg, Req, State) ->
  Json = {
    obj,
    [{"code", Code}, {"msg", Msg}]},
  JsonString = rfc4627:encode(Json),
  {ok, Req2} = cowboy_req:reply(200, [
    {<<"content-type">>, <<"text/html;charset=utf-8">>}
  ], erlang:list_to_binary(JsonString), Req),
  {ok, Req2, State}.
%%查询

user(T) ->
  {obj,[{"email", list_to_binary(T#table_user.email)},
    {"nick_name", T#table_user.nick_name},
    {"declaration", unicode:characters_to_binary(T#table_user.declaration)}]}.
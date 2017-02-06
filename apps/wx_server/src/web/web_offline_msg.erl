%%%-------------------------------------------------------------------
%%% @author wukai
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 19. 七月 2016 15:52
%%%-------------------------------------------------------------------
-module(web_offline_msg).
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
  {Email, _} = cowboy_req:qs_val(<<"email">>, Req, Null),
  if
    Email =/= Null ->
      case db_message_dao:get_all_message_email(Email) of
        {ok, VAl} ->
          MSGS = lists:flatmap(fun(X)->[message(X)] end, VAl),
          io:format("users ~p ~n",[MSGS]),
          Response = {obj, [{"off_msg", MSGS},{"o",<<"ok">>}]},
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

message(T) ->
  {obj,[
    {"from",list_to_binary(T#table_message_offline.from)},
    {"msg", T#table_message_offline.msg},
    {"port",T#table_message_offline.port},
    {"cmd",T#table_message_offline.cmd},
    {"time",T#table_message_offline.time}
    ]}.
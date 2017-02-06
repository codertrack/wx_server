%%%-------------------------------------------------------------------
%%% @author wukai
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 09. 七月 2016 11:34
%%%-------------------------------------------------------------------
-module(web_login_token).
-author("wukai").
-behavior(cowboy_http_handler).


%% API
-export([init/3, handle/2, terminate/3]).
-include("user_record.hrl").
-include("web_res_code.hrl").
-include_lib("stdlib/include/qlc.hrl").

init(_Type, Req, []) ->
  {ok, Req, undefined}.

handle(Req, State) ->
  Null = <<"null">>,
  {Token, _} = cowboy_req:qs_val(<<"token">>, Req, Null),
  if
    Token =/= Null ->
      T2 = binary_to_list(Token),
      case db_user_dao:get_user(T2) of
        {ok} ->
          io:format("login sucess"),
          replyResponse(?ACTION_CODE_SUCESS, <<"login sucess">>, Req, State);
        {error} ->
          replyResponse(?ACTION_CODE_FAILED, <<"login failed">>, Req, State)
      end;
    true ->
      replyResponse(?ACTION_CODE_FAILED, <<"params error">>, Req, State)
  end.

terminate(_Reason, _Req, _State) ->
  io:format("complete close~n"),
  
  ok.


replyResponse(Code, Msg, Req, State) ->
  Json = {
    obj,
    [{"code", Code}, {"msg", Msg}]},
  Json_str = rfc4627:encode(Json),
  {ok, Req2} = cowboy_req:reply(200, [
    {<<"content-type">>, <<"text/plain">>}
  ], erlang:list_to_binary(Json_str), Req),
  {ok, Req2, State}.


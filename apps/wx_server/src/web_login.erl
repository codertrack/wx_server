%%%-------------------------------------------------------------------
%%% @author wukai
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 09. 七月 2016 11:34
%%%-------------------------------------------------------------------


-module(web_login).
-author("wukai").
-behavior(cowboy_http_handler).
%% API
-export([init/3,handle/2,terminate/3]).
-include("user_record.hrl").
-include("web_res_code.hrl").
-include_lib("stdlib/include/qlc.hrl").


init(_Type, Req, [])->
  {ok, Req, undefined}.

handle(Req,State)->
  {Email,_} = cowboy_req:qs_val(<<"username">>, Req, true),
  {Pass,_} = cowboy_req:qs_val(<<"password">>, Req, true),
  if
    Email ==true orelse Pass==true ->
      replyResponse(?ACTION_CODE_FAILED, <<"parms error">>, Req, State);
    true ->

      E1 = binary_to_list(Email),
      P1= binary_to_list(Pass),
      S1 = string:concat(E1, P1),
      Md5 = md5_string:md5_hex(S1),

      case db_user_dao:get_user_by_md5(Md5) of
        {ok, Data} ->
          {table_user,_,_,_,Token,_,_,_,_,_} = Data,
          Msg1 = {obj, [{"token", list_to_binary(Token)}]},
          replyResponse(?ACTION_CODE_SUCESS, Msg1, Req, State);
        {error,Reson} ->
          replyResponse(?ACTION_CODE_FAILED, <<"login failed">>, Req, State)
      end
  end.


%%查询
do_query(Where) ->
  F = fun() -> qlc:e(Where) end,
  {atomic, Val} = mnesia:transaction(F),
  Val.


terminate(_Reason, _Req, _State) ->
  io:format("complete close~n"),
  ok.

replyResponse(Code,Msg,Req,State)->
  Json = {
    obj,
    [{"code", Code}, {"msg",Msg}]},
  Json_str = rfc4627:encode(Json),
  {ok, Req2} = cowboy_req:reply(200, [
    {<<"content-type">>, <<"text/plain">>}
  ], erlang:list_to_binary(Json_str), Req),
  {ok, Req2, State}.
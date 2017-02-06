%%%-------------------------------------------------------------------
%%% @author wukai
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 09. 七月 2016 11:34
%%%-------------------------------------------------------------------
-module(web_register).
-author("wukai").
-include("user_record.hrl").
-include("web_res_code.hrl").

%%使用erlang,qlc
-include_lib("stdlib/include/qlc.hrl").
-include("user_record.hrl").
-behavior(cowboy_http_handler).
%% API
-export([init/3, handle/2, terminate/3]).

init(_Type, Req, []) ->
  {ok, Req, undefined}.

handle(Req, State) ->
    Null = <<"null">>,
%%  case cowboy_req:body_qs(Req) of
%%    {ok,[{<<"username">>,Username},{<<"password">>,Password}]}
%%  end,
  {User_Email,_} = cowboy_req:qs_val(<<"username">>, Req,Null),
  {User_Pass,_} = cowboy_req:qs_val(<<"password">>, Req,Null),
  {Nick_name,_} = cowboy_req:qs_val(<<"nickname">>, Req,Null),

    if
      User_Email == Null orelse User_Pass== Null orelse Nick_name == Null->
        replyResponse(?ACTION_CODE_FAILED, <<"params error">>, Req, State);
      true ->
        case user_exits(binary_to_list(User_Email)) of
          {ok} ->
            Time = time_utils:timestamp(),
            Email = binary_to_list(User_Email),
            Pass = binary_to_list(User_Pass),
            S1 = string:concat(Email, Pass),
            %%生成Md5
            MD5 = md5_string:md5_hex(S1),

            Token=wx_uuid_server:new(),
            User = #table_user{
              email = Email, password = Pass,
              time = Time, token = binary_to_list(Token), md5 = MD5,nick_name =Nick_name},
            case register(User) of
              {ok}->
                Msg1 = {obj, [{"token", Token}]},
                %%Msg1 = {obj, [{"token", list_to_binary(Token)}]},
                replyResponse(?ACTION_CODE_FAILED, Msg1, Req, State);
              {error}->
                replyResponse(?ACTION_CODE_FAILED, <<"register failed">>, Req, State)
              end;
          {error} ->
            replyResponse(?ACTION_CODE_FAILED, <<"email is used">>, Req, State)
        end
    end.

terminate(_Reason, _Req, _State) ->
  io:format("conn close~n"),
  ok.


user_exits(User_Email) ->

  io:format("query by= ~s ~n",[User_Email]),
  Where = qlc:q([X|| X <- mnesia:table(table_user), X#table_user.email == User_Email],{unique, true}),
  Val = do_query(Where),
  Len = length(Val),
  if
    Len > 0 -> {error};
    Len == 0 -> {ok}
  end
.

register(User) ->

  io:format("write user=> ~p~n", [User]),
  F = fun() -> mnesia:write(User) end,
  case mnesia:transaction(F) of
    {atomic, Val} ->
      io:format("write user sucess ~n"),
      io:format("write= ~p~n", [Val]),
      {ok};
    {aborted, Reason} ->
      io:format("write error ~p", [Reason]),
      {error}
  end.


replyResponse(Code, Msg, Req, State) ->
  Json = {obj, [{"code", Code}, {"msg", Msg}]},
  JsonString = rfc4627:encode(Json),
  {ok, Req2} = cowboy_req:reply(200, [
    {<<"content-type">>, <<"text/plain">>}
  ], erlang:list_to_binary(JsonString), Req),
  {ok, Req2, State}.
%%查询
do_query(Where) ->
  F = fun() -> qlc:e(Where) end,
  {atomic, Val} = mnesia:transaction(F),
  Val.

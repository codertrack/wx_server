%%%-------------------------------------------------------------------
%%% @author wukai
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 19. 七月 2016 10:09
%%%-------------------------------------------------------------------
-module(wx_protocol_user).
-include("../user_record.hrl").
-include("../protocol_define.hrl").
-author("wukai").
%%发送消息
-define(USER_CMD_MSG, 16#01).
%%请求添加好友
-define(USER_ADD_FRI, 16#02).
%%添加好友反馈
-define(USER_CMD_ADD_FRI_RES, 16#03).

%% API
-export([handle_cmd/3]).

handle_cmd(?USER_CMD_MSG, MSG, State) ->
  io:format("on proress state-> ~p ~n ", [State]),
  A = rfc4627:decode(MSG),
  io:format("receive msg-> ~p ~n", [A]),
  case A of

    {ok, JsonObject,[]} ->
      {ok,Talk} = rfc4627:get_field(JsonObject,"msg"),
      {ok,Target} = rfc4627:get_field(JsonObject,"target"),
      {ok,Time} = rfc4627:get_field(JsonObject,"time"),
      {ok,Type} = rfc4627:get_field(JsonObject,"type"),

      Target2 = binary_to_list(Target),
      Conn = ets:lookup(table_conn, Target2),
      Len = length(Conn),
      if
        Len > 0 ->
          [F | _] = Conn,
          {table_conn,_, Pid} = F,
          Pid ! {msg, Talk, Time, Type,State#state.email,16#02,?USER_CMD_MSG};
        true ->
          %% 发送用户不在线消息
           io:format("用户不在线"),
          R= db_message_dao:save_offline_msg(Talk, Time, Type,Target,State#state.email,16#02,?USER_CMD_MSG),
          io:format("write msg  ~p ~n",[R])
      end;
    _->
      io:format("match error  ~p ~n",[A])
  end
;


handle_cmd(?USER_ADD_FRI, MSG, State) ->
  io:format("user add").

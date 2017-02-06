%%%-------------------------------------------------------------------
%%% @author wukai
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 19. 七月 2016 10:09
%%%-------------------------------------------------------------------
-module(wx_protocol_sys).
-author("wukai").
-include("../user_record.hrl").
-include("../protocol_define.hrl").
%%login消息
-define(SYS_CMD_Login, 16#01).

%% API
-export([handle_cmd/3]).

handle_cmd(?SYS_CMD_Login, MSG, State) ->

  <<Version:?UBYTE,Left/binary>>=MSG,
  Token = binary_to_list(Left),
  io:format("version code-> ~p login token->~p", [Version,Token]),

  case db_user_dao:get_user_by_token(Token) of
    {ok, User} ->
      S1 = State#state{email = User#table_user.email,version = Version},
      send_init_status(S1, "ok");
    {error, _Reson} ->

      io:format("login failed"),

      S2 = State#state{continue = false},
      send_init_status(S2, "error"),
      {ok,S2}
  end.

send_init_status(State, Result) ->
  T = State#state.trans,
  Socket = State#state.socket,
  Seq = wx_message_worker:get_new_seq(State),

  Version = State#state.version,
  %%转二进制
  Con_Binary =list_to_binary(Result),
  %%内容长度
  Len =byte_size(Con_Binary),

  HeadFrame = wx_message_worker:get_frame_Head(Seq,?FRAME_TYPE_MSG,Len+3,Version),
  Data = <<HeadFrame/binary,1:?UBYTE,?SYS_CMD_Login:?USHORT,Con_Binary/binary>>,
  T:send(Socket,Data),
  NewState = State#state{send_seq = Seq},


  %%把此进程加入到ets进程表中
  ets:insert(table_conn,#table_conn{email = State#state.email,pid=self()}),
  {ok,NewState}.


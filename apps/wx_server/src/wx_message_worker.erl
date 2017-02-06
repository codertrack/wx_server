%%%-------------------------------------------------------------------
%%% @author wukai
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 14. 七月 2016 19:59
%%%-------------------------------------------------------------------
-module(wx_message_worker).
-author("wukai").
%% port 1byte--cmd-2byte,from-16byte content bytes(utf-8)
-behaviour(gen_server).

-define(SYS_PORT, 1).
-define(USER_PORT, 2).
-include("user_record.hrl").
%% API
-export([start_link/4]).
-include("protocol_define.hrl").
%% gen_server callbacks
-export([init/1,
  handle_call/3,
  handle_cast/2,
  handle_info/2,
  terminate/2,
  code_change/3]).

-export([get_frame_Head/4, get_new_seq/1]).
-define(SERVER, ?MODULE).



start_link(Ref, Socket, Transport, _Opts) ->
  gen_server:start_link(?MODULE, [Ref, Socket, Transport, _Opts], []).

init([Ref, Socket, Transport, _Opts]) ->
  inet:setopts(Socket, [{active, once}]),
  {ok, #state{socket = Socket, trans = Transport, version = 1, wait_frame = wait_a5, wait_len = 1, send_seq = 0}, 0}.

handle_call(_Request, _From, State) ->
  {reply, ok, State}.

handle_cast(_Request, State) ->
  {noreply, State}.

%%tcp数据
handle_info({tcp, Socket, Data}, State) ->
  Buffer = State#state.buffer,
  NewBuf = <<Buffer/binary, Data/binary>>,
  io:format("new buffer= ~p~n", [NewBuf]),
  Wait = State#state.wait_frame,
  Len = State#state.wait_len,
  case parse_buffer({Wait, NewBuf, Len}, Socket, State) of
    {ok, NEW_State} ->
      io:format("parse complete"),
      %%State#state{wait_frame = Action, buffer = N_Buffer, wait_len = L};
      inet:setopts(Socket, [{active, once}]),
      {noreply, NEW_State};
    _ ->
      inet:setopts(Socket, [{active, once}]),
      io:format("parse error.."),
      {noreply, State}
  end;

%%链接关闭了
handle_info({tcp_closed, Socket}, State) ->

  close_client(State),
  {stop, normal, State};

%%用户聊天消息转发
handle_info({msg, Talk, Time, Type, From, Port, Cmd}, State) ->
  io:format("time-> ~p talk->~p,type->~p,from->~p,", [Time, Talk, Type, From]),
  S = State#state.socket,
  T = State#state.trans,
  T:send(S,get_msg_binary(Talk, Time, Type, From, Port, Cmd,State)),
  {noreply, State};

%%其它处理
handle_info(_Info, State) ->
  {noreply, State}.

-spec(terminate(Reason :: (normal | shutdown | {shutdown, term()} | term()),
    State :: #state{}) -> term()).

terminate(_Reason, _State) ->
  ok.

-spec(code_change(OldVsn :: term() | {down, term()}, State :: #state{},
    Extra :: term()) ->
  {ok, NewState :: #state{}} | {error, Reason :: term()}).
code_change(_OldVsn, State, _Extra) ->
  {ok, State}.



parse_buffer(Frame, Socket, State) ->
  Continue = State#state.continue,
  if
    Continue==true -> {Action, Buf, L} = Frame,
      %%io:format("buf= ~p ~n", [Buf]),
      B_size = byte_size(Buf),
      %%io:format("Bsize= ~p ~n", [B_size]),
      if
        B_size < L ->
          NEW_S = State#state{buffer = Buf},
          io:format("frame length less."),
          inet:setopts(Socket, [{active, once}]),
          {ok, NEW_S};
        true -> case Action of
                  wait_a5 ->
                    <<A5:?UBYTE, Other1/binary>> = Buf,
                    io:format("a5= ~p~n", [A5]),
                    if
                      A5 == ?FRAME_START ->
                        parse_buffer({wait_head, Other1, ?FRAME_LEN}, Socket, State);
                      true ->
                        parse_buffer({wait_a5, Other1, 1}, Socket, State)
                    end;
                  wait_head ->

                    <<Head:?FRAME_CONTENT_LEN/binary, Old_CRC32:?UINT, Other2/binary>> = Buf,
                    %%计算CRC32

                    CRC32 = erlang:crc32(Head),
                    io:format("old crc32= ~p and new crc32= ~p ~n", [Old_CRC32, CRC32]),
                    %%判断CRC32的值是否相等
                    if
                      CRC32 == Old_CRC32 ->
                        <<Version:?UBYTE, MSG_TYPE:?UBYTE, Frame_seq:?USHORT, C_Len:?UINT>> = Head,
                        io:format("version->~p,frame_type->~p,frame_seq->~p,leobn->~p", [Version, MSG_TYPE, Frame_seq, C_Len]),
                        if
                          MSG_TYPE == ?FRAME_TYPE_ACK ->
                            %%loopparse
                            on_ack_frame(State),
                            parse_buffer({wait_a5, Other2, 1}, Socket, State);
                          MSG_TYPE == ?FRAME_TYPE_MSG ->
                            %%客户端帧序号
                            NewState = State#state{from_seq = Frame_seq},
                            parse_buffer({wait_body, Other2, C_Len}, Socket, NewState);

                          MSG_TYPE == ?FRAME_TYPE_HEART ->
                            io:format("crc error~n"),
                            parse_buffer({wait_a5, Other2, 1}, Socket, State);
                        %%loopparse,
                          true ->
                            io:format("received unkown frame type ~p", [MSG_TYPE]),
                            parse_buffer({wait_a5, Other2, 1}, Socket, State)
                        end;
                      true -> io:format("crc error")
                    end;
                  wait_body ->
                    <<Body:L/binary, Other3/binary>> = Buf,

                    CC = State#state.from_seq,
                    send_ack_frame(State#state.socket, State#state.trans, CC),
                    io:format("from frame sequnce ~p ~n", [CC]),

                    %%解析指令
                    <<Port:?UBYTE, Cmd:?USHORT, Content/binary>> = Body,
                    io:format("receive msg->port-> ~p cmd-> ~p ~n", [Port, Cmd]),
                    case handle_cmd(Port, Cmd, Content, State) of
                      {ok, N_State} ->

                        parse_buffer({wait_a5, Other3, 1}, Socket, N_State);
                      _ ->
                        parse_buffer({wait_a5, Other3, 1}, Socket, State)
                    end
                end
      end;
    true ->
      T = State#state.trans,
      S = State#state.socket,
      T:close(S),
      close_client(State)
  end.


on_ack_frame(State) ->
%%取消定时器
  ok.
%%发送确认帧

send_ack_frame(Socket, Transport, Sequnce) ->

  io:format("~p,~p,~p ~n", [Socket, Transport, Sequnce]),
  Head = <<?FRAME_VERSION:?UBYTE, ?FRAME_TYPE_ACK:?UBYTE, Sequnce:?USHORT, 0:?UINT>>,
  %%计算CRC32的值
  CRC32 = erlang:crc32(Head),
  Data = <<?FRAME_START:?UBYTE, Head/binary, CRC32:?UINT>>,
  Transport:send(Socket, Data).


handle_cmd(?SYS_PORT, Cmd, MSg, State) ->
  wx_protocol_sys:handle_cmd(Cmd, MSg, State);
handle_cmd(?USER_PORT, Cmd, MSg, State) ->
  wx_protocol_user:handle_cmd(Cmd, MSg, State).

get_frame_Head(Seq, Frame_type, Msg_Len, Version) ->

  HeadBody = <<Version:?UBYTE, Frame_type:?UBYTE, Seq:?USHORT, Msg_Len:?UINT>>,
  CRC32 = erlang:crc32(HeadBody),

  <<HeadBody/binary, CRC32:?UINT>>.

get_new_seq(State) ->
  Seq = State#state.send_seq,
  if
    Seq == 10000 -> 0;
    true -> Seq + 1
  end.

get_msg_binary(Msg, Time, Type, From, Port, Cmd, State) ->

  Seq = get_new_seq(State),
  Json = {obj, [{"msg", Msg}, {"time", Time}, {"type", Type},{"from",From}]},
  Json_list = rfc4627:encode(Json),
  A = list_to_binary(Json_list),
  io:format("binary ~p ~n",[A]),
  Len = byte_size(A),
  Len2=Len+3,%port-->1byte+cmd-->2byte

  Head = get_frame_Head(Seq, ?FRAME_TYPE_MSG, Len2, State#state.version),
  Body = <<?USER_PORT:?UBYTE,Cmd:?USHORT,A/binary>>,
  <<?FRAME_START:?UBYTE,Head/binary,Body/binary>>.

close_client(State)->
  error_logger:info_msg(" Client  disconnected.\n"),
  ets:delete(table_conn, State#state.email),
  supervisor:terminate_child(wx_message_sup, self()),
  supervisor:delete_child(wx_message_sup, self()).

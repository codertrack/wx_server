%%%-------------------------------------------------------------------
%%% @author wukai
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 06. 七月 2016 15:11
%% 协议栈

%%frame_head 帧头长度14byte

%%/0xA5--1byte(version)--/--1byte(msg_type)/--4byte(framesequnce)/--4byte(con_len)/--4byte(crc32)
%%/bytes(frame_body)/--byte(crc32)
%%%-------------------------------------------------------------------


-module(wx_protocol).
-author("wukai").
-behavior(ranch_protocol).


%% API
-export([start_link/4]).

start_link(Ref, Socket, Transport, Opts) ->
  io:format("protocol start_link~n"),
  supervisor:start_child(wx_message_sup, [Ref, Socket, Transport, Opts]).





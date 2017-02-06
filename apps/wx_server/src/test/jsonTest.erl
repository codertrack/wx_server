%%%-------------------------------------------------------------------
%%% @author wukai
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 13. 七月 2016 11:59
%%%-------------------------------------------------------------------
-module(jsonTest).
-author("wukai").
%% API
-export([encodeTest/0,test_binary/1]).
-define(UINT, 32 / unsigned - big - integer).
-define(INT, 32 / signed - big - integer).
-define(USHORT, 16 / unsigned - big - integer).
-define(SHORT, 16 / signed - big - integer).
-define(UBYTE, 8 / unsigned - big - integer).
-define(BYTE, 8 / signed - big - integer).

-define(FRAME_LEN,14).
%%确认帧
-define(FRAME_TYPE_ACK, 1).
%%消息帧
-define(FRAME_TYPE_MSG, 2).
%%心跳
-define(FRAME_TYPE_HEART, 3).

%%当前协议版本号
-define(FRAME_VERSION,1).
%%起始域
-define(FRAME_START,16#a5).

encodeTest()->
  Code = {obj,
    [
      {"code", 1},
      {"msg",
        {obj,
          [
            {"key1", 1}, {"key2", <<"value2">>},
            {"key1", 1}, {"key2", unicode:characters_to_binary("中国zhong")}
          ]
        }
      }]},


  JsonStr = rfc4627:encode(Code),
  decodeTest(list_to_binary(JsonStr)).

decodeTest(JsonBinary)->

  rfc4627:decode(JsonBinary).




list_test()->
  lists:keyfind().

test_binary(Sequnce)->
  Head = <<?FRAME_VERSION:?UBYTE, ?FRAME_TYPE_ACK:?UBYTE, Sequnce:?UINT, 10:?UINT>>.

%%%-------------------------------------------------------------------
%%% @author wukai
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 14. 七月 2016 20:34
%%%-------------------------------------------------------------------
-author("wukai").
-ifndef(protocol).
-define(protocl,true ).
-define(UINT, 32 / unsigned - big - integer).
-define(INT, 32 / signed - big - integer).
-define(USHORT, 16 / unsigned - big - integer).
-define(SHORT, 16 / signed - big - integer).
-define(UBYTE, 8 / unsigned - big - integer).
-define(BYTE, 8 / signed - big - integer).

-define(FRAME_LEN,12).
-define(FRAME_CONTENT_LEN,8).

-define(FRAME_TYPE_MSG, 1).
-define(FRAME_TYPE_ACK, 2).
-define(FRAME_TYPE_HEART, 3).

%%当前协议版本号
-define(FRAME_VERSION,1).
%%起始域
-define(FRAME_START,16#a5).

-endif.
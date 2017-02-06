%%%-------------------------------------------------------------------
%%% @author wukai
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 13. 七月 2016 16:06
%%%-------------------------------------------------------------------
-module(time_utils).
-author("wukai").

%% API
-export([timestamp/0,local_time/0,datetime_to_timestamp/1,timestamp_to_datetime/1]).
%%获取时间戳
timestamp() ->
  {M, S, _} = os:timestamp(),
  M * 1000000 + S.

%%本地时间
local_time() ->
  calendar:local_time().

%时间转时间戳
datetime_to_timestamp(DateTime) ->
  calendar:datetime_to_gregorian_seconds(DateTime) -
    calendar:datetime_to_gregorian_seconds({{1970,1,1}, {0,0,0}}).

% 时间戳转时间
timestamp_to_datetime(Timestamp) ->
  calendar:gregorian_seconds_to_datetime(Timestamp +
    calendar:datetime_to_gregorian_seconds({{1970,1,1}, {0,0,0}})).
%%%-------------------------------------------------------------------
%%% @author wukai
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 16. 七月 2016 16:46
%%%-------------------------------------------------------------------
-module(wx_util).
-author("wukai").

%% API
-export([to_hex/1]).
to_hex([]) ->
  [];
to_hex(Bin) when is_binary(Bin) ->
  to_hex(binary_to_list(Bin));
to_hex([H|T]) ->
  [to_digit(H div 16), to_digit(H rem 16) | to_hex(T)].

to_digit(N) when N < 10 -> $0 + N;
to_digit(N)             -> $a + N-10.


%% @spec to_bin(string()) -> binary()
%% @doc Convert a hexadecimal string to a binary.
to_bin(L) ->
  to_bin(L, []).

to_bin([], Acc) ->
  iolist_to_binary(lists:reverse(Acc));
to_bin([C1, C2 | Rest], Acc) ->
  to_bin(Rest, [(dehex(C1) bsl 4) bor dehex(C2) | Acc]).

%% @spec dehex(char()) -> integer()
%% @doc Convert a hex digit to its integer value.
dehex(C) when C >= $0, C =< $9 ->
  C - $0;
dehex(C) when C >= $a, C =< $f ->
  C - $a + 10;
dehex(C) when C >= $A, C =< $F ->
  C - $A + 10.
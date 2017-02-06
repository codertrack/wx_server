%%%-------------------------------------------------------------------
%%% @author wukai
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 13. 七月 2016 11:21
%%%-------------------------------------------------------------------
-module(json_utils).
-author("wukai").

%% API
-export([get_auth_response_binary/2]).

%%0-ok,1-error message::list
get_auth_response_binary(State,Message)->
  OutPut ={obj,{"code",State},{"message",list_to_binary(Message)}}.


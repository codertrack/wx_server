%%%-------------------------------------------------------------------
%%% @author wukai
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 06. 七月 2016 19:33
%%%-------------------------------------------------------------------
-author("wukai").
-ifndef(record).
-define(record,true).

-record(table_conn, {email, pid}).

%%database
-record(table_user,{
  email,%%电子邮件
  password,
  gender=1,%%性别
  token,%%用于登录的token
  time,%%注册时间
  state=1,%%状态 token是否可用 1.可用,2,不可用
  md5,%%用户名密码校验,
  nick_name,
  declaration="一起来聊天呗..." %%交友宣言
}).

%%未发送成功的消息表
-record(table_message_offline,{
  target,%%目标用户
  msg,%%消息内容
  type, %%消息类型
  port, %%端口号
  cmd,   %%指令
  time, %%时间
  from %%消息来源
}).

-record(state, {
  version,
  socket,
  email,
  buffer = <<>>,
  trans,
  wait_frame,
  wait_len,
  timer_ref,
  from_seq,
  send_seq=0,
  continue =true
}).
-endif.
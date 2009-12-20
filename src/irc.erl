-module(irc).
-export([
    start/4,
    parse/1,
    strip_crlf/1,
    send/2,
    server_loop/2
    ]).


start(Server, Port, Username, Realname) ->
  {ok, Socket} = gen_tcp:connect(Server, Port, [binary, {packet, 0}, {active, false}]),
  send(Socket, "NICK " ++ Username),
  send(Socket, "USER " ++ Username ++ " " ++ Realname),
  server_loop(Socket, []).

%%%-----------------------------------------------------------
%%% @doc
%%% Parses a string and returns the result
%%%
%%% @spec parse(Data::binary()) -> {ok, {MessageType, Data}}
%%% @end
%%%-----------------------------------------------------------
parse(<<"PING :", Data/binary>>) ->
    {ok, {ping, strip_crlf(binary_to_list(Data))}};
parse(<<":", Line/binary>>) ->
	[Prefix | Message] = re:split(Line, ":", [{parts,2}]),
	[Nick | User] = re:split(Prefix, "[!@]", [{parts,2}]),

	Str = strip_crlf(binary_to_list(Data)),
    {ok, {general, Str}}.
 
%%%-----------------------------------------------------------
%%% @doc
%%% Strips the string from ending '\n\r'
%%%
%%% @spec strip_crlf(Str::string()) -> StrippedString
%%% @end
%%%-----------------------------------------------------------
strip_crlf(Str) ->
    string:strip(string:strip(Str, right, $\n), right, $\r).
 
%%%-----------------------------------------------------------
%%% @doc
%%% Sends a message to a socket
%%%
%%% @spec send(Socket, Message::string()) -> ok | {error, Reason}
%%% @end
%%%-----------------------------------------------------------
send(Socket, Message) ->
  io:format(
          "==========================================~n"
          "= SENDING MESSAGE                        =~n"
          "------------------------------------------~n"
          "~s~n"
          "==========================================~n",
          [Message]),
          gen_tcp:send(Socket, list_to_binary(Message ++ "\r\n")). 

%%%-----------------------------------------------------------
%%% @doc
%%% Main loop. Waits for messages and forwards some of them to
%%% the dispatcher.
%%%
%%% @spec server_loop(Dispatcher::pid(), Socket) -> ok
%%% @end
%%%-----------------------------------------------------------
server_loop(Socket, MessageList) ->
  receive
    {command, Cmd} ->
      send(Socket, Cmd),
			server_loop(Socket, MessageList);
		{action, get_update, Pid} ->
			Pid ! MessageList,
			server_loop(Socket, [])
  after 0 ->
    case gen_tcp:recv(Socket, 0, 50) of 
      {ok, Packet} ->
        case parse(Packet) of
          {ok, {ping, Data}} ->
            send(Socket, "PONG " ++ Data),
            server_loop(Socket, [{status, "Got ping~n"}|MessageList]);

          {ok, {general, Data}} ->
            server_loop(Socket, [{status, Data}|MessageList])
        end;
      {error, Reason} ->
        server_loop(Socket, [{error, Reason}|MessageList])
    end
  end.

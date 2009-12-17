-module(irc).
-export([
    start/5,
    parse/1,
    strip_crlf/1,
    send/2,
    server_loop/2
    ]).


start(Dispatcher, Server, Port, Username, Realname) ->
  {ok, Socket} = gen_tcp:connect(Server, Port, [binary, {packet, 0}, {active, false}]),
  send(Socket, "NICK " ++ Username),
  send(Socket, "USER " ++ Username ++ " " ++ Realname),
  server_loop(Dispatcher,Socket).

%%%-----------------------------------------------------------
%%% @doc
%%% Parses a string and returns the result
%%%
%%% @spec parse(Data::binary()) -> {ok, {MessageType, Data}}
%%% @end
%%%-----------------------------------------------------------
parse(<<"PING :", Data/binary>>) ->
    {ok, {ping, strip_crlf(binary_to_list(Data))}};
parse(<<From, " PRIVMSG ", _To, " :", Message>>) ->
    {ok, {privmsg, {From, Message}}};
parse(Data) ->
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
server_loop(Dispatcher, Socket) ->
  receive
    {command, Cmd} ->
      send(Socket, Cmd),
			server_loop(Dispatcher, Socket)
  after 50 ->
    case gen_tcp:recv(Socket, 0, 50) of 
      {ok, Packet} ->
        case parse(Packet) of
          {ok, {message, Message}} ->
            Dispatcher ! {message, {Message}},
            server_loop(Dispatcher, Socket);
          {ok, {ping, Data}} ->
            Dispatcher ! {status, {"Got ping~n"}},
            send(Socket, "PONG " ++ Data),
            server_loop(Dispatcher, Socket);
          {ok, {general, Data}} ->
            Dispatcher ! {status, {Data}},
            server_loop(Dispatcher, Socket)
        end;
      {error, Reason} ->
        Dispatcher ! {error, Reason},
        server_loop(Dispatcher, Socket)
    end
  end.

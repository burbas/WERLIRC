-module(ircclient).
-export([start_link/0, init/1, handle_call/3, get_update/0, send/2, send/1, parse/1, strip_crlf/1]).


-behaviour(gen_server).


start_link() ->
    gen_server:start_link({global, ?MODULE}, ?MODULE, [], []).

init(_Args) ->
    {ok, Socket} = gen_tcp:connect("irc.efnet.org", 6667, [binary, {packet, 0}, {active, false}]),
    send(Socket, "NICK " ++ "burbot"),
    send(Socket, "USER " ++ "burbot" ++ " i am a good bot"),
    {ok, {{socket,Socket}}}.

get_update() ->
    gen_server:call({global, ?MODULE}, {get_update}).

%% Sends to the socket
send(Text) ->
    gen_server:call({global, ?MODULE}, {send_cmd, Text}).

send(Socket, Text) ->
    gen_tcp:send(Socket, list_to_binary(Text ++ "\r\n")).


        
handle_call({get_update}, _From, {{socket, Socket}}) ->
        case gen_tcp:recv(Socket, 0) of
            {ok, Packet} ->
                case parse(Packet) of 
                    {ok, {message, Message}} ->
                        {reply, {message, Message}, {{socket, Socket}}};
                    {ok, {ping, Data}} ->
                        send(Socket, "PONG :" ++ Data),
                        {reply, {ping, "PONG :" ++ Data}, {{socket, Socket}}};
                    {ok, {general, Message}} ->
                        {reply, {general, Message}, {{socket, Socket}}}
                end;
            {error, Reason} ->
                {reply, {error, Reason}, {{socket, Socket}}} 
        end;
%% Sends data via the socket
handle_call({send_cmd, Text}, _From, {{socket, Socket}}) ->
    gen_tcp:send(Socket, list_to_binary(Text ++ "\r\n"));
handle_call(_, _From, State) ->
    {reply, State}.

%% Parses a binary
parse(<<"PING :", Data/binary>>) ->
    {ok, {ping, strip_crlf(binary_to_list(Data))}};
parse(Data) ->
    Str = strip_crlf(binary_to_list(Data)),
    {ok, {general, Str}}.


%% Strips \n\r
strip_crlf(Str) ->
    string:strip(string:strip(Str, right, $\n), right, $\r).

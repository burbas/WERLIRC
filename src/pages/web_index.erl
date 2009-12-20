-module (web_index).
-include_lib ("wf.inc").
-compile(export_all).

main() -> 
	#template { file="./wwwroot/template.html"}.

title() ->
	"WERLIRC".

%% Username, Server and so.
stage1() ->
	Output = [
		#panel{id=mainDiv, body=[
			#h2{text="User information"},
			#label{text="Nickname: "},
			#textbox{id=username},
			#label{text="Real name: "},
			#textbox{id=realname},
			#label{text="Server:"},
			#dropdown { id=serverlist, value="Choose server", options=[
     		#option { text="Efnet", value="irc.efnet.org" },
     		#option { text="Freenode", value="irc.freenode.org" },
     		#option { text="Undernet", value="irc.undernet.org" }
			]},
			#label{text="Server port:"},
			#textbox{id=serverport},
			#p{},
			#button{id=contunueButton, text="Connect", postback={stage2}}
		]}
	],
	Output.

%% The chat-window
stage2() ->
	Output = [
		#panel{id=mainDiv, body=[
			#button{text="Status", postback={change_window, status}},
			#button{text="#dv"},
			#panel{id=ircStatus, style="background-color: #FFFFFF; border: 1px solid; height: 150px; overflow: auto; padding: 12px; width: 100%"},
			#p{},
			#textbox{id=cmd},
			#button{text="Send", postback=sendCommand}
		]}
	],
	Output.


body() ->
		Body = stage1(),
    wf:render(Body).


event({stage2}) ->
	%% Query all fields
	[Nickname] = wf:q(username),
	[Realname] = wf:q(realname),
	[Server] = wf:q(serverlist),
	[Port] = wf:q(serverport),
	wf:update(mainDiv, stage2()),
	wf:comet(fun() -> start_irc(Nickname, Realname, Server, Port) end);
event(sendCommand) ->
    IrcPid = wf:session(ircpid),
    [Cmd] = wf:q(cmd),
    IrcPid ! {command, Cmd};
event(_) -> ok.

start_irc(Nickname, Realname, Server, _Port) ->
	case wf:session(ircpid) of
		undefined ->
			Pid = spawn(irc, start, [
							Server, 
							6667, 
							Nickname, 
							Realname
							]),
  		wf:session(ircpid, Pid);
		_ ->
			ok
		end,
		running_irc().

running_irc() ->
	IrcPid = wf:session(ircpid),
	IrcPid ! {action, get_update, self()},
	receive 
		MessageList ->
			NewIrcLog = lists:reverse(parseListToNitrogen(MessageList))
	end,
	wf:insert_bottom(ircStatus, NewIrcLog),
	wf:comet_flush(),
	timer:sleep(1000),
	running_irc().


parseListToNitrogen([]) ->
	[];
parseListToNitrogen([{status, Message}|T]) ->
	[#span{text=Message},#br{}|parseListToNitrogen(T)];
parseListToNitrogen([{general, Data}|T]) ->
	[#span{text=Data}, #br{}|parseListToNitrogen(T)];
parseListToNitrogen([_H|T]) ->
	parseListToNitrogen(T).

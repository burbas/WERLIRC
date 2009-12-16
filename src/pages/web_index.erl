-module (web_index).
-include_lib ("wf.inc").
-compile(export_all).

main() -> 
	#template { file="./wwwroot/template.html"}.

title() ->
	"WERLIRC".

body() ->
    Body = [
        #button{text="Status", postback={change_window, status}},
        #button{text="#dv"},
        #panel{id=ircStatus, style="background-color: #FFFFFF; border: 1px solid; height: 150px; overflow: auto; padding: 12px; width: 80%"},
        #p{},
        #textbox{id=cmd},
        #button{text="Send", postback=sendCommand}
    ],
    wf:comet(fun() -> running_irc() end),
    wf:render(Body).
event(sendCommand) ->
    IrcPid = wf:session(ircpid),
    [Cmd] = wf:q(cmd),
    IrcPid ! {command, Cmd};
event(_) -> ok.


start_irc(Server, Port, Username, Realname) ->
  running_irc().

running_irc() ->
	case wf:session(ircpid) of
		undefined ->
			Pid = spawn(irc, start, [self(), "irc.efnet.org", 6667, "burbas", "bu rbas is good"]),
  		wf:session(ircpid, Pid);
		_ ->
			ok
		end,
    receive 
        {message, {Message}} ->
            FormatedMsg = wf:f("~w", [Message]),
            NewIrcLog = [
                    #span{text=FormatedMsg}
            ];
        {status, {Message}} ->
            FormatedMsg = wf:f("~s", [Message]),
            NewIrcLog = [
                    #span{text=FormatedMsg}
            ]
    end,
    wf:insert_bottom(ircStatus, NewIrcLog),
    wf:wire("obj('ircLog').scrollTop = obj('ircLog').scrollHeight;"),
    wf:comet_flush(),
    timer:sleep(500),
    running_irc().


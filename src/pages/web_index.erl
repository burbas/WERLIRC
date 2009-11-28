-module (web_index).
-include_lib ("nitrogen/include/wf.inc").
-compile(export_all).

main() -> 
	#template { file="./wwwroot/template.html"}.

title() ->
	"WERLIRC".

body() ->
    Body = [
        #panel{id=ircLog, style="background-color: #FFFFFF; border: 1px solid; height: 150px; overflow: auto; padding: 12px; width: 80%"},
        #p{},
        #textbox{id=cmd},
        #button{text="Send", postback=sendCommand}
     ],
    wf:comet(fun() -> irc_loop() end),
    ircclient:start_link(),
    wf:render(Body).

event(sendCommand) ->
    [Command] = wf:q(cmd),
    ircclient:send(Command),
    ok;
event(_) -> ok.

irc_loop() ->
    timer:sleep(10),
    case ircclient:get_update() of 
        {_Type, Message} ->
            Terms = [
                #p{},
                #span{text=Message}
           ],
            wf:insert_bottom(ircLog, Terms),
            wf:wire("obj('ircLog').scrollTop = obj('ircLog').scrollHeight;"),
            wf:comet_flush();
        _ -> 
            ok
    end,
    irc_loop().

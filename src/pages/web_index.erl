-module (web_index).
-include_lib ("nitrogen/include/wf.inc").
-compile(export_all).

main() -> 
	#template { file="./wwwroot/template.html"}.

title() ->
	"web_index".

body() ->
    Body = [
        #label{text="WERLIRC."},
        #panel{ id=ircLog }
    ],
    wf:comet(fun() -> irc_loop() end),
    ircclient:start_link(),
    wf:render(Body).

event(_) -> ok.

irc_loop() ->
    timer:sleep(100),
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



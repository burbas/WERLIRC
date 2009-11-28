{application, ircclient, [
	{description,  "Nitrogen Website"},
	{mod, {ircclient_app, []}},
    {module, ircclient},
	{env, [
		{platform, inets}, %% {inets|yaws|mochiweb}
		{port, 8000},
		{session_timeout, 20},
		{sign_key, "SIGN_KEY"},
		{www_root, "./wwwroot"}
	]}
]}.

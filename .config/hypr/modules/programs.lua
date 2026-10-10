---------------------
---- MY PROGRAMS ----
---------------------

-- Set programs that you use. Shared by env.lua and binds.lua.
return {
	terminal = "ghostty",
	fileManager = "nautilus",
	-- The default browser: SUPER+B, and exported as $BROWSER (see env.lua)
	-- for everything started from here -- the quickshell launcher's
	-- web search uses it.
	browser = "zen-browser",
	-- Where the launcher's web search goes (%s = the query), as $BROWSER_SEARCH.
	search_url = "https://www.google.com/search?q=%s",
	menu = "qs ipc call launcher toggle",
}

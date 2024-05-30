SUBSYSTEM_DEF(efdb)
	name = "Effigy Database Services"
	flags = SS_TICKER
	wait = 10 // Not seconds because we're running on SS_TICKER
	runlevels = RUNLEVEL_LOBBY|RUNLEVELS_DEFAULT
	init_order = INIT_ORDER_DBCORE
	priority = FIRE_PRIORITY_DATABASE

/mob/dead/new_player
	/// Title screen is ready to receive signals
	var/title_screen_is_ready = FALSE

/mob/dead/new_player/Topic(href, href_list[])
	if(src != usr)
		return

	if(!client)
		return

	if(client.interviewee)
		return FALSE

	if(SSdbcore.IsConnected() && !client.client_authenticated)
		sleep(3 SECONDS)
		if(!client.client_authenticated) // retry
			to_chat_immediate(src, SPAN_BOX_ALERT(PINK, "Not Authorized \[2F173/2]<br><br>Effigy uses a player whitelist and your account was not found!<br><br>Please visit <a href=\"https://effigy.se/new-players/\">https://effigy.se/new-players/</a> for details and to submit your application and perform verification."))
			if(!GLOB.account_alert)
				GLOB.account_alert = new
			GLOB.account_alert.ui_interact(client.mob)
			return FALSE

	if(href_list["observe"])
		play_lobby_button_sound()
		make_me_an_observer()
		return

	if(href_list["view_manifest"])
		play_lobby_button_sound()
		ViewManifest()
		return

	if(href_list["toggle_antag"])
		play_lobby_button_sound()
		var/datum/preferences/preferences = client.prefs
		preferences.write_preference(GLOB.preference_entries[/datum/preference/toggle/be_antag], !preferences.read_preference(/datum/preference/toggle/be_antag))
		client << output(preferences.read_preference(/datum/preference/toggle/be_antag), "title_browser:toggle_antag")
		return

	if(href_list["character_setup"])
		play_lobby_button_sound()
		var/datum/preferences/preferences = client.prefs
		preferences.current_window = PREFERENCE_TAB_CHARACTER_PREFERENCES
		preferences.update_static_data(src)
		preferences.ui_interact(src)
		return

	if(href_list["game_options"])
		play_lobby_button_sound()
		var/datum/preferences/preferences = client.prefs
		preferences.current_window = PREFERENCE_TAB_GAME_PREFERENCES
		preferences.update_static_data(usr)
		preferences.ui_interact(usr)
		return

	if(href_list["toggle_ready"])
		play_lobby_button_sound()

		if(!is_admin(client) && length_char(client?.prefs?.read_preference(/datum/preference/text/flavor_text)) < FLAVOR_TEXT_CHAR_REQUIREMENT)
			to_chat(src, span_notice("You need at least [FLAVOR_TEXT_CHAR_REQUIREMENT] characters of flavor text to ready up for the round. You have [length_char(client.prefs.read_preference(/datum/preference/text/flavor_text))] characters."))
			return

		ready = !ready
		client << output(ready, "title_browser:toggle_ready")
		return

	if(href_list["late_join"])
		play_lobby_button_sound()
		GLOB.latejoin_menu.ui_interact(usr)

	if(href_list["title_is_ready"])
		title_screen_is_ready = TRUE
		return


/mob/dead/new_player/Login()
	. = ..()
	show_title_screen()

/**
 * Shows the titlescreen to a new player.
 */
/mob/dead/new_player/proc/show_title_screen()
	if (client?.interviewee)
		return

	winset(src, "title_browser", "is-disabled=false;is-visible=true")
	winset(src, "status_bar", "is-visible=false")

	var/datum/asset/assets = get_asset_datum(/datum/asset/simple/lobby) //Sending pictures to the client
	assets.send(src)

	update_title_screen()

/**
 * Hard updates the title screen HTML, it causes visual glitches if used.
 */
/mob/dead/new_player/proc/update_title_screen()
	var/dat = get_title_html()

	src << browse(SStitle.current_title_screen, "file=title-x3.png;display=0")
	src << browse(dat, "window=title_browser")

/**
 * Removes the titlescreen entirely from a mob.
 */
/mob/dead/new_player/proc/hide_title_screen()
	if(client?.mob)
		winset(client, "title_browser", "is-disabled=true;is-visible=false")
		winset(client, "status_bar", "is-visible=true")

/mob/dead/new_player/proc/play_lobby_button_sound()
//	SEND_SOUND(src, sound('local/icons/runtime/save.ogg')) // EffigyEdit TODO

/client/verb/district_select()
	set category = "OOC"
	set name = "District Select"
	set desc = "District Select"

	var/datum/district_select/tgui = new(usr)//create the datum
	tgui.ui_interact(usr)//datum has a tgui component, here we open the window

/datum/district_select
	var/client/holder //client of whoever is using this datum

/datum/district_select/New(user)//user can either be a client or a mob due to byondcode(tm)
	if(istype(user, /client))
		var/client/user_client = user
		holder = user_client //if its a client, assign it to holder
	else
		var/mob/user_mob = user
		holder = user_mob.client //if its a mob, assign the mob's client to holder

/datum/district_select/ui_state(mob/user)
	return GLOB.admin_state

/datum/district_select/ui_close()
	qdel(src)

/datum/district_select/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "EffigyDistrictSelect")
		ui.open()

/datum/district_select/ui_data(mob/user)
	var/list/data = list()
	return data

/**
 * Shows the player a list of current polls, if any.
 */
/mob/dead/new_player/proc/playerpolls()
	if(!usr || !client)
		return

	var/output
	if (!SSdbcore.Connect())
		return
	var/isadmin = FALSE
	if(client?.holder)
		isadmin = TRUE
	var/datum/db_query/query_get_new_polls = SSdbcore.NewQuery({"
		SELECT id FROM [format_table_name("poll_question")]
		WHERE (adminonly = 0 OR :isadmin = 1)
		AND Now() BETWEEN starttime AND endtime
		AND deleted = 0
		AND id NOT IN (
			SELECT pollid FROM [format_table_name("poll_vote")]
			WHERE ckey = :ckey
			AND deleted = 0
		)
		AND id NOT IN (
			SELECT pollid FROM [format_table_name("poll_textreply")]
			WHERE ckey = :ckey
			AND deleted = 0
		)
	"}, list("isadmin" = isadmin, "ckey" = ckey))

	if(!query_get_new_polls.Execute())
		qdel(query_get_new_polls)
		return
	if(query_get_new_polls.NextRow())
		output +={"<a class="menu_button menu_newpoll" href='?src=[text_ref(src)];viewpoll=1'>POLLS (NEW)</a>"}
	else
		output +={"<a class="menu_button" href='?src=[text_ref(src)];viewpoll=1'>POLLS</a>"}
	qdel(query_get_new_polls)
	if(QDELETED(src))
		return
	return output

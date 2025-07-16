#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <cstrike>
#include <sqlx>

//#define mysql
#if defined mysql

#define SQL_HOST	"127.0.0.1"
#define SQL_USER	"root"
#define SQL_PASS	""

#endif

#define SQL_DBNAME	"ultimate_shop"
#define SQL_DBTABLE	"jugadores"

new Handle:g_Tuple
new Handle:g_Connection
new error[512]
new playerName[33][33]

new bool:firstspawn[33] = false

///////////////////////////// models menu ////////////////////////////

#define MAX_MODELS	35

#define		ALL	-1
#define		TE	1
#define		CT	2

new player_model[33]
new last_model_te[33]
new last_model_ct[33]

enum _:models_data
{
	model_menu[32],
	model_name[32],
	model_team,
	model_cost
}

new modelsplayers[MAX_MODELS][models_data];

new model_buyed[33][sizeof modelsplayers]
new model_select[33]

new modelCount = -1;

//////////////////////////////////////// hats menu ///////////////////////////////////

#define MAX_HATS	35

#define hatcarpeta "hat"

new player_hat[33]
new hat_selected[33]

enum _:hats_data
{
	hat_menu[32],
	hat_name[32],
	hat_cost
}

new hatmodels[MAX_HATS][hats_data];

new hat_buyed[33][sizeof hatmodels]
new hat_select[33]

new hatCount = -1;

//////////////////////////// knifes menu /////////////////////////////////

#define MAX_KNIFES	35

#define knifecarpeta "dark"
#define knifeurl "http://tuweb.com/knifes"

new knife_model[33]
new buyk[33]

enum _:knife_data
{
	knife_vname[32],
	knife_pname[32],
	knife_menu[32],
	knife_cost
}

new knifemodels[MAX_KNIFES][knife_data];

new knife_buyed[33][sizeof knifemodels]
new knife_select[33]

new knifeCount = -1;

//////////////////////////////// trails menu ///////////////////////////////

#define MAX_TRAILS	35

new sprite
new bool:blocktrail[33]
new trail[33]
new trail_pred[33]
new trail_pgreen[33]
new trail_pblue[33]

enum _:trails_data
{
	trail_color[32],
	trail_red,
	trail_green,
	trail_blue,
	trail_cost
}

new trails[MAX_TRAILS][trails_data];

new trail_buyed[33][sizeof trails]
new trail_select[33]

new trailCount = -1;

////////////////////////////////////////////////////////

new g_puntos[33]

public plugin_init()
{
	register_plugin("Ultimate Shop", "2.0", "Nelo")

	///////////// models menu //////////

	register_event("TextMsg", "joined_team", "a", "1=1", "2=#Game_join_terrorist", "2=#Game_join_ct", "2=#Game_join_terrorist_auto", "2=#Game_join_ct_auto")

	//////////// knifes menu /////////////

	RegisterHam(Ham_Item_Deploy, "weapon_knife", "Knife_Deploy", 1)

	////////////// general //////////////////////

	RegisterHam(Ham_Spawn, "player", "set_pmodel", 1)
	register_clcmd("nightvision", "show_menu_shop")
}

public plugin_cfg()
{
	SQL_Init()
}

////////////////////////////////////////////////////

public plugin_precache()
{
	////////////////////// inis ///////////////////////////

	load_models_config()
	load_hats_config()
	load_knifes_config()
	load_trails_config()

	/////////////////////////////// models menu //////////////////////////////
	
	new i, modelos[64]
	
	for(i = 0; i < sizeof(modelsplayers); i++)
	{
		formatex(modelos, charsmax(modelos), "models/player/%s/%s.mdl", modelsplayers[i][model_name], modelsplayers[i][model_name])

		if(file_exists(modelos))
			precache_model(modelos)
	}

	//////////////////////// hats menu //////////////////////

	new h, hat_models[64]

	for(h = 0; h < sizeof(hatmodels); h++)
	{
		formatex(hat_models, charsmax(hat_models), "models/%s/%s.mdl", hatcarpeta, hatmodels[h][hat_name])

		if(file_exists(hat_models))
			precache_model(hat_models)
	}

	////////////////////// knifes menu ///////////////////// 

	new k, vmodels[64], pmodels[64]

	for(k = 0; k < sizeof(knifemodels); k++)
	{
		formatex(vmodels, charsmax(vmodels), "models/%s/%s.mdl", knifecarpeta, knifemodels[k][knife_vname])
		formatex(pmodels, charsmax(pmodels), "models/%s/%s.mdl", knifecarpeta, knifemodels[k][knife_pname])

		if(file_exists(vmodels))
			precache_model(vmodels)

		if(file_exists(pmodels))
			precache_model(pmodels)
	}

	////////////////////// trail menu /////////////////////

	sprite = precache_model("sprites/laserbeam.spr")
}

public plugin_natives() register_native("dar_puntos", "native_puntos", 1)

public client_putinserver(id)
{
	knife_model[id] = -1

	get_user_name(id, playerName[id], charsmax(playerName[]))
	Cargar(id)
}

public client_disconnected(id)
{
	if(firstspawn[id])
		Guardar(id)

	/////////////// models menu /////////////

	player_model[id] = 0
	last_model_te[id] = 0
	last_model_ct[id] = 0

	//////////////// hats menu //////////////

	if(is_valid_ent(hat_selected[id]))
	{
		remove_entity(hat_selected[id])
		hat_selected[id] = 0
		player_hat[id] = 0
	}

	////////////// knifes menu //////////////

	knife_model[id] = -1

	////////////// trail menu ///////////////

	blocktrail[id] = false
	trail[id] = 0

	////////////// general ////////////////

	g_puntos[id] = 0
	firstspawn[id] = false

	for(new i = 0; i < sizeof(modelsplayers); i++)
		model_buyed[id][i] = 0

	for(new h = 0; h < sizeof(hatmodels); h++)
		hat_buyed[id][h] = 0

	for(new k = 0; k < sizeof(knifemodels); k++)
		knife_buyed[id][k] = 0

	for(new t = 0; t < sizeof(trails); t++)
		trail_buyed[id][t] = 0

	model_select[id] = 0
	hat_select[id] = 0
	knife_select[id] = 0
	trail_select[id] = 0
}

/////////////// models menu ///////////////

public joined_team()
{
	new player[32]
	read_data(3, player, charsmax(player))
  
	new id = get_user_index(player)

	new CsTeams:Team = cs_get_user_team(id)

	switch(Team) 
	{ 
		case CS_TEAM_T:		player_model[id] = last_model_te[id]
		case CS_TEAM_CT:	player_model[id] = last_model_ct[id]
	}
}

/////////////// trails menu ///////////////

public client_PreThink(id)
{
	if(!is_user_alive(id) || !trail[id])
		return

	static Float:velocity[3]
	static Float:speed

	pev(id, pev_velocity, velocity)
	speed = vector_length(velocity)

	if(speed > 0 && !blocktrail[id])
	{
		blocktrail[id] = true
		trail_on(id)
	}
	
	else if(!speed)
	{
		blocktrail[id] = false
		trail_off(id)
	}
}

/////////////////////////////////// funciones //////////////////////////////////////

////////////////////////////////// models menu ////////////////////////////////////

public menu_pmodel(id)
{
	static menu, items[64]
	menu = menu_create("Menu de models", "func_menu_pmodels")
    
	static i
	for (i = 0; i <= modelCount; i++)
	{
		new TEAM[12]
		
		if(modelsplayers[i][model_team] == CT)	
			formatex(TEAM, charsmax(TEAM),"\yCT")
		else if(modelsplayers[i][model_team] == TE)
			formatex(TEAM, charsmax(TEAM),"\yTE")
		
		formatex(items, charsmax(items), "%s %s", modelsplayers[i][model_menu], TEAM)

		if(model_buyed[id][i])
		{
			if(player_model[id] == i)
				add(items, charsmax(items), " \y(Equipado)")
			else
				add(items, charsmax(items), " \r(Comprado)")
		}

		else
		{
			new cost[32]
			
			if(modelsplayers[i][model_cost] == 0)
			{
				formatex(cost, charsmax(cost), "")

				if(player_model[id] == i)
					add(items, charsmax(items), " \y(Equipado)")
			}
			else
				formatex(cost, charsmax(cost), " \dCuesta \r%d \dPuntos", modelsplayers[i][model_cost])
			
			add(items, charsmax(items), cost)
		}
		
		menu_additem(menu, items, _)
	}

	menu_setprop(menu, MPROP_NUMBER_COLOR, "\y")
	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL)
	menu_setprop(menu, MPROP_BACKNAME , "Atras")
	menu_setprop(menu, MPROP_NEXTNAME , "Siguiente")
	menu_setprop(menu, MPROP_EXITNAME, "Salir")
	menu_display(id, menu, 0)
}

public func_menu_pmodels(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}
	
	if(item == 0)
	{
		player_model[id] = 0

		new CsTeams:Team = cs_get_user_team(id)

		switch(Team) 
		{
			case CS_TEAM_T:		last_model_te[id] = 0
			case CS_TEAM_CT:	last_model_ct[id] = 0
		}

		if(is_user_alive(id))
			set_pmodel(id)

		return PLUGIN_HANDLED
	}

	if(!model_buyed[id][item] && modelsplayers[item][model_cost] != 0)
	{
		if(g_puntos[id] < modelsplayers[item][model_cost])
			client_print(id, print_chat, "No tienes puntos suficientes para comprar esto")
		else
		{
			model_select[id] = item
			menu_confirm_model(id)
		}

		return PLUGIN_HANDLED
	}

	if(modelsplayers[item][model_team] != ALL && get_user_team(id) != modelsplayers[item][model_team])
	{
		client_print(id, print_chat, "Este model no es para tu equipo")
		menu_display(id, menu)
		return PLUGIN_HANDLED
	}

	player_model[id] = item
	client_print(id, print_chat, "Equipaste el model %s", modelsplayers[player_model[id]][model_menu])

	if(is_user_alive(id))
		set_pmodel(id)

	new CsTeams:Team = cs_get_user_team(id)

	switch(Team) 
	{
		case CS_TEAM_T:		last_model_te[id] = player_model[id]
		case CS_TEAM_CT:	last_model_ct[id] = player_model[id]
	}

	return PLUGIN_HANDLED
}

public set_pmodel(id) 
{
	if(!is_user_alive(id))
		return

	if(!player_model[id])
		cs_reset_user_model(id)	
	else
		cs_set_user_model(id, modelsplayers[player_model[id]][model_name], false)

	if(!firstspawn[id])
		player_first_spawn(id)
}

public menu_confirm_model(id)
{
	new title[64]
	formatex(title, charsmax(title), "Seguro que quieres comprar el model %s?", modelsplayers[model_select[id]][model_menu])

	new menu = menu_create(title, "model_confirm_handler")

	menu_additem(menu, "Si")
	menu_additem(menu, "No")

	menu_setprop(menu, MPROP_EXIT, MEXIT_NEVER)
	menu_display(id, menu, 0)
}

public model_confirm_handler(id, menu, item)
{
	if(item == 0)
	{
		model_buyed[id][model_select[id]] = true
		g_puntos[id] -= modelsplayers[model_select[id]][model_cost]
		client_print(id, print_chat, "Compraste el model %s", modelsplayers[model_select[id]][model_menu])
	}

	menu_destroy(menu)
	return PLUGIN_CONTINUE
}

////////////////////// hats menu ///////////////////////////////

public menuhat(id)
{
	if(!is_user_alive(id))
		return PLUGIN_HANDLED

	static menu, items[64]
	menu = menu_create("Menu de hats", "func_menu_hat")

	static i
	for (i = 0; i <= hatCount; i++)
	{
		formatex(items, charsmax(items), "%s", hatmodels[i][hat_menu])
		
		if(hat_buyed[id][i])
		{
			if(player_hat[id] == i)
				add(items, charsmax(items), " \y(Equipado)")
			else
				add(items, charsmax(items), " \r(Comprado)")
		}

		else
		{
			new cost[32]
			
			if(hatmodels[i][hat_cost] == 0)
			{
				formatex(cost, charsmax(cost), "")

				if(player_hat[id] == i)
					add(items, charsmax(items), " \y(Equipado)")
			}
			else
				formatex(cost, charsmax(cost), " \dCuesta \r%d \dPuntos", hatmodels[i][hat_cost])

			add(items, charsmax(items), cost)
		}
		
		menu_additem(menu, items, _)
	}

	menu_setprop(menu, MPROP_NUMBER_COLOR, "\y")
	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL)
	menu_setprop(menu, MPROP_BACKNAME , "Atras")
	menu_setprop(menu, MPROP_NEXTNAME , "Siguiente")
	menu_setprop(menu, MPROP_EXITNAME, "Salir")
	menu_display(id, menu, 0)

	return PLUGIN_CONTINUE
}

public func_menu_hat(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}

	if(item == 0)
	{
		if (is_valid_ent(hat_selected[id]))
		{
			remove_entity(hat_selected[id])
			player_hat[id] = 0
			hat_selected[id] = 0
		}
		return PLUGIN_HANDLED
	}
	
	if(!hat_buyed[id][item] && hatmodels[item][hat_cost] != 0)
	{
		if(g_puntos[id] < hatmodels[item][hat_cost])
			client_print(id, print_chat, "No tienes puntos suficientes para comprar esto")
		else
		{
			hat_select[id] = item
			menu_confirm_hat(id)
		}

		return PLUGIN_HANDLED
	}

	player_hat[id] = item
	client_print(id, print_chat, "Equipaste el hat %s", hatmodels[player_hat[id]][hat_menu])

	if(is_valid_ent(hat_selected[id]))
		remove_entity(hat_selected[id])

	sethat(id)

	return PLUGIN_HANDLED
}

public sethat(id) 
{
	if(!is_user_alive(id))
		return PLUGIN_HANDLED

	hat_selected[id] = create_entity("info_target")

	new phat[32]
	formatex(phat, charsmax(phat), "models/%s/%s.mdl", hatcarpeta, hatmodels[player_hat[id]][hat_name])
				
	if(!is_valid_ent(hat_selected[id]))
		return PLUGIN_HANDLED

	entity_set_int(hat_selected[id], EV_INT_movetype, MOVETYPE_FOLLOW)
	entity_set_edict(hat_selected[id], EV_ENT_aiment, id)
	entity_set_int(hat_selected[id], EV_INT_rendermode, kRenderNormal)
	entity_set_model(hat_selected[id], phat)

	return PLUGIN_CONTINUE
}

public menu_confirm_hat(id)
{
	new title[64]
	formatex(title, charsmax(title), "Seguro que quieres comprar el hat %s?", hatmodels[hat_select[id]][hat_menu])

	new menu = menu_create(title, "hat_confirm_handler")

	menu_additem(menu, "Si")
	menu_additem(menu, "No")

	menu_setprop(menu, MPROP_EXIT, MEXIT_NEVER)
	menu_display(id, menu, 0)
}

public hat_confirm_handler(id, menu, item)
{
	if(item == 0)
	{
		hat_buyed[id][hat_select[id]] = true
		g_puntos[id] -= hatmodels[hat_select[id]][hat_cost]
		client_print(id, print_chat, "Compraste el hat %s", hatmodels[hat_select[id]][hat_menu])
	}

	menu_destroy(menu)
	return PLUGIN_CONTINUE
}

///////////////////////////////// knife menu //////////////////////////////

public choosek(id)
{
	new menu = menu_create("Tienda de cuchillos", "choosek_menu")

	menu_additem(menu, "Comprar/equipar cuchillo")
	menu_additem(menu, "Previsualizar cuchillo")

	menu_setprop(menu, MPROP_EXITNAME, "Salir")
	menu_display(id, menu)
}

public choosek_menu(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}

	switch(item)
	{
		case 0: buyk[id] = 1
		case 1: buyk[id] = 0
	}

	menu_knife(id, 0)
	return PLUGIN_CONTINUE
}

public menu_knife(id, page)
{
	if(!is_user_alive(id))
		return PLUGIN_HANDLED

	if(!page)
		page = 0

	static menu, items[64]
	menu = menu_create("Menu de cuchillos", "func_menu_knife")

	if(buyk[id])
	{
		new text[32]
		formatex(text, charsmax(text), "%s", knife_model[id] == -1 ? "Default \y(Equipado)" : "Default")
		menu_additem(menu, text)
	}

	static i
	for (i = 0; i <= knifeCount; i++)
	{		
		formatex(items, charsmax(items), "%s", knifemodels[i][knife_menu])
		
		if(buyk[id])
		{
			if(knife_buyed[id][i])
			{
				if(knife_model[id] == i)
					add(items, charsmax(items), " \y(Equipado)")
				else
					add(items, charsmax(items), " \r(Comprado)")
			}
			else
			{
				new cost[32]

				if(knifemodels[i][knife_cost] == 0)
				{
					formatex(cost, charsmax(cost), "")

					if(knife_model[id] == i)
						add(items, charsmax(items), " \y(Equipado)")
				}
				else
					formatex(cost, charsmax(cost), " \dCuesta \r%d \dPuntos", knifemodels[i][knife_cost])

				add(items, charsmax(items), cost)
			}
		}
		
		menu_additem(menu, items, _)
	}

	menu_setprop(menu, MPROP_NUMBER_COLOR, "\y")
	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL)
	menu_setprop(menu, MPROP_BACKNAME , "Atras")
	menu_setprop(menu, MPROP_NEXTNAME , "Siguiente")
	menu_setprop(menu, MPROP_EXITNAME, "Salir")
	menu_display(id, menu, page)

	return PLUGIN_CONTINUE
}

public func_menu_knife(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}

	if(!buyk[id])
	{
		new motd[512];
		new title[64];
		formatex(title, charsmax(title), "%s", knifemodels[item][knife_menu]);

		formatex(motd, charsmax(motd), "%s<html>", motd);
		formatex(motd, charsmax(motd), "%s<body style=^"margin: 0;^">", motd);
		formatex(motd, charsmax(motd), "%s<img src=^"%s/%s.jpg^" style=^"height: 100%%; width: 100%%;^">", motd, knifeurl, knifemodels[item][knife_menu]);

		formatex(motd, charsmax(motd), "%s</body>", motd);
		formatex(motd, charsmax(motd), "%s</html>", motd);

		show_motd(id, motd, title);
		
		switch(item)
		{
			case 0..6: 	menu_knife(id, 0)
			case 7..13: 	menu_knife(id, 1)
			case 14..20: 	menu_knife(id, 2)
		}

		return PLUGIN_HANDLED
	}

	item -= buyk[id]

	if(item == -1)
	{
		knife_model[id] = -1
		setknife(id)
		return PLUGIN_HANDLED
	}

	if(!knife_buyed[id][item] && knifemodels[item][knife_cost] != 0)
	{
		if(g_puntos[id] < knifemodels[item][knife_cost])
			client_print(id, print_chat, "No tienes puntos suficientes para comprar esto")
		else
		{
			knife_select[id] = item
			menu_confirm_knife(id)
		}

		return PLUGIN_HANDLED
	}

	knife_model[id] = item
	client_print(id, print_chat, "Equipaste el cuchillo %s", knifemodels[knife_model[id]][knife_menu])
	setknife(id)

	return PLUGIN_HANDLED
}

public setknife(id) 
{
	if(!is_user_alive(id) || get_user_weapon(id) != CSW_KNIFE)
		return PLUGIN_HANDLED

	new model_v[64], model_p[64]

	if(knife_model[id] == -1)
	{
		formatex(model_v, charsmax(model_v), "models/v_knife.mdl")
		formatex(model_p, charsmax(model_p), "models/p_knife.mdl")
	}

	else
	{
		formatex(model_v, charsmax(model_v), "models/%s/%s.mdl", knifecarpeta, knifemodels[knife_model[id]][knife_vname])
		formatex(model_p, charsmax(model_p), "models/%s/%s.mdl", knifecarpeta, knifemodels[knife_model[id]][knife_pname])
	}

	entity_set_string(id, EV_SZ_viewmodel, model_v)
	entity_set_string(id, EV_SZ_weaponmodel, model_p)
	
	return PLUGIN_CONTINUE
}

public Knife_Deploy(weapon)
{
	new id = get_pdata_cbase(weapon, 41, 4)
	
	if(!pev_valid(id))
		return HAM_IGNORED

	setknife(id)	
	return HAM_IGNORED
}

public menu_confirm_knife(id)
{
	new title[64]
	formatex(title, charsmax(title), "Seguro que quieres comprar el cuchillo %s?", knifemodels[knife_select[id]][knife_menu])

	new menu = menu_create(title, "knife_confirm_handler")

	menu_additem(menu, "Si")
	menu_additem(menu, "No")

	menu_setprop(menu, MPROP_EXIT, MEXIT_NEVER)
	menu_display(id, menu, 0)
}

public knife_confirm_handler(id, menu, item)
{
	if(item == 0)
	{
		knife_buyed[id][knife_select[id]] = true
		g_puntos[id] -= knifemodels[knife_select[id]][knife_cost]
		client_print(id, print_chat, "Compraste el cuchillo %s", knifemodels[knife_select[id]][knife_menu])
	}

	menu_destroy(menu)
	return PLUGIN_CONTINUE
}

////////////////////////////// trail menu ////////////////////////////////

public menutrail(id)
{
	if(!is_user_alive(id))
		return PLUGIN_HANDLED

	static menu, items[64]
	menu = menu_create("Menu de trails", "func_menu_trail")
    
	static i
	for (i = 0; i <= trailCount; i++)
	{		
		formatex(items, charsmax(items), "%s", trails[i][trail_color])

		if(trail_buyed[id][i])
		{
			if(trail[id] == i)
				add(items, charsmax(items), " \y(Equipado)")
			else
				add(items, charsmax(items), " \r(Comprado)")
		}
		else
		{
			new cost[32]

			if(trails[i][trail_cost] == 0)
			{
				formatex(cost, charsmax(cost), "")

				if(trail[id] == i)
					add(items, charsmax(items), " \y(Equipado)")
			}
			else
				formatex(cost, charsmax(cost), " \dCuesta \r%d \dPuntos", trails[i][trail_cost])

			add(items, charsmax(items), cost)
		}

		menu_additem(menu, items, _)
	}

	menu_setprop(menu, MPROP_NUMBER_COLOR, "\y")
	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL)
	menu_setprop(menu, MPROP_BACKNAME , "Atras")
	menu_setprop(menu, MPROP_NEXTNAME , "Siguiente")
	menu_setprop(menu, MPROP_EXITNAME, "Salir")
	menu_display(id, menu, 0)

	return PLUGIN_CONTINUE
}

public func_menu_trail(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}
	
	if(item == 0)
	{
		trail[id] = 0
		trail_off(id)
		return PLUGIN_HANDLED
	}
	
	if(!trail_buyed[id][item] && trails[item][trail_cost] != 0)
	{
		if(g_puntos[id] < trails[item][trail_cost])
			client_print(id, print_chat, "No tienes puntos suficientes para comprar esto")
		else
		{
			trail_select[id] = item
			menu_confirm_trail(id)
		}	

		return PLUGIN_HANDLED
	}

	trail[id] = item
	trail_pred[id] = trails[trail[id]][trail_red]
	trail_pgreen[id] = trails[trail[id]][trail_green]
	trail_pblue[id] = trails[trail[id]][trail_blue]

	client_print(id, print_chat, "Equipaste el trail %s", trails[trail[id]][trail_color])
	
	trail_off(id)
	trail_on(id)

	return PLUGIN_HANDLED
}

public trail_on(id)
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(22)	// TE_BEAMFOLLOW
	write_short(id) // id
	write_short(sprite) // sprite
	write_byte(10) // life
	write_byte(5) // size
	write_byte(trail_pred[id]) // r
	write_byte(trail_pgreen[id]) // g
	write_byte(trail_pblue[id]) // b
	write_byte(105) // alpha
	message_end()
}

public trail_off(id)
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(99)	// TE_KILLBEAM
	write_short(id) // id
	message_end()
}

public menu_confirm_trail(id)
{
	new title[64]
	formatex(title, charsmax(title), "Seguro que quieres comprar el trail %s?", trails[trail_select[id]][trail_color])

	new menu = menu_create(title, "trail_confirm_handler")

	menu_additem(menu, "Si")
	menu_additem(menu, "No")

	menu_setprop(menu, MPROP_EXIT, MEXIT_NEVER)
	menu_display(id, menu, 0)
}

public trail_confirm_handler(id, menu, item)
{
	if(item == 0)
	{
		trail_buyed[id][trail_select[id]] = true
		g_puntos[id] -= trails[trail_select[id]][trail_cost]
		client_print(id, print_chat, "Compraste el trail %s", trails[trail_select[id]][trail_color])
	}

	menu_destroy(menu)
	return PLUGIN_CONTINUE
}

/////////////////////////////// general //////////////////////////////

public show_menu_shop(id)
{
	if(get_user_team(id) == 0 || get_user_team(id) == 3)
		return PLUGIN_HANDLED

	new title[64]
	formatex(title, charsmax(title), "Ultimate Shop por \rXX-BRI4N-^n^n \dTienes \r%d \dPuntos", g_puntos[id])
	
	new menu = menu_create(title, "shop_menu")

	menu_additem(menu, "Comprar Models")
	menu_additem(menu, "Comprar Hats")
	menu_additem(menu, "Comprar Cuchillos")
	menu_additem(menu, "Comprar Trails")

	menu_setprop(menu, MPROP_EXITNAME, "Salir")
	menu_display(id, menu)

	return PLUGIN_HANDLED
}

public shop_menu(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}

	switch(item)
	{
		case 0: menu_pmodel(id)

		case 1: menuhat(id)

		case 2: choosek(id)

		case 3: menutrail(id)
	}

	return PLUGIN_HANDLED
}

public player_first_spawn(id)
{
	if(player_hat[id])
	{
		if(is_valid_ent(hat_selected[id]))
			remove_entity(hat_selected[id])

		sethat(id)
	}

	if(knife_model[id] != -1)
		set_task(0.3, "setknife", id)

	if(trail[id])
	{
		trail_pred[id] = trails[trail[id]][trail_red]
		trail_pgreen[id] = trails[trail[id]][trail_green]
		trail_pblue[id] = trails[trail[id]][trail_blue]
		trail_on(id)
	}

	firstspawn[id] = true
}

public native_puntos(id, cant)
{
	g_puntos[id] += cant
	client_print(id, print_chat, "Recibiste %d puntos", cant)

	// sma externo -> native dar_puntos(id, cant)
	// uso -> dar_puntos(id, cant)
}

//////////////////////////////////// stocks ////////////////////////////// 

PackArrayToString(szString[], iLen, const iDest[], const iDestSize = sizeof iDest, const iSeparator = ',') // (creditos metalicross)
{
	if(iDestSize <= 0)
		return 0;
    
	new iWritten, i = 1
	iWritten = num_to_str(iDest[0], szString, iLen)
    
	while( i < iDestSize && iWritten < iLen )
	iWritten += formatex(szString[iWritten], iLen - iWritten, "%c%d", iSeparator, iDest[i++])
    
	return iWritten;
}

StringToArray(const szData[], iDest[], const iDestSize = sizeof iDest, const iSeparator = ',')
{
	new szChunk[32], szBuffer[128], i;
	copy(szBuffer, charsmax(szBuffer), szData);

	while( i < iDestSize )
	{
		strtok(szBuffer, szChunk, charsmax(szChunk), szBuffer, charsmax(szBuffer), iSeparator, 1)
		iDest[i++] = str_to_num(szChunk)
	}
    
	return i;
}

stock get_team_value(teamstr[])
{
	if(equal(teamstr, "ALL")) return ALL;
	if(equal(teamstr, "TE"))  return TE;
	if(equal(teamstr, "CT"))  return CT;
	return -1;
}

//////////////////////////////////// sql /////////////////////////////////////////////

public Guardar(id)
{
	static mdlbuy[99], hatbuy[99], knfbuy[99], trlbuy[99]
	PackArrayToString(mdlbuy, charsmax(mdlbuy), model_buyed[id])
	PackArrayToString(hatbuy, charsmax(hatbuy), hat_buyed[id])
	PackArrayToString(knfbuy, charsmax(knfbuy), knife_buyed[id])
	PackArrayToString(trlbuy, charsmax(trlbuy), trail_buyed[id])

	new query[512]
	formatex(query, charsmax(query),
	"UPDATE %s SET pmodel='%d', last_te='%d', last_ct='%d', mdlbuyed='%s', phat='%d', hatbuyed='%s', knfmodel='%d', knfbuyed='%s', ptrail='%d', trlbuyed='%s', puntos='%d' WHERE Nombre='%s';",
	SQL_DBTABLE, player_model[id], last_model_te[id], last_model_ct[id],
	mdlbuy, player_hat[id], hatbuy, knife_model[id], knfbuy, trail[id], trlbuy,
	g_puntos[id], playerName[id])

	SQL_ThreadQuery(g_Tuple, "Guardar_Callback", query)
}

public Guardar_Callback(FailState, Handle:Query, error[], errcode, data[], datasize)
{
	if(FailState == TQUERY_CONNECT_FAILED || FailState == TQUERY_QUERY_FAILED)
	{
		log_to_file("sql_error.txt", "Error al guardar: %s", error)
	}
}

public Cargar(id)
{
	new data[1]
	data[0] = id

	new query[256]
	formatex(query, charsmax(query),
	"SELECT pmodel, last_te, last_ct, mdlbuyed, phat, hatbuyed, knfmodel, knfbuyed, ptrail, trlbuyed, puntos FROM %s WHERE Nombre='%s';",
	SQL_DBTABLE, playerName[id])

	SQL_ThreadQuery(g_Tuple, "Cargar_Callback", query, data, sizeof(data))
}

public Cargar_Callback(FailState, Handle:Query, error[], errcode, data[], datasize)
{
	if(FailState == TQUERY_CONNECT_FAILED || FailState == TQUERY_QUERY_FAILED)
	{
		log_to_file("sql_error.txt", "Error al cargar: %s", error)
		return
	}

	new id = data[0]

	if(SQL_NumResults(Query))
	{
		static mdlbuy[99], hatbuy[99], knfbuy[99], trlbuy[99]

		player_model[id] = SQL_ReadResult(Query, 0)
		last_model_te[id] = SQL_ReadResult(Query, 1)
		last_model_ct[id] = SQL_ReadResult(Query, 2)
		SQL_ReadResult(Query, 3, mdlbuy, charsmax(mdlbuy))
		player_hat[id] = SQL_ReadResult(Query, 4)
		SQL_ReadResult(Query, 5, hatbuy, charsmax(hatbuy))
		knife_model[id] = SQL_ReadResult(Query, 6)
		SQL_ReadResult(Query, 7, knfbuy, charsmax(knfbuy))
		trail[id] = SQL_ReadResult(Query, 8)
		SQL_ReadResult(Query, 9, trlbuy, charsmax(trlbuy))
		g_puntos[id] = SQL_ReadResult(Query, 10)

		StringToArray(mdlbuy, model_buyed[id])
		StringToArray(hatbuy, hat_buyed[id])
		StringToArray(knfbuy, knife_buyed[id])
		StringToArray(trlbuy, trail_buyed[id])
	}
	else
	{
		new insert[128]
		formatex(insert, charsmax(insert), "INSERT INTO %s (Nombre) VALUES ('%s');", SQL_DBTABLE, playerName[id])
		SQL_ThreadQuery(g_Tuple, "Cargar_Insert_Callback", insert)
	}
}

public Cargar_Insert_Callback(FailState, Handle:Query, error[], errcode, data[], datasize)
{
	if(FailState == TQUERY_CONNECT_FAILED || FailState == TQUERY_QUERY_FAILED)
	{
		log_to_file("sql_error.txt", "Error al insertar nuevo jugador: %s", error)
	}
}

#if defined mysql

public SQL_Init()
{
	static g_error

	g_Tuple = SQL_MakeDbTuple(SQL_HOST, SQL_USER, SQL_PASS, SQL_DBNAME)

	if(g_Tuple == Empty_Handle) 
	{
		log_to_file("sql_ushop_mysql.txt", "Error en MakeDbTuple")
		return pause("a")
	}

	g_Connection = SQL_Connect(g_Tuple, g_error, error, charsmax(error))

	if(g_Connection == Empty_Handle)
	{
		log_to_file("sql_ushop_mysql.txt", "Error en la conexion")
		return pause("a")
	}
	
	return PLUGIN_CONTINUE
}

#else

public SQL_Init()
{
	static get_type[12], g_error, len, table[3000]
	
	SQL_SetAffinity("sqlite")
	SQL_GetAffinity(get_type, charsmax(get_type))
	
	if(!equal(get_type, "sqlite"))
	{
		log_to_file("sql_ushop_sqlite.txt", "El modulo sqlite no esta activado")
		return pause("a")
	}
	
	g_Tuple = SQL_MakeDbTuple("", "", "", SQL_DBNAME)
	g_Connection = SQL_Connect(g_Tuple, g_error, error, charsmax(error))

	len = 0
	len += formatex(table[len], charsmax(table) - len, "CREATE TABLE IF NOT EXISTS '%s'", SQL_DBTABLE)
	len += formatex(table[len], charsmax(table) - len, "(Nombre varchar(32) NOT NULL UNIQUE PRIMARY KEY,")
	len += formatex(table[len], charsmax(table) - len, "pmodel int NOT NULL DEFAULT '0',")
	len += formatex(table[len], charsmax(table) - len, "last_te int NOT NULL DEFAULT '0',")
	len += formatex(table[len], charsmax(table) - len, "last_ct int NOT NULL DEFAULT '0',")
	len += formatex(table[len], charsmax(table) - len, "mdlbuyed varchar(99) NOT NULL DEFAULT '',")
	len += formatex(table[len], charsmax(table) - len, "phat int NOT NULL DEFAULT '0',")
	len += formatex(table[len], charsmax(table) - len, "hatbuyed varchar(99) NOT NULL DEFAULT '',")
	len += formatex(table[len], charsmax(table) - len, "knfmodel int NOT NULL DEFAULT '-1',")
	len += formatex(table[len], charsmax(table) - len, "knfbuyed varchar(99) NOT NULL DEFAULT '',")
	len += formatex(table[len], charsmax(table) - len, "ptrail int NOT NULL DEFAULT '0',")
	len += formatex(table[len], charsmax(table) - len, "trlbuyed varchar(99) NOT NULL DEFAULT '',")
	len += formatex(table[len], charsmax(table) - len, "puntos int NOT NULL DEFAULT '0')")

	new Handle:g_Query
	g_Query = SQL_PrepareQuery(g_Connection, table)
	
	SQL_Execute(g_Query)
	SQL_FreeHandle(g_Query)

	return PLUGIN_CONTINUE
}

#endif

public plugin_end()
{
	SQL_FreeHandle(g_Tuple)
	SQL_FreeHandle(g_Connection)
}

////////////////////////////// carga de inis //////////////////////////////

load_models_config()
{
    new ConfigFile[100]; get_configsdir(ConfigFile, charsmax(ConfigFile));
    add(ConfigFile, charsmax(ConfigFile), "/ushop/models.ini");

    if(!file_exists(ConfigFile))
        return;

    new file = fopen(ConfigFile, "rt");
    new key[64], value[64], line[300];

    while(!feof(file))
    {
        fgets(file, line, charsmax(line));
        trim(line);

        if(!line[0] || line[0] == ';')
            continue;

        if(line[0] == '[')
        {
            modelCount++;
            continue;
        }

        strtok(line, key, charsmax(key), value, charsmax(value), '=');
        trim(key); trim(value);

        if(equal(key, "MODEL_NAME"))
            copy(modelsplayers[modelCount][model_menu], 32, value);
        else if(equal(key, "MODEL_FILE"))
            copy(modelsplayers[modelCount][model_name], 32, value);
        else if(equal(key, "MODEL_TEAM"))
	    modelsplayers[modelCount][model_team] = get_team_value(value);
        else if(equal(key, "MODEL_COST"))
            modelsplayers[modelCount][model_cost] = str_to_num(value);
    }
    fclose(file);
}

load_hats_config()
{
    new ConfigFile[100]; get_configsdir(ConfigFile, charsmax(ConfigFile));
    add(ConfigFile, charsmax(ConfigFile), "/ushop/hats.ini");

    if(!file_exists(ConfigFile))
        return;

    new file = fopen(ConfigFile, "rt");
    new key[64], value[64], line[300];

    while(!feof(file))
    {
        fgets(file, line, charsmax(line));
        trim(line);

        if(!line[0] || line[0] == ';')
            continue;

        if(line[0] == '[')
        {
            hatCount++;
            continue;
        }

        strtok(line, key, charsmax(key), value, charsmax(value), '=');
        trim(key); trim(value);

        if(equal(key, "HAT_NAME"))
            copy(hatmodels[hatCount][hat_menu], 32, value);
        else if(equal(key, "HAT_MODEL"))
            copy(hatmodels[hatCount][hat_name], 32, value);
        else if(equal(key, "HAT_COST"))
            hatmodels[hatCount][hat_cost] = str_to_num(value);
    }
    fclose(file);
}

load_knifes_config()
{
    new ConfigFile[100]; get_configsdir(ConfigFile, charsmax(ConfigFile));
    add(ConfigFile, charsmax(ConfigFile), "/ushop/knifes.ini");

    if(!file_exists(ConfigFile))
        return;

    new file = fopen(ConfigFile, "rt");
    new key[64], value[64], line[300];

    while(!feof(file))
    {
        fgets(file, line, charsmax(line));
        trim(line);

        if(!line[0] || line[0] == ';')
            continue;

        if(line[0] == '[')
        {
            knifeCount++;
            continue;
        }

        strtok(line, key, charsmax(key), value, charsmax(value), '=');
        trim(key); trim(value);

        if(equal(key, "KNIFE_VIEW"))
            copy(knifemodels[knifeCount][knife_vname], 32, value);
        else if(equal(key, "KNIFE_PLAYER"))
            copy(knifemodels[knifeCount][knife_pname], 32, value);
        else if(equal(key, "KNIFE_NAME"))
            copy(knifemodels[knifeCount][knife_menu], 32, value);
        else if(equal(key, "KNIFE_COST"))
            knifemodels[knifeCount][knife_cost] = str_to_num(value);
    }
    fclose(file);
}

load_trails_config()
{
    new ConfigFile[100]; get_configsdir(ConfigFile, charsmax(ConfigFile));
    add(ConfigFile, charsmax(ConfigFile), "/ushop/trails.ini");

    if(!file_exists(ConfigFile))
        return;

    new file = fopen(ConfigFile, "rt");
    new key[64], value[64], line[300];

    while(!feof(file))
    {
        fgets(file, line, charsmax(line));
        trim(line);

        if(!line[0] || line[0] == ';')
            continue;

        if(line[0] == '[')
        {
            trailCount++;
            continue;
        }

        strtok(line, key, charsmax(key), value, charsmax(value), '=');
        trim(key); trim(value);

        if(equal(key, "TRAIL_NAME"))
            copy(trails[trailCount][trail_color], 32, value);
        else if(equal(key, "TRAIL_R"))
            trails[trailCount][trail_red] = str_to_num(value);
        else if(equal(key, "TRAIL_G"))
            trails[trailCount][trail_green] = str_to_num(value);
        else if(equal(key, "TRAIL_B"))
            trails[trailCount][trail_blue] = str_to_num(value);
        else if(equal(key, "TRAIL_COST"))
            trails[trailCount][trail_cost] = str_to_num(value);
    }
    fclose(file);
}

////////////////////////////// consulta ///////////////////////////////////

// sqlite

/*
CREATE TABLE 'jugadores' (
Nombre varchar(32) NOT NULL UNIQUE PRIMARY KEY,
pmodel int NOT NULL default '0',
last_te int NOT NULL default '0',
last_ct int NOT NULL default '0',
mdlbuyed varchar(99) NOT NULL DEFAULT '',
phat int NOT NULL default '0',
hatbuyed varchar(99) NOT NULL DEFAULT '',
knfmodel int NOT NULL default '-1',
knfbuyed varchar(99) NOT NULL DEFAULT '',
ptrail int NOT NULL default '0',
trlbuyed varchar(99) NOT NULL DEFAULT '',
puntos int NOT NULL default '0'
)
*/

// mysql

/*
CREATE TABLE `jugadores` (
  `Nombre` varchar(32) NOT NULL UNIQUE,
  `pmodel` int(11) NOT NULL DEFAULT '0',
  `last_te` int(11) NOT NULL DEFAULT '0',
  `last_ct` int(11) NOT NULL DEFAULT '0',
  `mdlbuyed` varchar(99) NOT NULL DEFAULT '0',
  `phat` int(11) NOT NULL DEFAULT '0',
  `hatbuyed` varchar(99) NOT NULL DEFAULT '0',
  `knfmodel` int(11) NOT NULL DEFAULT '-1',
  `knfbuyed` varchar(99) NOT NULL DEFAULT '0',
  `ptrail` int(11) NOT NULL DEFAULT '0',
  `trlbuyed` varchar(99) NOT NULL DEFAULT '0',
  `puntos` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`Nombre`)
)
*/

////////////////////////////// dato extra ///////////////////////////////////

/*	
	Dependiendo de la cantidad de items que tengan en cada tienda el valor del varchar que los guarda deberia ser de un poco mas del doble que la cantidad de items
	ya que son arrays bidimencionales que se convierten a string para almacenarse en sql y por ende, necesita guardar tanto los valores como los 
	separadores, asi que se guardaria algo asi -> (0,1,1,0)
	
	Ejemplo: si yo tengo 10 cuchillos el varchar que los guarda <`knfbuyed` varchar(99)> y todos los demas (hats, etc) deberian ser de un poco 
	mas del doble de tamaño que la cantidad de items que tenga cada uno en su respectiva tienda, lo mismo con los statics definidos en guardar/cargar
	<static mdlbuy[99], hatbuy[99]...> deberian ser del mismo tamaño que nuestras columnas
	
	Es decir, al tener 10 cuchillos en total el valor del varchar deberia de ser de al menos unos 22 aunque siempre es recomendable poner un poco mas
	para evitar perdida de datos, en este caso yo le puse 99 a cada uno asi que estoy sobrado dado a la cantidad de items que tengo de cada tienda, pero si
	van a poner muchos mas items deberian aumentar el valor de sus campos varchar, ya que si no lo hacen el array no se va a guardar 
	completo porque no tendra el espacio necesario
*/
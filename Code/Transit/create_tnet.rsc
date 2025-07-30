Macro "create_tnet" (time_period, transit_mode, access_mode, Dir)

	shared route_file, routename, net_file, link_lyr, node_lyr


// ----- Setup Parameters for Building Transit Network  -----------------------------------

 // RunMacro("G30 File Close All")

//// Update Walk time field such that perceived walk time is a function of pedestrian environment (JainM, Sept. 08)

    // Add new field to link layer
    NewFlds = {{"TTWtdWlkAB",   "real"},{"TTWtdWlkBA",   "real"}
              }
    if !RunMacro("TCB Run Macro", 1, "TCB Add View Fields", {link_lyr, NewFlds}) then goto badquit
    NewFlds=null

    Opts=null
    Opts = {{"Input",    {{"Dataview Set",   {net_file + "|" + link_lyr}}}},
            {"Global",   {{"Fields",         {"TTWtdWlkAB"}},
                          {"Method",         "Formula"},
                          {"Parameter",      {"if (areatp=1 and Mode=10) then 1.5*TTwalkAB else if (areatp=2 and Mode=10) then 2.0*TTwalkAB else if (areatp=3 and Mode=10) then 2.5*TTwalkAB else if (areatp>3 and Mode=10) then 3.5*TTwalkAB else TTwalkAB"}}}}}
    if !RunMacro("TCB Run Operation", 2, "Fill Dataview", Opts) then goto badquit

    Opts=null
    Opts = {{"Input",    {{"Dataview Set",   {net_file + "|" + link_lyr}}}},
            {"Global",   {{"Fields",         {"TTWtdWlkBA"}},
                          {"Method",         "Formula"},
                          {"Parameter",      {"if (areatp=1 and Mode=10) then 1.5*TTwalkBA else if (areatp=2 and Mode=10) then 2.0*TTwalkBA else if (areatp=3 and Mode=10) then 2.5*TTwalkBA else if (areatp>3 and Mode=10) then 3.5*TTwalkBA else TTwalkBA"}}}}}
    if !RunMacro("TCB Run Operation", 3, "Fill Dataview", Opts) then goto badquit

     Opts = null
     Opts.Input.[Dataview Set] = {net_file + "|" + link_lyr, link_lyr, "Selection", "Select * where areatp>3 and Mode=10 and (Pedactivity= 'M' or Pedactivity= 'H' or Developden='H')"}
     Opts.Global.Fields = {"TTWtdWlkAB"}
     Opts.Global.Method = "Formula"
     Opts.Global.Parameter = "2.5*TTwalkAB"

     if !RunMacro("TCB Run Operation", 4, "Fill Dataview", Opts) then goto badquit

     Opts = null
     Opts.Input.[Dataview Set] = {net_file + "|" + link_lyr, link_lyr, "Selection", "Select * where areatp>3 and Mode=10 and (Pedactivity= 'M' or Pedactivity= 'H' or Developden='H')"}
     Opts.Global.Fields = {"TTWtdWlkBA"}
     Opts.Global.Method = "Formula"
     Opts.Global.Parameter = "2.5*TTwalkBA"

     if !RunMacro("TCB Run Operation", 5, "Fill Dataview", Opts) then goto badquit

// JainM, 07.11.2010. For links with funcl=85 (transit only station/pnr access links, set the walk time weight = 1.0
     Opts = null
     Opts.Input.[Dataview Set] = {net_file + "|" + link_lyr, link_lyr, "Selection", "Select * where funcl=85 and Mode=10"}
     Opts.Global.Fields = {"TTWtdWlkAB"}
     Opts.Global.Method = "Formula"
     Opts.Global.Parameter = "1.0*TTwalkAB"

     if !RunMacro("TCB Run Operation", 6, "Fill Dataview", Opts) then goto badquit

     Opts = null
     Opts.Input.[Dataview Set] = {net_file + "|" + link_lyr, link_lyr, "Selection", "Select * where funcl=85 and Mode=10"}
     Opts.Global.Fields = {"TTWtdWlkBA"}
     Opts.Global.Method = "Formula"
     Opts.Global.Parameter = "1.0*TTwalkBA"

     if !RunMacro("TCB Run Operation", 7, "Fill Dataview", Opts) then goto badquit

//// End of Update Walk time field

     Opts = null

     Opts.Input.[Transit RS] = route_file
	 

	// -- setting for selecting transit routes
	
	if ( transit_mode = "premium") then do
		if (time_period = "AM") then do
			qry = "Select * where AM_HEAD > 0 and ALT_FLAG = 1"
			Opts.Input.[RS Set] = {route_file + "|Vehicle Routes", "Vehicle Routes", "All Modes", qry} 
		end
		else if (time_period = "MD") then do
			qry = "Select * where MID_HEAD > 0 and ALT_FLAG = 1"
			Opts.Input.[RS Set] = {route_file + "|Vehicle Routes", "Vehicle Routes", "All Modes", qry} 
		end
		else if (time_period = "PM") then do
			qry = "Select * where PM_HEAD > 0 and ALT_FLAG = 1"
			Opts.Input.[RS Set] = {route_file + "|Vehicle Routes", "Vehicle Routes", "All Modes", qry} 
		end
		else if (time_period = "NT") then do	
			qry = "Select * where NIGHT_HEAD > 0 and ALT_FLAG = 1"
			Opts.Input.[RS Set] = {route_file + "|Vehicle Routes", "Vehicle Routes", "All Modes", qry} 
		end
	end
	else if ( transit_mode = "premium2") then do
		if (time_period = "AM") then do
			qry = "Select * where AM_HEAD > 0 and Mode < 5 and ALT_FLAG = 1"	
			Opts.Input.[RS Set] = {route_file + "|Vehicle Routes", "Vehicle Routes",  qry} 
		end
		else if (time_period = "MD") then do
			qry = "Select * where MID_HEAD > 0 and Mode < 5 and ALT_FLAG = 1"
			Opts.Input.[RS Set] = {route_file + "|Vehicle Routes", "Vehicle Routes", qry} 
		end
		else if (time_period = "PM") then do
			qry = "Select * where PM_HEAD > 0 and Mode < 5 and ALT_FLAG = 1"
			Opts.Input.[RS Set] = {route_file + "|Vehicle Routes", "Vehicle Routes", qry} 
		end
		else if (time_period = "NT") then do	
			qry = "Select * where NIGHT_HEAD > 0 and Mode < 5 and ALT_FLAG = 1"
			Opts.Input.[RS Set] = {route_file + "|Vehicle Routes", "Vehicle Routes", qry} 
		end
	end
	else if ( transit_mode = "bus") then do
		if (time_period = "AM") then do
			qry = "Select * where AM_HEAD > 0 and Mode >= 5 and ALT_FLAG = 1"
			Opts.Input.[RS Set] = {route_file + "|Vehicle Routes", "Vehicle Routes", "All Modes", qry} 
		end
		if (time_period = "MD") then do
			qry = "Select * where MID_HEAD > 0 and Mode >= 5 and ALT_FLAG = 1"
			Opts.Input.[RS Set] = {route_file + "|Vehicle Routes", "Vehicle Routes", "All Modes", qry}
		end
		if (time_period = "PM") then do
			qry = "Select * where PM_HEAD > 0 and Mode >= 5 and ALT_FLAG = 1"
			Opts.Input.[RS Set] = {route_file + "|Vehicle Routes", "Vehicle Routes", "All Modes", qry} 
		end
		if (time_period = "NT") then do
			qry = "Select * where NIGHT_HEAD > 0 and Mode >= 5 and ALT_FLAG = 1"
			Opts.Input.[RS Set] = {route_file + "|Vehicle Routes", "Vehicle Routes", "All Modes", qry}
		end
	end


	/*if ( transit_mode = "premium") then do
		if (time_period = "peak") then 
			 Opts.Input.[RS Set] = {route_file + "|Vehicle Routes", "Vehicle Routes", "All Modes", "Select * where AM_HEAD > 0 and ALT_FLAG = 1"} 
		if (time_period = "offpeak") then 
		     //Opts.Input.[RS Set] = {route_file + "|Vehicle Routes", "[Vehicle Routes+ROUTES]", "All Modes", "Select * where MID_HEAD > 0 and ALT_FLAG = 1"} 
			 Opts.Input.[RS Set] = {route_file + "|Vehicle Routes", "Vehicle Routes", "All Modes", "Select * where MID_HEAD > 0 and ALT_FLAG = 1"} 
	end
	
	if ( transit_mode = "premium2") then do
		if (time_period = "peak") then 
		     //Opts.Input.[RS Set] = {route_file + "|Vehicle Routes", "[Vehicle Routes+ROUTES]", "All Modes", "Select * where AM_HEAD > 0 and Mode < 5 and ALT_FLAG = 1"} 
			 Opts.Input.[RS Set] = {route_file + "|Vehicle Routes", "Vehicle Routes",  "All Modes", "Select * where AM_HEAD > 0 and Mode < 5 and ALT_FLAG = 1"} 
		if (time_period = "offpeak") then 
		     //Opts.Input.[RS Set] = {route_file + "|Vehicle Routes", "[Vehicle Routes+ROUTES]", "All Modes", "Select * where MID_HEAD > 0  and Mode < 5 and ALT_FLAG = 1"} 
			 Opts.Input.[RS Set] = {route_file + "|Vehicle Routes", "Vehicle Routes",  "All Modes", "Select * where MID_HEAD > 0  and Mode < 5 and ALT_FLAG = 1"} 
	end
	
	if ( transit_mode = "bus") then do
		if (time_period = "peak") then 
		    // Opts.Input.[RS Set] = {route_file + "|Vehicle Routes", "[Vehicle Routes+ROUTES]", "All Buses", "Select * where AM_HEAD > 0 and (Mode >= 5) and ALT_FLAG = 1"} 
			Opts.Input.[RS Set] = {route_file + "|Vehicle Routes", "Vehicle Routes", "All Buses", "Select * where AM_HEAD > 0 and (Mode >= 5) and ALT_FLAG = 1"} 
		if (time_period = "offpeak") then 
			// Opts.Input.[RS Set] = {route_file + "|Vehicle Routes", "[Vehicle Routes+ROUTES]", "All Buses", "Select * where MID_HEAD > 0 and (Mode >= 5) and ALT_FLAG = 1"}
			 Opts.Input.[RS Set] = {route_file + "|Vehicle Routes", "Vehicle Routes", "All Buses", "Select * where MID_HEAD > 0 and (Mode >= 5) and ALT_FLAG = 1"}
	end
	*/
//     Opts.Input.[Walk Link Set] = {net_file + "|" + link_lyr, link_lyr, "Walking Links", "Select * where TTwalkAB <> 9999.00 or TTwalkBA <> 9999.00"}
     Opts.Input.[Walk Link Set] = {net_file + "|" + link_lyr, link_lyr, "Walking Links", "Select * where Mode = 10"}
     Opts.Input.[Stop Set] = {Dir + "\\"+ routename + "S.DBD|Route Stops","Route Stops"}

	// -- set up the network names for premium skims

	if ( transit_mode = "premium") then do

		if ( time_period = "AM") then do

			if ( access_mode = "walk") then do
			     Opts.Output.[Network File] = Dir + "\\PrmW_AM.tnw"
	     		 Opts.Global.[Network Label] = "AM Peak Premium Walk Network"
			end

			if ( access_mode = "drive") then do
			     Opts.Output.[Network File] = Dir + "\\PrmD_AM.tnw"
	     		 Opts.Global.[Network Label] = "AM Peak Premium Drive Network"
			end

			if ( access_mode = "dropoff") then do
			     Opts.Output.[Network File] = Dir + "\\PrmDrop_AM.tnw"
	     		 Opts.Global.[Network Label] = "AM Peak Premium DropOff Network"
			end
		end

		if ( time_period = "PM") then do

			if ( access_mode = "walk") then do
			     Opts.Output.[Network File] = Dir + "\\PrmW_PM.tnw"
	     		 Opts.Global.[Network Label] = "PM Peak Premium Walk Network"
			end

			if ( access_mode = "drive") then do
			     Opts.Output.[Network File] = Dir + "\\PrmD_PM.tnw"
	     		 Opts.Global.[Network Label] = "PM Peak Premium Drive Network"
			end

			if ( access_mode = "dropoff") then do
			     Opts.Output.[Network File] = Dir + "\\PrmDrop_AM.tnw"
	     		 Opts.Global.[Network Label] = "PM Peak Premium DropOff Network"
			end
		end

		if ( time_period = "MD") then do

			if ( access_mode = "walk") then do
			     Opts.Output.[Network File] = Dir + "\\PrmW_MD.tnw"
	     		 Opts.Global.[Network Label] = "MD OffPeak Premium Walk Network"
			end

			if ( access_mode = "drive") then do
			     Opts.Output.[Network File] = Dir + "\\PrmD_MD.tnw"
	     		 Opts.Global.[Network Label] = "MD OffPeak Premium Drive Network"
			end

			if ( access_mode = "dropoff") then do
			     Opts.Output.[Network File] = Dir + "\\PrmDrop_MD.tnw"
	     		 Opts.Global.[Network Label] = "MD OffPeak Premium DropOff Network"
			end
		end

		if ( time_period = "NT") then do

			if ( access_mode = "walk") then do
			     Opts.Output.[Network File] = Dir + "\\PrmW_NT.tnw"
	     		 Opts.Global.[Network Label] = "NT OffPeak Premium Walk Network"
			end

			if ( access_mode = "drive") then do
			     Opts.Output.[Network File] = Dir + "\\PrmD_NT.tnw"
	     		 Opts.Global.[Network Label] = "NT OffPeak Premium Drive Network"
			end

			if ( access_mode = "dropoff") then do
			     Opts.Output.[Network File] = Dir + "\\PrmDrop_NT.tnw"
	     		 Opts.Global.[Network Label] = "NT OffPeak Premium DropOff Network"
			end
		end

	end
	
	if ( transit_mode = "premium2") then do

		if ( time_period = "AM") then do

			if ( access_mode = "walk") then do
			     Opts.Output.[Network File] = Dir + "\\Prm2W_AM.tnw"
	     		 Opts.Global.[Network Label] = "AM Peak Premium2 Walk Network"
			end

			if ( access_mode = "drive") then do
			     Opts.Output.[Network File] = Dir + "\\Prm2D_AM.tnw"
	     		 Opts.Global.[Network Label] = "AM Peak Premium2 Drive Network"
			end

			if ( access_mode = "dropoff") then do
			     Opts.Output.[Network File] = Dir + "\\Prm2Drop_AM.tnw"
	     		 Opts.Global.[Network Label] = "AM Peak Premium2 DropOff Network"
			end
		end

		if ( time_period = "PM") then do

			if ( access_mode = "walk") then do
			     Opts.Output.[Network File] = Dir + "\\Prm2W_PM.tnw"
	     		 Opts.Global.[Network Label] = "PM Peak Premium2 Walk Network"
			end

			if ( access_mode = "drive") then do
			     Opts.Output.[Network File] = Dir + "\\Prm2D_PM.tnw"
	     		 Opts.Global.[Network Label] = "PM Peak Premium2 Drive Network"
			end

			if ( access_mode = "dropoff") then do
			     Opts.Output.[Network File] = Dir + "\\Prm2Drop_PM.tnw"
	     		 Opts.Global.[Network Label] = "PM Peak Premium2 DropOff Network"
			end
		end

		if ( time_period = "MD") then do

			if ( access_mode = "walk") then do
			     Opts.Output.[Network File] = Dir + "\\Prm2W_MD.tnw"
	     		 Opts.Global.[Network Label] = "MD OffPeak Premium2 Walk Network"
			end

			if ( access_mode = "drive") then do
			     Opts.Output.[Network File] = Dir + "\\Prm2D_MD.tnw"
	     		 Opts.Global.[Network Label] = "MD OffPeak Premium2 Drive Network"
			end

			if ( access_mode = "dropoff") then do
			     Opts.Output.[Network File] = Dir + "\\Prm2Drop_MD.tnw"
	     		 Opts.Global.[Network Label] = "MD OffPeak Premium2 DropOff Network"
			end
		end

		if ( time_period = "NT") then do

			if ( access_mode = "walk") then do
			     Opts.Output.[Network File] = Dir + "\\Prm2W_NT.tnw"
	     		 Opts.Global.[Network Label] = "NT OffPeak Premium2 Walk Network"
			end

			if ( access_mode = "drive") then do
			     Opts.Output.[Network File] = Dir + "\\Prm2D_NT.tnw"
	     		 Opts.Global.[Network Label] = "NT OffPeak Premium2 Drive Network"
			end

			if ( access_mode = "dropoff") then do
			     Opts.Output.[Network File] = Dir + "\\Prm2Drop_NT.tnw"
	     		 Opts.Global.[Network Label] = "NT OffPeak Premium2 DropOff Network"
			end
		end

	end

	// -- set up the network names for bus skims

	if ( transit_mode = "bus") then do

		if ( time_period = "AM") then do

			if ( access_mode = "walk") then do
			     Opts.Output.[Network File] = Dir + "\\PbusW_AM.tnw"
	     		 Opts.Global.[Network Label] = "AM Peak Bus Walk Network"
			end

			if ( access_mode = "drive") then do
			     Opts.Output.[Network File] = Dir + "\\PbusD_AM.tnw"
	     		 Opts.Global.[Network Label] = "AM Peak Bus Drive Network"
			end

			if ( access_mode = "dropoff") then do
			     Opts.Output.[Network File] = Dir + "\\PbusDrop_AM.tnw"
	     		 Opts.Global.[Network Label] = "AM Peak Bus DropOff Network"
			end
		end

		if ( time_period = "PM") then do

			if ( access_mode = "walk") then do
			     Opts.Output.[Network File] = Dir + "\\PbusW_PM.tnw"
	     		 Opts.Global.[Network Label] = "PM Peak Bus Walk Network"
			end

			if ( access_mode = "drive") then do
			     Opts.Output.[Network File] = Dir + "\\PbusD_PM.tnw"
	     		 Opts.Global.[Network Label] = "PM Peak Bus Drive Network"
			end

			if ( access_mode = "dropoff") then do
			     Opts.Output.[Network File] = Dir + "\\PbusDrop_PM.tnw"
	     		 Opts.Global.[Network Label] = "PM Peak Bus DropOff Network"
			end
		end

		if ( time_period = "MD") then do

			if ( access_mode = "walk") then do
			     Opts.Output.[Network File] = Dir + "\\PbusW_MD.tnw"
	     		 Opts.Global.[Network Label] = "MD OffPeak Bus Walk Network"
			end

			if ( access_mode = "drive") then do
			     Opts.Output.[Network File] = Dir + "\\PbusD_MD.tnw"
	     		 Opts.Global.[Network Label] = "MD OffPeak Bus Drive Network"
			end

			if ( access_mode = "dropoff") then do
			     Opts.Output.[Network File] = Dir + "\\PbusDrop_MD.tnw"
	     		 Opts.Global.[Network Label] = "MD OffPeak Bus DropOff Network"
			end
		end

		if ( time_period = "NT") then do

			if ( access_mode = "walk") then do
			     Opts.Output.[Network File] = Dir + "\\PbusW_NT.tnw"
	     		 Opts.Global.[Network Label] = "NT OffPeak Bus Walk Network"
			end

			if ( access_mode = "drive") then do
			     Opts.Output.[Network File] = Dir + "\\PbusD_NT.tnw"
	     		 Opts.Global.[Network Label] = "NT OffPeak Bus Drive Network"
			end

			if ( access_mode = "dropoff") then do
			     Opts.Output.[Network File] = Dir + "\\PbusDrop_NT.tnw"
	     		 Opts.Global.[Network Label] = "NT OffPeak Bus DropOff Network"
			end
		end
	end

    // Opts.Global.[Network Options].[Route Attributes].MODE = {"[Vehicle Routes+ROUTES].MODE"}
	 Opts.Global.[Network Options].[Route Attributes].MODE = {"[Vehicle Routes].MODE"}

	if ( time_period = "AM") then 
			Opts.Global.[Network Options].[Route Attributes].AM_HEAD = {"[Vehicle Routes].AM_HEAD"}
		else if ( time_period = "MD") then
			Opts.Global.[Network Options].[Route Attributes].MID_HEAD = {"[Vehicle Routes].MID_HEAD"}
		else if ( time_period = "PM") then
			Opts.Global.[Network Options].[Route Attributes].PM_HEAD = {"[Vehicle Routes].PM_HEAD"}
		else 
			Opts.Global.[Network Options].[Route Attributes].NIGHT_HEAD = {"[Vehicle Routes].NIGHT_HEAD"}

	Opts.Global.[Network Options].[Route Attributes].DWELL = {"[Vehicle Routes].DWELL"}
	Opts.Global.[Network Options].[Stop Attributes].UserID = {"[Route Stops].UserID"}

	/*if ( time_period = "peak") then
	     //Opts.Global.[Network Options].[Route Attributes].AM_HEAD = {"[Vehicle Routes+ROUTES].AM_HEAD"}
		 Opts.Global.[Network Options].[Route Attributes].AM_HEAD = {"[Vehicle Routes].AM_HEAD"}
	else if ( time_period = "offpeak") then 
		//Opts.Global.[Network Options].[Route Attributes].MID_HEAD = {"[Vehicle Routes+ROUTES].MID_HEAD"}
		Opts.Global.[Network Options].[Route Attributes].MID_HEAD = {"[Vehicle Routes].MID_HEAD"}
     //Opts.Global.[Network Options].[Route Attributes].DWELL = {"[Vehicle Routes+ROUTES].DWELL"}
     Opts.Global.[Network Options].[Route Attributes].DWELL = {"[Vehicle Routes].DWELL"}
	 Opts.Global.[Network Options].[Stop Attributes].UserID = {"[Route Stops].UserID"}
	*/
	 
// --- Set the Stop Access flag for Express Buses - Disabled Temporarily	
// Enable stop access coding for modes 5 and 6 for use with TransCAD5, JainM, 07.20.08
     Opts.Global.[Network Options].[Stop Attributes].XPR_FLAG = {"[Route Stops].XPR_FLAG"}

     Opts.Global.[Network Options].[Street Attributes].Length = {link_lyr + ".Length", link_lyr + ".Length"}

	if (access_mode = "walk") then
	     Opts.Global.[Network Options].[Street Attributes].[TTfree*] = {link_lyr + ".TTWtdWlkAB", link_lyr + ".TTWtdWlkBA"}
	else if (access_mode = "drive" or access_mode = "dropoff") then
	     Opts.Global.[Network Options].[Street Attributes].[TTfree*] = {link_lyr + ".TTfreeAB", link_lyr + ".TTfreeBA"}

     Opts.Global.[Network Options].[Street Attributes].[TTFrLoc*] = {link_lyr + ".TTWtdWlkAB", link_lyr + ".TTWtdWlkBA"}
     Opts.Global.[Network Options].[Street Attributes].[TTFrXpr*] = {link_lyr + ".TTWtdWlkAB", link_lyr + ".TTWtdWlkBA"}
     Opts.Global.[Network Options].[Street Attributes].[TTFrSkS*] = {link_lyr + ".TTWtdWlkAB", link_lyr + ".TTWtdWlkBA"}
     Opts.Global.[Network Options].[Street Attributes].[TTFrNSt*] = {link_lyr + ".TTWtdWlkAB", link_lyr + ".TTWtdWlkBA"}

	if (access_mode = "walk") then
	     Opts.Global.[Network Options].[Street Attributes].[TTPkAssn*] = {link_lyr + ".TTWtdWlkAB", link_lyr + ".TTWtdWlkBA"}
	else if (access_mode = "drive" or access_mode = "dropoff") then 
	     Opts.Global.[Network Options].[Street Attributes].[TTPkAssn*] = {link_lyr + ".TTPkAssnAB", link_lyr + ".TTPkAssnBA"}

     Opts.Global.[Network Options].[Street Attributes].[TTPkLoc*] = {link_lyr + ".TTWtdWlkAB", link_lyr + ".TTWtdWlkBA"}
     Opts.Global.[Network Options].[Street Attributes].[TTPkXpr*] = {link_lyr + ".TTWtdWlkAB", link_lyr + ".TTWtdWlkBA"}
     Opts.Global.[Network Options].[Street Attributes].[TTPkSkS*] = {link_lyr + ".TTWtdWlkAB", link_lyr + ".TTWtdWlkBA"}
     Opts.Global.[Network Options].[Street Attributes].[TTPkNSt*] = {link_lyr + ".TTWtdWlkAB", link_lyr + ".TTWtdWlkBA"}
     Opts.Global.[Network Options].[Street Attributes].[TTwalk*] = {link_lyr + ".TTwalkAB", link_lyr + ".TTwalkBA"}
     Opts.Global.[Network Options].[Street Attributes].[TTWtdWlk*] = {link_lyr + ".TTWtdWlkAB", link_lyr + ".TTWtdWlkBA"}
     Opts.Global.[Network Options].[Street Attributes].[BRT_Flag] = {link_lyr + ".BRT_Flag", link_lyr + ".BRT_Flag"}
     Opts.Global.[Network Options].Walk = "Yes"
     Opts.Global.[Network Options].Overide = {"[Route Stops].ID", "[Route Stops].UserID"}
     Opts.Global.[Network Options].[Link Attributes] = {
		{"Length", {link_lyr + ".Length", link_lyr + ".Length"}, "SUMFRAC"}, 
		{"TTfree*", {link_lyr + ".TTfreeAB", link_lyr + ".TTfreeBA"}, "SUMFRAC"},
		{"TTFrLoc*", {link_lyr + ".TTFrLocAB", link_lyr + ".TTFrLocBA"}, "SUMFRAC"},
		{"TTFrXpr*", {link_lyr + ".TTFrXprAB", link_lyr + ".TTFrXprBA"}, "SUMFRAC"},
		{"TTFrSkS*", {link_lyr + ".TTFrSkSAB", link_lyr + ".TTFrSkSBA"}, "SUMFRAC"},
		{"TTFrNSt*", {link_lyr + ".TTFrNStAB", link_lyr + ".TTFrNStBA"}, "SUMFRAC"},
		{"TTPkAssn*", {link_lyr + ".TTPkAssnAB", link_lyr + ".TTPkAssnBA"}, "SUMFRAC"},
		{"TTPkLoc*", {link_lyr + ".TTPkLocAB", link_lyr + ".TTPkLocBA"}, "SUMFRAC"},
		{"TTPkXpr*", {link_lyr + ".TTPkXprAB", link_lyr + ".TTPkXprBA"}, "SUMFRAC"},
		{"TTPkSkS*", {link_lyr + ".TTPkSkSAB", link_lyr + ".TTPkSkSBA"}, "SUMFRAC"},
		{"TTPkNSt*", {link_lyr + ".TTPkNStAB", link_lyr + ".TTPkNStBA"}, "SUMFRAC"},
		{"TTwalk*", {link_lyr + ".TTwalkAB", link_lyr + ".TTwalkBA"}, "SUMFRAC"},
		{"TTWtdWlk*", {link_lyr + ".TTWtdWlkAB", link_lyr + ".TTWtdWlkBA"}, "SUMFRAC"},
		{"BRT_Flag", {link_lyr + ".BRT_Flag", link_lyr + ".BRT_Flag"}, "SUMFRAC"}}

     //Opts.Global.[Network Options].[Mode Field] = "[Vehicle Routes+ROUTES].Mode"
     Opts.Global.[Network Options].[Mode Field] = "[Vehicle Routes].MODE"
	 Opts.Global.[Network Options].[Walk Mode] = link_lyr + ".Mode"

	if ( access_mode = "drive" or access_mode = "dropoff") then 
	     Opts.Global.[Network Options].[Link Direction Field] = link_lyr + ".Dir"

	// -- set transit stop access . Disabled Temporarily
// Enable stop access coding for modes 5 and 6 for use with TransCAD5, JainM, 07.20.08
       Opts.Global.[Network Options].[Stop Access] = "[Route Stops].XPR_FLAG"
	Return(Opts)

badquit:
Throw("create_tnet - Error in tcb operation")

    RunMacro("TCB Closing", 0, "TRUE" ) 
	RunMacro("G30 File Close All")
	goto quit

quit:

endMacro
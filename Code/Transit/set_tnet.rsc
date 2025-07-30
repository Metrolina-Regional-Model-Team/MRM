Macro "set_tnet" (time_period, transit_mode, access_mode, Dir)

	shared route_file, routename, net_file, link_lyr, node_lyr

// --- Create a selection set for the park & ride stations

	premium_stations = "Select * where PNR = 1 or PNR = 2"
	nonpremium_stations = "Select * where PNR = 1 or PNR = 2"
	dropoff_stops = "Select * where KNR = 1 or KNR = 2 or KNR = 3"

// --- Year "2007" network doesn't have premium stations. Set the nonpremium stations as 
// --- premium station so that the dummy premium skims get generated

	if (s2i(theyear) < 2008) then 
		premium_stations=nonpremium_stations

// --- Define the selection set for Drive Approach Links

	drive_links = "Select * where (funcl > 0 and funcl < 10) or funcl = 82 or funcl = 84 or funcl = 90"

// ----- Transit Network Settings for Path Finder -----------------------------------


    Opts = null
    Opts.Input.[Transit RS] = route_file



    if ( transit_mode = "premium") then do

		if ( time_period = "AM") then do 
			if (access_mode = "walk") then 
				Opts.Input.[Transit Network] = Dir + "\\PrmW_AM.tnw"
			else if (access_mode = "drive") then 
				Opts.Input.[Transit Network] = Dir + "\\PrmD_AM.tnw"
			else if (access_mode = "dropoff") then 
				Opts.Input.[Transit Network] = Dir + "\\PrmDrop_AM.tnw"
		end

        if ( time_period = "PM") then do 
			if (access_mode = "walk") then 
				Opts.Input.[Transit Network] = Dir + "\\PrmW_PM.tnw"
			else if (access_mode = "drive") then 
				Opts.Input.[Transit Network] = Dir + "\\PrmD_PM.tnw"
			else if (access_mode = "dropoff") then 
				Opts.Input.[Transit Network] = Dir + "\\PrmDrop_PM.tnw"
		end


		if ( time_period = "MD") then do 
			if (access_mode = "walk") then 
				Opts.Input.[Transit Network] = Dir + "\\PrmW_MD.tnw"
			else if (access_mode = "drive") then 
				Opts.Input.[Transit Network] = Dir + "\\PrmD_MD.tnw"
			else if (access_mode = "dropoff") then 
				Opts.Input.[Transit Network] = Dir + "\\PrmDrop_MD.tnw"
		end

        if ( time_period = "NT") then do 
			if (access_mode = "walk") then 
				Opts.Input.[Transit Network] = Dir + "\\PrmW_NT.tnw"
			else if (access_mode = "drive") then 
				Opts.Input.[Transit Network] = Dir + "\\PrmD_NT.tnw"
			else if (access_mode = "dropoff") then 
				Opts.Input.[Transit Network] = Dir + "\\PrmDrop_NT.tnw"
		end
    end

    if ( transit_mode = "premium2") then do

		if ( time_period = "AM") then do 
			if (access_mode = "walk") then 
				Opts.Input.[Transit Network] = Dir + "\\Prm2W_AM.tnw"
			else if (access_mode = "drive") then 
				Opts.Input.[Transit Network] = Dir + "\\Prm2D_AM.tnw"
			else if (access_mode = "dropoff") then 
				Opts.Input.[Transit Network] = Dir + "\\Prm2Drop_AM.tnw"
		end

        if ( time_period = "PM") then do 
			if (access_mode = "walk") then 
				Opts.Input.[Transit Network] = Dir + "\\Prm2W_PM.tnw"
			else if (access_mode = "drive") then 
				Opts.Input.[Transit Network] = Dir + "\\Prm2D_PM.tnw"
			else if (access_mode = "dropoff") then 
				Opts.Input.[Transit Network] = Dir + "\\Prm2Drop_PM.tnw"
		end

		if ( time_period = "MD") then do 
			if (access_mode = "walk") then 
				Opts.Input.[Transit Network] = Dir + "\\Prm2W_MD.tnw"
			else if (access_mode = "drive") then 
				Opts.Input.[Transit Network] = Dir + "\\Prm2D_MD.tnw"
			else if (access_mode = "dropoff") then 
				Opts.Input.[Transit Network] = Dir + "\\Prm2Drop_MD.tnw"
		end

        if ( time_period = "NT") then do 
			if (access_mode = "walk") then 
				Opts.Input.[Transit Network] = Dir + "\\Prm2W_NT.tnw"
			else if (access_mode = "drive") then 
				Opts.Input.[Transit Network] = Dir + "\\Prm2D_NT.tnw"
			else if (access_mode = "dropoff") then 
				Opts.Input.[Transit Network] = Dir + "\\Prm2Drop_NT.tnw"
		end
    end

    if ( transit_mode = "bus") then do

		if ( time_period = "AM") then do 
			if (access_mode = "walk") then 
				Opts.Input.[Transit Network] = Dir + "\\BusW_AM.tnw"
			else if (access_mode = "drive") then 
				Opts.Input.[Transit Network] = Dir + "\\BusD_AM.tnw"
			else if (access_mode = "dropoff") then 
				Opts.Input.[Transit Network] = Dir + "\\BusDrop_AM.tnw"
		end

        if ( time_period = "PM") then do 
			if (access_mode = "walk") then 
				Opts.Input.[Transit Network] = Dir + "\\BusW_PM.tnw"
			else if (access_mode = "drive") then 
				Opts.Input.[Transit Network] = Dir + "\\BusD_PM.tnw"
			else if (access_mode = "dropoff") then 
				Opts.Input.[Transit Network] = Dir + "\\BusDrop_PM.tnw"
		end

		if ( time_period = "MD") then do 
			if (access_mode = "walk") then 
				Opts.Input.[Transit Network] = Dir + "\\BusW_MD.tnw"
			else if (access_mode = "drive") then 
				Opts.Input.[Transit Network] = Dir + "\\BusD_MD.tnw"
			else if (access_mode = "dropoff") then 
				Opts.Input.[Transit Network] = Dir + "\\BusDrop_MD.tnw"
		end

        if ( time_period = "NT") then do 
			if (access_mode = "walk") then 
				Opts.Input.[Transit Network] = Dir + "\\BusW_NT.tnw"
			else if (access_mode = "drive") then 
				Opts.Input.[Transit Network] = Dir + "\\BusD_NT.tnw"
			else if (access_mode = "dropoff") then 
				Opts.Input.[Transit Network] = Dir + "\\BusDrop_NT.tnw"
		end
    end


    Opts.Input.[Mode Table] = {Dir + "\\Modes.DBF"}
    Opts.Input.[Mode Cost Table] = {Dir + "\\Modexfer.DBF"}
    Opts.Input.[Centroid Set] = {net_file + "|" + node_lyr, node_lyr,"Centroids","Select * where centroid = 1 or [External Station] = 1"}

 // -- set the P&R and drop-off stops

	if (access_mode = "drive") then do
        //if (time_period = "peak") then do
	    if (time_period = "AM" or time_period = "PM") then do
                 if ( transit_mode = "premium") then Opts.Input.[OP Time Currency] = {Dir + "\\skims\\skim_pnr_peak_prm.mtx", "TTPkAssn*", "Origin", "Destination"}
                 if ( transit_mode = "premium2") then Opts.Input.[OP Time Currency] = {Dir + "\\skims\\skim_pnr_peak_prm2.mtx", "TTPkAssn*", "Origin", "Destination"}
                 if ( transit_mode = "bus") then Opts.Input.[OP Time Currency] = {Dir + "\\skims\\skim_pnr_peak_bus.mtx", "TTPkAssn*", "Origin", "Destination"}
            end     
	    //if (time_period = "offpeak") then do
        if (time_period = "MD" or time_period = "NT") then do
                 if ( transit_mode = "premium") then Opts.Input.[OP Time Currency] = {Dir + "\\skims\\skim_pnr_offpeak_prm.mtx", "TTFree*", "Origin", "Destination"}
                 if ( transit_mode = "premium2") then Opts.Input.[OP Time Currency] = {Dir + "\\skims\\skim_pnr_offpeak_prm2.mtx", "TTFree*", "Origin", "Destination"}
                 if ( transit_mode = "bus") then Opts.Input.[OP Time Currency] = {Dir + "\\skims\\skim_pnr_offpeak_bus.mtx", "TTFree*", "Origin", "Destination"}
            end

	end

	if (access_mode = "dropoff") then do

	    //if (time_period = "peak") then
        if (time_period = "AM" or time_period = "PM") then
                 Opts.Input.[OP Time Currency] = {Dir + "\\skims\\skim_knr_peak.mtx", "TTPkAssn*", "Origin", "Destination"}
	    //else if (time_period = "offpeak") then
        else if (time_period = "MD" or time_period = "NT") then
                 Opts.Input.[OP Time Currency] = {Dir + "\\skims\\skim_knr_offpeak.mtx", "TTfree*", "Origin", "Destination"}

	end

	if (access_mode = "drive" or access_mode = "dropoff") then
	    Opts.Input.[Driving Link Set] = {net_file + "|" + link_lyr, link_lyr, "Drive Approach Links", drive_links}

// -- set the field to read transit and drive travel times

	if ( access_mode = "drive" or access_mode = "dropoff") then do     
		//if (time_period = "peak") then
        if (time_period = "AM" or time_period = "PM") then
			Opts.Field.[Link Drive Time] = "TTPkAssn*" 	    
		//else if (time_period = "offpeak") then
        else if (time_period = "MD" or time_period = "NT") then
			Opts.Field.[Link Drive Time] = "TTfree*" 	    
	end 

      //if (time_period = "peak") then do
      if (time_period = "AM" or time_period = "PM") then do
		if (transit_mode = "premium") then 
			Opts.Field.[Link Impedance] = "TTPkLoc*"
		else if (transit_mode = "premium2") then 
			Opts.Field.[Link Impedance] = "TTPkLoc*"
		else if (transit_mode = "bus") then 
			Opts.Field.[Link Impedance] = "TTPkXpr*"
      end
    
    //if (time_period = "offpeak") then do
    if (time_period = "MD" or time_period = "NT") then do
		if (transit_mode = "premium") then 
			Opts.Field.[Link Impedance] = "TTFrLoc*"
		else if (transit_mode = "premium2") then 
			Opts.Field.[Link Impedance] = "TTFrLoc*"
		else if (transit_mode = "bus") then 
			Opts.Field.[Link Impedance] = "TTFrXpr*"
    end

    /*if (time_period = "peak") then
        Opts.Field.[Route Headway] = "AM_HEAD"
    else if (time_period = "offpeak") then
        Opts.Field.[Route Headway] = "MID_HEAD"
    */

     if (time_period = "AM") then
        Opts.Field.[Route Headway] = "AM_HEAD"
    else if (time_period = "MD") then
        Opts.Field.[Route Headway] = "MID_HEAD"  
    else if (time_period = "PM") then
        Opts.Field.[Route Headway] = "PM_HEAD"
    else if (time_period = "NT") then
        Opts.Field.[Route Headway] = "NIGHT_HEAD"

//	TC ver 7 repair - 2/2017
//    Opts.Field.[Route Dwell Time] = "DWELL"
    Opts.Field.[Route Dwell On Time] = "DWELL"
    Opts.Field.[Route Dwell Off Time] = "DWELL"

    Opts.Field.[Route Mode] = "MODE"
    Opts.Field.[Mode Fare] = "MODES.FARE"
    Opts.Field.[Mode Imp Weight] = "MODES.W_IVTT"
    Opts.Field.[Mode IWait Weight] = "MODES.W_IWAIT"
    Opts.Field.[Mode Dwell Weight] = "MODES.W_DWELL"
    Opts.Field.[Mode Max IWait] = "MODES.MAX_IWAIT"
    Opts.Field.[Mode Xfer Weight] = "MODES.W_DWELL"
    Opts.Field.[Mode XWait Weight] = "MODES.W_XFERW"   // Change xfer time weight from 2.58 to 2
/*
if (time_period = "peak") then do
    if (access_mode = "drive") then do
       Opts.Field.[Mode Xfer Time] = "MODES.XPEN_TIME"  // Keep peak drive access xfer penalty as 6
    end else do
       Opts.Field.[Mode Xfer Time] = "MODES.XFERPEN"     // Change xfer penalty time from 6 to 2
    end
end
if (time_period = "offpeak") then do
    Opts.Field.[Mode Xfer Time] = "MODES.XFER_PEN"    // Change xfer penalty time from 6 to 0
end
*/
    //if (time_period = "peak") then 
    if (time_period = "AM" or time_period = "PM") then
        Opts.Field.[Mode Impedance] = "MODES.P_SPD_FIEL"
    //else if (time_period = "offpeak") then
    else if (time_period = "MD" or time_period = "NT") then 
        Opts.Field.[Mode Impedance] = "MODES.OP_SPD_FIE"

    Opts.Field.[Mode Speed] = "MODES.SPEED"
    Opts.Field.[Mode Used] = "MODES.MODE_USED"
    Opts.Field.[Inter-Mode Xfer From] = "MODEXFER.FROM"
    Opts.Field.[Inter-Mode Xfer To] = "MODEXFER.TO"
    Opts.Field.[Inter-Mode Xfer Stop] = "MODEXFER.STOP"

    //if (time_period = "peak") then do
    if (time_period = "AM" or time_period = "PM") then do
        if (access_mode = "drive") then do
        Opts.Field.[Inter-Mode Xfer Time] = "MODEXFER.XFERPEN2"  // Keep peak drive access xfer penalty as 6
        end else do
        Opts.Field.[Inter-Mode Xfer Time] = "MODEXFER.XFERPEN1"  // Change xfer penalty time from 6 to 2
        end
    end
    //if (time_period = "offpeak") then do
    if (time_period = "MD" or time_period = "NT") then do
        Opts.Field.[Inter-Mode Xfer Time] = "MODEXFER.XFERPEN3"    // Change xfer penalty time from 6 to 0
    end


//--- this field disabled 
//    Opts.Field.[Inter-Mode Xfer Time] = "MODEXFER.COST"

    Opts.Field.[Inter-Mode Xfer Fare] = "MODEXFER.FARE"
    Opts.Global.[Global Layover Time] = 0.0

    Opts.Global.[Global Fare Value] = 3
    Opts.Global.[Global Xfer Fare] = 0
    Opts.Global.[Global Fare Weight] = 1.0
    Opts.Global.[Global Xfer Weight] = 1.0  //change from 0 to 1 as TC5 requires this when using modexfer table
    Opts.Global.[Global XWait Weight] = 2.0
    Opts.Global.[Global Dwell Time] = 0.0


    Opts.Global.[Global Dwell Weight] = 0
    Opts.Global.[Global Min IWait] = 0.01
    Opts.Global.[Global Min XWait] = 0.01
    Opts.Global.[Global Max WACC Path] = 10

// -- Max Access and Egress Times are Reset to 60 minutes
    Opts.Global.[Global Max Access] = 120  //Changed from 60 to 75 as walk times are pre-weighted for AT 4&5, JainM 03.26.07; increase to 120 minutes as all walk times are wtd, JainM, 09.05.08
    Opts.Global.[Global Max Egress] = 120  //Changed from 60 to 75 as walk times are pre-weighted for AT 4&5, JainM 03.26.07; increase to 120 minutes as all walk times are wtd, JainM, 09.05.08
    Opts.Global.[Global Max Imp] = 400    //Added to change from default 240 to 300 as walk times are pre-weighted for AT 4&5, JainM 03.26.07; increase to 400 minutes as all walk times are wtd, JainM, 09.05.08

    Opts.Global.[Global Max Transfer] = 75 //Changed from 10 to 20 as walk times are pre-weighted for AT 4&5, JainM 03.26.07; changed to 30, JainM Aug08; increase to 75 minutes as all walk times are wtd, JainM, 09.05.08
    Opts.Global.[Walk Weight] = 1.00 //change to 1.0 from 2.58 as all walk times are wtd, JainM, 09.05.08

//-- Path Threshold Boosted
    Opts.Global.[Path Threshold] = 0.25  // Changed from 0.75 to 0.25 to test new model 07.18.08, JainM

    Opts.Flag.[Use All Walk Path]   = "No"
    Opts.Flag.[Use Mode] = "Yes"
    Opts.Flag.[Use Mode Cost] = "Yes"
    Opts.Flag.[Combine By Mode] = "No"

//--- set the value of time as $12/hour
    Opts.Global.[Value of Time] = 0.2

// For Choice Set 2 paths, use restircted walk access/egress/transfer max times.

if (transit_mode = "premium2") then do
// -- Max Access and Egress Times are Reset to 60 minutes
    Opts.Global.[Global Max Access]   = 60
    Opts.Global.[Global Max Egress]   = 60
    Opts.Global.[Global Max Imp]      = 240
    Opts.Global.[Global Max Transfer] = 20
    if (access_mode = "walk") then Opts.Flag.[Use All Walk Path] = "Yes"
end

//-- STOP Access for buses disabled as it doesnt work with 4.7
  Opts.Flag.[Use Stop Access] = "Yes"  // Enable stop access coding for modes 5 and 6 for use with TransCAD5, JainM, 07.20.08

// -- setup for park & ride

    if ( access_mode = "drive" or access_mode = "dropoff") then do     
        if (access_mode = "drive" and time_period="AM" or time_period="PM") then Opts.Global.[Drive Time Weight] = 1.0
	    //if (access_mode = "drive" and time_period="peak") then Opts.Global.[Drive Time Weight] = 1.0  // JainM, March07, change drive access weight to 1.5 from 2.58 to make it consistent with Mode Choice
            // Set off-peak drive access / drop-off time weight to 2.58 (from 1.5) for better survey trip table assignment, JainM, 06.17.08
	    //if (access_mode = "drive" and time_period="offpeak") then Opts.Global.[Drive Time Weight] = 2.58  // JainM, March07, change drive access weight to 1.5 from 2.58 to make it consistent with Mode Choice
	    if (access_mode = "drive" and time_period="MD" or time_period="NT") then Opts.Global.[Drive Time Weight] = 2.58  
        if (access_mode = "dropoff") then Opts.Global.[Drive Time Weight] = 2.58 // JainM, March07, change drop-off access weight to 1.5 from 2.58 to make it consistent with Mode Choice

// JainM, March07 change maximum drive time from 45 to 60 for drive access paths
// JainM, 08.11.08, for premium paths, increase maximum to 150 minutes.
	    /*if (access_mode = "drive" and time_period="peak" and transit_mode = "bus") then Opts.Global.[Max Drive Time] = 75.0
	    if (access_mode = "drive" and time_period="peak" and transit_mode = "premium") then Opts.Global.[Max Drive Time] = 150.0
	    if (access_mode = "drive" and time_period="peak" and transit_mode = "premium2") then Opts.Global.[Max Drive Time] = 150.0
	    if (access_mode = "drive" and time_period="offpeak") then Opts.Global.[Max Drive Time] = 45.0
        */
        if (access_mode = "drive" and time_period= "AM" or time_period= "PM" and transit_mode = "bus") then Opts.Global.[Max Drive Time] = 75.0
	    if (access_mode = "drive" and time_period= "AM" or time_period= "PM" and transit_mode = "premium") then Opts.Global.[Max Drive Time] = 150.0
	    if (access_mode = "drive" and time_period= "AM" or time_period= "PM" and transit_mode = "premium2") then Opts.Global.[Max Drive Time] = 150.0
	    if (access_mode = "drive" and time_period= "MD" or time_period= "NT") then Opts.Global.[Max Drive Time] = 45.0
	    if (access_mode = "dropoff") then Opts.Global.[Max Drive Time] = 45.0
	    Opts.Flag.[Use Park and Ride] = "Yes"
        Opts.Flag.[Use P&R Walk Access] = "No"
        Opts.Flag.[Use Transit Access] = "No"
    end

	Return(Opts)

quit:

endMacro

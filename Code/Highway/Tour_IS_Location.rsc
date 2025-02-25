Macro "Tour_IS_Location" (Args)
//temp fix to peak TT skim (made in non-compressed).  Need to update later (copy skim matrix and save as non-compressed, both peak & free)
// 1/17, mk: changed from .dbf to .bin
// 8/8/17, all i've done so far is remove tfac for HBU
// 9/20/18, mk: cleaned up total PA and AP tour times
// 10/4/18, mk: changes per Bill's 10/2 email
// 8/26/19, mk: reset random number seed for each iteration
// 10/7/20, mk: removed tfac from time-to-last-stop vector(line 398), changed vector to float

	// on error goto badquit
	// LogFile = Args.[Log File].value
	// ReportFile = Args.[Report File].value
	// SetLogFileName(LogFile)
	// SetReportFileName(ReportFile)
	
	sedata_file = Args.[LandUse file]
	Dir = Args.[Run Directory]
	theyear = Args.[Run Year]
	msg = null
	datentime = GetDateandTime()
	AppendToLogFile(1, "Intermediate Stop Location: " + datentime)
	RunMacro("TCB Init")

	RunMacro("G30 File Close All") 

	DirArray  = Dir + "\\TG"
 	DirOutDC  = Dir + "\\TD"
 	
 	yr_str = Right(theyear,2)
	yr = s2i(yr_str)


  CreateProgressBar("Starting Tour Intermediate Stops Model", "TRUE")

	se_vw = OpenTable("SEFile", "FFB", {sedata_file,})
	access_peak = OpenTable("access_peak", "FFB", {DirArray + "\\ACCESS_PEAK.bin",})
	access_free = OpenTable("access_free", "FFB", {DirArray + "\\ACCESS_FREE.bin",})
	areatype = OpenTable("areatype", "DBASE", {Dir + "\\landuse\\SE" + theyear + "_DENSITY.dbf",})  
	distExtsta_vw = OpenTable("distextsta", "FFA", {Dir + "\\Ext\\Dist_to_Closest_ExtSta.asc",})
	distCBD_vw = OpenTable("distcbd", "FFA", {Dir + "\\LandUse\\Dist_to_CBD.asc",})

	se_vectors = GetDataVectors(se_vw+"|", {"TAZ", "RTL", "HWY", "STU_K8", "STU_HS", "TOTEMP", "SEQ", "POP"},{{"Sort Order", {{"TAZ","Ascending"}}}})
	taz = se_vectors[1]
	retail = se_vectors[2]
	hwy = se_vectors[3]
	stuk8 = se_vectors[4]
	stuhs = se_vectors[5]
	totemp = se_vectors[6]
	tazseq = se_vectors[7]
	pop = se_vectors[8]
	k12enr = stuk8 + stuhs
	popemp = pop + totemp
	retEmp = max(retail + hwy, 1)
	nonRet = max(totemp - retEmp, 1)
	tpop = max(pop, 1)
	temp = max(totemp, 1)

	accE15c_peak = GetDataVector(access_peak+"|", "EMPCMP15", {{"Sort Order",{{"TAZ","Ascending"}}}})
	accE15c_free = GetDataVector(access_free+"|", "EMPCMP15", {{"Sort Order",{{"TAZ","Ascending"}}}})
	accH15c_peak = GetDataVector(access_peak+"|", "HHCMP15", {{"Sort Order",{{"TAZ","Ascending"}}}})
	accH15c_free = GetDataVector(access_free+"|", "HHCMP15", {{"Sort Order",{{"TAZ","Ascending"}}}})

	atype = GetDataVector(areatype+"|", "AREATYPE", {{"Sort Order", {{"TAZ","Ascending"}}}}) 
	urban = if (atype <= 2) then 1 else 0

	dst2extsta = GetDataVector(distExtsta_vw+"|", "Len", {{"Sort Order", {{"From","Ascending"}}}}) 
	dst2cbd = GetDataVector(distCBD_vw+"|", "Len", {{"Sort Order", {{"From","Ascending"}}}}) 
	//to get rid of external stations:
	dim dist2extsta_ar[taz.length]
	dim dist2cbd_ar[taz.length]
	for i =  1 to taz.length do		//create a intracounty vector with all TAZs = 0 except for this TAZ (=1)
		dist2extsta_ar[i] = dst2extsta[i]
		dist2cbd_ar[i] = dst2cbd[i]
	end
	dist2extsta = a2v(dist2extsta_ar)
	dist2cbd = a2v(dist2cbd_ar)

/* Stop location model coefficients from ALOGIT estimation (as of Aug 2015).  Here are the models:
 1 HBW, stop 1, income 1-3 4 SCH, stop 1                   7 all non-work, stop 2     10 HBU, stop 1
 2 HBW, stop 1, income 4   5 HBS/HBO/ATW, stop 1, inc 1-3  8 all purposes, stop 3
 3 HBW, stop 2             6 HBS/HBO/ATW, stop 1, inc 4    9 all purposes, stops 4-7
*/
//model number		 1	  2	    3	      4		 5	 6	   7	     8	      9		10
	detour_c =   {-0.09805,-0.08676,-0.04077,  -0.0200,  -0.1500, -0.1300,  -0.0100,        0,        0, -1.0000}		//detour time
	shortDum_c = {  1.1920,  0.8392,  1.2830,   1.1370,   0.5490,  0.5221,   0.9098,   1.4720,   1.4270,  1.5000}	//short detour time dummy
	stopAT_c =   { -0.2450,       0,       0,        0,        0,       0,        0,        0,        0,       0}		//area type
	urban_c =    {	     0,       0,       0,   0.6999,   0.6805,  0.7392,   0.6989,   0.4874,   0.4711,  0.6999}		//urban dummy
	dCBD_c =     {	     0,	      0,       0,  0.02983,        0, 0.04428,        0,        0,        0, 0.02983}		//distance to CBD
	SAdummy_c =  {	     0,  1.2840,       0,   1.1290,        0,  0.9373,        0,        0,        0,     1.5}		//stop-destination time dummy
 	lastStop_c = {	     0,       0,-0.09997,        0,        0,       0,  -0.1500,  -0.1938,  -0.2163,       0}	//time from last stop
 	accemp_c =   {	     0,3.334E-6,       0,-4.736E-6,        0,       0,        0,        0,        0,-4.736E-6}	//accessibility to employment
 	acchh_c =    {	     0,       0,       0,        0, 3.731E-6,       0,        0,        0,        0,       0}	//accessibility to households
 	SAtime_c =   {	     0,       0,       0,        0,        0,       0, -0.13220,  -0.1284,  -0.1394,       0}		//stop-destination time
 	retEmp_c =   {	     1,       1,       1,        0,        1,       1,        1,        1,        1,       0}		//Size: retail emp
 	nonRet_c =   { 0.16268, 0.17464, 0.11919,        0,  0.08821, 0.12051,  0.04559,  0.02352,  0.06829,       0}		//Size: non-retail emp* (exponentiated values)
	tpop_c =     { 0.18637, 0.08425, 0.07251,  0.32078,  0.08383, 0.06522,  0.08433,  0.07646,  0.14016, 0.32078}		//Size: population* (exponentiated values)
 	k12enr_c =   { 0.53741, 0.34750, 0.30789,        0,  0.17222, 0.20577,  0.09283,  0.08734,  0.10445,       0}		//Size: K-12 enrollment* (exponentiated values)
	totemp_c =   { 	     0,       0,       0,        1,        0,       0,        0,        0,        0,       1}		//Size: total emp
	coeff = {detour_c,shortDum_c,stopAT_c,urban_c,dCBD_c,SAdummy_c,lastStop_c,accemp_c,acchh_c,SAtime_c,retEmp_c,nonRet_c,tpop_c, k12enr_c,totemp_c}

/* Max allowable detour time/PA time ratio by purpose.  See radius.xlsx. Set max ratio to 10 and minimum ratio to 0.10.
            tm  work non-work        
          = '0	9.05	6.98',
	    '5	6.53 	4.51',
	    '10	4.00	2.03',
	    '15	2.76	1.49',
	    '20	1.53	0.94',
	    '25	1.21	0.75',
	    '30	0.89	0.56',
	    '35	0.73	0.50',
	    '40	0.57	0.43',
	    '45	0.55	0.41',
	    '50	0.53	0.38',
	    '55	0.45	0.33',
	    '60	0.38	0.28',
	    '65	0.36	0.23',
	    '70	0.35	0.18',
	    '75	0.34	0.15',
	    '80	0.33	0.12',
	    '85	0.30	0.10',
	    '90	0.27	0.10',
	    '95	0.19	0.10',
	    '100 0.10	0.10'
*/        maxRatio = { { 9.05, 6.53, 4.00, 2.76, 1.53, 1.21, 0.89, 0.73, 0.57, 0.55, 0.53, 0.45, 0.38, 0.36, 0.35, 0.34, 0.33, 0.30, 0.27, 0.19, 0.10},
		       { 6.98, 4.51, 2.03, 1.49, 0.94, 0.75, 0.56, 0.50, 0.43, 0.41, 0.38, 0.33, 0.28, 0.23, 0.18, 0.15, 0.12, 0.1 , 0.1 , 0.1 , 0.1 } }


	PA_fields = {"SL_PA1", "SL_PA2", "SL_PA3", "SL_PA4", "SL_PA5", "SL_PA6", "SL_PA7"} 
	AP_fields = {"SL_AP1", "SL_AP2", "SL_AP3", "SL_AP4", "SL_AP5", "SL_AP6", "SL_AP7"} 

	lastStop_v = Vector(atype.length, "float", {{"Constant", 0}})

	purp = {"HBW", "SCH", "HBU", "HBS", "HBO", "ATW", "IX", "XIW", "XIN"}
	purpfile = {"dcHBW", "dcSCH", "dcHBU", "dcHBS", "dcHBO", "dcATW", "dcEXT", "dcXIW", "dcXIN"}

//Make a copy of the skim matrices that is memory based, otherwise will take much too long to run
	tt_mat = OpenMatrix(Dir + "\\Skims\\TThwy_Peak.mtx", "False")			
	tt_cur = CreateMatrixCurrency(tt_mat, "TotalTT", "Rows", "Columns", )
	new_mat = CopyMatrix(tt_cur, {{"File Name", Dir + "\\Skims\\peak_hwyskim.mtx"}, {"Label", "Peak_TT_Skim"}, {"File Based", "No"}, {"Compression", 0}})
	tt_mat = null
	tt_mat = OpenMatrix(Dir + "\\Skims\\TThwy_Free.mtx", "False")			
	tt_cur = CreateMatrixCurrency(tt_mat, "TotalTT", "Rows", "Columns", )
	new_mat = CopyMatrix(tt_cur, {{"File Name", Dir + "\\Skims\\offpk_hwyskim.mtx"}, {"Label", "Offpeak_TT_Skim"}, {"File Based", "No"}, {"Compression", 0}})
	tt_mat = null

	//create a sequential vector to add to cumulative probability vector so that when it's sorted, the correct (first) TAZ is chosen
	aide_de_sort_vec = Vector(taz.length, "float", {{"Sequence", 0.001, 0.001}})

//Start loop on purposes.  HBW & XIW use the peak travel time matrix.  
RandSeed = 111
	for p = 1 to 9 do					//9

  UpdateProgressBar("Intermediate Stops Location Model (" + purp[p] + ")", 10) 
		current_file = OpenTable(purpfile[p], "FFB", {DirOutDC + "\\" + purpfile[p] + ".bin",})
	 	strct = GetTableStructure(purpfile[p])		//Add new IS field to tour records file 			
		for j = 1 to strct.length do
	 		strct[j] = strct[j] + {strct[j][1]}
	 	end
		strct = strct + {{"SL_PA1", "Integer", 5,,,,,,,,,}}
		strct = strct + {{"SL_PA2", "Integer", 5,,,,,,,,,}}
		strct = strct + {{"SL_PA3", "Integer", 5,,,,,,,,,}}
		strct = strct + {{"SL_PA4", "Integer", 5,,,,,,,,,}}
		strct = strct + {{"SL_PA5", "Integer", 5,,,,,,,,,}}
		strct = strct + {{"SL_PA6", "Integer", 5,,,,,,,,,}}
		strct = strct + {{"SL_PA7", "Integer", 5,,,,,,,,,}}
		strct = strct + {{"SL_AP1", "Integer", 5,,,,,,,,,}}
		strct = strct + {{"SL_AP2", "Integer", 5,,,,,,,,,}}
		strct = strct + {{"SL_AP3", "Integer", 5,,,,,,,,,}}
		strct = strct + {{"SL_AP4", "Integer", 5,,,,,,,,,}}
		strct = strct + {{"SL_AP5", "Integer", 5,,,,,,,,,}}
		strct = strct + {{"SL_AP6", "Integer", 5,,,,,,,,,}}
		strct = strct + {{"SL_AP7", "Integer", 5,,,,,,,,,}}
		strct = strct + {{"TourTT_PA", "Real", 8,2,,,,,,,,}}
		strct = strct + {{"TourTT_AP", "Real", 8,2,,,,,,,,}}
		ModifyTable(purpfile[p], strct)

		if (p = 1 or p = 8) then do
			tt_mat = OpenMatrix(Dir + "\\Skims\\peak_hwyskim.mtx", "False")			//open as memory-based
			matrix_indices = GetMatrixIndexNames(tt_mat)	
			for i = 1 to matrix_indices[1].length do
				if matrix_indices[1][i] = "Internals" then goto gotindex
			end
			int_index = CreateMatrixIndex("Internals", tt_mat, "Both", se_vw+"|", "TAZ", "TAZ" )	//just internal zones
			gotindex:
			tt_extstacur = CreateMatrixCurrency(tt_mat, "TotalTT", "Rows", "Columns", )
			tt_extcolcur = CreateMatrixCurrency(tt_mat, "TotalTT", "Internals", "Columns", )
			tt_extrowcur = CreateMatrixCurrency(tt_mat, "TotalTT", "Rows", "Internals", )
			accEmp = accE15c_peak
			accHH = accH15c_peak
			maxRmax = 9.05
		end
		else do
			tt_mat = OpenMatrix(Dir + "\\Skims\\offpk_hwyskim.mtx", "False")			//open as memory-based
			matrix_indices = GetMatrixIndexNames(tt_mat)	
			for i = 1 to matrix_indices[1].length do
				if matrix_indices[1][i] = "Internals" then goto gotindex2
			end
			int_index = CreateMatrixIndex("Internals", tt_mat, "Both", se_vw+"|", "TAZ", "TAZ" )	//just internal zones
			gotindex2:
			tt_extstacur = CreateMatrixCurrency(tt_mat, "TotalTT", "Rows", "Columns", )
			tt_extcolcur = CreateMatrixCurrency(tt_mat, "TotalTT", "Internals", "Columns", )
			tt_extrowcur = CreateMatrixCurrency(tt_mat, "TotalTT", "Rows", "Internals", )
			accEmp = accE15c_free
			accHH = accH15c_free
			maxRmax = 6.98
		end

		//initially set total PA and AP times to the OD/DO time.  This will be overwritten is there are stops.
		all_v = GetDataVectors(purpfile[p]+"|", {"OD_Time", "DO_Time"},{{"Sort Order", {{"ID","Ascending"}}}}) 
		SetDataVectors(purpfile[p]+"|", {{"TourTT_PA", all_v[1]}, {"TourTT_AP", all_v[2]}},{{"Sort Order", {{"ID","Ascending"}}}}) 

		//pull data for tours with stops
		qry = "Select * where (IS_PA + IS_AP) > 0"
		SetView(purpfile[p])
		havestops = SelectByQuery("havestops", "Several", qry)
		SortSet("havestops", "ID")

	      if p < 8 then do
		set_v = GetDataVectors(purpfile[p]+"|havestops", {"ID", "ORIG_TAZ", "ORIG_SEQ", "DEST_TAZ", "DEST_SEQ", "IS_PA", "IS_AP", "OD_Time", "DO_Time", "TourTT_PA", "TourTT_AP", "INCOME"},{{"Sort Order", {{"ORIG_TAZ","Ascending"},{"DEST_TAZ","Ascending"}}}}) 
		idset = set_v[1]
		incset = set_v[12]
	      end
	      else do
		set_v = GetDataVectors(purpfile[p]+"|havestops", {"ID", "ORIG_TAZ", "ORIG_SEQ", "DEST_TAZ", "DEST_SEQ", "IS_PA", "IS_AP", "OD_Time", "DO_Time", "TourTT_PA", "TourTT_AP"},{{"Sort Order", {{"ORIG_TAZ","Ascending"},{"DEST_TAZ","Ascending"}}}})
		idset = set_v[1]
		incset = Vector(idset.length, "short", {{"Constant", 4}})
	      end
		tourorigtaz = set_v[2]
		tourorigtazseq = set_v[3]
		tourdesttaz = set_v[4]
		tourdesttazseq = set_v[5]
		ispaset = set_v[6]
		isapset = set_v[7]
		odtime_v = set_v[8]
		dotime_v = set_v[9]
		paTT_v = set_v[10]
		apTT_v = set_v[11]

		dim PA_fill_ar[7]
		dim AP_fill_ar[7]
		for i = 1 to 7 do
			PA_fill_ar[i] = Vector(idset.length, "float", )
			AP_fill_ar[i] = Vector(idset.length, "float", )
		end

		lastorigtaz = 0
		lastdesttaz = 0

SetRandomSeed(RandSeed)
	   for n = 1 to idset.length do		//idset.length
		thisorigtaz = tourorigtaz[n]
		thisdesttaz = tourdesttaz[n]
		if (thisorigtaz = lastorigtaz and thisdesttaz = lastdesttaz) then do
			goto skipDetourStep							//if origin and dest zones are the same from previous record, don't need to redo calcs
		end
		ODtime = odtime_v[n] //Get tour network travel time (use HOV).  Peak for HBW/XIW, off-peak for others.
		DOtime = dotime_v[n] //Get tour network travel time (use HOV).  Peak for HBW/XIW, off-peak for others.
		if ODtime >= 100 then do
			maxR = 0.10
		end
		else if ODtime = 0 then do
			maxR = maxRmax
		end
		else do
			Rval = Floor(ODtime / 5) + 1
			if (p = 1 or p = 8) then do
				maxR = maxRatio[1][Rval] + ((maxRatio[1][Rval] - maxRatio[1][Rval+1]) * (ODtime - (5 * Rval)) / 5)
			end
			else do
				maxR = maxRatio[2][Rval] + ((maxRatio[2][Rval] - maxRatio[2][Rval+1]) * (ODtime - (5 * Rval)) / 5)
			end
		end
		MaxDet = ODtime * maxR
	//start PA direction loop, selecting only those tours with intermediate stops
		skipDetourStep:
		if ispaset[n] > 0 then do
			tfac = 1
			if p = 7 then tfac = 10	//Validation adjustment for IX (10 for PA direction, 15 for AP direction).

			if (thisorigtaz = lastorigtaz and thisdesttaz = lastdesttaz) then do
				goto skipGetVar
			end
			Stime_v = GetMatrixVector(tt_extcolcur, {{"Column", thisdesttaz}})
			Stime_v.rowbased = True
			PStime_v = GetMatrixVector(tt_extrowcur, {{"Row", thisorigtaz}})
			detour_v =  max((Stime_v + PStime_v - ODtime), 0)
			restartloop:
			Uzerofac_v = if (detour_v > MaxDet) then 0 else 1	//this zeros out U if zone is outside detour range	
			// If NO candidate stop zones are found, boost the max detour time by 5 min and repeat the search.  
			//If we've pushed the max detour above 20 min and still haven't found a stop zone, quit (and then go check the input data).
			sumCandZones = VectorStatistic(Uzerofac_v, "Sum",)
			if sumCandZones = 0 then do
				if MaxDet <= 20 then do
					MaxDet = MaxDet + 5 
					goto restartloop
				end
				else if MaxDet > 20 then do
					goto badquit
				end
			end
						
			shortDum_v = if (detour_v <= 10) then 1 else 0
			SAdummy_v = if (Stime_v <= 5) then 1 else 0
			skipGetVar:
			for s = 1 to ispaset[n] do	//ispaset[n]
				/* Stop location model coefficients from ALOGIT estimation (as of Aug 2015).  Here are the models:
				 1 HBW, stop 1, income 1-3 4 SCH, stop 1                   7 all non-work, stop 2     10 HBU, stop 1
				 2 HBW, stop 1, income 4   5 HBS/HBO/ATW, stop 1, inc 1-3  8 all purposes, stop 3
				 3 HBW, stop 2             6 HBS/HBO/ATW, stop 1, inc 4    9 all purposes, stops 4-7
					purp = {"HBW", "SCH", "HBU", "HBS", "HBO", "ATW", "IX", "XIW", "XIN"}
				*/
				m = if (s = 3) then 8 else if (s >3) then 9 else if (s > 1 and (p = 1 or p = 8)) then 3 else if ((p = 1 or p = 8) and incset[n] = 4) then 2 
					else if (p = 1 or p = 8) then 1 else if (s = 2) then 7 else if (p = 2) then 4 else if (p = 3) then 10 else if (incset[n] = 4) then 6 else 5
				if (s > 1) then do
					lastStop_v = GetMatrixVector(tt_extrowcur, {{"Row", stop1}})	
				end
				if (s > 4) then do
					goto skipprobcalc
				end
				U = Uzerofac_v * (coeff[1][m]*detour_v*tfac + coeff[2][m]*shortDum_v + coeff[3][m]*atype + coeff[4][m]*urban + coeff[5][m]*dist2cbd + coeff[6][m]*SAdummy_v +
					 coeff[7][m]*lastStop_v*tfac + coeff[8][m]*accEmp + coeff[9][m]*accHH + coeff[10][m]*Stime_v + log(coeff[11][m]*retEmp + coeff[12][m]*nonRet + 
					 coeff[13][m]*tpop + coeff[14][m]*k12enr + coeff[15][m]*temp) )
				eU = if (U = 0) then 0 else exp(U)
				sumeU = VectorStatistic(eU, "Sum",)
				prob = eU / sumeU
				vecs = {prob, taz}
				cumprob1 = CumulativeVector(vecs[1])		//cumulative sum of probabilities, not sorted
				cumprob1[U.length] = 1
				skipprobcalc:
				redo_randval:
				rand_val = RandomNumber()
				if (rand_val = 0 or rand_val = 1)  then do
					goto redo_randval
				end
				addnum = max(r2i(1/rand_val), 500)
				cumprob = cumprob1 / rand_val
				cumprob = if cumprob < 1.0 then addnum else cumprob
				cumprob = cumprob + aide_de_sort_vec
				sorted_vecs = SortVectors({cumprob, vecs[2]})			
				choice = sorted_vecs[2][1]				
				stop1 = choice
				PA_fill_ar[s][n] = stop1
				lastStop_v = Vector(atype.length, "float", {{"Constant", 0.0}})
				if (s = 1) then do
					paTT_v[n] = 0.0	//reset PA time to zero is there are stops
					paTT_v[n] = GetMatrixValue(tt_extstacur, i2s(thisorigtaz), i2s(choice))
				end
				else do
					paTT_v[n] = paTT_v[n] + GetMatrixValue(tt_extstacur, i2s(prevchoice), i2s(choice))
				end
				if (s = ispaset[n]) then do
					lastlegtime = GetMatrixValue(tt_extstacur, i2s(choice), i2s(thisdesttaz))
					paTT_v[n] = paTT_v[n] + GetMatrixValue(tt_extstacur, i2s(choice), i2s(thisdesttaz))
				end
				prevchoice = choice			
			end
			lastorigtaz = thisorigtaz
			lastdesttaz = thisdesttaz
		end
		
//now do AP direction loop, selecting only those tours with intermediate stops
		if isapset[n] > 0 then do
			tfac = 1
			if p = 7 then tfac = 15	//Validation adjustment for IX (10 for PA direction, 15 for AP direction).

			if (thisorigtaz = lastorigtaz and thisdesttaz = lastdesttaz) then do
				goto skipGetVarAP
			end
			Stime_v = GetMatrixVector(tt_extcolcur, {{"Column", thisorigtaz}}) 	//since in AP dir Orig is actually the destination
			Stime_v.rowbased = True
			AStime_v = GetMatrixVector(tt_extrowcur, {{"Row", thisdesttaz}}) 
			detour_v =  max((Stime_v + AStime_v - DOtime), 0)
			Uzerofac_v = if (detour_v > MaxDet) then 0 else 1	//this zeros out U if zone is outside MSdist or detour range	
			shortDum_v = if (detour_v <= 10) then 1 else 0
			detour_v = detour_v
			restartloopAP:
			Uzerofac_v = if (detour_v > MaxDet) then 0 else 1	//this zeros out U if zone is outside detour range	
			// If NO candidate stop zones are found, boost the max detour time by 5 min and repeat the search.  
			//If we've pushed the max detour above 20 min and still haven't found a stop zone, quit (and then go check the input data).
			sumCandZones = VectorStatistic(Uzerofac_v, "Sum",)
			if sumCandZones = 0 then do
				if MaxDet <= 20 then do
					MaxDet = MaxDet + 5 
					goto restartloopAP
				end
				else if MaxDet > 20 then do
					goto badquit
				end
			end
			SPdummy_v = if (Stime_v <= 5) then 1 else 0

			skipGetVarAP:
			for s = 1 to isapset[n] do	//ispaset[n]
				m = if (s = 3) then 8 else if (s >3) then 9 else if (s > 1 and (p = 1 or p = 8)) then 3 else if ((p = 1 or p = 8) and incset[n] = 4) then 2 
					else if (p = 1 or p = 8) then 1 else if (s = 2) then 7 else if (p = 2) then 4 else if (p = 3) then 10 else if (incset[n] = 4) then 6 else 5
				if (s > 1) then do
					lastStop_v = GetMatrixVector(tt_extrowcur, {{"Row", stop1}}) 
//					lastStop_v = lastStop_v * tfac	//removed, since uses tfac in utility equation		
				end
				if (s > 4) then do
					goto skipprobcalc_ap
				end
				U = Uzerofac_v * (coeff[1][m]*detour_v*tfac + coeff[2][m]*shortDum_v + coeff[3][m]*atype + coeff[4][m]*urban + coeff[5][m]*dist2cbd + coeff[6][m]*SPdummy_v +
					 coeff[7][m]*lastStop_v*tfac + coeff[8][m]*accEmp + coeff[9][m]*accHH + coeff[10][m]*Stime_v + log(coeff[11][m]*retEmp + coeff[12][m]*nonRet  + 
					 coeff[13][m]*tpop + coeff[14][m]*k12enr + coeff[15][m]*temp) )
				eU = if (U = 0) then 0 else exp(U)
				sumeU = VectorStatistic(eU, "Sum",)
				prob = eU / sumeU
				vecs = {prob, taz}
				cumprob1 = CumulativeVector(vecs[1])		//cumulative sum of probabilities, not sorted
				cumprob1[U.length] = 1
				skipprobcalc_ap:
				redo_randval_ap:
				rand_val = RandomNumber()
				if (rand_val = 0 or rand_val = 1)  then do
					goto redo_randval_ap
				end
				addnum = max(r2i(1/rand_val), 500)
				cumprob = cumprob1 / rand_val
				cumprob = if cumprob < 1.0 then addnum else cumprob
				cumprob = cumprob + aide_de_sort_vec
				sorted_vecs = SortVectors({cumprob, vecs[2]})			
				choice = sorted_vecs[2][1]				
				stop1 = choice
				AP_fill_ar[s][n] = stop1
				lastStop_v = Vector(atype.length, "Short", {{"Constant", 0.0}})
				if (s = 1) then do
					apTT_v[n] = 0.0	//reset AP time to zero is there are stops
					apTT_v[n] = GetMatrixValue(tt_extstacur, i2s(thisdesttaz), i2s(choice))
				end
				else do
					apTT_v[n] = apTT_v[n] + GetMatrixValue(tt_extstacur, i2s(prevchoice), i2s(choice))
				end
				if (s = isapset[n]) then do
					apTT_v[n] = apTT_v[n] + GetMatrixValue(tt_extstacur, i2s(choice), i2s(thisorigtaz))
				end
				prevchoice = choice			
			end
			lastorigtaz = thisorigtaz
			lastdesttaz = thisdesttaz
	
		end
	    end
	    for s = 1 to PA_fill_ar.length do
//		if p < 8 then do
		 	SetDataVector(purpfile[p]+"|havestops", PA_fields[s], PA_fill_ar[s],{{"Sort Order", {{"ORIG_TAZ","Ascending"},{"DEST_TAZ","Ascending"}}}}) 
		 	SetDataVector(purpfile[p]+"|havestops", AP_fields[s], AP_fill_ar[s],{{"Sort Order", {{"ORIG_TAZ","Ascending"},{"DEST_TAZ","Ascending"}}}}) 
			SetDataVector(purpfile[p]+"|havestops", "TourTT_PA", paTT_v,{{"Sort Order", {{"ORIG_TAZ","Ascending"},{"DEST_TAZ","Ascending"}}}}) 
	    		SetDataVector(purpfile[p]+"|havestops", "TourTT_AP", apTT_v,{{"Sort Order", {{"ORIG_TAZ","Ascending"},{"DEST_TAZ","Ascending"}}}}) 
/*		 end
		 else do
		 	SetDataVector(purpfile[p]+"|havestops", PA_fields[s], PA_fill_ar[s],{{"Sort Order", {{"ORIG_TAZ","Ascending"},{"DEST_TAZ","Ascending"}}}})
		 	SetDataVector(purpfile[p]+"|havestops", AP_fields[s], AP_fill_ar[s],{{"Sort Order", {{"ORIG_TAZ","Ascending"},{"DEST_TAZ","Ascending"}}}})
	    		SetDataVector(purpfile[p]+"|havestops", "TourTT_PA", paTT_v,{{"Sort Order", {{"ORIG_TAZ","Ascending"},{"DEST_TAZ","Ascending"}}}}) 
	    		SetDataVector(purpfile[p]+"|havestops", "TourTT_AP", apTT_v,{{"Sort Order", {{"ORIG_TAZ","Ascending"},{"DEST_TAZ","Ascending"}}}}) 
	         end
*/	    end
	    CloseView(current_file)	

	    SetMatrixIndex(tt_mat, "Rows", "Columns")
	    DeleteMatrixIndex(tt_mat, "Internals")
	    tt_mat = null
	    tt_extstacur= null
	    tt_extcolcur= null
	    tt_extrowcur= null

RandSeed = r2i((RandSeed / 3) + 47)

	end
    DestroyProgressBar()
    RunMacro("G30 File Close All")
    goto quit

	badquit:
		on error, notfound default
		RunMacro("TCB Closing", ret_value, "TRUE" )
		Throw("Intermediate Stop Location: Error somewhere")
		AppendToLogFile(1, "Intermediate Stop Location: Error somewhere")
		datentime = GetDateandTime()
		AppendToLogFile(1, "Intermediate Stop Location " + datentime)

       	return({0, msg})

    quit:
		on error, notfound default
   		datentime = GetDateandTime()
		AppendToLogFile(1, "Exit Intermediate Stop Location " + datentime)
    	return({1, msg})

endmacro

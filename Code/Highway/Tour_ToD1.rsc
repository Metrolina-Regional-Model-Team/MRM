Macro "Tour_ToD1" (Args)

// 1/17, mk: changed from .dbf to .bin
// 9/20/18, mk: fixed accessibility error
// 9/24/18, mk: fixed a few coefficients
// 10/23/18, mk: changed HBW & SCH coefficients per Bill's 10/23/18 email
// 2/25/19, mk: changed             per Bill's 2/25/19 email
// 8/26/19, mk: reset random number seed for each iteration

	// on error goto badquit
	// LogFile = Args.[Log File].value
	// ReportFile = Args.[Report File].value
	// SetLogFileName(LogFile)
	// SetReportFileName(ReportFile)
	
	sedata_file = Args.[LandUse file]
	Dir = Args.[Run Directory]
	theyear = Args.[Run Year]
	//	net_file = Args.[Hwy Name].value
	msg = null
	datentime = GetDateandTime()
	AppendToLogFile(1, "Tour TOD1: " + datentime)
	RunMacro("TCB Init")

	RunMacro("G30 File Close All") 

	DirArray  = Dir + "\\TG"
 	DirOutDC  = Dir + "\\TD"
 	
 	yr_str = Right(theyear,2)
	yr = s2i(yr_str)

  	CreateProgressBar("Starting TOD1", "TRUE")

	autofree = OpenMatrix(Dir + "\\Skims\\TThwy_free.mtx", "False")			//open as memory-based
	OpenMatrixFileHandle(autofree, "Write")
	autofreecur = CreateMatrixCurrency(autofree, "TotalTT", "Rows", "Columns", )
	autopeak = OpenMatrix(Dir + "\\Skims\\TThwy_peak.mtx", "False")			//open as memory-based
	OpenMatrixFileHandle(autopeak, "Write")
	autopeakcur = CreateMatrixCurrency(autopeak, "TotalTT", "Rows", "Columns", )

	areatype = OpenTable("areatype", "FFB", {Dir + "\\landuse\\SE" + theyear + "_DENSITY.bin",})  
//	distExtsta_vw = OpenTable("distextsta", "FFA", {Dir + "\\Ext\\Dist_to_Closest_ExtSta.asc",})
	distCBD_vw = OpenTable("distcbd", "FFA", {Dir + "\\LandUse\\Dist_to_CBD.asc",})
	se_vw = OpenTable("SEFile", "FFB", {sedata_file,})

	atype = GetDataVector(areatype+"|", "AREATYPE", {{"Sort Order", {{"TAZ","Ascending"}}}}) 
	se_vectors = GetDataVectors(se_vw+"|", {"TAZ", "RTL", "HWY", "AREA", "TOTEMP", "SEQ", "POP"},{{"Sort Order", {{"TAZ","Ascending"}}}})
	taz = se_vectors[1]
	rtl = se_vectors[2]
	hwy = se_vectors[3]
	area_sqmi = se_vectors[4]
	totemp = se_vectors[5]
	seq = se_vectors[6]
	pop = se_vectors[7]
	rtlemp = rtl + hwy
	area = area_sqmi * 640		//convert area from square miles to acres.

	dst2cbd = GetDataVector(distCBD_vw+"|", "Len", {{"Sort Order", {{"From","Ascending"}}}}) 
	//to get rid of external stations:
	dim dist2cbd_ar[taz.length]
	for i =  1 to taz.length do		//create a intracounty vector with all TAZs = 0 except for this TAZ (=1)
		dist2cbd_ar[i] = dst2cbd[i]
	end
	dist2cbd = a2v(dist2cbd_ar)

	access_free = OpenTable("access_free", "FFB", {DirArray + "\\ACCESS_FREE.bin",})
	accE15c_free = GetDataVector(access_free+"|", "EMPCMP15", {{"Sort Order",{{"TAZ","Ascending"}}}})
	accH15c_free = GetDataVector(access_free+"|", "HHCMP15", {{"Sort Order",{{"TAZ","Ascending"}}}})

	vws = GetViewNames()
	for i = 1 to vws.length do
		CloseView(vws[i])
	end

	purp = {"HBW", "SCH", "HBU", "HBS", "HBO", "ATW", "IX", "XIW", "XIN"}
	purpfile = {"dcHBW", "dcSCH", "dcHBU", "dcHBS", "dcHBO", "dcATW", "dcEXT", "dcXIW", "dcXIN"}

	//PA factors		HBW	  SCH	   HBU	    HBS	     HBO	ATW	IX	XIW	XIN
	bias_c =     { 1.0000,  3.5000,  0.9000, -1.2900, -0.1400, -4.8000, -1.4500,  1.0000, -0.1400}		//bias constant
	inc1dum_c =  {-0.3487,  0.0000,  0.0000,  0.0000,  0.0000,  0.0000,  0.0000, -0.3487,  0.0000}		//income 1 dummy
	inc4dum_c =  { 0.6100,  0.0000,  0.0000,  0.0000,  0.1482,  0.0000,  0.0000,  0.6100,  0.1482}		//income 4 dummy
	lc1dum_c =   { 0.0000,  0.0000,  0.0000, -0.4369,  0.0000,  0.0000,  0.0000,  0.0000,  0.0000}		//LC 1 dummy
	lc2dum_c =   { 0.2482,  0.0000,  0.0000,  0.3766,  0.5276,  0.0000,  0.0000,  0.2482,  0.5276}		//LC 2 dummy
	wrkrs_c =    {-0.1196,  0.0000, -0.4295,  0.1282,  0.0000,  0.0000,  0.0000, -0.1196,  0.0000}		//workers
 	wrkr0dum_c = { 0.0000,  0.0000,  0.0000,  0.0000, -0.1095,  0.0000,  0.0000,  0.0000, -0.1095}		//worker 0 dummy
 	size5dum_c = { 0.0000, -0.2844,  0.0000,  0.0000,  0.0000,  0.0000,  0.0000,  0.0000,  0.0000}		//size 5 dummy
 	trvltime_c = {-0.0119, -0.03058, 0.0000,  0.0000,  0.0000, 0.07064,  0.0000, -0.0119,  0.0000}		//travel time
 	//totstops_c = { 0.1067,  0.0000,  0.0000,  0.0000, -0.08573, 0.4848,  0.0000,  0.1067, -0.08573}		//total stops
 	//PAstops_c =  { 0.0000, -0.3803,  1.9760,  0.0000,  0.0000,  0.0000,  0.0000,  0.0000,  0.0000}		//PA stops
	prodzurb_c = { 0.0000,  0.0000,  0.0000,  0.0000, -0.1844,  0.0000,  0.0000,  0.0000, -0.1844}		//prod zone urban
 	prodzrur_c = { 0.0000,  0.0000,  0.0000,  0.2912,  0.0000,  0.0000,  0.0000,  0.0000,  0.0000}		//prod zone rural
	prodzatp_c = { 0.0000,  0.0000,  0.0000,  0.0000,  0.0000,  0.0000,  0.3444,  0.0000,  0.0000}		//prod zone atype
	prodzcbd_c = { 0.0000,  0.0000,  0.0000,  0.0000,  0.0000,  0.07846, 0.0000,  0.0000,  0.0000}		//prod zone dist CBD
 	aempden_c =  {0.00093,  0.0000,  0.0547,  0.0000,  0.0000,  0.0000,  0.0000,  0.00093, 0.0000}		//attr empl density
	aretlpct_c = { 0.0000,  0.0000,  0.0000,  0.0000,  0.0000,  0.0000,  0.0000,  0.0000,  0.0000}		//attr % retail emp
	shoptour_c = { 0.0000,  0.0000,  0.0000,  0.0000,  0.0000,  0.0000, -0.5838,  0.0000,  0.0000}		//shop tour
	attraccH_c = {-0.001813,-0.01649,0.0000,  0.007277,0.0000,  0.0000,  0.0000,-0.001813, 0.0000}		//attr access to HH (000)
	prodaccE_c = { 0.0000,  0.0000,  0.0000,  0.0000,  0.0000,  0.01448, 0.0000,  0.0000,  0.0000}		//prod access to emp (000)
	//pacoeff = {bias_c,inc1dum_c,inc4dum_c,lc1dum_c,lc2dum_c,wrkrs_c,wrkr0dum_c,size5dum_c,trvltime_c,totstops_c,PAstops_c,prodzurb_c, prodzrur_c,prodzatp_c,prodzcbd_c,aempden_c,aretlpct_c,shoptour_c,attraccH_c,prodaccE_c}
	pacoeff = {bias_c,inc1dum_c,inc4dum_c,lc1dum_c,lc2dum_c,wrkrs_c,wrkr0dum_c,size5dum_c,trvltime_c,,,prodzurb_c, prodzrur_c,prodzatp_c,prodzcbd_c,aempden_c,aretlpct_c,shoptour_c,attraccH_c,prodaccE_c}
	//Note: bias constants have been adjusted in validation.

	//AP factors		HBW 	    SCH	     HBU    HBS		HBO  	  ATW	    IX	     XIW	XIN
	apbias_c =     {-0.2500,  -1.7000, -0.8500, -5.5000,  -2.0200,  -8.5000, -0.2000, -0.2500,   -2.0870}		//bias constant
	appaprd_c =    { 0.3488,   0.9821, -0.6133,  2.0400,   0.9648,   2.7930,  0.0000,  0.3488,    0.9648}		//PA period
	apinc4dum_c =  { 0.3288,   0.4100,  0.0000,  0.0000,   0.0000,   0.0000,  0.0000,  0.3288,    0.0000}		//income 4 dummy
	aplc2dum_c =   { 0.0000,   0.0000,  0.0000,  0.0000,   0.2769,   0.0000,  0.0000,  0.0000,    0.2769}		//LC 2 dummy
	apsize_c =     { 0.0000,  -0.1340,  0.0000,  0.0000,   0.0000,   0.0000,  0.0000,  0.0000,    0.0000}		//size
	apwrkrs_c =    {-0.2031,   0.0000,  0.2871,  0.0000,   0.0000,   0.0000,  0.0000, -0.2031,    0.0000}		//workers
 	apnonwrkrs_c = { 0.0000,   0.0000,  0.0000,  0.0000,   0.08202,  0.0000,  0.0000,  0.0000,   0.08202}		//non-workers
 	aptrvltime_c = { 0.02571,  0.02676,-0.04278,-0.01512,  0.0000,   0.0000,  0.0000,  0.02571,   0.0000}		//travel time
 	aptimedif_c =  {-0.04171,  0.0000,  0.0000,  0.0000,  -0.04538,  0.0000,  0.0000, -0.04171, -0.04538}		//peak time diff
 	//aptotstops_c = { 0.0000,   0.0000,  0.0000,  0.0000,  -0.1104,  -0.6643,  0.0000,  0.0000,   -0.1104}		//total stops
 	//apAPstops_c =  {-0.2064,   0.0000,  0.0000,  0.0000,   0.0000,   0.0000,  0.0000, -0.2064,    0.0000}		//AP stops
	aplongdist_c = { 0.0000,   0.0000,  0.0000,  0.0000,   1.4410,   0.0000,  0.0000,  0.0000,    1.4410}		//long trip dummy (>45)
 	approdzurb_c = { 0.0000,   0.0000,  0.0000,  0.0000,   0.0000,   0.0000, -1.8860,  0.0000,    0.0000}		//prod zone urban
	approdzrur_c = { 0.0000,   0.0000,  0.0000, -0.2588,  -0.3655,   0.0000,  0.0000,  0.0000,   -0.3655}		//prod zone rural
	approddens_c = { 0.0000,   0.0000,  0.0000,  0.0000,   0.0000,   0.0000,  0.0000,  0.0000,    0.0000}		//prod zone density
 	approdzcbd_c = { 0.0000,  -0.02017, 0.02974, 0.0000,   0.0000,   0.0000,  0.0000,  0.0000,    0.0000}		//prod zone dist CBD
	apaempden_c =  { 0.0000,   0.0000,  0.0000,  0.0000,   0.0000,   0.0000,  0.0000,  0.0000,    0.0000}		//attr emp density
	aparetlpct_c = {-0.6715,   0.0000,  0.0000,  0.0000,   0.0000,   0.0000,  0.0000, -0.6715,    0.0000}		//attr % retail emp
	apattrzcbd_c = { 0.0000,   0.0000,  0.0000,  0.0000,   0.0000,   0.05729, 0.0000,  0.0000,    0.0000}		//attr zone dist CBD
	apshoptour_c = { 0.0000,   0.0000,  0.0000,  0.0000,   0.0000,   0.0000, -0.5487,  0.0000,    0.0000}		//shop tour
	apattraccH_c = { 0.0000, -0.01189,  0.0000, 0.05532,-0.001521,   0.0287,  0.0000,  0.0000, -0.001521}		//attr access to HH (000)
	//apcoeff = {apbias_c,appaprd_c,apinc4dum_c,aplc2dum_c,apsize_c,apwrkrs_c,apnonwrkrs_c,aptrvltime_c,aptimedif_c,aptotstops_c,apAPstops_c,aplongdist_c,approdzurb_c,approdzrur_c,approddens_c,approdzcbd_c,apaempden_c,aparetlpct_c,apattrzcbd_c,apshoptour_c,apattraccH_c}
	apcoeff = {apbias_c,appaprd_c,apinc4dum_c,aplc2dum_c,apsize_c,apwrkrs_c,apnonwrkrs_c,aptrvltime_c,aptimedif_c,,,aplongdist_c,approdzurb_c,approdzrur_c,approddens_c,approdzcbd_c,apaempden_c,aparetlpct_c,apattrzcbd_c,apshoptour_c,apattraccH_c}

/*Special validation adjustment.  Applied if first half-tour is in off-peak.
;    purp  mod
r = ' 1,   -0.05',
    ' 2,    0.0 ',
    ' 3,    0.20',
    ' 4,   -0.15',
    ' 5,   -0.10',
    ' 6,    0.20',
    ' 7,   -0.20'
*/
	special_val_adj = {-0.05, 0.0, 0.20, -0.15, -0.10, 0.20, -0.20}
	RandSeed = 1134
	for p = 1 to 9 do					//9
  		UpdateProgressBar("TOD1 (" + purp[p] + ")", 10) 
		current_file = OpenTable(purpfile[p], "FFB", {DirOutDC + "\\" + purpfile[p] + ".bin",})
	 	strct = GetTableStructure(purpfile[p])		//Add new IS field to tour records file 			
		for j = 1 to strct.length do
	 		strct[j] = strct[j] + {strct[j][1]}
	 	end
		strct = strct + {{"PAper", "Integer", 2,,,,,,,,,}}
		strct = strct + {{"APper", "Integer", 2,,,,,,,,,}}
		ModifyTable(purpfile[p], strct)

	    vecOpts = null
		vecOpts.[Sort Order] = {{"ORIG_SEQ","Ascending"}, {"DEST_SEQ","Ascending"}}
		vecOpts.[Return Options Array] = 1
		if p < 8 then do
			set_v = GetDataVectors(purpfile[p]+"|", {"ID", "ORIG_TAZ", "ORIG_SEQ", "DEST_TAZ", "DEST_SEQ", "PURP", "INCOME", "LIFE", "WRKRS", "SIZE"}, vecOpts)  			
			idset = set_v.ID
			purpset = set_v.PURP
			incset = set_v.INCOME
			lifeset = set_v.LIFE
			wrkrsset = set_v.WRKRS
			sizeset = set_v.SIZE
		end
	    else do
			set_v = GetDataVectors(purpfile[p]+"|", {"ID", "ORIG_TAZ", "ORIG_SEQ", "DEST_TAZ", "DEST_SEQ"}, vecOpts)  			
			//We know nothing about the non-resident travellers, so use the most common values from the Metrolina survey.
			idset = set_v.ID
			incset = Vector(idset.length, "short", {{"Constant", 4}})
			lifeset = Vector(idset.length, "short", {{"Constant", 3}})
			wrkrsset = Vector(idset.length, "short", {{"Constant", 1}})
			sizeset = Vector(idset.length, "short", {{"Constant", 2}})
	    end
		tourorigtaz = set_v.ORIG_TAZ
		tourorigtazseq = set_v.ORIG_SEQ
		tourdesttaz = set_v.DEST_TAZ
		tourdesttazseq = set_v.DEST_SEQ

		inc1dum = if (incset = 1) then 1 else 0
		inc4dum = if (incset = 4) then 1 else 0
		lc1dum = if (lifeset = 1) then 1 else 0
		lc2dum = if (lifeset = 2) then 1 else 0
		wkr0dum = if (wrkrsset = 0) then 1 else 0
		siz5dum = if (sizeset = 5) then 1 else 0
		nonwkrs = max(sizeset - wrkrsset, 0)

		PAtime = Vector(idset.length, "float", )
		APtime_pk = Vector(idset.length, "float", )
		APtime_offpk = Vector(idset.length, "float", )
		prodAT = Vector(idset.length, "short", )
		pDistCBD = Vector(idset.length, "float", )
		aDistCBD = Vector(idset.length, "float", )
		pPopDen = Vector(idset.length, "float", )
		aEmpDen = Vector(idset.length, "float", )
		aPctRet = Vector(idset.length, "float", )
		accHH = Vector(idset.length, "float", )
		accEm = Vector(idset.length, "float", )
		rand_val = Vector(idset.length, "float", )	//for PA direction
		rand_val2 = Vector(idset.length, "float", )	//for AP direction

		SetRandomSeed(RandSeed)
		pbar = CreateObject("G30 Progress Bar", "Processing...", true, idset.length)

		
		for n = 1 to idset.length do
			pbar.Step()
			if (tourorigtaz[n] = lastorigtaz and tourdesttaz[n] = lastdesttaz) then do
				PAtime[n] = PAtime[n-1]
				APtime_pk[n] = APtime_pk[n-1]
				APtime_offpk[n] = APtime_offpk[n-1]
				prodAT[n] = prodAT[n-1]
				pDistCBD[n] = pDistCBD[n-1]
				aDistCBD[n] = aDistCBD[n-1]
				pPopDen[n] = pPopDen[n-1]
				aEmpDen[n] = aEmpDen[n-1]
				aPctRet[n] = aPctRet[n-1]
				accHH[n] = accHH[n-1]
				accEm[n] = accEm[n-1]				
			end
			else do
				PAtime[n] = if (p = 1) then GetMatrixValue(autopeakcur, i2s(tourorigtaz[n]), i2s(tourdesttaz[n])) else GetMatrixValue(autofreecur, i2s(tourorigtaz[n]), i2s(tourdesttaz[n])) 
				APtime_pk[n] = GetMatrixValue(autopeakcur, i2s(tourdesttaz[n]), i2s(tourorigtaz[n]))
				APtime_offpk[n] = GetMatrixValue(autofreecur, i2s(tourdesttaz[n]), i2s(tourorigtaz[n]))
				prodAT[n] = atype[tourorigtazseq[n]]
				pDistCBD[n] = dist2cbd[tourorigtazseq[n]]
				aDistCBD[n] = dist2cbd[tourdesttazseq[n]]
				//Note that in calibration, AREA was in ACRES.  "area" variable is converted from sq. miles to acres in upper section of macro
				pPopDen[n] = if (area[tourorigtazseq[n]] > 0) then (pop[tourorigtazseq[n]] / area[tourorigtazseq[n]]) else 0
				aEmpDen[n] = if (area[tourdesttazseq[n]] > 0) then (totemp[tourdesttazseq[n]] / area[tourdesttazseq[n]]) else 0
				aPctRet[n] = if (totemp[tourdesttazseq[n]] > 0) then (rtlemp[tourdesttazseq[n]] / totemp[tourdesttazseq[n]]) else 0
				accHH[n] = accH15c_free[tourdesttazseq[n]] / 1000
				accEm[n] = accE15c_free[tourorigtazseq[n]] / 1000
			end
			lastorigtaz = tourorigtaz[n]
			lastdesttaz = tourdesttaz[n]
			rand_val[n] = RandomNumber()
			rand_val2[n] = RandomNumber()
		end
		pbar.Destroy()
		if (p = 1) then do
			APtime = APtime_pk	//if purpose is HBW (XIW is considered off-peak)
		end
		else do
			APtime = APtime_offpk
		end
		longdum = if (APtime > 45) then 1 else 0
		pkTmDiff = APtime_pk - APtime_offpk
		prodUrb = if (prodAT < 3) then 1 else 0
		prodRur = if (prodAT > 3) then 1 else 0
		//External stations have an area type of zero.  For X/I origins, set origin area type to Rural
		prodUrb = if (tourorigtaz > 12000) then 0 else prodUrb
		prodRur = if (tourorigtaz > 12000) then 1 else prodRur
		prodAT = if (tourorigtaz > 12000) then 5 else prodAT
		//Shop tour dummy applies only to I/X tours
		shopdum = Vector(idset.length, "short", {{"Constant", 0}})
		if p = 7 then do
			shopdum = if (purpset = "HBS") then 1 else 0
		end
		//Apply PA model
		/*
		U = pacoeff[1][p] + pacoeff[2][p]*inc1dum + pacoeff[3][p]*inc4dum + pacoeff[4][p]*lc1dum + pacoeff[5][p]*lc2dum + pacoeff[6][p]*wrkrsset + pacoeff[7][p]*wkr0dum + 
			 pacoeff[8][p]*siz5dum + pacoeff[9][p]*PAtime + pacoeff[10][p]*totstops + pacoeff[11][p]*ispaset + pacoeff[12][p]*prodUrb + pacoeff[13][p]*prodRur + 
			 pacoeff[14][p]*prodAT + pacoeff[15][p]*pDistCBD + pacoeff[16][p]*aEmpDen + pacoeff[17][p]*aPctRet + pacoeff[18][p]*shopdum + pacoeff[19][p]*accHH + pacoeff[20][p]*accEm
		*/
		
		// Remove IS stop variables from utility equation since these variables will only be computed later
		U = pacoeff[1][p] + pacoeff[2][p]*inc1dum + pacoeff[3][p]*inc4dum + pacoeff[4][p]*lc1dum + pacoeff[5][p]*lc2dum + pacoeff[6][p]*wrkrsset + pacoeff[7][p]*wkr0dum + 
			 pacoeff[8][p]*siz5dum + pacoeff[9][p]*PAtime + pacoeff[12][p]*prodUrb + pacoeff[13][p]*prodRur + 
			 pacoeff[14][p]*prodAT + pacoeff[15][p]*pDistCBD + pacoeff[16][p]*aEmpDen + pacoeff[17][p]*aPctRet + pacoeff[18][p]*shopdum + pacoeff[19][p]*accHH + pacoeff[20][p]*accEm
		eU = if (U > -20) then exp(U) else 0
		
		//Calculate peak probability
		probPk = eU / (1 + eU)
		PAper = if (probPk > rand_val) then 2 else 1	// 1 = off-peak; 2 = peak

		//Next apply AP model
		//Special validation adjustment.  If the first half-tour leaves in the off-peak, force more of the tours to return in a certain period.  
		valid = Vector(idset.length, "float", {{"Constant", 0.0}})
		if p < 8 then do
			valid = if (PAper = 1) then special_val_adj[p] else 0.0
		end
		/*
		U = apcoeff[1][p] + apcoeff[2][p]*PAper + apcoeff[3][p]*inc4dum + apcoeff[4][p]*lc1dum + apcoeff[5][p]*sizeset + apcoeff[6][p]*wrkrsset + apcoeff[7][p]*nonwkrs + apcoeff[8][p]*APtime + 
		      apcoeff[9][p]*pkTmDiff + apcoeff[10][p]*totstops + apcoeff[11][p]*isapset + apcoeff[12][p]*longdum + apcoeff[13][p]*prodUrb + apcoeff[14][p]*prodRur + apcoeff[15][p]*pPopDen + 
		      apcoeff[16][p]*pDistCBD + apcoeff[17][p]*aEmpDen + apcoeff[18][p]*aPctRet + apcoeff[19][p]*aDistCBD + apcoeff[20][p]*shopdum + apcoeff[21][p]*accHH + valid
		*/	
		
		// Remove IS stop variables from utility equation since these variables will only be computed later
		U = apcoeff[1][p] + apcoeff[2][p]*PAper + apcoeff[3][p]*inc4dum + apcoeff[4][p]*lc1dum + apcoeff[5][p]*sizeset + apcoeff[6][p]*wrkrsset + apcoeff[7][p]*nonwkrs + apcoeff[8][p]*APtime + 
		      apcoeff[9][p]*pkTmDiff + apcoeff[12][p]*longdum + apcoeff[13][p]*prodUrb + apcoeff[14][p]*prodRur + apcoeff[15][p]*pPopDen + 
		      apcoeff[16][p]*pDistCBD + apcoeff[17][p]*aEmpDen + apcoeff[18][p]*aPctRet + apcoeff[19][p]*aDistCBD + apcoeff[20][p]*shopdum + apcoeff[21][p]*accHH + valid
		eU = if (U > -20) then exp(U) else 0
		
		//Calculate peak probability
		probPk = eU / (1 + eU)
		APper = if (probPk > rand_val2) then 2 else 1	// 1 = off-peak; 2 = peak

		SetDataVector(purpfile[p]+"|", "PAper", PAper,{{"Sort Order", {{"ORIG_SEQ","Ascending"}, {"DEST_SEQ","Ascending"}}}})
		SetDataVector(purpfile[p]+"|", "APper", APper,{{"Sort Order", {{"ORIG_SEQ","Ascending"}, {"DEST_SEQ","Ascending"}}}})
		RandSeed = r2i((RandSeed / 6) + 7)

	end
	CloseMatrixFileHandle(autofree)
	CloseMatrixFileHandle(autopeak)
	CloseView(current_file)	
    DestroyProgressBar()
    RunMacro("G30 File Close All")
    goto quit

	badquit:
		on error, notfound default
		RunMacro("TCB Closing", ret_value, "TRUE" )
		Throw("Tour TOD1: Error somewhere")
		AppendToLogFile(1, "Tour TOD1: Error somewhere")
		datentime = GetDateandTime()
		AppendToLogFile(1, "Tour TOD1 " + datentime)

       	return({0, msg})

    quit:
		on error, notfound default
   		datentime = GetDateandTime()
		AppendToLogFile(1, "Exit Tour TOD1 " + datentime)
    	return({1, msg})
endmacro
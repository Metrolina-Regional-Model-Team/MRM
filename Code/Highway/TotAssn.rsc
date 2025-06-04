macro "TotAssn" (Args, AssnSubDir, assntype)
//	Changed from dbf to .bin output to avoid dbf error writing fields after MI join.  This version still writes [tid] (temp id) 5 times.
//   JWM  4/25/17
// 6/21/19, mk: There are now three distinct networks: uses AM peak network for totassn
// 7/15/19, mk: Added TotVolAB/BA fields, and moved some fields around
// 10/21/19: Added STCNTY field

// Need to rewrite so each piece is done separately .  Current error is in/after midday fields - AB_TIME.. and AB_VOC to MAX_VOC wrote fine.  
//  The VMT fields got part of an extended field name.  Try rewriting to do each of 4 separately, then join  
//  TC adds to joinviews
//  This version copies the bin to a dbf after saving so subsequent programs can read it, JWM

// revised August 2013 using mobile6.rsc as form - thanks Jhun @ KHA
// assntype - "base", "HOT2+", "HOT3+"

// peak hour factor = factor used in calculating V/C ratios from peak assignments
// peak assignment 3 hr AM, 3 hr PM (6 hrs), - assume peak hour is 40% of total in each  3.0 
//   peak 0.33, shoulders 0.33, 0.33;  pkhrfac = 0.333 
//   peak 0.4,  shoulders 0.3, 0.3;    pkhrfac = 0.400
//   peak 0.5,  shoulders 0.25, 0.25;  pkhrfac = 0.500
//   counts - 2000 - am peak = 41%.  pm peak 38%

// minspfac - changed to MaxTTFac - multiple of TTfree - free speed travel set as maximum (reciprocal of minimum speed, & we use TT, not speed)
// McLelland 

//	goto skiparound

	Dir = Args.[Run Directory]
	//hwy_file = Args.[AM Peak Hwy Name]
	hwy_file = Args.[Hwy Name]
	{, , netview, } = SplitPath(hwy_file)
	MaxTTFac = Args.MaxTravTimeFactor
	pkhrfac = Args.[Peak Hour Factor]
	
	totassnOK = 1
	
	info = GetDBInfo(Dir + "\\"+netview+".dbd")
	scope = info[1]

	// Create a map using this scope
	CreateMap(netview, {{"Scope", scope},{"Auto Project", "True"}})

	file = Dir + "\\"+netview+".dbd"
	layers = GetDBLayers(file)
	addlayer(netview, "Node", file, layers[1])
	addlayer(netview, netview, file, layers[2])
	SetLayerVisibility("Node", "True")
	SetIcon("Node|", "Font Character", "Caliper Cartographic|2", 36)
	SetLayerVisibility(netview, "True")
	solid = LineStyle({{{1, -1, 0}}})
	SetLineStyle(netview+"|", solid)
	SetLineColor(netview+"|", ColorRGB(32000, 32000, 32000))
	SetLineWidth(netview+"|", 0)

	setview(netview)

	cntflag		= CreateExpression(netview, "CNTFLAG", "if CALIB > 0 then 1 else 0",)
	MTKflag		= CreateExpression(netview, "MTKFLAG", "if MTK > 0 then 1 else 0",)
	HTKflag		= CreateExpression(netview, "HTKFLAG", "if HTK > 0 then 1 else 0",)
	fun2		= CreateExpression(netview, "Fun2", "if FUNCL = 1 or FUNCL = 2 or FUNCL = 9 then 1 else if funcl < 6 then 3 else if funcl < 10 then 4 else if (funcl > 20 and funcl < 30 or funcl = 82 or funcl = 83) then 2 else 0",)  
	cntyaf	= CreateExpression(netview, "CntyAF", "COUNTY * 10000 + AREATP * 100 + Fun2",)
	vmtlen	= CreateExpression(netview, "VMTLen", "if FUNCL = 90 then nz(LENGTH) * 2 else nz(LENGTH)",)
	stcnty	= CreateExpression(netview, "STCNTY", "r2i(State * 1000 + County)",)

// drop transit links
	selectset = "select * where FUNCL < 30 or FUNCL = 82 or FUNCL = 83 or FUNCL = 90"
	nlnks = SelectbyQuery("HwyLinks", "Several", selectset,)

	net_bin = AssnSubDir + "\\Tempnet.bin"
	tjoin_bin = AssnSubDir + "\\Tempjoinnet.bin"

	netfields = {"ID", "LENGTH", "DIR", "FUNCL", "FEDFUNC_AQ", "CO_FEDFUNC", "Strname", "A_CrossStr", "B_CrossStr", "AREATP", "CALIB", "MTK", "HTK", "Scrln", 
				"COUNTY", "STCNTY", "Cap1hrAB", "Cap1hrBA", "TTfreeAB", "TTfreeBA", "TTPkAssnAB", "TTPkAssnBA", "lanesAB", "lanesBA", "CNTFLAG", "Fun2", "CntyAF", "VMTLen"}

	ExportView(netview+"|HwyLinks", "FFB", net_bin, netfields ,)

	// temporary fields for joining to assn output tables
	tid 		= CreateExpression(netview, "tid", "ID",)
	tdir		= CreateExpression(netview, "tdir", "DIR",)
	tfun 	= CreateExpression(netview,  "tfun", "FUNCL",)
	ttfrab 	= CreateExpression(netview, "ttfrab", "nz(TTFreeAB)",)
	ttfrba 	= CreateExpression(netview, "ttfrba", "nz(TTFreeBA)",)
	tcapab	= CreateExpression(netview, "tcapab", "nz(Cap1HrAB)",)
	tcapba	= CreateExpression(netview, "tcapba", "nz(Cap1HrBA)",)

	ExportView(netview+"|HwyLinks", "FFB", tjoin_bin, {"tid","tdir","tfun","ttfrab", "ttfrba", "tcapab","tcapba", "VMTLen"},{"Indexed Fields", {"tid"}}) 
	closemap()
	
	if assntype = "base" then do
		am_bin = AssnSubDir + "\\Assn_AMPeak.bin"
		pm_bin = AssnSubDir + "\\Assn_PMPeak.bin"
		mi_bin = AssnSubDir + "\\Assn_Midday.bin"
		nt_bin = AssnSubDir + "\\Assn_Night.bin"
		out_bin = AssnSubDir + "\\Tot_Assn.bin"
	end
	else do
		am_bin = AssnSubDir + "\\Assn_AMPeakhot.bin"
		pm_bin = AssnSubDir + "\\Assn_PMPeakhot.bin"
		mi_bin = AssnSubDir + "\\Assn_Middayhot.bin"
		nt_bin = AssnSubDir + "\\Assn_Nighthot.bin"
		out_bin = AssnSubDir + "\\Tot_Assn_HOT.bin"
		out_dbf = AssnSubDir + "\\Tot_Assn_HOT.dbf"
	end


	tempam_bin = AssnSubDir + "\\TempAM.bin"
	temppm_bin = AssnSubDir + "\\TempPM.bin"
	tempmi_bin = AssnSubDir + "\\TempMI.bin"	
	tempnt_bin = AssnSubDir + "\\TempNT.bin"


// open temp network join and tod - join

	temp_bin = {tempam_bin, temppm_bin, tempmi_bin, tempnt_bin}
	tod = {"AM", "PM", "MI", "NT"}
	tod_bin = {am_bin, pm_bin, mi_bin, nt_bin}

   for i = 1 to tod.length do // loop on 4 TODs

	tjoin_in = OpenTable("Net", "FFB", {tjoin_bin,})
	tod_in  = OpenTable(tod[i], "FFB", {tod_bin[i],})
    
	jointod = JoinViews("jointod", "Net.tid",tod[i] + ".ID1",)
    
	CloseView(tod_in)
    
// Create TOD fields

	volab		= CreateExpression(jointod, "Vol" + tod[i] + "AB", "nz(AB_Flow)",) 
	volba		= CreateExpression(jointod, "Vol" + tod[i] + "BA", "nz(BA_Flow)",) 
	totvol		= CreateExpression(jointod, "Vol" + tod[i], "r2i(nz(AB_Flow) + nz(BA_Flow))",) 
	minrawab	= CreateExpression(jointod, "MinRaw" + tod[i] + "AB", "if tfun = 90 then nz(AB_Time)* 2 else nz(AB_Time)",)
	minrawba	= CreateExpression(jointod, "MinRaw" + tod[i] + "BA", "if tfun = 90 then nz(BA_Time)* 2 else nz(BA_Time)",)
	minab		= CreateExpression(jointod, "min" + tod[i] + "AB", "min(nz(MinRaw" + tod[i] + "AB), ttfrab * " + i2s(MaxTTFac) + ")",)
	minba		= CreateExpression(jointod, "min" + tod[i] + "BA", "min(nz(MinRaw" + tod[i] + "BA), ttfrba * " + i2s(MaxTTFac) + ")",)
	vmtab		= CreateExpression(jointod, "VMT" + tod[i] + "AB", "Vol" + tod[i] + "AB * VMTlen",)
	vmtba		= CreateExpression(jointod, "VMT" + tod[i] + "BA", "Vol" + tod[i] + "BA * VMTlen",)
	vhtab		= CreateExpression(jointod, "VHT" + tod[i] + "AB", "Vol" + tod[i] + "AB * (min" + tod[i] + "AB / 60.)",)
	vhtba		= CreateExpression(jointod, "VHT" + tod[i] + "BA", "Vol" + tod[i] + "BA * (min" + tod[i] + "BA / 60.)",)
	vmt_tod		= CreateExpression(jointod, "VMT_" + tod[i], "VMT" + tod[i] + "AB + VMT" + tod[i] + "BA",)
	vht_tod		= CreateExpression(jointod, "VHT_" + tod[i], "VHT" + tod[i] + "AB + VHT" + tod[i] + "BA",)

	fresovab	= CreateExpression(jointod, "Fresov" + tod[i] + "AB", "nz(AB_Flow_SOV)",)
	fresovba	= CreateExpression(jointod, "Fresov" + tod[i] + "BA", "nz(BA_Flow_SOV)",)
	frepl2ab	= CreateExpression(jointod, "Frepl2" + tod[i] + "AB", "nz(AB_Flow_Pool2)",)
	frepl2ba	= CreateExpression(jointod, "Frepl2" + tod[i] + "BA", "nz(BA_Flow_Pool2)",)
	pl3ab		= CreateExpression(jointod, "Frepl3" + tod[i] + "AB", "nz(AB_Flow_Pool3)",)
	pl3ba		= CreateExpression(jointod, "Frepl3" + tod[i] + "BA", "nz(BA_Flow_Pool3)",)
	frecomab	= CreateExpression(jointod, "Frecom" + tod[i] + "AB", "nz(AB_Flow_COM)",)
	frecomba	= CreateExpression(jointod, "Frecom" + tod[i] + "BA", "nz(BA_Flow_COM)",)
	mtkab		= CreateExpression(jointod, "mtk" + tod[i] + "AB", "nz(AB_Flow_MTK)",)
	mtkba		= CreateExpression(jointod, "mtk" + tod[i] + "BA", "nz(BA_Flow_MTK)",)
	htkab		= CreateExpression(jointod, "htk" + tod[i] + "AB", "nz(AB_Flow_HTK)",)
	htkba		= CreateExpression(jointod, "htk" + tod[i] + "BA", "nz(BA_Flow_HTK)",)

// v/c - 2 classes - (2 peaks) - each gets 1/4 capacity lane miles (1/2 of oneway) 
	vcab		= CreateExpression(jointod, "vc" + tod[i] + "AB", "if tdir <> -1 then (nz(AB_Flow) * " + r2s(pkhrfac) + ") / tcapab else 0",)
	vcba		= CreateExpression(jointod, "vc" + tod[i] + "BA", "if tdir <> 1 then (nz(BA_Flow) * " + r2s(pkhrfac) + ") / tcapba else 0",)

//	pool3tod	= CreateExpression(jointod, "pool3" + tod[i], "Frepl3" + tod[i] + "AB + Frepl3" + tod[i] + "BA",)
	mtktod		= CreateExpression(jointod, "mtk" + tod[i], "mtk" + tod[i] + "AB + mtk" + tod[i] + "BA",)
	htktod		= CreateExpression(jointod, "htk" + tod[i], "htk" + tod[i] + "AB + htk" + tod[i] + "BA",)


//hot tables
	if assntype = "base" then do
		sov		= CreateExpression(jointod, "sov" + tod[i], "Fresov" + tod[i] + "AB + Fresov" + tod[i] + "BA",)
		com		= CreateExpression(jointod, "com" + tod[i], "Frecom" + tod[i] + "AB + Frecom" + tod[i] + "BA",)
		pool2		= CreateExpression(jointod, "pool2" + tod[i], "Frepl2" + tod[i] + "AB + Frepl2" + tod[i] + "BA",)
		pool3		= CreateExpression(jointod, "pool3" + tod[i], "Frepl3" + tod[i] + "AB + Frepl3" + tod[i] + "BA",)
		MiddleField = {"Fresov" + tod[i] + "AB", "Fresov" + tod[i] + "BA", "Frepl2" + tod[i] + "AB", "Frepl2" + tod[i] + "BA", 
			   "Frepl3" + tod[i] + "AB", "Frepl3" + tod[i] + "BA", "Frecom" + tod[i] + "AB", "Frecom" + tod[i] + "BA", "mtk" + tod[i] + "AB", "mtk" + tod[i] + "BA", "htk" + tod[i] + "AB", "htk" + tod[i] + "BA", 
			   "sov" + tod[i], "pool2" + tod[i], "pool3" + tod[i], "com" + tod[i], "mtk" + tod[i], "htk" + tod[i]}

	end
/*	else if assntype = "HOT2+" then do
		hotsovab	= CreateExpression(jointod, "HOTsov" + tod[i] + "AB", "nz(AB_Flow_HOTSOV)",)
		hotsovba	= CreateExpression(jointod, "HOTsov" + tod[i] + "BA", "nz(BA_Flow_HOTSOV)",)
		hotcomab	= CreateExpression(jointod, "HOTcom" + tod[i] + "AB", "nz(AB_Flow_HOTCOM)",)
		hotcomba	= CreateExpression(jointod, "HOTcom" + tod[i] + "BA", "nz(BA_Flow_HOTCOM)",)
		sov		= CreateExpression(jointod, "sov" + tod[i], "Fresov" + tod[i] + "AB + Fresov" + tod[i] + "BA + HOTsov" + tod[i] + "AB + HOTsov" + tod[i] + "BA",)
		com		= CreateExpression(jointod, "com" + tod[i], "Frecom" + tod[i] + "AB + Frecom" + tod[i] + "BA + HOTcom" + tod[i] + "AB + HOTcom" + tod[i] + "BA",)
		pool2		= CreateExpression(jointod, "pool2" + tod[i], "Frepl2" + tod[i] + "AB + Frepl2" + tod[i] + "BA",)
		HOTField	= {"HOTsov" + tod[i] + "AB", "HOTsov" + tod[i] + "BA", "HOTcom" + tod[i] + "AB", "HOTcom" + tod[i] + "BA"}
	end
*/	else if assntype = "HOT3+" then do
		hotsovab	= CreateExpression(jointod, "HOTsov" + tod[i] + "AB", "nz(AB_Flow_HOTSOV)",)
		hotsovba	= CreateExpression(jointod, "HOTsov" + tod[i] + "BA", "nz(BA_Flow_HOTSOV)",)
		hotpl2ab	= CreateExpression(jointod, "HOTpl2" + tod[i] + "AB", "nz(AB_Flow_HOTPOOL2)",)
		hotpl2ba	= CreateExpression(jointod, "HOTpl2" + tod[i] + "BA", "nz(BA_Flow_HOTPOOL2)",)
		hotpl3ab	= CreateExpression(jointod, "HOTpl3" + tod[i] + "AB", "nz(AB_Flow_HOTPOOL3)",)
		hotpl3ba	= CreateExpression(jointod, "HOTpl3" + tod[i] + "BA", "nz(BA_Flow_HOTPOOL3)",)
		hotcomab	= CreateExpression(jointod, "HOTcom" + tod[i] + "AB", "nz(AB_Flow_HOTCOM)",)
		hotcomba	= CreateExpression(jointod, "HOTcom" + tod[i] + "BA", "nz(BA_Flow_HOTCOM)",)
		sov		    = CreateExpression(jointod, "sov" + tod[i], "Fresov" + tod[i] + "AB + Fresov" + tod[i] + "BA + HOTsov" + tod[i] + "AB + HOTsov" + tod[i] + "BA",)
		com		    = CreateExpression(jointod, "com" + tod[i], "Frecom" + tod[i] + "AB + Frecom" + tod[i] + "BA + HOTcom" + tod[i] + "AB + HOTcom" + tod[i] + "BA",)
		pool2		= CreateExpression(jointod, "pool2" + tod[i], "Frepl2" + tod[i] + "AB + Frepl2" + tod[i] + "BA + HOTpl2" + tod[i] + "AB + HOTpl2" + tod[i] + "BA",)
		pool3		= CreateExpression(jointod, "pool3" + tod[i], "Frepl3" + tod[i] + "AB + Frepl3" + tod[i] + "BA + HOTpl3" + tod[i] + "AB + HOTpl3" + tod[i] + "BA",)
		MiddleField	= {"Fresov" + tod[i] + "AB", "Fresov" + tod[i] + "BA", "HOTsov" + tod[i] + "AB", "HOTsov" + tod[i] + "BA", 
					"Frepl2" + tod[i] + "AB", "Frepl2" + tod[i] + "BA", "HOTpl2" + tod[i] + "AB", "HOTpl2" + tod[i] + "BA", 
					"Frepl3" + tod[i] + "AB", "Frepl3" + tod[i] + "BA", "HOTpl3" + tod[i] + "AB", "HOTpl3" + tod[i] + "BA", 
					"Frecom" + tod[i] + "AB", "Frecom" + tod[i] + "BA", "HOTcom" + tod[i] + "AB", "HOTcom" + tod[i] + "BA",
					"mtk" + tod[i] + "AB", "mtk" + tod[i] + "BA", "htk" + tod[i] + "AB", "htk" + tod[i] + "BA",
					"sov" + tod[i], "pool2" + tod[i], "pool3" + tod[i], "com" + tod[i], "mtk" + tod[i], "htk" + tod[i]}
	end

	BeginField = {"tid", "MinRaw" + tod[i] + "AB", "MinRaw" + tod[i] + "BA", "min" + tod[i] + "AB", "min" + tod[i] + "BA"}

	EndField = {"Vol" + tod[i] + "AB", "Vol" + tod[i] + "BA", "Vol" + tod[i], "VMT" + tod[i] + "AB", "VMT" + tod[i] + "BA", 
			   "VHT" + tod[i] + "AB", "VHT" + tod[i] + "BA", "VMT_" + tod[i], "VHT_" + tod[i], "vc" + tod[i] + "AB", "vc" + tod[i] + "BA"}

	Fields = BeginField + MiddleField + EndField
	ExportView(jointod+"|", "FFB", temp_bin[i], Fields,)

	CloseView(jointod)

   end	// end tod loop
	
	//Reopen the four tod temp files and join
	net2_in = OpenTable("Net2", "FFB", {net_bin})
  	am2_in  = OpenTable("AM2", "FFB", {tempam_bin,})
  	pm2_in  = OpenTable("PM2", "FFB", {temppm_bin,})
  	mi2_in  = OpenTable("MI2", "FFB", {tempmi_bin,})
  	nt2_in  = OpenTable("NT2", "FFB", {tempnt_bin,})

	join1 = JoinViews("join1", "Net2.ID","AM2.tid",)
	join2 = JoinViews("join2", "join1.ID", "PM2.tid",)
	join3 = JoinViews("join3", "join2.ID", "MI2.tid",)
	join4 = JoinViews("join4", "join3.ID", "NT2.tid",)

	CloseView(net2_in)
	CloseView(am2_in)
	CloseView(pm2_in)
	CloseView(mi2_in)
	CloseView(nt2_in)
	CloseView(join1)
	CloseView(join2)
	CloseView(join3)  

//Daily fields
	totsov		= CreateExpression(join4, "TOT_SOV", "sovAM + sovPM + sovMI + sovNT",)
	totpl2		= CreateExpression(join4, "TOT_POOL2", "pool2AM + pool2PM + pool2MI + pool2NT",)
	totpl3		= CreateExpression(join4, "TOT_POOL3", "pool3AM + pool3PM + pool3MI + pool3NT",)
	totcom		= CreateExpression(join4, "TOT_COM", "comAM + comPM + comMI + comNT",)
	totmtk		= CreateExpression(join4, "TOT_MTK", "mtkAM + mtkPM + mtkMI + mtkNT",)
	tothtk		= CreateExpression(join4, "TOT_HTK", "htkAM + htkPM + htkMI + htkNT",)
	totvolAB	= CreateExpression(join4, "TotVolAB", "VolAMAB + VolPMAB + VolMIAB + VolNTAB",)
	totvolBA	= CreateExpression(join4, "TotVolBA", "VolAMBA + VolPMBA + VolMIBA + VolNTBA",)
	tot_vol		= CreateExpression(join4, "Tot_Vol", "VolAMAB + VolAMBA + VolPMAB + VolPMBA + VolMIAB + VolMIBA + VolNTAB + VolNTBA",)
	volpost		= CreateExpression(join4, "VOL_POST", "r2i(round(TOT_VOL / 100, 0) * 100)",)

	tot_vmt		= CreateExpression(join4, "TOT_VMT", "VMT_AM + VMT_MI + VMT_PM + VMT_NT",)	//move in front of vol flds
	tot_vht		= CreateExpression(join4, "TOT_VHT", "VHT_AM + VHT_MI + VHT_PM + VHT_NT",)


	cntmcsq		= CreateExpression(join4, "CNTMCSQ", "if CALIB > 0 then pow(TOT_VOL - CALIB,2) else 0",)
//	commcsq		= CreateExpression(join4, "COMMCSQ", "if COM08 > 0 then pow(TOT_COM - COM08,2) else 0",)
	mtkmcsq		= CreateExpression(join4, "MTKMCSQ", "if MTK > 0 then pow(TOT_MTK - MTK,2) else 0",) 
	htkmcsq		= CreateExpression(join4, "HTKMCSQ", "if HTK > 0 then pow(TOT_HTK - HTK,2) else 0",)

	if typeassn = "base" then do
		OutFields = 
		{"ID", "LENGTH", "DIR", "FUNCL", "FEDFUNC_AQ", "CO_FEDFUNC", "Strname", "A_CrossStr", "B_CrossStr", 
	  	 "AREATP", "CALIB", "MTK", "HTK", "Scrln", "COUNTY", "STCNTY", "Cap1hrAB", "Cap1hrBA", 
	 	 "TTfreeAB", "TTfreeBA", "TTPkAssnAB", "TTPkAssnBA", "lanesAB", "lanesBA",
	 	 "Fun2", "CntyAF", "VMTLen", 
	 	 "TotVolAB", "TotVolBA", "VOL_POST", "Tot_Vol",  
	 	 "VMT_AM", "VMT_MI", "VMT_PM", "VMT_NT", "VHT_AM", "VHT_MI", "VHT_PM", "VHT_NT",  
 	 	 "TOT_SOV", "sovAM", "sovMI", "sovPM", "sovNT", 
 	 	 "TOT_POOL2", "pool2AM", "pool2MI", "pool2PM", "pool2NT", 
 	 	 "TOT_POOL3", "pool3AM", "pool3MI", "pool3PM","pool3NT",  
 	 	 "TOT_COM", "comAM", "comMI", "comPM", "comNT", 
 	 	 "TOT_MTK", "mtkAM", "mtkMI", "mtkPM", "mtkNT", 
 	 	 "TOT_HTK", "htkAM", "htkMI", "htkPM", "htkNT", 
	 	 "VolAMAB", "VolAMBA", "VolMIAB", "VolMIBA", "VolPMAB", "VolPMBA", "VolNTAB", "VolNTBA", 
	 	 "FresovAMAB", "FresovAMBA",  "FresovMIAB", "FresovMIBA", "FresovPMAB", "FresovPMBA", "FresovNTAB", "FresovNTBA",  
	 	 "Frepl2AMAB", "Frepl2AMBA", "Frepl2MIAB", "Frepl2MIBA", "Frepl2PMAB", "Frepl2PMBA", "Frepl2NTAB", "Frepl2NTBA",  
	 	 "pl3AMAB", "pl3AMBA", "pl3MIAB", "pl3MIBA", "pl3PMAB", "pl3PMBA", "pl3NTAB", "pl3NTBA",   
	 	 "FrecomAMAB", "FrecomAMBA", "FrecomMIAB", "FrecomMIBA", "FrecomPMAB", "FrecomPMBA", "FrecomNTAB", "FrecomNTBA",
	 	 "mtkAMAB", "mtkAMBA", "mtkMIAB", "mtkMIBA", "mtkPMAB", "mtkPMBA", "mtkNTAB", "mtkNTBA",   
	 	 "htkAMAB", "htkAMBA", "htkMIAB", "htkMIBA", "htkPMAB", "htkPMBA","htkNTAB", "htkNTBA",
	 	 "minAMAB", "minAMBA", "minMIAB", "minMIBA", "minPMAB", "minPMBA", "minNTAB", "minNTBA", 
	 	 "MinRawAMAB", "MinRawAMBA", "MinRawMIAB", "MinRawMIBA", "MinRawPMAB", "MinRawPMBA", "MinRawNTAB", "MinRawNTBA", 
	 	 "VMTAMAB", "VMTAMBA", "VMTMIAB", "VMTMIBA", "VMTPMAB", "VMTPMBA", "VMTNTAB", "VMTNTBA",   
	 	 "VHTAMAB", "VHTAMBA", "VHTMIAB", "VHTMIBA", "VHTPMAB", "VHTPMBA", "VHTNTAB", "VHTNTBA",  
	 	 "vcAMAB", "vcAMBA", "vcPMAB", "vcPMBA", 
	 	 "CNTFLAG", "MTKFLAG", "HTKFLAG", "CNTMCSQ", "MTKMCSQ", "HTKMCSQ"}
	end
	
else if typeassn = "HOT3+" then do
		OutFields = 
		{"ID", "LENGTH", "DIR", "FUNCL", "FEDFUNC_AQ", "CO_FEDFUNC", "Strname", "A_CrossStr", "B_CrossStr", 
	  	 "AREATP", "CALIB", "MTK", "HTK", "Scrln", "COUNTY", "STCNTY", "Cap1hrAB", "Cap1hrBA", 
	 	 "TTfreeAB", "TTfreeBA", "TTPkAssnAB", "TTPkAssnBA", "lanesAB", "lanesBA",
	 	 "Fun2", "CntyAF", "VMTLen", 
	 	 "TotVolAB", "TotVolBA", "VOL_POST", "Tot_Vol",   
	 	 "TOT_VMT", "VMT_AM", "VMT_MI", "VMT_PM", "VMT_NT", 
		 "TOT_VHT", "VHT_AM", "VHT_MI", "VHT_PM", "VHT_NT",  
 	 	 "TOT_SOV", "sovAM", "sovMI", "sovPM", "sovNT", 
 	 	 "TOT_POOL2", "pool2AM", "pool2MI", "pool2PM", "pool2NT", 
 	 	 "TOT_POOL3", "pool3AM", "pool3MI", "pool3PM","pool3NT",  
 	 	 "TOT_COM", "comAM", "comMI", "comPM", "comNT", 
 	 	 "TOT_MTK", "mtkAM", "mtkMI", "mtkPM", "mtkNT", 
 	 	 "TOT_HTK", "htkAM", "htkMI", "htkPM", "htkNT", 
	 	 "VolAMAB", "VolAMBA", "VolMIAB", "VolMIBA", "VolPMAB", "VolPMBA", "VolNTAB", "VolNTBA", 
	 	 "FresovAMAB", "FresovAMBA",  "FresovMIAB", "FresovMIBA", "FresovPMAB", "FresovPMBA", "FresovNTAB", "FresovNTBA",  
	 	 "HOTsovAMAB", "HOTsovAMBA", "HOTsovMIAB", "HOTsovMIBA", "HOTsovPMAB", "HOTsovPMBA", "HOTsovNTAB", "HOTsovNTBA",  
	 	 "Frepl2AMAB", "Frepl2AMBA", "Frepl2MIAB", "Frepl2MIBA", "Frepl2PMAB", "Frepl2PMBA", "Frepl2NTAB", "Frepl2NTBA",  
	 	 "HOTpl2AMAB", "HOTpl2AMBA", "HOTpl2MIAB", "HOTpl2MIBA", "HOTpl2PMAB", "HOTpl2PMBA", "HOTpl2NTAB", "HOTpl2NTBA",   
	 	 "pl3AMAB", "pl3AMBA", "pl3MIAB", "pl3MIBA", "pl3PMAB", "pl3PMBA", "pl3NTAB", "pl3NTBA",   
	 	 "FrecomAMAB", "FrecomAMBA", "FrecomMIAB", "FrecomMIBA", "FrecomPMAB", "FrecomPMBA", "FrecomNTAB", "FrecomNTBA",
	 	 "HOTcomAMAB", "HOTcomAMBA", "HOTcomMIAB", "HOTcomMIBA", "HOTcomPMAB", "HOTcomPMBA", "HOTcomNTAB", "HOTcomNTBA",    
	 	 "mtkAMAB", "mtkAMBA", "mtkMIAB", "mtkMIBA", "mtkPMAB", "mtkPMBA", "mtkNTAB", "mtkNTBA",   
	 	 "htkAMAB", "htkAMBA", "htkMIAB", "htkMIBA", "htkPMAB", "htkPMBA","htkNTAB", "htkNTBA",
	 	 "minAMAB", "minAMBA", "minMIAB", "minMIBA", "minPMAB", "minPMBA", "minNTAB", "minNTBA", 
	 	 "MinRawAMAB", "MinRawAMBA", "MinRawMIAB", "MinRawMIBA", "MinRawPMAB", "MinRawPMBA", "MinRawNTAB", "MinRawNTBA", 
	 	 "VMTAMAB", "VMTAMBA", "VMTMIAB", "VMTMIBA", "VMTPMAB", "VMTPMBA", "VMTNTAB", "VMTNTBA",   
	 	 "VHTAMAB", "VHTAMBA", "VHTMIAB", "VHTMIBA", "VHTPMAB", "VHTPMBA", "VHTNTAB", "VHTNTBA",  
	 	 "vcAMAB", "vcAMBA", "vcPMAB", "vcPMBA", 
	 	 "CNTFLAG", "MTKFLAG", "HTKFLAG", "CNTMCSQ", "MTKMCSQ", "HTKMCSQ"}
	end


	ExportView(join4+"|", "FFB", out_bin, OutFields,)

	CloseView(join4)

	return(totassnOK)

endmacro

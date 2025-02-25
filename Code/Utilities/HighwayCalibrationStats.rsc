Macro "HighwayCalibrationStats" (Args)

	// Part of runstats_hwyassn_hot that deal with calibration
	//	\report\RunStats_HwyAssn.dbf
	//	\report\Screenlinesummary.dbf		\hwyassn\screenlinelinks.bin
	//	\report\runstats_dwnldCOATFUN.dbf
	//  changed tot_assn_hot.dbf to tot_assn_hot.bin (4/25/17)

	//Input Datasets
	//	Dir + "\\HwyAssn\\HOT\\TOT_ASSN_HOT.bin"
	
	//Aggregation datasets
	//	MRMDir + "\\ScreenlineID.bin"
	//	MRMDir + "\\County_ATFun.bin"
	//	MRMDir + "\\County_ATFunID.bin"
	//	MRMDir + "\\ATFUN_ID.dbf"

	Dir = Args.[Run Directory]
	MetDir = Args.[MET Directory]
	Year = Args.[Run Year]
	msg = null
	HwyCalibStatsOK = 1

	if Year <> "2022" then goto Skip

	datentime = GetDateandTime()
	AppendToLogFile(1, "Enter HighwayCalibrationStats: " + datentime)

	// Add section to check if datasets exist

	//Open files
	TotAssn = OpenTable("TotAssn", "FFB", {Dir + "\\HwyAssn\\HOT\\TOT_ASSN_HOT.bin",})
	CATMatch = OpenTable("CATMatch", "FFB", {MetDir + "\\County_ATFun.bin",})
	CATMatch2 = OpenTable("CATMatch2", "FFB", {MetDir + "\\County_ATFunID.bin",})
	ScrlnID  = OpenTable("ScrLnID", "FFB", {MetDir + "\\ScreenlineID.bin",})
	ATFUNID  = OpenTable("ATFUNID", "DBASE", {MetDir + "\\ATFUN_ID.dbf",})
	COATFUNID  = OpenTable("COATFUNID", "DBASE", {MetDir + "\\COATFUN_ID.dbf",})

	//Tot_assn variables
	CATFun   = CreateExpression("TotAssn", "CATFun", "if (county = 57 or county = 91) then (45000+county)*1000 + AREATP * 100 + funcl else (37000 + county) * 1000 + areatp * 100 + funcl",)
	Lane_Mi  = CreateExpression("TotAssn", "Lane_Mi", "LENGTH * LANESAB + LENGTH * LANESBA",)
	mtkflag  = CreateExpression("TotAssn", "MTKFlag", "if MTK <> null then 1 else 0",)
	htkflag  = CreateExpression("TotAssn", "HTKFlag", "if HTK <> null then 1 else 0",)
	assnvol  = CreateExpression("TotAssn", "AssnVol", "if CALIB <> null then TOT_VOL else 0",)
	assnmtk  = CreateExpression("TotAssn", "AssnMTK", "if MTK     <> null then TOT_VOL else 0",)
	assnhtk  = CreateExpression("TotAssn", "AssnHTK", "if HTK     <> null then TOT_VOL else 0",)

	atfun = CreateExpression("TotAssn", "ATFUN", "AREATP * 100 + funcl",)
	coatfun = CreateExpression("TotAssn", "COATFUN", "IF COUNTY = 119 THEN (10000 + (AREATP * 100) + FUNCL) ELSE (20000 + (AREATP * 100) + FUNCL) ",)


	//  RUNSTATS_HWYASSN.CSV ***********************

	//Join CATFUN (STCNTY * 1000 + ATYPE * 100 + Funcl)
	join1 =  JoinViews("AssnMatch1", "TotAssn.CATFun", "CATMatch.CATFun",)

	//Aggregate to CATFun2 - sum AT (1,2,4=comm), Funcl - Freeway, ExprWay, Tfare, Other, HighOcc, Cenconn
	//      all counties except Mecklenburg - use full area type and funcl
	join2 =  JoinViews("AssnCATFun2", "CATMatch2.CATFun2", "AssnMatch1.CATFun2", 
        	           {{"A",}, 
    			    {"Fields",{{"LENGTH",    {{"Sum"}}}, {"Lane_Mi",  {{"Sum"}}},
		        	       {"VMT_AM",    {{"Sum"}}}, {"VHT_AM",   {{"Sum"}}},     		       
		        	       {"VMT_MI",    {{"Sum"}}}, {"VHT_MI",   {{"Sum"}}},     		       
		        	       {"VMT_PM",    {{"Sum"}}}, {"VHT_PM",   {{"Sum"}}},     		       
		      		       {"VMT_NT",    {{"Sum"}}}, {"VHT_NT",   {{"Sum"}}},     		       
			               {"CALIB",   {{"Sum"}}}, {"AssnVol",  {{"Sum"}}},     		       
			               {"CNTFLAG",   {{"Sum"}}}, {"CNTMCSQ",  {{"Sum"}}},     		            		       
			               {"MTK",     {{"Sum"}}}, {"AssnMTK",  {{"Sum"}}},     		       
			               {"MTKFLAG",   {{"Sum"}}}, {"MTKMCSQ",  {{"Sum"}}},     		       
			               {"HTK",     {{"Sum"}}}, {"AssnHTK",  {{"Sum"}}},     		       
			               {"HTKFLAG",   {{"Sum"}}}, {"HTKMCSQ",  {{"Sum"}}},     		       
   			       }}})

	IDNameArray    = {"CATFun2", "CATMatch2.STCNTY", "CATMatch2.AT2", "CATMatch2.Fun2", 
			  "CATMatch2.CntyName", "AT2Name", "Fun2Name"}
	MileNameArray  = {"LENGTH", "LANE_MI"}
	VMTNameArray   = {"VMT_AM", "VHT_AM", "VMT_MI", "VHT_MI", "VMT_PM", "VHT_PM", "VMT_NT", "VHT_NT"}
        CountNameArray = {"CALIB","AssnVol", "CNTFLAG", "CNTMCSQ",
        		  "MTK",    "AssnMTK", "MTKFLAG", "MTKMCSQ",  
        		  "HTK",    "AssnHTK", "HTKFLAG", "HTKMCSQ"} 
	OutNameArray   = IDNameArray + MileNameArray + VMTNameArray + CountNameArray
	ExportView(join2 +"|", "CSV", Dir + "\\Report\\RunStats_HwyAssn.csv", OutNameArray,{{"CSV Header", "True"},})
	CloseView(CATMatch)
	CloseView(CATMatch2)
	CloseView(join1)
	CloseView(join2)


	// pull screenline records
	SetView("TotAssn")
	ScrLineSelect = "Select * where SCRLN <> null and CNTFLAG = 1"
	nlnks = SelectbyQuery("ScrLineLinks", "Several", ScrLineSelect,)

	ExportView("TotAssn"+"|ScrLineLinks", "CSV", Dir + "\\hwyassn\\ScreenLineLinks.csv", 
		{"SCRLN", "ID", "LENGTH", "DIR", "FUNCL", "AREATP", "COUNTY","Strname", "A_CrossStr", "B_CrossStr", 
		 "CALIB", "TOT_VOL", "CNTFLAG", "CNTMCSQ"},
		 {
			{"CSV Header", "True"},
		})
		 
	

	//Reopen file of screenline links - join to screenline id
	ScrLnLinks = OpenTable("ScrLnLinks", "CSV", {Dir + "\\hwyassn\\ScreenLineLinks.csv",})
	 	
	join3 =  JoinViews("ScrLnSum", "ScrLnID.SCRLN", "ScrLnLinks.SCRLN", 
        	           {{"A",}, 
    			    {"Fields",{{"CALIB", {{"Sum"}}}, {"TOT_VOL",  {{"Sum"}}},     		       
			               {"CNTFLAG",   {{"Sum"}}}, {"CNTMCSQ",  {{"Sum"}}}     		       
   			       }}})

	ExportView("ScrLnSum|", "CSV", Dir + "\\report\\ScreenLineSummary.csv", 
		{"SCRLN", "CALIB", "TOT_VOL", "CNTFLAG", "CNTMCSQ"},
		{
			{"CSV Header", "True"},
		})
	
	CloseView(ScrlnID)
	CloseView(join3)
	CloseView(ScrLnLinks)

	// runstats_dwnldVol.csv
	join_vol =  JoinViews("Counts", "ATFUNID.ATFUN", "TotAssn.ATFUN", 
        	           {{"A",}, 
    			    {"Fields",{{"CNTFLAG", {{"Sum"}}}, {"CALIB", {{"Sum"}}}, {"AssnVol",  {{"Sum"}}}, {"CNTMCSQ", {{"Sum"}}}   		       
   			       }}})

	ExportView("Counts|", "CSV", Dir + "\\report\\runstats_dwnldVOL.csv", 
		{"ATFUN", "CNTFLAG", "CALIB", "AssnVol", "CNTMCSQ"},
		{
			{"CSV Header", "True"},
		})
	
	CloseView(join_vol)
	CloseView(ATFUNID)

	// runstats_dwnldcoatfun.csv
	join_vol2 =  JoinViews("Counts2", "COATFUNID.COATFUN", "TotAssn.COATFUN", 
        	           {{"A",}, 
    			    {"Fields",{{"CNTFLAG", {{"Sum"}}}, {"CALIB", {{"Sum"}}}, {"AssnVol",  {{"Sum"}}}, {"CNTMCSQ", {{"Sum"}}}   		       
   			       }}})

	ExportView("Counts2|", "CSV", Dir + "\\report\\runstats_dwnldCOATFUN.csv", 
		{"ORDER", "COATFUN", "CNTFLAG", "CALIB", "AssnVol", "CNTMCSQ"},
		{
			{"CSV Header", "True"},
		})

	CloseView(join_vol2)
	CloseView(COATFUNID)


	CloseView(TotAssn)

	Skip: 

	datentime = GetDateandTime()
	AppendToLogFile(1, "Exit HighwayCalibrationStats: " + datentime)
	return({HwyCalibStatsOK, msg})



EndMacro

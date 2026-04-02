macro "Trip_Generation" (Args)
//runs the Sept 2013 version
//adj trip fac 3.23.07 - McLelland
//adj atfacta for com, mtk, htk 2.25.09 - McLelland
//new compile TGMET for 2005 base at external stations - 2.25.09 Gallup
//references updated fortran file with 2012 external station counts & new boundary external stations, fixes extadj for Auto EI--5.24.13 Kinnamon
//Calls fortran file with external stations input repaired 9/13
//new compile TGMET for 2010 base Cleveland Expansion - 2.4.15 Familian
//references updated fortran file with 2012 external station counts & Cleveland expansion, fixes extadj for Auto EI-2.4.15 Familian
//Calls fortran file with external stations input repaired 9/13
//
//Moved EE trips to new job - EETrips (and to TD subdirectory)
//Updated for new UI - Aug, 2015 - McLelland
//
//new compile TGMET for 2015 base year with Iredell Expansion - compile 7.11.16 Familian; macro update 9.7.16 Gallup


	// LogFile = Args.[Log File].value
	// ReportFile = Args.[Report File].value
	// SetLogFileName(LogFile)
	// SetReportFileName(ReportFile)

	METDir = Args.[MET Directory]
	Dir = Args.[Run Directory]
	//sedata_dbf = Args.[LandUse File]
	sedata_bin = Args.[LandUse File]
	theyear = Args.[Run Year]
	yearnet = right(theyear,2)
	msg = null
	TripGenOK = 1

	datentime = GetDateandTime()
	AppendToLogFile(1, "Enter Trip Generation: " + datentime)

	//dbf2csv macro at end of trip gen code

	//sedata_file = RunMacro("dbf2csv", sedata_dbf)
	sedata_file = RunMacro("bin2csv", sedata_bin)

	FortInfo = GetFileInfo(METDir + "\\Pgm\\tgmet2015_171013.exe")
	TimeStamp = FortInfo[7] + " " + FortInfo[8]
	AppendToLogFile(2, "Trip Generation call to fortran: pgm=tgmet2015_171013.exe, timestamp: " + TimeStamp)


	macname = METDir + "\\Pgm\\Param\\TG.CTL"
	exist = GetFileInfo(macname)
	if (exist <> null) then DeleteFile(macname)
	mac = OpenFile(macname, "w")

	WriteLine(mac, "Metrolina Trip Generation Program -- "+theyear+" Run")
	WriteLine(mac, "Version date Sept. 24, 2013")
	WriteLine(mac, " ")
	WriteLine(mac, "tg.ctl")
	WriteLine(mac, " ")
	WriteLine(mac, "&files")
	WriteLine(mac, "  sefile      = '" + sedata_file+"'")
	WriteLine(mac, "  distcorfile = '" + Dir + "\\Ext\\dist_to_closest_extsta.asc'")
	WriteLine(mac, "  xvolfile    = '" + Dir + "\\Ext\\extstavol" + yearnet + ".asc'")
  	WriteLine(mac, "  atfile      = '" + Dir + "\\LandUse\\TAZ_AREATYPE.bin'")
	WriteLine(mac, "  pumafile    = '" + METDir + "\\TAZ\\PUMAequiv.prn'")
	WriteLine(mac, " ")
	WriteLine(mac, "  hhfile      = '" +Dir + "\\TG\\hhdetail.asc'")
	WriteLine(mac, "  prodfile    = '" +Dir + "\\TG\\productions.asc'")
	WriteLine(mac, "  attrfile    = '" +Dir + "\\TG\\attractions.asc'")
	WriteLine(mac, "  xxfile      = '" +Dir + "\\TG\\xxfactor.asc'")
	WriteLine(mac, "  list        = '" +Dir + "\\Report\\tg"+theyear+".prn'")
	WriteLine(mac, "/")
	WriteLine(mac, " ")
	WriteLine(mac, "&parameters")
	WriteLine(mac, "  begtr       = 0")
	WriteLine(mac, "  endtr       = 0")
	WriteLine(mac, "  savescr     = .false.")
	WriteLine(mac, "  zTAZ       = 1")
	WriteLine(mac, "  zPOP_TOT = 2")
	WriteLine(mac, "  zPOP_HHS = 3")
	WriteLine(mac, "  zPOP_GRP = 4")
	WriteLine(mac, "  zHH = 5")
	WriteLine(mac, "  zMED_INC = 6")
	WriteLine(mac, "  zLOIND = 7")
	WriteLine(mac, "  zHIIND = 8")
	WriteLine(mac, "  zRTL = 9")
	WriteLine(mac, "  zHWY = 10")
	WriteLine(mac, "  zLOSVC = 11")
	WriteLine(mac, "  zHISVC = 12")
	WriteLine(mac, "  zOFFGOV = 13")
	WriteLine(mac, "  zEDUC = 14")
	WriteLine(mac, "  zEMP_TOT = 15")
	WriteLine(mac, "  zSTU_K8 = 16")
	WriteLine(mac, "  zSTU_HS = 17")
	WriteLine(mac, "  zSTU_CU = 18")	
	WriteLine(mac, "  zDORM = 19")	
	WriteLine(mac, "  zAREA = 20")	
	WriteLine(mac, "  do_gq = .true.")	
	WriteLine(mac, "/")
	WriteLine(mac, " ")
	WriteLine(mac, "Calibration adjustments")
	WriteLine(mac, "- EXTADJ adjusts the I/E share (a,1) and E/I share (a,2) models by area type")
	WriteLine(mac, "- ARATE adjusts the attraction equations to increase CBD, reduce Rural trips")
  	WriteLine(mac, "- ATFACTA adjusts the COM, MTK, and HTK trip totals")
  	WriteLine(mac, " ")
	WriteLine(mac, "&coeffs")
	WriteLine(mac, "  extadj(1,1)  = 1.1130, extadj(1,2) = 0.4376")
	WriteLine(mac, "  extadj(2,1)  = 1.8272, extadj(2,2) = 0.1935")
	WriteLine(mac, "  extadj(3,1)  = 0.4772, extadj(3,2) = 0.1491")
	WriteLine(mac, "  extadj(4,1)  = 0.7798, extadj(4,2) = 0.2673")
	WriteLine(mac, "  extadj(5,1)  = 5.3757, extadj(5,2) = 1.4012")
	WriteLine(mac, " ") 
//	WriteLine(mac, "  arate(1,15) = 1300.0")
//	WriteLine(mac, "  arate(5,1) = 1.25")
//	WriteLine(mac, "  arate(5,4) = 2.4")
//	WriteLine(mac, "  arate(5,5) = 2.4")
//	WriteLine(mac, "  arate(5,7) = 3.0")
//	WriteLine(mac, "  arate(4,2) = 0.05")
//	WriteLine(mac, "  arate(4,3) =-0.3")
//	WriteLine(mac, "  arate(4,4) = 2.05")
//	WriteLine(mac, "  arate(4,5) = 3.3")
//	WriteLine(mac, "  arate(4,7) = 0.9")
//	WriteLine(mac, "  arate(4,8) =-0.6")
//	WriteLine(mac, "  arate(6,15) = 325.0")
//	WriteLine(mac, " ")
	WriteLine(mac, "  atfacta(9,1) = 1.00")
	WriteLine(mac, "  atfacta(9,2) = 1.00")
	WriteLine(mac, "  atfacta(9,3) = 1.00")
	WriteLine(mac, "  atfacta(9,4) = 1.00")
	WriteLine(mac, "  atfacta(9,5) = 1.00")
	WriteLine(mac, " ")
	WriteLine(mac, "  atfacta(10,1) = 1.00")
	WriteLine(mac, "  atfacta(10,2) = 1.00")
	WriteLine(mac, "  atfacta(10,3) = 1.00")
	WriteLine(mac, "  atfacta(10,4) = 1.00")
	WriteLine(mac, "  atfacta(10,5) = 1.00")
	WriteLine(mac, " ")
	WriteLine(mac, "  atfacta(11,1) = 1.00")
	WriteLine(mac, "  atfacta(11,2) = 1.00")
	WriteLine(mac, "  atfacta(11,3) = 1.00")
	WriteLine(mac, "  atfacta(11,4) = 1.00")
	WriteLine(mac, "  atfacta(11,5) = 1.00")
	WriteLine(mac, " ")
	WriteLine(mac, "  pfact(1,1) = 0.887")
	WriteLine(mac, "  pfact(1,2) = 0.822")
	WriteLine(mac, "  pfact(1,3) = 0.718")
	WriteLine(mac, "  pfact(1,4) = 0.774")
	WriteLine(mac, " ")
	WriteLine(mac, "  pfact(2,1) = 0.793")
	WriteLine(mac, "  pfact(2,2) = 0.793")
	WriteLine(mac, "  pfact(2,3) = 0.793")
	WriteLine(mac, "  pfact(2,4) = 0.793")
	WriteLine(mac, " ")
	WriteLine(mac, "  pfact(3,1) = 1.016")
	WriteLine(mac, "  pfact(3,2) = 1.016")
	WriteLine(mac, "  pfact(3,3) = 1.016")
	WriteLine(mac, "  pfact(3,4) = 1.016")
	WriteLine(mac, " ")
	WriteLine(mac, "  pfact(4,1) = 1.297")
	WriteLine(mac, "  pfact(4,2) = 1.264")
	WriteLine(mac, "  pfact(4,3) = 0.931")
	WriteLine(mac, "  pfact(4,4) = 0.959")
	WriteLine(mac, " ")
	WriteLine(mac, "  pfact(5,1) = 1.060")
	WriteLine(mac, "  pfact(5,2) = 1.129")
	WriteLine(mac, "  pfact(5,3) = 0.830")
	WriteLine(mac, "  pfact(5,4) = 0.963")
	WriteLine(mac, " ")
	WriteLine(mac, "  pfact(6,1) = 0.730")
	WriteLine(mac, "  pfact(6,2) = 0.730")
	WriteLine(mac, "  pfact(6,3) = 0.730")
	WriteLine(mac, "  pfact(6,4) = 0.730")
	WriteLine(mac, " ")
	WriteLine(mac, "  pfact(7,1) = 0.733")
	WriteLine(mac, "  pfact(7,2) = 0.733")
	WriteLine(mac, "  pfact(7,3) = 0.733")
	WriteLine(mac, "  pfact(7,4) = 0.733")
	WriteLine(mac, " ")
	WriteLine(mac, "  pfact(8,1) = 0.926")
	WriteLine(mac, "  pfact(8,2) = 0.926")
	WriteLine(mac, "  pfact(8,3) = 0.926")
	WriteLine(mac, "  pfact(8,4) = 0.926")
	WriteLine(mac, " ")
	WriteLine(mac, "/")
	WriteLine(mac, " ")
	WriteLine(mac, "&equiv")
	WriteLine(mac, "  cbd         = 10001,-10003,10005,-10025,10039,10059,10103,10104,10106,")
	WriteLine(mac, "                10112,10115,10117,-10120,10139,-10144,10152,10174,10177,")
	WriteLine(mac, "                11025")
	WriteLine(mac, " ")
	WriteLine(mac, "  uptown         = 10001,-10025,10106,10117,10118,10120,10139,10142,10143,")
	WriteLine(mac, "                10149,10150,10174,-10177,10184,-10186,10188,10189,11025,")
	WriteLine(mac, "                11026")
	WriteLine(mac, "/")
	WriteLine(mac, " ")
	WriteLine(mac, "&special")
	WriteLine(mac, "/")
	CloseFile(mac)


	macname = Dir + "\\TG.BAT"
	exist = GetFileInfo(macname)
	if (exist <> null) then DeleteFile(macname)
	mac = OpenFile(macname, "w")
  	WriteLine(mac, METDir + "\\Pgm\\tgmet2015_171013.exe " + METDir + "\\Pgm\\Param\\TG.CTL")
	WriteLine(mac, "erase temp4.scr")
	WriteLine(mac, "erase temp9a.scr")
	WriteLine(mac, "erase temp9b.scr")
	WriteLine(mac, "erase temp10.scr")
	WriteLine(mac, "erase temp11.scr")
	WriteLine(mac, "erase temp12.scr")
	WriteLine(mac, "erase temp13.scr")
	WriteLine(mac, "erase temp13a.scr")
	WriteLine(mac, "erase temp14.scr")
	CloseFile(mac)

	RunProgram(Dir + "\\TG.BAT", )

	RunOK = RunMacro("DidItRun", Dir + "\\TG\\Productions.asc")
	if RunOK[2] = null or RunOK[2] > 2 then goto fortdidnotrun
	goto quit	

	fortdidnotrun:
	Throw("Trip_Gen, ERROR-pgm=tgmet2015_171013 did not run!, \\TG\\Productions.asc date=" + RunOK[1])
	AppendToLogFile(1, "Trip_GenGen, ERROR-pgm=tgmet2015_171013 did not run!, \\TG\\Productions.asc date=" + RunOK[1])
	TripGenOK = 0
	goto quit

	userquit:
	msg = {"Trip Gen - User quit"}
	TripGenOK = 0
	goto quit

	quit:

	datentime = GetDateandTime()
	AppendToLogFile(1, "Exit Trip Generation: " + datentime)
	RunMacro("G30 File Close All")

	return({TripGenOK, msg})
endmacro


//macro "dbf2csv" (dbffile)
macro "bin2csv" (binfile)
	
	//dbfpath = SplitPath(dbffile)
	binpath = SplitPath(binfile)
	//sedata_file = dbfpath[1] + dbfpath[2] + dbfpath[3] + "_csv.csv"
	sedata_file = binpath[1] + binpath[2] + binpath[3] + "_csv.csv"
	//dbftemp = dbfpath[1] + dbfpath[2] + "temp.dbf"
	bintemp = binpath[1] + binpath[2] + "temp.bin"
	//csvtemp = dbfpath[1] + dbfpath[2] + "temp.csv"
	csvtemp = binpath[1] + binpath[2] + "temp.csv"

	//exist = GetFileInfo(dbftemp)
	exist = GetFileInfo(bintemp)
	//if exist <> null then DeleteFile(dbftemp)
	if exist <> null then DeleteFile(bintemp)
	//TheDBASE = OpenTable("TheDBASE", "DBASE", {dbffile})
	TheBIN = OpenTable("TheBIN", "FFB", {binfile})
	
	//pop_tot = CreateExpression(TheDBASE, "POP_TOT", "POP",)
	pop_tot = CreateExpression(TheBIN, "POP_TOT", "POP",)
	//emp_tot = CreateExpression(TheDBASE, "EMP_TOT", "LOIND + HIIND + RTL + HWY + LOSVC + HISVC + OFFGOV + EDUC",)
	emp_tot = CreateExpression(TheBIN, "EMP_TOT", "LOIND + HIIND + RTL + HWY + LOSVC + HISVC + OFFGOV + EDUC",)
	//subcodist = CreateExpression(TheDBASE, "SUBCODIST", "DISTRICT",)
	subcodist = CreateExpression(TheBIN, "SUBCODIST", "DISTRICT",)
	//acres = CreateExpression(TheDBASE, "ACRES", "round((AREA_LU * 640) * 0.75,0)",)
	acres = CreateExpression(TheBIN, "ACRES", "round((AREA_LU * 640) * 0.75,0)",)
	
	//ExportView(TheDBASE+"|", "DBASE", dbftemp,
	  ExportView(TheBIN+"|", "FFB", bintemp,
		{"TAZ", "POP_TOT", "POP_HHS", "POP_GRP", "HH", "MED_INC", 
		 "LOIND", "HIIND", "RTL", "HWY", "LOSVC", "HISVC", "OFFGOV", "EDUC",
		 "EMP_TOT", "STU_K8", "STU_HS", "STU_CU", "DORM",
		 "ACRES", "STCNTY", "SUBCODIST"},{{"Row Order", {{"TAZ", "Ascending"}}}})	

	//TheTEMP = OpenTable("TheTEMP", "DBASE", {dbftemp})
	TheTEMP = OpenTable("TheTEMP", "FFB", {bintemp})
	TableStructure = GetTableStructure(TheTEMP)
	
// Add array info[i][12] = original field name - REQUIRED, see ModifyTable() 
	for i = 1 to TableStructure.length do
		TableStructure[i] = TableStructure[i] + {TableStructure[i][1]}
	end

// Modify fields as necessay, export to CSV
//   Acres to area only one so far, 

	TableStructure[20][1] = "AREA"
	TableStructure[20][2] = "Integer"
	TableStructure[20][3] = 11
	TableStructure[20][4] = 0
	

//	ShowArray(TableStructure)
	ModifyTable(TheTEMP, TableStructure)
	ExportView(TheTEMP+"|", "CSV", csvtemp,,)

	hdr = "TAZ,POP_TOT,POP_HHS,POP_GRP,HH,MED_INC,LOIND,HIIND,RTL,HWY,LOSVC,HISVC,OFFGOV,EDUC,EMP_TOT,STU_K8,STU_HS,STU_CU,DORM,AREA,STCNTY,SUBCODIST"
	csvptr = OpenFile(sedata_file, "w")
	WriteLine(csvptr, hdr)

	tempptr = OpenFile(csvtemp, "r")
	while not FileAtEOF(tempptr) do
		seline = ReadLine(tempptr)
		WriteLine(csvptr, seline)
	end
	
	//CloseView(TheDBASE)
	CloseView(TheBIN)
	CloseView(TheTEMP)
	CloseFile(tempptr)
	CloseFile(csvptr)
	return(sedata_file)
endmacro

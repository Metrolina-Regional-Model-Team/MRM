Macro "TDMTK" (Args)

	//Trip Distribution - Medium trucks	
	//Friction factors, intrazonal K : Bill Allen Oct, 2013
	//Modified for new UI - Oct, 2015

	// LogFile = Args.[Log File].value
	// ReportFile = Args.[Report File].value
	// SetLogFileName(LogFile)
	// SetReportFileName(ReportFile)

	METDir = Args.[MET Directory]
	Dir = Args.[Run Directory]
	
	msg = null
	TripDistOK = 1

	datentime = GetDateandTime()
	AppendToLogFile(1, "Enter TDmtk: " + datentime)

	//template matrix
	TemplateMat = null
	templatecore = null
	TemplateMat = OpenMatrix( METDir + "\\TAZ\\matrix_template.mtx", "True")
	templatecore = CreateMatrixCurrency(TemplateMat, "Table", "Rows", "Columns", )

	//create new td matrix
	CopyMatrixStructure({templatecore}, {{"File Name", Dir + "\\TD\\TDmtk.mtx"},
    		{"Label", "TDmtk"},
    		{"File Based", "Yes"},
    		{"Tables", {"Trips"}},
    		{"Operation", "Union"}})

	//080124:  Default fortran return 24 if job doesn't run, Jan 24, 2008 McLelland
	rtnfptr = null
	rtnfptr=openfile(Dir + "\\Report\\return_code.txt","w")
	writeline(rtnfptr,"      24")
	closefile(rtnfptr)		

	//TDMET control file
	ctlname = METDir + "\\Pgm\\Param\\TDmtk.ctl"
	exist = GetFileInfo(ctlname)
	if(exist <> null) then DeleteFile(ctlname)
	ctlhandle = OpenFile(ctlname, "w")
	WriteLine(ctlhandle, "Metrolina Regional Travel Model")
	WriteLine(ctlhandle, "Gravity Model Program")
	WriteLine(ctlhandle, "TDmtk.set: mtk")
	WriteLine(ctlhandle, " ")
	WriteLine(ctlhandle, "Files:")
	WriteLine(ctlhandle, "  Input:")
	WriteLine(ctlhandle, "    ffactors  = F factors")
	WriteLine(ctlhandle, "    prods     = productions (ASCII)")
	WriteLine(ctlhandle, "    attrs     = attractions (ASCII)")
	WriteLine(ctlhandle, "    htime     = highway time matrix")
	WriteLine(ctlhandle, "    ttime     = transit time matrix")
	WriteLine(ctlhandle, "    htoll     = highway toll matrix (optional)")
	WriteLine(ctlhandle, "  Output:")
	WriteLine(ctlhandle, "    trips     = output ASCII trip table")
	WriteLine(ctlhandle, "    listing   = program reports")
	WriteLine(ctlhandle, " ")
	WriteLine(ctlhandle, "&files")
	WriteLine(ctlhandle, "  ffactors = '" + METDir + "\\Pgm\\Frictionfactors\\ffmtk.prn'")
	WriteLine(ctlhandle, "  prods    = '" + Dir + "\\TG\\productions.asc'")
	WriteLine(ctlhandle, "  attrs    = '" + Dir + "\\TG\\attractions.asc'")
	WriteLine(ctlhandle, "  htime    = '" + Dir + "\\Skims\\TThwy_free.mtx',")
	WriteLine(ctlhandle, "  ttime    = '" + Dir + "\\Skims\\TTTran_free.mtx',")
	WriteLine(ctlhandle, "  trips    = '" + Dir + "\\TD\\TDmtk.mtx'")
	WriteLine(ctlhandle, "  listing  = '" + Dir + "\\Report\\TDmtk.txt'")
	WriteLine(ctlhandle, "  rtncode  = '" + Dir + "\\Report\\return_code.txt'")
	WriteLine(ctlhandle, "/")
	WriteLine(ctlhandle, "Parameters:")
	WriteLine(ctlhandle, "  print_te   = print trip ends? (t/f, default t)")
	WriteLine(ctlhandle, "  print_tlf  = print trip lth. freq. distribution? (t/f, def. t)")
	WriteLine(ctlhandle, "  skimmax    = max. impedance value for highway time (90)")
	WriteLine(ctlhandle, "  iter       = number of gravity model iterations requested (4)")
	WriteLine(ctlhandle, "  ttimefac   = sensitivity factor for transit time (1.0)")
	WriteLine(ctlhandle, "  htollfac   = sensitivity factor for highway toll (0.0)")
	WriteLine(ctlhandle, "  tformat    = trip end format specifier (no default)")
	WriteLine(ctlhandle, "  	(this must identify 2 Integer fields and one Real field:")
	WriteLine(ctlhandle, "  	TAZ, sequential zone number, trip ends [productions or attractions])")
	WriteLine(ctlhandle, "  tlf_file   = output TLF file? (t/f, def. f)")
	WriteLine(ctlhandle, "  intrak     = intrazonal K factor (1.0)")
	WriteLine(ctlhandle, " ")
	WriteLine(ctlhandle, "/")
	WriteLine(ctlhandle, "&parameters")
	WriteLine(ctlhandle, "  print_te   = t")
	WriteLine(ctlhandle, "  print_tlf  = t")
	WriteLine(ctlhandle, "  skimmax    = 100")
	WriteLine(ctlhandle, "  iter       = 3")
	WriteLine(ctlhandle, "  tformat    = '(i10,i10,180x,f10.3)'")
	WriteLine(ctlhandle, "  ttimefac   = 0.00")
	WriteLine(ctlhandle, "  tlf_file   = t")
	WriteLine(ctlhandle, "  trace      = 0")
	WriteLine(ctlhandle, "  intrak     = 1.0")
	WriteLine(ctlhandle, "/")
	CloseFile(ctlhandle)

	ctlhandle = null
	ctlname = null
	exist = null

	ctlname = Dir + "\\TD.BAT"
	exist = GetFileInfo(ctlname)
	if (exist <> null) then DeleteFile(ctlname)
	ctlhandle = OpenFile(ctlname, "w")
	WriteLine(ctlhandle, METDir + "\\Pgm\\tdmet_mtx.exe " + METDir + "\\Pgm\\Param\\TDmtk.ctl")
	CloseFile(ctlhandle)

	ctlhandle = null
	ctlname = null
	exist = null	

	RunMacro("G30 File Close All")

	RunProgram(Dir + "\\TD.BAT",)

	rtnfptr = null
	normal = '       0'
	exist = GetFileInfo(Dir + "\\Report\\return_code.txt")
	if exist = null 
		then goto fortdidnotrun 
		else do
			rtnptr = OpenFile(Dir + "\\Report\\return_code.txt", "r")
			if not FileAtEOF(rtnptr) 
				then do
					fortrtn = ReadLine(rtnptr)
					CloseFile(rtnptr)
					if fortrtn = normal then goto quit
								     else goto fortbadrun
				end
			     else do
					CloseFile(ptr)
					goto fortdidnotrun
				end
		end
	goto quit	

	fortdidnotrun:
	Throw("TDmtk, ERROR - Fortran job tdmet_mtx (trip distribution) did not run!")
	AppendToLogFile(1, "TDmtk,  ERROR - Fortran tdmet_mtx (trip distribution) did not run!")
	TripDistOK = 0
	goto quit

	fortbadrun:
	Throw("TDmtk, Fatal error in fortran program tdmet_mtx (trip distribution)")
	AppendToLogFile(1, "TDmtk, Fatal error in fortran program tdmet_mtx (trip distribution)")
	TripDistOK = 0
	goto quit

	quit:
	datentime = GetDateandTime()
	AppendToLogFile(1, "Exit TDmtk: " + datentime)

	return({TripDistOK, msg})
  
endmacro
Macro "TOD1_HBU_OffPeak" (Args)

	//Percentages are currently based on the 2012 HHTS 
	//Calculations for percentages are in calibration\TRIPPROP_MRM14v1.0.xls, tab TOD1
	//Modified for new UI, Oct, 2015
	
	// LogFile = Args.[Log File].value
	// ReportFile = Args.[Report File].value
	// SetLogFileName(LogFile)
	// SetReportFileName(ReportFile)

	METDir = Args.[MET Directory]
	Dir = Args.[Run Directory]
	msg = null
	TOD1OK = 1
	
	datentime = GetDateandTime()
	AppendToLogFile(1, "Enter TOD1_HBU_OffPeak: " + datentime)

	RunMacro("TCB Init")
	
	//template matrix
	TemplateMat = null
	templatecore = null
	TemplateMat = OpenMatrix(METDir + "\\TAZ\\matrix_template.mtx", "True")
	templatecore = CreateMatrixCurrency(TemplateMat, "Table", "Rows", "Columns", )

	CopyMatrixStructure({templatecore}, {{"File Name", Dir + "\\TripTables\\HBU_OFFPEAK_TRIPS.mtx"},
		{"Label", "hbu_offpeak_person"},
		{"File Based", "Yes"},
		{"Tables", {"HBU_OFFPEAK"}},
		{"Operation", "Union"}})

	//_________HBU_Peak________________

    FM1 = OpenMatrix(Dir + "\\TD\\TDhbu.mtx", "True")
	PM = openmatrix(Dir + "\\TripTables\\HBU_OFFPEAK_TRIPS.mtx", "True")
	dm1 = CreateMatrixCurrency(FM1, "Trips", "Rows", "Columns",)
	pm1 = CreateMatrixCurrency(PM, "HBU_OFFPEAK", "Rows", "Columns",)

	MatrixOperations(pm1, {dm1}, {0.2944},,, {{"Operation", "Add"}, {"Force Missing", "No"}})

	dm1 = null
	pm1 = null
	FM1 = null
	PM  = null

	// zero fill matrices
		Opts = null
		Opts.Input.[Matrix Currency] = {Dir + "\\TripTables\\HBU_OFFPEAK_TRIPS.mtx", "HBU_OFFPEAK", "Rows", "Columns"}
		Opts.Global.Method = 11
		Opts.Global.[Cell Range] = 2
		Opts.Global.[Expression Text] = "nz([HBU_OFFPEAK])"
		Opts.Global.[Force Missing] = "Yes"
	ret_value = RunMacro("TCB Run Operation", 1, "Fill Matrices", Opts)
	if !ret_value then goto badfill

	goto quit

	badfill:
	TOD1OK = 0
	Throw("TOD1_HBU_OffPeak - zero fill matrix failed")
	RunMacro("TCB Closing", ret_value, "TRUE" )
	goto quit

	quit:
	datentime = GetDateandTime()
	AppendToLogFile(1, "Exit TOD1_HBU_OffPeak: " + datentime)
	return({TOD1OK, msg})

endmacro 
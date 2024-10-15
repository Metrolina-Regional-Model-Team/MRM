// Macro "InitializeArgs" 

// //  Args.[parameter_name] = (parameter_type,{ initial_value }, description,join_to_other_parameter,display_theme_name)

		  
// 	Args.[Run Directory] = As("Folder",{},"Run directory, must be a full path.")
// 	Args.[Args File] = As("File",{"Arguments.args"},"Name of arguments file")
// 	Args.[MRM Directory] = As("Folder",{},"MRM (master) directory. Must be a full path.")
// 	Args.[Run Year] = As("string",{},"Year for Highway and Transit Networks")
// 	Args.[AM Peak Hwy Name] = As("string",{},"AM Peak Highway name - default RegNetYY_AMPeak")
// 	Args.[PM Peak Hwy Name] = As("string",{},"PM Peak Highway name - default RegNetYY_PMPeak")
// 	Args.[Offpeak Hwy Name] = As("string",{},"Offpeak Highway name - default RegNetYY_Offpeak")
// 	Args.[MET Directory] = As("Folder",{},"Scenario base folder (e.g. \\metrolina")
// 	Args.[Scenario Name] = As("string",{},"Description of current run")
// 	Args.[Model Type] = As("string",{},"Trip or Tour")
// 	Args.[TAZ File] = As("File",{},"TAZ geography file")
//  	Args.[LandUse File] = As("File",{},"Land Use file for Current Run")
// 	Args.[Log File] = As("File",{},"Scenario log file (XML)")
// 	Args.[Report File] = As("File",{},"Scenario report file (XML).")
// 	Args.[Version] = As("double",{},"Version number")
// 	Args.[Build] = As("integer",{},"Build number")
// 	Args.[Turn Penalty File] = As("File",{},"Turn penalty file for Current Run")
// 	Args.[TimeWeight] = As("double",{1.0},"Minimum path weight on travel time (minutes")
// 	Args.[DistWeight] = As("double",{0.0},"Minimum path weight on distance (miles)")
// 	Args.[MaxTravTimeFactor] = As("double",{10.0},"Maximum travel time on link expressed as multiple of free speed travel time (Min Speed)")
// 	Args.[Peak Hour Factor] = As("double",{0.4},"Pct of peak hour of the 3 hour peak period - used in calculating V/C in tot_assn")
// 	Args.[Feedback Iterations] = As("integer",{3},"Number of peak speed feedback iterations")
// 	Args.[Current Feedback Iter] = As("integer",{1},"Current iteration in peak speed feedback")
// 	Args.[HOTAssn Iterations] = As("integer",{5},"Number of iterations for HOT lanes assignment")
// 	Args.[HwyAssn Max Iter Feedback] = As("integer",{250},"TransCad MMA assignment - max. number of iterations for all but final assignment")
// 	Args.[HwyAssn Converge] = As("double",{0.01},"TransCad MMA assignment - convergence criteria for all but final assignment")
// 	Args.[HwyAssn Max Iter Final] = As("integer",{25000},"TransCad MMA assignment - max. number of iterations for all but final assignment")
// 	Args.[HwyAssn Converge] = As("double",{0.0001},"TransCad MMA assignment - convergence criteria for all but final assignment")

// 	return(Args)
// endmacro
/*

*/

Macro "Initial Processing" (Args)
    RunMacro("Build_Networks", Args)
    RunMacro("Area_Type", Args)
    RunMacro("CapSpd", Args)
    RunMacro("RouteSystemSetUp", Args)
    return(1)
endmacro

Macro "Skimming" (Args)

    first_iter = if Args.[Current Feedback Iter] = 1
        then "true"
        else "false"

    if first_iter then do
        RunMacro("HwySkim_Free", Args)
        RunMacro("Prepare_Transit_Files", Args)
    end
    RunMacro("HwySkim_Peak", Args)
    RunMacro("FillParkCost", Args)
    RunMacro("AutoSkims_Free", Args)
    RunMacro("AutoSkims_Peak", Args)
    if first_iter then RunMacro("Reg_NonMotorized", Args)
    RunMacro("Reg_PPrmW", Args)
    RunMacro("Reg_PPrmD", Args)
    RunMacro("Reg_PPrmDrop", Args)
    RunMacro("Reg_PBusW", Args)
    RunMacro("Reg_PBusD", Args)
    RunMacro("Reg_PBusDrop", Args)
    if first_iter then do
        RunMacro("Reg_OPPrmW", Args)
        RunMacro("Reg_OPPrmD", Args)
        RunMacro("Reg_OPPrmDrop", Args)
        RunMacro("Reg_OPBusW", Args)
        RunMacro("Reg_OPBusD", Args)
        RunMacro("Reg_OPBusDrop", Args)
    end
    return(1)
endmacro

Macro "Trip Generation" (Args)
    if Args.[Current Feedback Iter] > 1 then 
        return(1)
    
    RunMacro("ExtStaforTripGen", Args)
    RunMacro("HHMET", Args)
    RunMacro("Tour_Accessibility", Args)
    RunMacro("Tour_XX", Args)
    RunMacro("Tour_Frequency", Args)
    return(1)
endmacro

Macro "Trip Distribution" (Args)
    RunMacro("TD_TranPath_Peak", Args)
    RunMacro("TD_TranPath_Free", Args)
    RunMacro("Tour_DestinationChoice", Args)
    return(1)
endmacro

Macro "Trucks" (Args)
    RunMacro("Tour_TruckTGTD", Args)
    return(1)
endmacro

Macro "Mode Split" (Args)
    RunMacro("Tour_ToD1", Args)
    RunMacro("Tour Mode Split", Args)

    return(1)
endmacro

Macro "Intermediate Stops"(Args)
    RunMacro("Tour_IS", Args)
    RunMacro("Tour_IS_Location", Args)

    return(1)
endmacro


Macro "Create OD"(Args)
    // Assign forward and return TOD (AM, MD, PM, NT) to each tour
    RunMacro("Tour TOD Combinations", Args)

    // Create purpose specific trip file and purpose specific TOD (AM, MD, PM, NT) matrices
    RunMacro("Create Trips", Args)

    // Create IX/XI matrices by time period directly from dc tour file(s)
    RunMacro("Create IE EI OD", Args)

    // Combine all purposes, IE/EI, Truck and Commercial data to create OD for AMPeak time period
    RunMacro("Create Highway OD", Args, "AM")

    return(1)
endMacro


Macro "Peak Highway Assignment" (Args)
    RunMacro("HwyAssn_RunAMPeak", Args)    
    return(1)
endmacro


Macro "Convergence" (Args)
    curiter = Args.[Current Feedback Iter]
	maxiter = Args.[Feedback Iterations]
    if curiter < maxiter then do
        converged = 0
        RunMacro("Feedback_TravelTime", Args)    
        Args.[Current Feedback Iter] = Args.[Current Feedback Iter] + 1
    end else converged = 1
    return(converged + 1)
endmacro


Macro "Post Feedback" (Args)
    RunMacro("Create Highway OD", Args, "PM")
    RunMacro("HwyAssn_RunPMPeak", Args)
    
    RunMacro("Create Highway OD", Args, "MD")
    RunMacro("HwyAssn_RunMidday", Args)

    RunMacro("Create Highway OD", Args, "NT")
    RunMacro("HwyAssn_RunNight", Args)
    return(1)
endmacro


Macro "Transit Assignment" (Args)
    RunMacro("Transit_Input", Args)
    RunMacro("PPrmW_Assign", Args)
    RunMacro("PPrmD_Assign", Args)
    RunMacro("PPrmDrop_Assign", Args)
    RunMacro("PBusW_Assign", Args)
    RunMacro("PBusD_Assign", Args)
    RunMacro("PBusDrop_Assign", Args)
    RunMacro("OPPrmW_Assign", Args)
    RunMacro("OPPrmD_Assign", Args)
    RunMacro("OPPrmDrop_Assign", Args)
    RunMacro("OPBusW_Assign", Args)
    RunMacro("OPBusD_Assign", Args)
    RunMacro("OPBusDrop_Assign", Args)
    return(1)
endmacro

Macro "HOT" (Args)
    RunMacro("HwyAssn_RunHOTAMPeak", Args)
    RunMacro("HwyAssn_RunHOTPMPeak", Args)
    RunMacro("HwyAssn_RunHOTMidday", Args)
    RunMacro("HwyAssn_RunHOTNight", Args)
    RunMacro("HwyAssn_RunHOTTotAssn", Args)
    return(1)
endmacro


Macro "Summaries" (Args)
    RunMacro("ODMatrixStats", Args)
    RunMacro("VMTAQ", Args)
    RunMacro("AvgTripLenTrips_tour", Args)
    RunMacro("MSMatrixStats", Args)
    RunMacro("HighwayCalibrationStats", Args)
    RunMacro("Tour_RunStats", Args)
    RunMacro("Transit_Pax_Stats", Args)
    RunMacro("Transit_Operations_Stats", Args)
    RunMacro("Transit_Boardings", Args)
    RunMacro("Transit_RunStats", Args)
    RunMacro("Other Summaries", Args)
    RunMacro("Destroy Progress Bars", Args)
    return(1)
endmacro

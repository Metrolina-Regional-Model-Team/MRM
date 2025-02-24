rem parameters for mode choice mode:
rem      1 - file name for control file
rem
rem parameters for calibms:
rem      1 - file name for most recent control file
rem      2 - file name for next control file to test
rem      3 - output print file showing results for this iteration
rem      4 - (optional) parameter showing sensitivity for formula-based adj.
rem      5 - (optional) file name for previous iteration print file
rem              used for developing interpolated adjustments
rem
rem
 
rem ***  PEAK OAR1  *********************************************************
if exist ALT_DIR\ModeSplit\PURPPERIODINC.MC DEL ALT_DIR\ModeSplit\PURPPERIODINC.MC
ModeChoice_DIR\ModeChoice ALT_DIR\ModeSplit\Inputs\Controls\ALTNAME_HBW_OFFPEAK.CTL
echo "Done" > ALT_DIR\ModeSplit\PURPPERIODINC.MC
exit

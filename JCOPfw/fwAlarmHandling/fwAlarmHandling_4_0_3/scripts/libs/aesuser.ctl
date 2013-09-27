/**
  Main initialisation routine. 
  @param none
  @author Martin Pallesch
  @version 1.0
  @return nothing
*/
void invokedAESUserFunc( string shapeName, int screenType, int tabType, int row, int column, string value, mapping mTableRow )
{
  bool isGranted;
  int position;
  string columnName, userName;
  dyn_uint columnIds;
  dyn_string columnNames, accessRights, exceptionInfo;
  
//  DebugN("invokedAESUserFunc() - shape=" + shapeName + " column=" + column + " row=" + row );
  
  fwAlarmHandlingScreen_getAccessControlOptions(accessRights, exceptionInfo);
  
  dpGet("_AESConfig.tables.alertTable.columns.position", columnIds,
        "_AESConfig.tables.alertTable.columns.name", columnNames);
  
  position = dynContains(columnIds, column);
  if(position <= 0)
    return;
  
  columnName = columnNames[position];
  if(columnName == fwAlarmHandlingScreen_COLUMN_COMMENT)
  {
    isGranted = TRUE;
    if(isFunctionDefined("fwAccessControl_isGranted"))
    {
      if(accessRights[fwAlarmHandlingScreen_ACCESS_COMMENT] != "")
        fwAccessControl_isGranted(accessRights[fwAlarmHandlingScreen_ACCESS_COMMENT], isGranted, exceptionInfo);
      else
        isGranted = TRUE;
    }
    if(!isGranted)
    {
      fwException_raise(exceptionInfo, "ERROR", "You do not have sufficient rights to comment this alarm", "");
      fwExceptionHandling_display(exceptionInfo);
      return;      
    }

    aes_insertComment(row, mTableRow);
  }
  else if(columnName == fwAlarmHandlingScreen_COLUMN_ACKNOWLEDGE)  
  {
    isGranted = TRUE;
    if(isFunctionDefined("fwAccessControl_isGranted"))
    {
      if(accessRights[fwAlarmHandlingScreen_ACCESS_ACKNOWLEDGE] != "")
        fwAccessControl_isGranted(accessRights[fwAlarmHandlingScreen_ACCESS_ACKNOWLEDGE], isGranted, exceptionInfo);
      else
        isGranted = TRUE;
    }    
    if(!isGranted)
    {
      fwException_raise(exceptionInfo, "ERROR", "You do not have sufficient rights to acknowledge this alarm", "");
      fwExceptionHandling_display(exceptionInfo);
      return;      
    }

    aesuser_doAcknowledge(screenType, tabType, row, column, value, mTableRow);
  }
}

aesuser_doAcknowledge(string screenType, int tabType, int row, string column, string value, mapping mTableRow )
{
  const string _func_="aesuser_doAcknowledge";
  int colIdx;
  string propDpName;
  string dpid;
  bool ackable, ackOldest;

  int res=0;
  unsigned propMode, runMode;

  // get the panelglobal propDpNames ( for top/bot ) because we have no scope to g_propDp there
  aes_getTBPropDpName( tabType, propDpName );
  aes_getPropMode( propDpName, propMode );
  colIdx=aes_getColumnIndex4Name( screenType, column );

  aes_getRunMode( propDpName, runMode );
  
  ackable   =this.cellValueRC( row, _ACKABLE_ );
  ackOldest =this.cellValueRC( row, _ACK_OLD_ );

  if( propMode == AES_MODE_CLOSED && ( funcName == AECSF_DOACKNOWLEDGE ) && ackable )
  {
    aec_warningDialog( AEC_WARNINGID_ACKNOTPOSSIBLE );
    return;
  }

  res=aes_getDpidFromTable( row, dpid, mTableRow );
  if( res != 0 )
  {
    return;
  }

  if( runMode != AES_RUNMODE_RUNNING )
  {
    aec_warningDialog( AEC_WARNINGID_ACKNOTPOSINSTOP );
    return;
  }

  // call single acknowledge with row information
  if( ackable && ackOldest )
  {
    mapping mTableMultipleRows;
    //change format of mapping because ack supports multiple rows
    mTableMultipleRows[row] = mTableRow;
    aes_changedAcknowledgeWithRowData( AES_CHANGED_ACKSINGLE, tabType, mTableMultipleRows );
  }
  else if( ackable && !ackOldest )
  {
    aec_warningDialog( AEC_WARNINGID_NOTTHEOLDESTALERT );
  }
}

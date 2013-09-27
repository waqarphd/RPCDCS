// This file is generated, don't edit it!!

#if !defined(ERRHEADER_XMLExcepts)
#define ERRHEADER_XMLExcepts

#include <xercesc/util/XercesDefs.hpp>
#include <xercesc/dom/DOMError.hpp>

XERCES_CPP_NAMESPACE_BEGIN

class XMLExcepts
{
public :
    enum Codes
    {
        NoError                            = 0
      , W_LowBounds                        = 1
      , Scan_CouldNotOpenSource_Warning    = 2
      , GC_ExistingGrammar                 = 3
      , W_HighBounds                       = 4
      , F_LowBounds                        = 5
      , Array_BadIndex                     = 6
      , Array_BadNewSize                   = 7
      , AttrList_BadIndex                  = 8
      , AttDef_BadAttType                  = 9
      , AttDef_BadDefAttType               = 10
      , Bitset_BadIndex                    = 11
      , Bitset_NotEqualSize                = 12
      , BufMgr_NoMoreBuffers               = 13
      , BufMgr_BufferNotInPool             = 14
      , CPtr_PointerIsZero                 = 15
      , CM_BinOpHadUnaryType               = 16
      , CM_MustBeMixedOrChildren           = 17
      , CM_NoPCDATAHere                    = 18
      , CM_NotValidForSpecType             = 19
      , CM_UnaryOpHadBinType               = 20
      , CM_UnknownCMType                   = 21
      , CM_UnknownCMSpecType               = 22
      , CM_NoParentCSN                     = 23
      , CM_NotValidSpecTypeForNode         = 24
      , DTD_UnknownCreateReason            = 25
      , ElemStack_EmptyStack               = 26
      , ElemStack_BadIndex                 = 27
      , ElemStack_StackUnderflow           = 28
      , ElemStack_NoParentPushed           = 29
      , Enum_NoMoreElements                = 30
      , File_CouldNotOpenFile              = 31
      , File_CouldNotGetCurPos             = 32
      , File_CouldNotCloseFile             = 33
      , File_CouldNotSeekToEnd             = 34
      , File_CouldNotSeekToPos             = 35
      , File_CouldNotDupHandle             = 36
      , File_CouldNotReadFromFile          = 37
      , File_CouldNotWriteToFile           = 38
      , File_CouldNotResetFile             = 39
      , File_CouldNotGetSize               = 40
      , File_CouldNotGetBasePathName       = 41
      , File_BasePathUnderflow             = 42
      , Gen_ParseInProgress                = 43
      , Gen_NoDTDValidator                 = 44
      , Gen_CouldNotOpenDTD                = 45
      , Gen_CouldNotOpenExtEntity          = 46
      , Gen_UnexpectedEOF                  = 47
      , HshTbl_ZeroModulus                 = 48
      , HshTbl_BadHashFromKey              = 49
      , HshTbl_NoSuchKeyExists             = 50
      , Mutex_CouldNotCreate               = 51
      , Mutex_CouldNotClose                = 52
      , Mutex_CouldNotLock                 = 53
      , Mutex_CouldNotUnlock               = 54
      , Mutex_CouldNotDestroy              = 55
      , NetAcc_InternalError               = 56
      , NetAcc_LengthError                 = 57
      , NetAcc_InitFailed                  = 58
      , NetAcc_TargetResolution            = 59
      , NetAcc_CreateSocket                = 60
      , NetAcc_ConnSocket                  = 61
      , NetAcc_WriteSocket                 = 62
      , NetAcc_ReadSocket                  = 63
      , NetAcc_UnsupportedMethod           = 64
      , Pool_ElemAlreadyExists             = 65
      , Pool_BadHashFromKey                = 66
      , Pool_InvalidId                     = 67
      , Pool_ZeroModulus                   = 68
      , RdrMgr_ReaderIdNotFound            = 69
      , Reader_BadAutoEncoding             = 70
      , Reader_CouldNotDecodeFirstLine     = 71
      , Reader_NelLsepinDecl               = 72
      , Reader_EOIInMultiSeq               = 73
      , Reader_SrcOfsNotSupported          = 74
      , Reader_EncodingStrRequired         = 75
      , Scan_CouldNotOpenSource            = 76
      , Scan_UnbalancedStartEnd            = 77
      , Scan_BadPScanToken                 = 78
      , Stack_BadIndex                     = 79
      , Stack_EmptyStack                   = 80
      , Str_ZeroSizedTargetBuf             = 81
      , Str_UnknownRadix                   = 82
      , Str_TargetBufTooSmall              = 83
      , Str_StartIndexPastEnd              = 84
      , Str_ConvertOverflow                = 85
      , Strm_StdErrWriteFailure            = 86
      , Strm_StdOutWriteFailure            = 87
      , Strm_ConWriteFailure               = 88
      , StrPool_IllegalId                  = 89
      , Trans_CouldNotCreateDefCvtr        = 90
      , Trans_InvalidSizeReq               = 91
      , Trans_Unrepresentable              = 92
      , Trans_NotValidForEncoding          = 93
      , Trans_BadBlockSize                 = 94
      , Trans_BadSrcSeq                    = 95
      , Trans_BadSrcCP                     = 96
      , Trans_BadTrailingSurrogate         = 97
      , Trans_CantCreateCvtrFor            = 98
      , URL_MalformedURL                   = 99
      , URL_UnsupportedProto               = 100
      , URL_UnsupportedProto1              = 101
      , URL_OnlyLocalHost                  = 102
      , URL_NoProtocolPresent              = 103
      , URL_ExpectingTwoSlashes            = 104
      , URL_IncorrectEscapedCharRef        = 105
      , URL_UnterminatedHostComponent      = 106
      , URL_RelativeBaseURL                = 107
      , URL_BaseUnderflow                  = 108
      , URL_BadPortField                   = 109
      , UTF8_FormatError                   = 110
      , UTF8_Invalid_2BytesSeq             = 111
      , UTF8_Invalid_3BytesSeq             = 112
      , UTF8_Irregular_3BytesSeq           = 113
      , UTF8_Invalid_4BytesSeq             = 114
      , UTF8_Exceede_BytesLimit            = 115
      , Vector_BadIndex                    = 116
      , Val_InvalidElemId                  = 117
      , Val_CantHaveIntSS                  = 118
      , XMLRec_UnknownEncoding             = 119
      , Parser_Parse1                      = 120
      , Parser_Parse2                      = 121
      , Parser_Next1                       = 122
      , Parser_Next2                       = 123
      , Parser_Next3                       = 124
      , Parser_Next4                       = 125
      , Parser_Factor1                     = 126
      , Parser_Factor2                     = 127
      , Parser_Factor3                     = 128
      , Parser_Factor4                     = 129
      , Parser_Factor5                     = 130
      , Parser_Factor6                     = 131
      , Parser_Atom1                       = 132
      , Parser_Atom2                       = 133
      , Parser_Atom3                       = 134
      , Parser_Atom4                       = 135
      , Parser_Atom5                       = 136
      , Parser_CC1                         = 137
      , Parser_CC2                         = 138
      , Parser_CC3                         = 139
      , Parser_CC4                         = 140
      , Parser_CC5                         = 141
      , Parser_CC6                         = 142
      , Parser_Ope1                        = 143
      , Parser_Ope2                        = 144
      , Parser_Ope3                        = 145
      , Parser_Descape1                    = 146
      , Parser_Descape2                    = 147
      , Parser_Descape3                    = 148
      , Parser_Descape4                    = 149
      , Parser_Descape5                    = 150
      , Parser_Process1                    = 151
      , Parser_Process2                    = 152
      , Parser_Quantifier1                 = 153
      , Parser_Quantifier2                 = 154
      , Parser_Quantifier3                 = 155
      , Parser_Quantifier4                 = 156
      , Parser_Quantifier5                 = 157
      , Gen_NoSchemaValidator              = 158
      , XUTIL_UnCopyableNodeType           = 159
      , SubGrpComparator_NGR               = 160
      , FACET_Invalid_Len                  = 161
      , FACET_Invalid_maxLen               = 162
      , FACET_Invalid_minLen               = 163
      , FACET_NonNeg_Len                   = 164
      , FACET_NonNeg_maxLen                = 165
      , FACET_NonNeg_minLen                = 166
      , FACET_Len_maxLen                   = 167
      , FACET_Len_minLen                   = 168
      , FACET_maxLen_minLen                = 169
      , FACET_bool_Pattern                 = 170
      , FACET_Invalid_Tag                  = 171
      , FACET_Len_baseLen                  = 172
      , FACET_minLen_baseminLen            = 173
      , FACET_minLen_basemaxLen            = 174
      , FACET_maxLen_basemaxLen            = 175
      , FACET_maxLen_baseminLen            = 176
      , FACET_Len_baseMinLen               = 177
      , FACET_Len_baseMaxLen               = 178
      , FACET_minLen_baseLen               = 179
      , FACET_maxLen_baseLen               = 180
      , FACET_enum_base                    = 181
      , FACET_Invalid_WS                   = 182
      , FACET_WS_collapse                  = 183
      , FACET_WS_replace                   = 184
      , FACET_Invalid_MaxIncl              = 185
      , FACET_Invalid_MaxExcl              = 186
      , FACET_Invalid_MinIncl              = 187
      , FACET_Invalid_MinExcl              = 188
      , FACET_Invalid_TotalDigit           = 189
      , FACET_Invalid_FractDigit           = 190
      , FACET_PosInt_TotalDigit            = 191
      , FACET_NonNeg_FractDigit            = 192
      , FACET_max_Incl_Excl                = 193
      , FACET_min_Incl_Excl                = 194
      , FACET_maxExcl_minExcl              = 195
      , FACET_maxExcl_minIncl              = 196
      , FACET_maxIncl_minExcl              = 197
      , FACET_maxIncl_minIncl              = 198
      , FACET_TotDigit_FractDigit          = 199
      , FACET_maxIncl_base_maxExcl         = 200
      , FACET_maxIncl_base_maxIncl         = 201
      , FACET_maxIncl_base_minIncl         = 202
      , FACET_maxIncl_base_minExcl         = 203
      , FACET_maxExcl_base_maxExcl         = 204
      , FACET_maxExcl_base_maxIncl         = 205
      , FACET_maxExcl_base_minIncl         = 206
      , FACET_maxExcl_base_minExcl         = 207
      , FACET_minExcl_base_maxExcl         = 208
      , FACET_minExcl_base_maxIncl         = 209
      , FACET_minExcl_base_minIncl         = 210
      , FACET_minExcl_base_minExcl         = 211
      , FACET_minIncl_base_maxExcl         = 212
      , FACET_minIncl_base_maxIncl         = 213
      , FACET_minIncl_base_minIncl         = 214
      , FACET_minIncl_base_minExcl         = 215
      , FACET_maxIncl_notFromBase          = 216
      , FACET_maxExcl_notFromBase          = 217
      , FACET_minIncl_notFromBase          = 218
      , FACET_minExcl_notFromBase          = 219
      , FACET_totalDigit_base_totalDigit   = 220
      , FACET_fractDigit_base_totalDigit   = 221
      , FACET_fractDigit_base_fractDigit   = 222
      , FACET_maxIncl_base_fixed           = 223
      , FACET_maxExcl_base_fixed           = 224
      , FACET_minIncl_base_fixed           = 225
      , FACET_minExcl_base_fixed           = 226
      , FACET_totalDigit_base_fixed        = 227
      , FACET_fractDigit_base_fixed        = 228
      , FACET_maxLen_base_fixed            = 229
      , FACET_minLen_base_fixed            = 230
      , FACET_len_base_fixed               = 231
      , FACET_whitespace_base_fixed        = 232
      , FACET_internalError_fixed          = 233
      , FACET_List_Null_baseValidator      = 234
      , FACET_Union_Null_memberTypeValidators   = 235
      , FACET_Union_Null_baseValidator     = 236
      , FACET_Union_invalid_baseValidatorType   = 237
      , VALUE_NotMatch_Pattern             = 238
      , VALUE_Not_Base64                   = 239
      , VALUE_Not_HexBin                   = 240
      , VALUE_GT_maxLen                    = 241
      , VALUE_LT_minLen                    = 242
      , VALUE_NE_Len                       = 243
      , VALUE_NotIn_Enumeration            = 244
      , VALUE_exceed_totalDigit            = 245
      , VALUE_exceed_fractDigit            = 246
      , VALUE_exceed_maxIncl               = 247
      , VALUE_exceed_maxExcl               = 248
      , VALUE_exceed_minIncl               = 249
      , VALUE_exceed_minExcl               = 250
      , VALUE_WS_replaced                  = 251
      , VALUE_WS_collapsed                 = 252
      , VALUE_Invalid_NCName               = 253
      , VALUE_Invalid_Name                 = 254
      , VALUE_ID_Not_Unique                = 255
      , VALUE_ENTITY_Invalid               = 256
      , VALUE_QName_Invalid                = 257
      , VALUE_NOTATION_Invalid             = 258
      , VALUE_no_match_memberType          = 259
      , VALUE_URI_Malformed                = 260
      , XMLNUM_emptyString                 = 261
      , XMLNUM_WSString                    = 262
      , XMLNUM_2ManyDecPoint               = 263
      , XMLNUM_Inv_chars                   = 264
      , XMLNUM_null_ptr                    = 265
      , XMLNUM_URI_Component_Empty         = 266
      , XMLNUM_URI_Component_for_GenURI_Only   = 267
      , XMLNUM_URI_Component_Invalid_EscapeSequence   = 268
      , XMLNUM_URI_Component_Invalid_Char   = 269
      , XMLNUM_URI_Component_Set_Null      = 270
      , XMLNUM_URI_Component_Not_Conformant   = 271
      , XMLNUM_URI_No_Scheme               = 272
      , XMLNUM_URI_NullHost                = 273
      , XMLNUM_URI_NullPath                = 274
      , XMLNUM_URI_Component_inPath        = 275
      , XMLNUM_URI_PortNo_Invalid          = 276
      , XMLNUM_DBL_FLT_maxNeg              = 277
      , XMLNUM_DBL_FLT_maxPos              = 278
      , XMLNUM_DBL_FLT_minNegPos           = 279
      , XMLNUM_DBL_FLT_InvalidType         = 280
      , XMLNUM_DBL_FLT_No_Exponent         = 281
      , Regex_Result_Not_Set               = 282
      , Regex_CompactRangesError           = 283
      , Regex_MergeRangesTypeMismatch      = 284
      , Regex_SubtractRangesError          = 285
      , Regex_IntersectRangesError         = 286
      , Regex_ComplementRangesInvalidArg   = 287
      , Regex_InvalidCategoryName          = 288
      , Regex_KeywordNotFound              = 289
      , Regex_BadRefNo                     = 290
      , Regex_UnknownOption                = 291
      , Regex_UnknownTokenType             = 292
      , Regex_RangeTokenGetError           = 293
      , Regex_NotSupported                 = 294
      , Regex_InvalidChildIndex            = 295
      , Regex_RepPatMatchesZeroString      = 296
      , Regex_InvalidRepPattern            = 297
      , NEL_RepeatedCalls                  = 298
      , RethrowError                       = 299
      , Out_Of_Memory                      = 300
      , DV_InvalidOperation                = 301
      , XPath_NoAttrSelector               = 302
      , XPath_NoUnionAtStart               = 303
      , XPath_NoMultipleUnion              = 304
      , XPath_MissingAttr                  = 305
      , XPath_ExpectedToken1               = 306
      , XPath_PrefixNoURI                  = 307
      , XPath_NoDoubleColon                = 308
      , XPath_ExpectedStep1                = 309
      , XPath_ExpectedStep2                = 310
      , XPath_ExpectedStep3                = 311
      , XPath_NoForwardSlash               = 312
      , XPath_NoDoubleForwardSlash         = 313
      , XPath_NoForwardSlashAtStart        = 314
      , XPath_NoSelectionOfRoot            = 315
      , XPath_EmptyExpr                    = 316
      , XPath_NoUnionAtEnd                 = 317
      , XPath_InvalidChar                  = 318
      , XPath_TokenNotSupported            = 319
      , XPath_FindSolution                 = 320
      , DateTime_Assert_Buffer_Fail        = 321
      , DateTime_dt_missingT               = 322
      , DateTime_gDay_invalid              = 323
      , DateTime_gMth_invalid              = 324
      , DateTime_gMthDay_invalid           = 325
      , DateTime_dur_Start_dashP           = 326
      , DateTime_dur_noP                   = 327
      , DateTime_dur_DashNotFirst          = 328
      , DateTime_dur_inv_b4T               = 329
      , DateTime_dur_NoTimeAfterT          = 330
      , DateTime_dur_NoElementAtAll        = 331
      , DateTime_dur_inv_seconds           = 332
      , DateTime_date_incomplete           = 333
      , DateTime_date_invalid              = 334
      , DateTime_time_incomplete           = 335
      , DateTime_time_invalid              = 336
      , DateTime_ms_noDigit                = 337
      , DateTime_ym_incomplete             = 338
      , DateTime_ym_invalid                = 339
      , DateTime_year_tooShort             = 340
      , DateTime_year_leadingZero          = 341
      , DateTime_ym_noMonth                = 342
      , DateTime_tz_noUTCsign              = 343
      , DateTime_tz_stuffAfterZ            = 344
      , DateTime_tz_invalid                = 345
      , DateTime_year_zero                 = 346
      , DateTime_mth_invalid               = 347
      , DateTime_day_invalid               = 348
      , DateTime_hour_invalid              = 349
      , DateTime_min_invalid               = 350
      , DateTime_second_invalid            = 351
      , DateTime_tz_hh_invalid             = 352
      , PD_EmptyBase                       = 353
      , PD_NSCompat1                       = 354
      , PD_OccurRangeE                     = 355
      , PD_NameTypeOK1                     = 356
      , PD_NameTypeOK2                     = 357
      , PD_NameTypeOK3                     = 358
      , PD_NameTypeOK4                     = 359
      , PD_NameTypeOK5                     = 360
      , PD_NameTypeOK6                     = 361
      , PD_NameTypeOK7                     = 362
      , PD_RecurseAsIfGroup                = 363
      , PD_Recurse1                        = 364
      , PD_Recurse2                        = 365
      , PD_ForbiddenRes1                   = 366
      , PD_ForbiddenRes2                   = 367
      , PD_ForbiddenRes3                   = 368
      , PD_ForbiddenRes4                   = 369
      , PD_NSSubset1                       = 370
      , PD_NSSubset2                       = 371
      , PD_NSRecurseCheckCardinality1      = 372
      , PD_RecurseUnordered                = 373
      , PD_MapAndSum                       = 374
      , PD_InvalidContentType              = 375
      , NodeIDMap_GrowErr                  = 376
      , XSer_ProtoType_Null_ClassName      = 377
      , XSer_ProtoType_NameLen_Dif         = 378
      , XSer_ProtoType_Name_Dif            = 379
      , XSer_InStream_Read_LT_Req          = 380
      , XSer_InStream_Read_OverFlow        = 381
      , XSer_Storing_Violation             = 382
      , XSer_StoreBuffer_Violation         = 383
      , XSer_LoadPool_UppBnd_Exceed        = 384
      , XSer_LoadPool_NoTally_ObjCnt       = 385
      , XSer_Loading_Violation             = 386
      , XSer_LoadBuffer_Violation          = 387
      , XSer_Inv_ClassIndex                = 388
      , XSer_Inv_FillBuffer_Size           = 389
      , XSer_Inv_checkFillBuffer_Size      = 390
      , XSer_Inv_checkFlushBuffer_Size     = 391
      , XSer_Inv_Null_Pointer              = 392
      , XSer_Inv_Buffer_Len                = 393
      , XSer_CreateObject_Fail             = 394
      , XSer_ObjCount_UppBnd_Exceed        = 395
      , XSer_GrammarPool_Locked            = 396
      , XSer_GrammarPool_Empty             = 397
      , XSer_GrammarPool_NotEmpty          = 398
      , XSer_StringPool_NotEmpty           = 399
      , XSer_BinaryData_Version_NotSupported   = 400
      , F_HighBounds                       = 401
      , E_LowBounds                        = 402
      , E_HighBounds                       = 403
    };


private:
    // -----------------------------------------------------------------------
    //  Unimplemented constructors and operators
    // -----------------------------------------------------------------------
    XMLExcepts();
};

XERCES_CPP_NAMESPACE_END

#endif


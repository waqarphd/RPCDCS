main()
{

  dpConnect("functionCB13", "AnalogDigital/VertexCooling_1.outValue");
  dpConnect("functionCB14", "AnalogDigital/VertexCooling_2.outValue");
  dpConnect("functionCB15", "AnalogDigital/VertexCooling_3.outValue");
  dpConnect("functionCB16", "AnalogDigital/VertexCooling_4.outValue");

  dpConnect("functionCB17", "AnalogDigital/VertexHV_1.outValue");
  dpConnect("functionCB18", "AnalogDigital/VertexHV_2.outValue");
  dpConnect("functionCB19", "AnalogDigital/VertexHV_3.outValue");
  dpConnect("functionCB20", "AnalogDigital/VertexHV_4.outValue");

  dpConnect("functionCB21", "AnalogDigital/VertexLV_1.outValue");
  dpConnect("functionCB22", "AnalogDigital/VertexLV_2.outValue");
  dpConnect("functionCB23", "AnalogDigital/VertexLV_3.outValue");
  dpConnect("functionCB24", "AnalogDigital/VertexLV_4.outValue");
  dpConnect("functionCB25", "AnalogDigital/VertexLV_5.outValue");

/////FC 12/06/2006

  dpConnect("functionCB26", "AnalogDigital/TrackerCooling_1.outValue");
  dpConnect("functionCB27", "AnalogDigital/TrackerCooling_2.outValue");
  dpConnect("functionCB28", "AnalogDigital/TrackerCooling_3.outValue");
  dpConnect("functionCB29", "AnalogDigital/TrackerCooling_4.outValue");

  dpConnect("functionCB30", "AnalogDigital/TrackerHV_1.outValue");
  dpConnect("functionCB31", "AnalogDigital/TrackerHV_2.outValue");
  dpConnect("functionCB32", "AnalogDigital/TrackerHV_3.outValue");
  dpConnect("functionCB33", "AnalogDigital/TrackerHV_4.outValue");

  dpConnect("functionCB34", "AnalogDigital/TrackerLV_1.outValue");
  dpConnect("functionCB35", "AnalogDigital/TrackerLV_2.outValue");
  dpConnect("functionCB36", "AnalogDigital/TrackerLV_3.outValue");
  dpConnect("functionCB37", "AnalogDigital/TrackerLV_4.outValue");
  dpConnect("functionCB38", "AnalogDigital/TrackerLV_5.outValue");

}

/////FVR 28/02/2006

void functionCB13(string dpe, float val)
{
     delay(2);  
     dpSet("AnalogDigital/VertexCooling_1.inValue", val);

}

void functionCB14(string dpe, float val)
{
     delay(2);  
     dpSet("AnalogDigital/VertexCooling_2.inValue", val);

}


void functionCB15(string dpe, float val)
{
     delay(2);  
     dpSet("AnalogDigital/VertexCooling_3.inValue", val);

}


void functionCB16(string dpe, float val)
{
     delay(2);  
     dpSet("AnalogDigital/VertexCooling_4.inValue", val);

}



void functionCB17(string dpe, float val)
{
     delay(5);  
     dpSet("AnalogDigital/VertexHV_1.inValue", val);

}



void functionCB18(string dpe, float val)
{
     delay(5);  
     dpSet("AnalogDigital/VertexHV_2.inValue", val);

}



void functionCB19(string dpe, float val)
{
     delay(5);  
     dpSet("AnalogDigital/VertexHV_3.inValue", val);

}



void functionCB20(string dpe, float val)
{
     delay(5);  
     dpSet("AnalogDigital/VertexHV_4.inValue", val);

}



void functionCB21(string dpe, float val)
{
     delay(4);  
     dpSet("AnalogDigital/VertexLV_1.inValue", val);

}

void functionCB22(string dpe, float val)
{
     delay(4);  
     dpSet("AnalogDigital/VertexLV_2.inValue", val);

}

void functionCB23(string dpe, float val)
{
     delay(4);  
     dpSet("AnalogDigital/VertexLV_3.inValue", val);

}

void functionCB24(string dpe, float val)
{
     delay(4);  
     dpSet("AnalogDigital/VertexLV_4.inValue", val);

}

void functionCB25(string dpe, float val)
{
     delay(4);  
     dpSet("AnalogDigital/VertexLV_5.inValue", val);

}

/////FC 12/06/2006

void functionCB26(string dpe, float val)
{
     delay(2);  
     dpSet("AnalogDigital/TrackerCooling_1.inValue", val);

}

void functionCB27(string dpe, float val)
{
     delay(2);  
     dpSet("AnalogDigital/TrackerCooling_2.inValue", val);

}


void functionCB28(string dpe, float val)
{
     delay(2);  
     dpSet("AnalogDigital/TrackerCooling_3.inValue", val);

}


void functionCB29(string dpe, float val)
{
     delay(2);  
     dpSet("AnalogDigital/TrackerCooling_4.inValue", val);

}



void functionCB30(string dpe, float val)
{
     delay(5);  
     dpSet("AnalogDigital/TrackerHV_1.inValue", val);

}



void functionCB31(string dpe, float val)
{
     delay(5);  
     dpSet("AnalogDigital/TrackerHV_2.inValue", val);

}



void functionCB32(string dpe, float val)
{
     delay(5);  
     dpSet("AnalogDigital/TrackerHV_3.inValue", val);

}



void functionCB33(string dpe, float val)
{
     delay(5);  
     dpSet("AnalogDigital/TrackerHV_4.inValue", val);

}



void functionCB34(string dpe, float val)
{
     delay(4);  
     dpSet("AnalogDigital/TrackerLV_1.inValue", val);

}

void functionCB35(string dpe, float val)
{
     delay(4);  
     dpSet("AnalogDigital/TrackerLV_2.inValue", val);

}

void functionCB36(string dpe, float val)
{
     delay(4);  
     dpSet("AnalogDigital/TrackerLV_3.inValue", val);

}

void functionCB37(string dpe, float val)
{
     delay(4);  
     dpSet("AnalogDigital/TrackerLV_4.inValue", val);

}

void functionCB38(string dpe, float val)
{
     delay(4);  
     dpSet("AnalogDigital/TrackerLV_5.inValue", val);

}


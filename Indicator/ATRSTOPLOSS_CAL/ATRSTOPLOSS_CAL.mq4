//+------------------------------------------------------------------+
//|                                              ATRSTOPLOSS_CAL.mq4 |
//|                                                        BUNYAKORN |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property strict
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots 2

#property indicator_label1 "STOPLOSS"
#property indicator_type1 DRAW_LINE
#property indicator_color1 clrLightSalmon
#property indicator_style1 STYLE_SOLID
#property indicator_width1 1

//--- indicator buffers
input int ATR_Periode = 14;
input double psar_step = 0.01;
double         STOPLOSSBuffer[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,STOPLOSSBuffer);
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
   
  {
//---
   int uncalculatedBar = rates_total - prev_calculated;
   
   for (int i = 0; i < uncalculatedBar; i++) {
      double periode_ATR = iATR(Symbol(),PERIOD_CURRENT,ATR_Periode,1);
      double periode_low = iLow(Symbol(),PERIOD_CURRENT,1);
      double periode_high = iHigh(Symbol(),PERIOD_CURRENT,1);
      double close_periode1bar = iClose(Symbol(),PERIOD_CURRENT,1);
      double last_psar = iSAR(Symbol(),PERIOD_CURRENT,psar_step,0.2,1); 
      // Buy condition
      if (close_periode1bar > last_psar){
         STOPLOSSBuffer[i] = periode_low - periode_ATR;
      }
      else {
         STOPLOSSBuffer[i] = periode_high + periode_ATR;
      }
   }
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+

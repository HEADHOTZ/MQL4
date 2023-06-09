//+------------------------------------------------------------------+
//|                                                 ATRSTOPLOSS1.mq4 |
//|                                                        BUNYAKORN |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
// ทำให้ indicator เป็นแบบ EA แค่ไม่ต้องเปิดออเดอร์อัตโนมัติ แต่ช่วยเหลือในการเทรดให้สะดวกเหมือนมี EA
#property strict
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots 2
// plot line
#property indicator_label1 "STOPLOSS"
#property indicator_type1 DRAW_LINE
#property indicator_color1 clrLightSalmon
#property indicator_style1 STYLE_SOLID
#property indicator_width1 1

#property indicator_label2 "ENTRY"
#property indicator_type2 DRAW_LINE
#property indicator_color2 clrWhite
#property indicator_style2 STYLE_SOLID
#property indicator_width2 1

#property indicator_label3 "TP"
#property indicator_type3 DRAW_LINE
#property indicator_color3 clrGold
#property indicator_style3 STYLE_SOLID
#property indicator_width3 1

//--- indicator buffers
input double TP = 1;
input int ATR_Periode = 14;
input double periode_ema = 200;
input double psar_step = 0.01;

double STOPLOSSBuffer[];
double ENTRYBuffer[];
double TPBuffer[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,STOPLOSSBuffer);
   SetIndexBuffer(1,ENTRYBuffer);
   SetIndexBuffer(2,TPBuffer);
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

   for(int i = 0; i < uncalculatedBar; i++)
     {
      double periode_ATR = iATR(Symbol(),PERIOD_CURRENT,ATR_Periode,1);
      double periode_low = iLow(Symbol(),PERIOD_CURRENT,1);
      double periode_high = iHigh(Symbol(),PERIOD_CURRENT,1);
      double close_periode1bar = iClose(Symbol(),PERIOD_CURRENT,1);
      double ema = iMA(Symbol(),PERIOD_CURRENT,periode_ema,0,MODE_EMA,PRICE_CLOSE,1);
      double last_psar = iSAR(Symbol(),PERIOD_CURRENT,psar_step,0.2,1);
      ENTRYBuffer[i] = iClose(Symbol(),PERIOD_CURRENT,1);
      STOPLOSSBuffer[i] = periode_low - periode_ATR;
      TPBuffer[i] = (ENTRYBuffer[i] - STOPLOSSBuffer[i]) * TP;
      /*
      // Buy condition
      if (close_periode1bar > last_psar && close_periode1bar > ema){
         ENTRYBuffer[i] = close_periode1bar;
         STOPLOSSBuffer[i] = periode_low - periode_ATR;
         TPBuffer[i] = (ENTRYBuffer[i] - STOPLOSSBuffer[i]) * TP;
      }
      // Sell condition
      else if (close_periode1bar < last_psar && close_periode1bar < ema) {
         ENTRYBuffer[i] = close_periode1bar;
         STOPLOSSBuffer[i] = periode_high + periode_ATR;
         TPBuffer[i] = (STOPLOSSBuffer[i] - ENTRYBuffer[i]) * TP;
      }*/
     }
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+

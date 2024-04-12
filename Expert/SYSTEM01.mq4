//+------------------------------------------------------------------+
//|                                                     SYSTEM01.mq4 |
//|                                                        BUNYAKORN |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property strict

//--- indicator buffers
input double day = 1;
input double Risk = 1;
input double TP = 1;
input double psar_step = 0.01;
input int periode_ema = 200;
input int ATR_Periode = 14;
input bool USE_ACCOUNTBALANCE = false;
input int MONEY = 10000;

double         SLBuffer[];
double         ENBuffer[];
double         TPBuffer[];

double Lots_Buy,Lots_Sell;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,SLBuffer);
   SetIndexBuffer(1,ENBuffer);
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
   
   for (int i = 0; i < uncalculatedBar; i++) {
      double periode_ATR = iATR(Symbol(),PERIOD_CURRENT,ATR_Periode,day);
      double periode_low = iLow(Symbol(),PERIOD_CURRENT,day);
      double periode_high = iHigh(Symbol(),PERIOD_CURRENT,day);
      double close_periode1bar = iClose(Symbol(),PERIOD_CURRENT,day);
      double last_psar = iSAR(Symbol(),PERIOD_CURRENT,psar_step,0.2,day); 
      double ema = iMA(Symbol(),PERIOD_CURRENT,periode_ema,0,MODE_EMA,PRICE_CLOSE,day);
      
      double sl_buy = (periode_low - periode_ATR);
      double sl_sell = (periode_ATR + periode_high);
      
      double diff_buy = (close_periode1bar - sl_buy) / _Point;
      double diff_sell = ((sl_sell - close_periode1bar) / _Point);
      double tp_buy = (close_periode1bar - sl_buy) * TP;  
      double tp_sell = ((sl_sell - close_periode1bar) * TP);
      
      if (USE_ACCOUNTBALANCE == true) {
         double Risk_Amount = AccountBalance() * (Risk / 100);
         Lots_Buy = Risk_Amount / diff_buy;
         Lots_Sell = Risk_Amount / diff_sell;
      }
      
      if(USE_ACCOUNTBALANCE == true && Symbol() == "XAUUSD") {
         double Risk_Amount = AccountBalance() * (Risk / 100);
         Lots_Buy = Risk_Amount / ((close_periode1bar - sl_buy) * 100);
         Lots_Sell = Risk_Amount / ((sl_sell - close_periode1bar) * 100);
   
      }
      
      if(USE_ACCOUNTBALANCE == true && Symbol() == "XAGUSD") {
         double Risk_Amount = AccountBalance() * (Risk / 100);
         Lots_Buy = Risk_Amount / ((close_periode1bar - sl_buy) * 5000);
         Lots_Sell = Risk_Amount / ((sl_sell - close_periode1bar) * 5000);
   
      }
      
      if(USE_ACCOUNTBALANCE == false) {
         double Risk_Amount = MONEY * (Risk / 100);
         Lots_Buy = Risk_Amount / diff_buy;
         Lots_Sell = Risk_Amount / diff_sell;
      }
      
      if(USE_ACCOUNTBALANCE == false && Symbol() == "XAUUSD") {
         double Risk_Amount = MONEY * (Risk / 100);
         Lots_Buy = Risk_Amount / ((close_periode1bar - sl_buy) * 100);
         Lots_Sell = Risk_Amount / ((sl_sell - close_periode1bar) * 100);
      }
      
      if(USE_ACCOUNTBALANCE == false && Symbol() == "XAGUSD") {
         double Risk_Amount = MONEY * (Risk / 100);
         Lots_Buy = Risk_Amount / ((close_periode1bar - sl_buy) * 5000);
         Lots_Sell = Risk_Amount / ((sl_sell - close_periode1bar) * 5000);
      }      
      
      // Buy condition
      if (close_periode1bar > last_psar && close_periode1bar > ema){
         ENBuffer[i] = close_periode1bar;
         SLBuffer[i] = periode_low - periode_ATR;
         TPBuffer[i] = ((ENBuffer[i] - SLBuffer[i]) * TP) + ENBuffer[i];
         
         ObjectDelete("LOTSELL");
         ObjectCreate("LOTBUY",OBJ_LABEL,0,0,0);
         ObjectSet("LOTBUY",OBJPROP_CORNER,CORNER_RIGHT_UPPER);
         ObjectSet("LOTBUY",OBJPROP_XDISTANCE,30);
         ObjectSet("LOTBUY",OBJPROP_YDISTANCE,60);
         ObjectSetText("LOTBUY","Lot Size : "+DoubleToStr(Lots_Buy,Digits),20,"Impact",Green);
      } 
      else if (close_periode1bar < last_psar && close_periode1bar < ema){
         ENBuffer[i] = close_periode1bar;
         SLBuffer[i] = periode_high + periode_ATR;
         TPBuffer[i] = ENBuffer[i] - ((SLBuffer[i] - ENBuffer[i]) *TP);
         
         ObjectDelete("LOTBUY");
         ObjectCreate("LOTSELL",OBJ_LABEL,0,0,0);
         ObjectSet("LOTSELL",OBJPROP_CORNER,CORNER_RIGHT_UPPER);
         ObjectSet("LOTSELL",OBJPROP_XDISTANCE,30);
         ObjectSet("LOTSELL",OBJPROP_YDISTANCE,60);
         ObjectSetText("LOTSELL","Lot Size : "+DoubleToStr(Lots_Sell,Digits),20,"Impact",Red);
      }
      else {
         ObjectDelete("LOTBUY");
         ObjectDelete("LOTSELL");
      }
   }
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+

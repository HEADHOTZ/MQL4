//+------------------------------------------------------------------+
//|                                           SYSTEM02_INDICATOR.mq4 |
//|                                  Copyright 2023, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property strict
//+------------------------------------------------------------------+
//| Custom indicator initialization function
input int DAY = 1;
input int MONEY = 10000;
input double RISK = 1;
input double TP = 1;
input double PSAR = 0.01;
input int BB_PERIOD = 20;
input int BB_DEVI = 2;

double lotBuy,lotSell;

double         SLBuffer[];
double         ENBuffer[];
double         TPBuffer[];
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
//| Custom indicator iteration function

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double getUpperBB(int shift)
  {
   return iBands(Symbol(),PERIOD_CURRENT,BB_PERIOD,BB_DEVI,0,PRICE_CLOSE,MODE_UPPER,shift);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double getLowerBB(int shift)
  {
   return iBands(Symbol(),PERIOD_CURRENT,BB_PERIOD,BB_DEVI,0,PRICE_CLOSE,MODE_LOWER,shift);
  }

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
   if(rates_total <= BB_PERIOD)
      return 0;

   int uncalculatedBar = rates_total - prev_calculated;

   for(int i = 0; i < uncalculatedBar; i++)
     {
      double upperBB = getUpperBB(i);
      double lowerBB = getLowerBB(i);

      double psar = iSAR(Symbol(),PERIOD_CURRENT,PSAR,0.2,DAY);
      double psar2 = iSAR(Symbol(),PERIOD_CURRENT,PSAR,0.2,DAY+1);

      double highPrice = iHigh(Symbol(),PERIOD_CURRENT,DAY);
      double lowPrice = iLow(Symbol(),PERIOD_CURRENT,DAY);

      double closePrice = iClose(Symbol(),PERIOD_CURRENT,DAY);
      double close2Price = iClose(Symbol(),PERIOD_CURRENT,DAY+1);

      double val_spread = (MarketInfo(Symbol(),MODE_SPREAD)) * _Point;

      double diffBuy = (closePrice - psar) / _Point;
      double diffSell = ((psar - closePrice) / _Point);
      double tpBuy = (closePrice - psar) * TP;
      double tpSell = ((psar - closePrice) * TP);

      double risk = MONEY * (RISK / 100);

      double contractSize = MarketInfo(Symbol(), MODE_LOTSIZE);

      if(Symbol() == "XAUUSD")
        {
         lotBuy = risk / ((closePrice - psar) * 100);
         lotSell = risk / ((psar - closePrice) * 100);
        }

      else
         if(Symbol() == "XAGUSD")
           {
            lotBuy = risk / ((closePrice - psar) * 5000);
            lotSell = risk / ((psar - closePrice) * 5000);
           }

         else
           {
            lotBuy = risk / diffBuy;
            lotSell = risk / diffSell;
           }


      if(lotBuy < MarketInfo(Symbol(),MODE_MINLOT))
         lotBuy = MarketInfo(Symbol(),MODE_MINLOT);
      if(lotSell < MarketInfo(Symbol(),MODE_MINLOT))
         lotSell = MarketInfo(Symbol(),MODE_MINLOT);

      if(lotBuy > MarketInfo(Symbol(),MODE_MAXLOT))
         lotBuy = MarketInfo(Symbol(),MODE_MAXLOT);
      if(lotSell > MarketInfo(Symbol(),MODE_MAXLOT))
         lotSell = MarketInfo(Symbol(),MODE_MAXLOT);

      if(high[i] > upperBB)
        {
         ObjectCreate(0, "HighSymbol_" + IntegerToString(i), OBJ_ARROW_UP, 0, time[i], high[i]);
         ObjectSetInteger(0, "HighSymbol_" + IntegerToString(i), OBJPROP_COLOR, clrGreen);
         ObjectSetInteger(0, "HighSymbol_" + IntegerToString(i), OBJPROP_WIDTH, 2);
        }

      if(low[i] < lowerBB)
        {
         ObjectCreate(0, "LowSymbol_" + IntegerToString(i), OBJ_ARROW_UP, 0, time[i], low[i]);
         ObjectSetInteger(0, "LowSymbol_" + IntegerToString(i), OBJPROP_COLOR, clrRed);
         ObjectSetInteger(0, "LowSymbol_" + IntegerToString(i), OBJPROP_WIDTH, 2);
        }

      // Buy condition
      if(close2Price < psar2 && closePrice > psar)
        {
         ENBuffer[i] = closePrice;
         SLBuffer[i] = psar;
         //TPBuffer[i] = ((ENBuffer[i] - SLBuffer[i]) * TP) + ENBuffer[i];
         TPBuffer[i] = ((ENBuffer[i] - (psar)) * TP) + ENBuffer[i];

         ObjectDelete("LOTSELL");
         ObjectCreate("LOTBUY",OBJ_LABEL,0,0,0);
         ObjectSet("LOTBUY",OBJPROP_CORNER,CORNER_RIGHT_UPPER);
         ObjectSet("LOTBUY",OBJPROP_XDISTANCE,30);
         ObjectSet("LOTBUY",OBJPROP_YDISTANCE,60);
         ObjectSetText("LOTBUY","Lot Size : "+DoubleToStr(lotBuy,Digits),20,"Impact",Green);
        }
      // Sell condition
      else
         if(close2Price > psar2 && closePrice < psar)
           {
            ENBuffer[i] = closePrice;
            SLBuffer[i] = psar;
            //TPBuffer[i] = ENBuffer[i] - ((SLBuffer[i] - ENBuffer[i]));
            TPBuffer[i] = ENBuffer[i] - (((psar) - ENBuffer[i]) * TP);

            ObjectDelete("LOTBUY");
            ObjectCreate("LOTSELL",OBJ_LABEL,0,0,0);
            ObjectSet("LOTSELL",OBJPROP_CORNER,CORNER_RIGHT_UPPER);
            ObjectSet("LOTSELL",OBJPROP_XDISTANCE,30);
            ObjectSet("LOTSELL",OBJPROP_YDISTANCE,60);
            ObjectSetText("LOTSELL","Lot Size : "+DoubleToStr(lotSell,Digits),20,"Impact",Red);
           }
         else
           {
            ObjectDelete("LOTBUY");
            ObjectDelete("LOTSELL");
           }
     }

//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                          PSAR+MOVINGAVERAGE1.mq4 |
//|                                                        BUNYAKORN |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "BUNYAKORN"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

input double RISK = 1;
input double TP = 1;
input double PSAR = 0.01;
input int BB_PERIOD = 20;
input bool TRALINGSTOP = false;
input bool SAFE_TP = false;
input int BB_DEVI = 2;
input int MONEY = 10000;

datetime D1;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {
//--- SETUP ZONE  ---//
   double psar = iSAR(Symbol(),PERIOD_CURRENT,PSAR,0.2,1);
   double psar2 = iSAR(Symbol(),PERIOD_CURRENT,PSAR,0.2,2);

   double bb_Uper = iBands(Symbol(),PERIOD_CURRENT,BB_PERIOD,BB_DEVI,0,PRICE_CLOSE,MODE_UPPER,1);
   double bb_Lower = iBands(Symbol(),PERIOD_CURRENT,BB_PERIOD,BB_DEVI,0,PRICE_CLOSE,MODE_LOWER,1);

   double high = iHigh(Symbol(),PERIOD_CURRENT,1);
   double low = iLow(Symbol(),PERIOD_CURRENT,1);

   double close = iClose(Symbol(),PERIOD_CURRENT,1);
   double close2 = iClose(Symbol(),PERIOD_CURRENT,2);

   static bool buyOnce = false;
   static bool sellOnce = false;

   string signal = "";

//--- ZONE  FIX   ERROR ---//
   static bool err = false;
   if((close - psar) == 0)
      err = true;
   else
      err = false;

//--- ZONE  RISK  REWARD   ---//
   double diffBuy = (close - psar) / _Point;
   double diffSell = ((psar - close) / _Point);
   double tpBuy = (close - psar) * TP;
   double tpSell = ((psar - close) * TP);

   double risk = MONEY * (RISK / 100);
   
   double contractSize = MarketInfo(Symbol(), MODE_LOTSIZE);

   if(err == false)
     {
      double lotBuy = NormalizeDouble(risk / ((close - psar) * contractSize),2);
      double lotSell = NormalizeDouble(risk / ((psar - close) * contractSize),2);

      if(lotBuy < MarketInfo(Symbol(),MODE_MINLOT))
         lotBuy = MarketInfo(Symbol(),MODE_MINLOT);
      if(lotSell < MarketInfo(Symbol(),MODE_MINLOT))
         lotSell = MarketInfo(Symbol(),MODE_MINLOT);
         
      if(lotBuy > MarketInfo(Symbol(),MODE_MAXLOT))
         lotBuy = MarketInfo(Symbol(),MODE_MAXLOT);
      if(lotSell > MarketInfo(Symbol(),MODE_MAXLOT))
         lotSell = MarketInfo(Symbol(),MODE_MAXLOT);

      //--- BUY CODITION   ---//
      if(close < psar)
         buyOnce = true;

      if(close2 < psar2 && close > psar && high < bb_Uper)
        {
         bool result = checkStateConditionBuy();
         if(result == true)
            signal = "Buy";
        }
      //--- SELL  CONDITION   ---//
      if(close > psar)
         sellOnce = true;

      if(close2 > psar2 && close < psar && low > bb_Lower)
        {
         bool result = checkStateConditionSell();
         if(result == true)
            signal = "Sell";
        }
      //--- BUY ORDER ---//
      if(signal == "Buy"  && buyOnce == true && OrdersTotal() == 0)
        {
         int ticket = OrderSend(Symbol(),OP_BUY,lotBuy,Ask,5,psar,Ask + tpBuy,NULL,0,0,clrGreen);
         buyOnce = false;
        }

      //--- SELL  ORDER ---//
      if(signal == "Sell" && sellOnce == true && OrdersTotal() == 0)
        {
         int ticket = OrderSend(Symbol(),OP_SELL,lotSell,Bid,5,psar,Bid - tpSell,NULL,0,0,clrRed);
         sellOnce = false;
        }

      //--- ZONE  HELPER   ---//
      if(D1 != iTime(Symbol(),PERIOD_CURRENT,0))
        {
         if(TRALINGSTOP == true && SAFE_TP == false)
            tralingStop(psar);

         if(SAFE_TP == true && TRALINGSTOP == false)
            safeTP();

         D1 = iTime(Symbol(),PERIOD_CURRENT,0);
        }

     }   // end   if(err==false)
   /*Comment("Signal : ",signal,"\n",
           "Spread : ",MarketInfo(Symbol(),MODE_SPREAD),"\n",
           "Spread Point : ",MarketInfo(Symbol(),MODE_SPREAD) * _Point
          );*/
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool checkStateConditionBuy()
  {
   bool stateBuy = false;
   int i = 3;

   while(i < Bars - 1)
     {
      double low = iLow(Symbol(),PERIOD_CURRENT,i);
      double close = iClose(Symbol(),PERIOD_CURRENT,i);

      double psar = iSAR(Symbol(),PERIOD_CURRENT,PSAR,0.2,i);
      double bb_Lower = iBands(Symbol(),PERIOD_CURRENT,BB_PERIOD,BB_DEVI,0,PRICE_CLOSE,MODE_LOWER,i);

      if(close < psar)
        {
         if(low < bb_Lower)
            stateBuy = true;
        }
      else
         break;
      i++;
     }
   return stateBuy;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool checkStateConditionSell()
  {
   bool stateSell = false;
   int i = 3;

   while(i < Bars - 1)
     {
      double high = iHigh(Symbol(),PERIOD_CURRENT,i);
      double close = iClose(Symbol(),PERIOD_CURRENT,i);

      double psar = iSAR(Symbol(),PERIOD_CURRENT,PSAR,0.2,i);
      double bb_Upper = iBands(Symbol(),PERIOD_CURRENT,BB_PERIOD,BB_DEVI,0,PRICE_CLOSE,MODE_UPPER,i);

      if(close > psar)
        {
         if(high > bb_Upper)
            stateSell = true;
        }
      else
         break;
      i++;
     }
   return stateSell;
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void tralingStop(double psar)
  {
   for(int i = OrdersTotal() - 1; i>=0; i--)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
        {
         if(OrderSymbol() == Symbol())
           {
            if(OrderType() == OP_BUY)
              {
               if(OrderStopLoss() < psar)
                 {
                  bool modify = OrderModify(OrderTicket(),OrderOpenPrice(),psar,OrderTakeProfit(),0,CLR_NONE);
                  if(modify == false)
                     Print("Traling Stop Buy Error : ",GetLastError());
                 }
              }
            if(OrderType() == OP_SELL)
              {
               if(OrderStopLoss() > psar)
                 {
                  bool modify = OrderModify(OrderTicket(),OrderOpenPrice(),psar,OrderTakeProfit(),0,CLR_NONE);
                  if(modify == false)
                     Print("Traling Stop Sell Error : ",GetLastError());
                 }
              }
           }
        }
     }
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void safeTP()
  {
   for(int i = OrdersTotal() -1; i>=0; i--)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
        {
         if(OrderSymbol() == Symbol())
           {
            if(OrderType() == OP_BUY && OrderStopLoss() < OrderOpenPrice())
              {
               double openPrice = OrderOpenPrice();
               double stopLoss = OrderStopLoss();
               double safeTakeprofit = (openPrice - stopLoss) + openPrice;
               if(Ask >= safeTakeprofit)
                 {
                  bool modify = OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice(),OrderTakeProfit(),0,CLR_NONE);
                  if(modify == false)
                     Print("SafeTakeprofit : ",GetLastError());
                 }
              }

            if(OrderType() == OP_SELL && OrderStopLoss() > OrderOpenPrice())
              {
               double openPrice = OrderOpenPrice();
               double stopLoss = OrderStopLoss();
               //double safeTakeprofit = ((stopLoss - openPrice) - openPrice)*-1;
               double safeTakeprofit = openPrice - (stopLoss - openPrice);
               Print("Safe TP Sell : ",safeTakeprofit);
               if(Bid <= safeTakeprofit)
                 {
                  bool modify = OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice(),OrderTakeProfit(),0,CLR_NONE);
                  if(modify == false)
                     Print("SafeTakeprofit : ",GetLastError());
                 }

              }
           }
        }
     }
  }
//+------------------------------------------------------------------+

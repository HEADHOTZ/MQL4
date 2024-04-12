//+------------------------------------------------------------------+
//|                                                     SHURIKEN.mq4 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Bunyakorn K."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

input double RISK = 1;
input double TP = 1;
input bool TRALINGSTOP = false;
input int MONEY = 10000;

double lotBuy,lotSell,psar3;

datetime D1;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {
   double psar1 = iSAR(Symbol(),PERIOD_CURRENT,0.01,0.2,1);
   double psar2 = iSAR(Symbol(),PERIOD_CURRENT,0.02,0.2,1);
   psar3 = iSAR(Symbol(),PERIOD_CURRENT,0.04,0.2,1);
   double psar1Periode = iSAR(Symbol(),PERIOD_CURRENT,0.01,0.2,2);
   double psar2Periode = iSAR(Symbol(),PERIOD_CURRENT,0.02,0.2,2);
   double psar3Periode = iSAR(Symbol(),PERIOD_CURRENT,0.04,0.2,2);

   double high = iHigh(Symbol(),PERIOD_CURRENT,1);
   double low = iLow(Symbol(),PERIOD_CURRENT,1);

   double close = iClose(Symbol(),PERIOD_CURRENT,1);
   double close2 = iClose(Symbol(),PERIOD_CURRENT,2);

   static bool buyOnce = false;
   static bool sellOnce = false;

   static bool stateBuy = false;
   static bool stateSell = false;

   string signal = "";

//--- ZONE  FIX   ERROR ---//
   static bool err = false;
   if((close - psar3) == 0)
      err = true;
   else
      err = false;

//--- ZONE  RISK  REWARD   ---//
   double diffBuy = (close - psar3) / _Point;
   double diffSell = ((psar3 - close) / _Point);
   double tpBuy = (close - psar3) * TP;
   double tpSell = ((psar3 - close) * TP);

   double risk = MONEY * (RISK / 100);

   if(err == false && D1 != iTime(Symbol(),PERIOD_D1,0))
     {
      if(Symbol() == "XAUUSD")
        {
         lotBuy = risk / ((close - psar3) * 100);
         lotSell = risk / ((psar3 - close) * 100);
        }

      else
         if(Symbol() == "XAGUSD")
           {
            lotBuy = risk / ((close - psar3) * 5000);
            lotSell = risk / ((psar3 - close) * 5000);
           }

         else
           {
            lotBuy = risk / diffBuy;
            lotSell = risk / diffSell;
           }

      if(lotBuy < 0.01)
         lotBuy = 0.01;
      if(lotSell < 0.01)
         lotSell = 0.01;

      //---  Buy Condition  ---//
      if(OrdersTotal() == 0)
        {
         if(close2 < psar1Periode || close2 < psar2Periode || close2 < psar3Periode)
           {
            if(close > psar1 && close > psar2 && close > psar3)
               stateBuy = true;
           }
         else
            stateBuy = false;

         //--- Sell  Condition   ---//
         if(close2 > psar1Periode || close2 > psar2Periode || close2 > psar3Periode)
           {
            if(close < psar1 && close < psar2 && close < psar3)
               stateSell = true;
           }
         else
            stateSell = false;
        }
      //--- Open  Order ---//
      if(OrdersTotal() == 0)
        {
         //--- Buy Order   ---//
         if(stateBuy == true)
           {
            int ticket = OrderSend(Symbol(),OP_BUY,lotBuy,Ask,5,psar3,Ask + tpBuy,NULL,0,0,clrGreen);
            stateBuy = false;
           }

         //--- Sell  Order ---//
         if(stateSell == true)
           {
            int ticket = OrderSend(Symbol(),OP_SELL,lotSell,Bid,5,psar3,Bid - tpSell,NULL,0,0,clrRed);
            stateSell = false;
           }

        }  // END if(OrdersTotal() == 0)

     }   // END if(err == false)

//--- TRALING  STOP  ZONE  ---//
   if(TRALINGSTOP == true)
     {
      tralingStopBuy();
      tralingStopSell();
     }

   D1 = iTime(Symbol(),PERIOD_D1,0);

   Comment("StateBuy : ",stateBuy,"\n",
           "StateSell : ",stateSell,"\n",
           "SL : ",psar3
          );
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void tralingStopBuy()
  {
   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
        {
         if(OrderSymbol() == Symbol())
           {
            if(OrderType() == OP_BUY)
              {
               if(OrderStopLoss() < psar3)
                 {
                  bool modify = OrderModify(OrderTicket(),OrderOpenPrice(),psar3,OrderTakeProfit(),0,CLR_NONE);
                  if(modify == false)
                     Print("Traling Stop Buy Error : ",GetLastError());
                 }
              }
           }
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void tralingStopSell()
  {
   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
        {
         if(OrderSymbol() == Symbol())
           {
            if(OrderType() == OP_SELL)
              {
               if(OrderStopLoss() > psar3)
                 {
                  bool modify = OrderModify(OrderTicket(),OrderOpenPrice(),psar3,OrderTakeProfit(),0,CLR_NONE);
                  if(modify == false)
                     Print("Traling Stop Sell Error : ",GetLastError());
                 }
              }
           }
        }
     }
  }
//+------------------------------------------------------------------+

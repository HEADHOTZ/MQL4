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
input bool TRALINGSTOP = false;
input int MONEY = 10000;

double lotBuy,lotSell,psar;

datetime D1;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {
//--- SETUP ZONE  ---//
   psar = iSAR(Symbol(),PERIOD_CURRENT,PSAR,0.2,1);
   double psar2 = iSAR(Symbol(),PERIOD_CURRENT,PSAR,0.2,2);

   double high = iHigh(Symbol(),PERIOD_CURRENT,1);
   double low = iLow(Symbol(),PERIOD_CURRENT,1);

   double close = iClose(Symbol(),PERIOD_CURRENT,1);
   double close2 = iClose(Symbol(),PERIOD_CURRENT,2);

   static bool stateBuy = false;
   static bool stateSell = false;

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

   if(err == false && D1 != iTime(Symbol(),PERIOD_D1,0))
     {
      if(Symbol() == "XAUUSD")
        {
         lotBuy = risk / ((close - psar) * 100);
         lotSell = risk / ((psar - close) * 100);
        }

      else
         if(Symbol() == "XAGUSD")
           {
            lotBuy = risk / ((close - psar) * 5000);
            lotSell = risk / ((psar - close) * 5000);
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

      if(OrdersTotal() != 0)
        {
         stateBuy = false;
         stateSell = false;
        }

      //--- BUY CODITION   ---//
      if(close2 < psar2 && close > psar && OrdersTotal() == 0)
        {
         stateBuy = true;
         stateSell = false;
        }

      //--- SELL  CONDITION   ---//
      if(close2 > psar2 && close < psar && OrdersTotal() == 0)
        {
         stateSell = true;
         stateBuy = false;
        }

      //--- BUY ORDER ---//
      if(stateBuy == true && OrdersTotal() == 0)
        {
         int ticket = OrderSend(Symbol(),OP_BUY,lotBuy,Ask,5,psar,Ask + tpBuy,NULL,0,0,clrGreen);
        }

      //--- SELL  ORDER ---//
      if(stateSell == true && OrdersTotal() == 0)
        {
         int ticket = OrderSend(Symbol(),OP_SELL,lotSell,Bid,5,psar,Bid - tpSell,NULL,0,0,clrRed);
        }

      //--- TRALING  STOP  ZONE  ---//
      if(TRALINGSTOP == true)
        {
         tralingStopBuy();
         tralingStopSell();
        }
      D1 = iTime(Symbol(),PERIOD_D1,0);
      Comment("State Buy : ",stateBuy,"\n",
              "State Sell : ",stateSell,"\n",
              "Psar : ",psar);
     }   // END if(Err==false)
  }  //END OnTick

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
               if(OrderStopLoss() < psar)
                 {
                  bool modify = OrderModify(OrderTicket(),OrderOpenPrice(),psar,OrderTakeProfit(),0,CLR_NONE);
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
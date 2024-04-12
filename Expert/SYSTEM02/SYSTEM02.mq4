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
input int BB_DEVI = 2;
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

   double bb_Uper = iBands(Symbol(),PERIOD_CURRENT,BB_PERIOD,BB_DEVI,0,PRICE_CLOSE,MODE_UPPER,1);
   double bb_Lower = iBands(Symbol(),PERIOD_CURRENT,BB_PERIOD,BB_DEVI,0,PRICE_CLOSE,MODE_LOWER,1);

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

   if(err == false)
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

      //--- BUY CODITION   ---//
      if(close < psar)
         buyOnce = true;

      if(low < bb_Lower && close < psar)
        {
         stateBuy = true;
         stateSell = false;
        }

      if(close2 < psar2 && close > psar)
         signal = "Buy";

      //--- SELL  CONDITION   ---//
      if(close > psar)
         sellOnce = true;

      if(high > bb_Uper && close > psar)
        {
         stateBuy = false;
         stateSell = true;
        }

      if(close2 > psar2 && close < psar)
         signal = "Sell";

      //--- BUY ORDER ---//
      if(signal == "Buy" && stateBuy == true && buyOnce == true && OrdersTotal() == 0)     // 31/3/24 remove buyOnce == true because var is not used
        {
         int ticket = OrderSend(Symbol(),OP_BUY,lotBuy,Ask,5,psar,Ask + tpBuy,NULL,0,0,clrGreen);
         buyOnce = false;
         stateBuy = false;
        }

      //--- SELL  ORDER ---//
      if(signal == "Sell" && stateSell == true && sellOnce == true && OrdersTotal() == 0)   // 31/3/24 remove sellOnce == true because var is not used
        {
         int ticket = OrderSend(Symbol(),OP_SELL,lotSell,Bid,5,psar,Bid - tpSell,NULL,0,0,clrRed);
         sellOnce = false;
         stateSell = false;
        }

      //--- TRALING  STOP  ZONE  ---//
      if(TRALINGSTOP == true)
        {
         if(D1 != iTime(Symbol(),PERIOD_D1,0))
           {
            tralingStopBuy();
            tralingStopSell();
            D1 = iTime(Symbol(),PERIOD_D1,0);
           }
        }
     }
   Comment("StateBuy : ",stateBuy,"\n",
           "StateSell : ",stateSell,"\n",
           "Signal : ",signal
          );
  }

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

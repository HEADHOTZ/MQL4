//+------------------------------------------------------------------+
//|                                          PSAR+MOVINGAVERAGE1.mq4 |
//|                                                        BUNYAKORN |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "BUNYAKORN"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

enum ORDER_POSITION
  {
   L=0,     // Long
   S=1,     // Short
   A=2,     // ALL
  };

input double RISK = 1;
input double TP = 1;
input double PSAR = 0.01;
input int BB_PERIOD = 20;
input  ORDER_POSITION POSITION = L;
input bool TRALINGSTOP = false;
input bool SAFE_TP = false;
input int BB_DEVI = 2;
input int MONEY = 10000;

double lotBuy,lotSell,tpBuy,tpSell;

datetime D1;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {
//--- SETUP ZONE  ---//
   checkTP();
   if(D1 != iTime(Symbol(),PERIOD_CURRENT,0))
     {
      double psar = iSAR(Symbol(),PERIOD_CURRENT,PSAR,0.2,1);
      double psar2 = iSAR(Symbol(),PERIOD_CURRENT,PSAR,0.2,2);

      double bb_Uper = iBands(Symbol(),PERIOD_CURRENT,BB_PERIOD,BB_DEVI,0,PRICE_CLOSE,MODE_UPPER,1);
      double bb_Lower = iBands(Symbol(),PERIOD_CURRENT,BB_PERIOD,BB_DEVI,0,PRICE_CLOSE,MODE_LOWER,1);

      double high = iHigh(Symbol(),PERIOD_CURRENT,1);
      double low = iLow(Symbol(),PERIOD_CURRENT,1);

      double close = iClose(Symbol(),PERIOD_CURRENT,1);
      double close2 = iClose(Symbol(),PERIOD_CURRENT,2);

      double open = iOpen(Symbol(),PERIOD_CURRENT,0);

      string signal = "";

      double contractSize = MarketInfo(Symbol(), MODE_LOTSIZE);
      double spreadPoint = MarketInfo(Symbol(),MODE_SPREAD) * Point;

      //--- ZONE  FIX   ERROR ---//
      static bool err = false;
      if((close - psar) == 0)
         err = true;
      else
         err = false;

      //--- ZONE  RISK  REWARD   ---//
      double diffBuy = (close - psar) / _Point;
      double diffSell = ((psar - close) / _Point);

      tpBuy = open + ((close - psar) * TP);
      tpSell = open - ((psar - close) * TP);

      if(err == false)
        {
         double risk = MONEY * (RISK / 100);

         if(Symbol() == "XAUUSDc")
           {
            lotBuy = risk / ((close - psar) * 100);
            lotSell = risk / ((psar - close) * 100);
           }

         else
            if(Symbol() == "XAGUSDc")
              {
               lotBuy = risk / ((close - psar) * 5000);
               lotSell = risk / ((psar - close) * 5000);
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

         //--- BUY CODITION   ---//
         if(close2 < psar2 && close > psar)
           {
            bool result = checkStateConditionBuy();
            if(result == true)
               signal = "Buy";
           }
         //--- SELL  CONDITION   ---//
         if(close2 > psar2 && close < psar)
           {
            bool result = checkStateConditionSell();
            if(result == true)
               signal = "Sell";
           }
         //--- BUY ORDER ---//
         if(signal == "Buy" && NoOpenOrdersForSymbol() == true)
           {
            if(POSITION == L || POSITION == A)
              {
               int ticket = OrderSend(Symbol(),OP_BUY,lotBuy,Ask,5,psar - spreadPoint,tpBuy - spreadPoint,NULL,0,0,clrGreen);
              }
           }

         //--- SELL  ORDER ---//
         if(signal == "Sell" && NoOpenOrdersForSymbol() == true)
           {
            if(POSITION == S || POSITION == A)
              {
               int ticket = OrderSend(Symbol(),OP_SELL,lotSell,Bid,5,psar + spreadPoint,tpSell + spreadPoint,NULL,0,0,clrRed);
              }
           }

         //--- ZONE  HELPER   ---//

         if(TRALINGSTOP == true)
            tralingStop(psar);

         if(SAFE_TP == true)
            safeTP();

         D1 = iTime(Symbol(),PERIOD_CURRENT,0);
        }   // end   if(err==false)
      /*Comment("Signal : ",signal,"\n",
              "Spread : ",MarketInfo(Symbol(),MODE_SPREAD),"\n",
              "Spread Point : ",MarketInfo(Symbol(),MODE_SPREAD) * _Point
             );*/
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool NoOpenOrdersForSymbol()
  {
   for(int i = 0; i < OrdersTotal(); i++)
     {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
         if(OrderSymbol() == Symbol())
           {
            return false;  // Found an open order for the current symbol
           }
        }
     }
   return true;      // No open orders for the current symbol
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
   double contractSize = MarketInfo(Symbol(), MODE_LOTSIZE);
   double spreadSL = MarketInfo(Symbol(),MODE_SPREAD) * Point;

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
                  bool modify = OrderModify(OrderTicket(),OrderOpenPrice(),psar - spreadSL,OrderTakeProfit(),0,CLR_NONE);
                  if(modify == false)
                     Print("Traling Stop Buy Error : ",GetLastError());
                 }
              }
            if(OrderType() == OP_SELL)
              {
               if(OrderStopLoss() > psar)
                 {
                  bool modify = OrderModify(OrderTicket(),OrderOpenPrice(),psar + spreadSL,OrderTakeProfit(),0,CLR_NONE);
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

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void checkTP()
  {
   for(int i = OrdersTotal() - 1; i>=0; i--)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
        {
         if(OrderSymbol() == Symbol())
           {
            double takeProfit = OrderTakeProfit();
            double high0 = iHigh(Symbol(),PERIOD_CURRENT,0);
            double low0 = iLow(Symbol(),PERIOD_CURRENT,0);

            if(OrderType() == OP_BUY && high0 >= takeProfit)
              {
               bool modify = OrderClose(OrderTicket(),OrderLots(),Ask,5,CLR_NONE);
               if(modify == false)
                  Print("checkTP : ",GetLastError());
              }
            if(OrderType() == OP_SELL && low0 <= takeProfit)
              {
               bool modify = OrderClose(OrderTicket(),OrderLots(),Bid,5,CLR_NONE);
               if(modify == false)
                  Print("CheckTP : ",GetLastError());
              }
           }
        }
     }
  }
//+------------------------------------------------------------------+

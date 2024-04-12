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
  };

input double RISK = 1;
input double FOLLOWING = 1;
input double PSAR = 0.01;
input int BB_PERIOD = 20;
input  ORDER_POSITION POSITION = L;
input int BB_DEVI = 2;
input int MONEY = 10000;

double lotBuy,lotSell;
double followingPoint,oldLineTP,stoploss;
bool stFollow,stChangeStoploss;
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

      //---TRALING   ZONE---//
      if(OrdersTotal() == 0)
        {
         followingPoint = 0;
         stFollow = false;
         oldLineTP = false;
         stChangeStoploss = false;
        }
      else
        {
         if(D1 != iTime(Symbol(),PERIOD_CURRENT,0))
           {
            followingTakeprofit();
            D1 = iTime(Symbol(),PERIOD_CURRENT,0);
           }
        }

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
      if(signal == "Buy"  && buyOnce == true && OrdersTotal() == 0 && POSITION == L)
        {
         int ticket = OrderSend(Symbol(),OP_BUY,lotBuy,Ask,5,psar,NULL,NULL,0,0,clrGreen);
         buyOnce = false;
        }

      //--- SELL  ORDER ---//
      if(signal == "Sell" && sellOnce == true && OrdersTotal() == 0 && POSITION == S)
        {
         int ticket = OrderSend(Symbol(),OP_SELL,lotSell,Bid,5,psar,NULL,NULL,0,0,clrRed);
         sellOnce = false;
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
void followingTakeprofit()
  {
   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
        {
         if(OrderSymbol() == Symbol())
           {
            if(OrderType() == OP_BUY)
              {
               if(stChangeStoploss == false)
                 {
                  stoploss = OrderStopLoss();
                  stChangeStoploss = true;
                 }
               double diff = OrderOpenPrice() - stoploss;
               double lineTP = ((followingPoint + FOLLOWING) * diff) + OrderOpenPrice();
               double followTP = (followingPoint * diff) + OrderOpenPrice();
               double tralingLine = ((followingPoint - FOLLOWING) * diff) + OrderOpenPrice();

               if(Ask >= lineTP && stFollow == false)
                 {
                  bool modify = OrderModify(OrderTicket(),OrderOpenPrice(),followTP,OrderTakeProfit(),0,CLR_NONE);
                  if(modify == false)
                     Print("Followin TP Buy : ",GetLastError());

                  oldLineTP = lineTP;
                  followingPoint = followingPoint + FOLLOWING;
                  stFollow = true;
                 }

               if(followTP >= oldLineTP)
                  stFollow = false;
              }

            if(OrderType() == OP_SELL)
              {
               if(stChangeStoploss == false)
                 {
                  stoploss = OrderStopLoss();
                  stChangeStoploss = true;
                 }
               double diff = stoploss - OrderOpenPrice();
               double lineTP = OrderOpenPrice() - ((followingPoint + FOLLOWING) * diff);
               double followTP = OrderOpenPrice() - (followingPoint * diff);
               //double tralingLine = ((followingPoint - FOLLOWING) * diff) - OrderOpenPrice();
               double tralingLine = OrderOpenPrice() - ((followingPoint - FOLLOWING) * diff);

               if(Bid <= lineTP && stFollow == false)
                 {
                  bool modify = OrderModify(OrderTicket(),OrderOpenPrice(),followTP,OrderTakeProfit(),0,CLR_NONE);
                  if(modify == false)
                     Print("Followin TP Sell : ",GetLastError());

                  oldLineTP = lineTP;
                  followingPoint = followingPoint + FOLLOWING;
                  stFollow = true;
                 }

               if(followTP <= oldLineTP)
                  stFollow = false;
              }
           }
        }
     }
  }

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+

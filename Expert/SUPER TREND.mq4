//+------------------------------------------------------------------+
//|                                                  SUPER TREND.mq4 |
//|                                                        BUNYAKORN |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "BUNYAKORN"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
input int Nbr_Periods1 = 10;
input double Multiplier1 = 1.0;
input int Nbr_Periods2 = 11;
input double Multiplier2 = 2.0;
input int Nbr_Periods3 = 12;
input double Multiplier3 = 3.0;

input double TP = 1;
input double RISK = 1;
input bool USE_ACCOUNTBALANCE = false;
input bool TralingStop = false;
input int MONEY = 10000;
input int ATR_Periode = 14;
input double atr_multi = 1.0;

double Trend1_BufferUP,Trend1_BufferDOWN;
double Trend2_BufferUP,Trend2_BufferDOWN;
double Trend3_BufferUP,Trend3_BufferDOWN;

double close,risk_amount,lotsbuy,lotssell;

void OnTick() {
   string NewBar = "";
   NewBar = CheckForNewBarOnChart();
   
   static bool buy_once = true;
   static bool sell_once = true;
   
   string signal = "";
  
  close = iClose(Symbol(),0,1);
  
  double periode_ATR = iATR(Symbol(),PERIOD_CURRENT,ATR_Periode,1);
  double periode_high = iHigh(Symbol(),PERIOD_CURRENT,1);
  double periode_low = iLow(Symbol(),PERIOD_CURRENT,1);
  
  int ticket1,ticket2;
  
  // ZONE STOP LOSS CAL \\
  double sl_buy = (periode_low - periode_ATR);
  double sl_sell = (periode_ATR + periode_high);
  
  // ZONE TP CAL \\
  double diff_buy = (close - sl_buy) / _Point;
  double diff_sell = ((sl_sell - close) / _Point);
  double tp_buy = (close - sl_buy) * TP;  
  double tp_sell = ((sl_sell - close) * TP);
  
  // ZONE LOTSIZE CAL \\
   if (USE_ACCOUNTBALANCE == true) {
      risk_amount = AccountBalance() * (RISK / 100);
      lotsbuy = risk_amount / diff_buy;
      lotssell = risk_amount / diff_sell;
   }
   
   if(USE_ACCOUNTBALANCE == false) {
      risk_amount = MONEY * (RISK / 100);
      lotsbuy = risk_amount / diff_buy;
      lotssell = risk_amount / diff_sell;
   }
   
   // START buy_once sell_once \\
   
   // CHECK  BUY_ONCE \\
   if(Trend1_BufferUP == EMPTY_VALUE || Trend2_BufferUP == EMPTY_VALUE || Trend3_BufferUP == EMPTY_VALUE) {
     buy_once = true;
      }
   // CHECK SELL_ONCE \\
   if (Trend1_BufferDOWN == EMPTY_VALUE || Trend2_BufferDOWN == EMPTY_VALUE || Trend3_BufferDOWN == EMPTY_VALUE) {
      sell_once = true;
   }

 
  //CHECK BUY SELL \\
   {
   //CHECK BUY \\
   if(close > Trend1_BufferUP && close > Trend2_BufferUP && close > Trend3_BufferUP) {
      if(Trend1_BufferUP != EMPTY_VALUE && Trend2_BufferUP != EMPTY_VALUE && Trend3_BufferUP != EMPTY_VALUE) {
      signal = "buy";
      }
   }
   //CHECK SELL \\
   else if(close < Trend1_BufferDOWN && close < Trend2_BufferDOWN && close < Trend3_BufferDOWN) {
      if(Trend1_BufferDOWN != EMPTY_VALUE && Trend2_BufferDOWN != EMPTY_VALUE && Trend3_BufferDOWN != EMPTY_VALUE) {
         signal = "sell";
      }
   }
 }
 
   // START NORMAL ORDER \\
   
   //BUY ORDER\\
   
   if(signal == "buy" && buy_once == true) {
      ticket1 = OrderSend(_Symbol,OP_BUY,lotsbuy,Ask,3,sl_buy,Ask + tp_buy,NULL,0,0,clrGreen);
      buy_once = false;
   }
   //SELL ORDER\\
   if(signal == "sell" && sell_once == true) {
      ticket2 = OrderSend(_Symbol,OP_SELL,lotssell,Bid,3,sl_sell,Bid - tp_sell,NULL,0,0,clrOrange);
      sell_once = false;
      }
   // END OF ORDER NORMAL \\
   
   // START IF TRALING STOP USE \\
   
   // BUY CONDITION \\
   if(TralingStop == true && close > Trend3_BufferUP) {
      Use_TralingStop_Buy();
   }
   
   //SELL CONDITION \\
   if(TralingStop == true && close < Trend3_BufferDOWN) {
      Use_TralingStop_Sell();
   }
   // END IF TRALING STOP USE \\

     
  Comment("Trend1_BufferUP : ",Trend1_BufferUP,"\n",
          "Trend1_BufferDOWN : ",Trend1_BufferDOWN,"\n",
          "Trend2_BufferUP : ",Trend2_BufferUP,"\n",
          "Trend2_BufferDOWN : ",Trend2_BufferDOWN,"\n",
          "Trend3_BufferUP : ",Trend3_BufferUP,"\n",
          "Trend3_BufferDOWN : ",Trend3_BufferDOWN,"\n",
          "CLOSE : ",close,"\n",
          "BUY_ONCE : ",buy_once,"\n"
          "SELL_ONCE : ",sell_once);
}

void Use_TralingStop_Buy () {
   for(int i = OrdersTotal() - 1; i >= 0;i--) {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)) {
         if(OrderSymbol() == Symbol()) {
            if(OrderType() == OP_BUY) {
               if(OrderStopLoss() < Trend3_BufferUP) {
                  OrderModify(OrderTicket(),OrderOpenPrice(),Trend3_BufferUP,OrderTakeProfit(),0,CLR_NONE);
               }
            }
         }
      }
   }
}

void Use_TralingStop_Sell () {
   for(int i = OrdersTotal() - 1; i >= 0;i--) {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)) {
         if(OrderSymbol() == Symbol()) {
            if(OrderType() == OP_SELL) {
               if(OrderStopLoss() > Trend3_BufferDOWN) {
                  OrderModify(OrderTicket(),OrderOpenPrice(),Trend3_BufferDOWN,OrderTakeProfit(),0,CLR_NONE);
               }
            }
         }
      }
   }
}

string CheckForNewBarOnChart() {
   static int LastBars;
   string NewBarAppeared = "OLDBARS";
   if(Bars>LastBars) {
      Trend1_BufferUP = iCustom(Symbol(),0,"Super Trend 01",Nbr_Periods1,Multiplier1,0,1);
      Trend1_BufferDOWN = iCustom(Symbol(),0,"Super Trend 01",Nbr_Periods1,Multiplier1,1,1);
   
      Trend2_BufferUP = iCustom(Symbol(),0,"Super Trend 01",Nbr_Periods2,Multiplier2,0,1);
      Trend2_BufferDOWN = iCustom(Symbol(),0,"Super Trend 01",Nbr_Periods2,Multiplier2,1,1);
   
      Trend3_BufferUP = iCustom(Symbol(),0,"Super Trend 01",Nbr_Periods3,Multiplier3,0,1);
      Trend3_BufferDOWN = iCustom(Symbol(),0,"Super Trend 01",Nbr_Periods3,Multiplier3,1,1);

      NewBarAppeared = "NEWBARS";
      LastBars = Bars;
   }
   return NewBarAppeared;
}

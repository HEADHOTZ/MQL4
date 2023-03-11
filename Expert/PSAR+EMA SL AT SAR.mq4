//+------------------------------------------------------------------+
//|                                          PSAR+MOVINGAVERAGE1.mq4 |
//|                                                        BUNYAKORN |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "BUNYAKORN"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

input double TP = 1;
input double Risk = 1;
input double psar_step = 0.01;
input double periode_ema = 200;
input bool TralingStop = false;
input bool USE_ACCOUNTBALANCE = false;
input int Money = 10000;

double last_psar,last_psar2,ema;
datetime D1;

void OnTick() {
   static bool buy_once = true;
   static bool sell_once = true;
   
   double Lots_Buy,Lots_Sell,Risk_amount;
      
   string signal = "";
   string signal_order = "";
   int ticket1;
   int ticket2;
   
   double periode_high = iHigh(Symbol(),PERIOD_CURRENT,1);
   double periode_low = iLow(Symbol(),PERIOD_CURRENT,1);
   double Cur_C = iClose(Symbol(),0,1);
   double close_periode2bar = iClose(Symbol(),PERIOD_CURRENT,2);
   double open = iOpen(Symbol(),PERIOD_CURRENT,0);

   last_psar = iSAR(Symbol(),PERIOD_CURRENT,psar_step,0.2,1);
   last_psar2 = iSAR(Symbol(),PERIOD_CURRENT,psar_step,0.2,2);
   ema = iMA(Symbol(),PERIOD_CURRENT,periode_ema,0,MODE_EMA,PRICE_CLOSE,1);
   
   // START NORMAL SETUP OPEN ORDER \\
   // ZONE STOP LOSS CAL \\
   double Stoploss_Psar = last_psar;
   
   // ZONE TP CAL \\
   double diff_buy = (Cur_C - Stoploss_Psar) / _Point;
   double diff_sell = ((Stoploss_Psar - Cur_C) / _Point);
   double tp_buy = (Cur_C - Stoploss_Psar) * TP;  
   double tp_sell = ((Stoploss_Psar - Cur_C) * TP);
   
   double fix_err = Cur_C - last_psar;
   if (fix_err != 0) {
   // ZONE LOTSIZE CAL \\
   if (USE_ACCOUNTBALANCE == true) {
      Risk_amount = AccountBalance() * (Risk / 100);
      Lots_Buy = Risk_amount / diff_buy;
      Lots_Sell = Risk_amount / diff_sell;
   }
   
   if(USE_ACCOUNTBALANCE == true && Symbol() == "XAUUSD") {
      double Risk_Amount = AccountBalance() * (Risk / 100);
      Lots_Buy = Risk_Amount / ((Cur_C - Stoploss_Psar) * 100);
      Lots_Sell = Risk_Amount / ((Stoploss_Psar - Cur_C) * 100);

   }
   
   if(USE_ACCOUNTBALANCE == true && Symbol() == "XAGUSD") {
      double Risk_Amount = AccountBalance() * (Risk / 100);
      Lots_Buy = Risk_Amount / ((Cur_C - Stoploss_Psar) * 5000);
      Lots_Sell = Risk_Amount / ((Stoploss_Psar - Cur_C) * 5000);

   }
   
   if(USE_ACCOUNTBALANCE == false) {
      Risk_amount = Money * (Risk / 100);
      Lots_Buy = Risk_amount / diff_buy;
      Lots_Sell = Risk_amount / diff_sell;
   }
   
   if(USE_ACCOUNTBALANCE == false && Symbol() == "XAUUSD") {
      double Risk_Amount = Money * (Risk / 100);
      Lots_Buy = Risk_Amount / ((Cur_C - Stoploss_Psar) * 100);
      Lots_Sell = Risk_Amount / ((Stoploss_Psar - Cur_C) * 100);
   }
   
   if(USE_ACCOUNTBALANCE == false && Symbol() == "XAGUSD") {
      double Risk_Amount = Money * (Risk / 100);
      Lots_Buy = Risk_Amount / ((Cur_C - Stoploss_Psar) * 5000);
      Lots_Sell = Risk_Amount / ((Stoploss_Psar - Cur_C) * 5000);
   }
   // END NORMAL SETUP OPEN ORDER \\
   
   // START CHECK PREPARE ORDER \\
   {
   // CHECK  PREPARE BUY \\
   if(Cur_C < last_psar) {
      signal = "prepare_buy";
      buy_once = true;
      
   }
   // CHECK PREPARE SELL \\
   else if (Cur_C > last_psar) {
      signal = "prepare_sell";
      sell_once = true;
   }
 }
     
  //CHECK BUY SELL \\
   {
   //CHECK BUY \\
   if(signal == "prepare_sell" && Cur_C > last_psar && Cur_C > ema ) {
      signal_order = "buy";
   }
   //CHECK SELL \\
   else if (signal == "prepare_buy" && Cur_C < last_psar && Cur_C < ema) {
      signal_order = "sell";
   }
 }
   
   // START NORMAL ORDER \\
   
   //BUY ORDER\\
   
   if(signal_order == "buy" && buy_once == true) {
      ticket1 = OrderSend(_Symbol,OP_BUY,Lots_Buy,Ask,3,Stoploss_Psar,Ask + tp_buy,NULL,0,0,clrGreen);
      buy_once = false;
   }
   //SELL ORDER\\
   if(signal_order == "sell" && sell_once == true) {
      ticket2 = OrderSend(_Symbol,OP_SELL,Lots_Sell,Bid,3,Stoploss_Psar,Bid - tp_sell,NULL,0,0,clrOrange);
      sell_once = false;
      }
   // END OF ORDER NORMAL \\
   
   // START IF TRALING STOP USE \\
   
   // BUY CONDITION \\
   if(D1 != iTime(Symbol(),0,0)) {
      if(TralingStop == true && last_psar < Cur_C) {
         Use_TralingStop_Buy();
      }
      if(TralingStop == true && last_psar > Cur_C) {
         Use_TralingStop_Sell();
      }
      D1 = iTime(Symbol(),0,0);
   }
   // END IF TRALING STOP USE \\
     
  Comment("Signal : ",signal_order,"\n",
         "Sell_Once : ",sell_once,"\n",
         "Buy_Once : ",buy_once,"\n",
         "Risk : ",Risk_amount,"\n",
         "TP : ",TP,"\n");     
  }
}

void Use_TralingStop_Buy () { 
   for(int i = OrdersTotal() - 1; i >= 0;i--) {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)) {
         if(OrderSymbol() == Symbol()) {
            if(OrderType() == OP_BUY) {
               if(OrderStopLoss() < last_psar) {
                  OrderModify(OrderTicket(),OrderOpenPrice(),last_psar,OrderTakeProfit(),0,CLR_NONE);
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
               if(OrderStopLoss() > last_psar) {
                  OrderModify(OrderTicket(),OrderOpenPrice(),last_psar,OrderTakeProfit(),0,CLR_NONE);
               }
            }
         }
      }
   }
}

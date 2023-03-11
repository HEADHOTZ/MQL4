//+------------------------------------------------------------------+
//|                                          PSAR+MOVINGAVERAGE1.mq4 |
//|                                                        BUNYAKORN |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "BUNYAKORN"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

input double Risk = 1;
input double TP = 1;
input double psar_step = 0.01;
input double periode_ema = 200;
input int ATR_Periode = 14;
input bool TralingStop = false;
input bool USE_ACCOUNTBALANCE = false;
input int MONEY = 10000;
input double atr_multi = 1.0;

double last_psar,last_psar2,tp_safebuy,tp_safesell;
datetime D1,D1_order;

void OnTick() {   
   double Lots_Buy,Lots_Sell,Risk_Amount;
      
   string signal = "";
   string signal_order = "";
   int ticket1;
   int ticket2;
   
   double periode_high = iHigh(Symbol(),PERIOD_CURRENT,1);
   double periode_low = iLow(Symbol(),PERIOD_CURRENT,1);
   double close_periode1bar = iClose(Symbol(),PERIOD_CURRENT,1);
   double close_periode2bar = iClose(Symbol(),PERIOD_CURRENT,2);
   double open = iOpen(Symbol(),PERIOD_CURRENT,0);

   double periode_ATR = iATR(Symbol(),PERIOD_CURRENT,ATR_Periode,1);
   last_psar = iSAR(Symbol(),PERIOD_CURRENT,psar_step,0.2,0);
   last_psar2 = iSAR(Symbol(),PERIOD_CURRENT,psar_step,0.2,1);
   double ema = iMA(Symbol(),PERIOD_CURRENT,periode_ema,0,MODE_EMA,PRICE_CLOSE,1);
   
   // START NORMAL SETUP OPEN ORDER \\
   // ZONE STOP LOSS CAL \\
   double sl_buy = (periode_low - periode_ATR);
   double sl_sell = (periode_ATR + periode_high);
   
   // ZONE TP CAL \\
   double diff_buy = (close_periode1bar - sl_buy) / _Point;
   double diff_sell = ((sl_sell - close_periode1bar) / _Point);
   double tp_buy = (close_periode1bar - sl_buy) * TP;  
   double tp_sell = ((sl_sell - close_periode1bar) * TP);
   
   // ZONE LOTSIZE CAL \\
   
   if (USE_ACCOUNTBALANCE == true) {
      Risk_Amount = AccountBalance() * (Risk / 100);
      Lots_Buy = Risk_Amount / diff_buy;
      Lots_Sell = Risk_Amount / diff_sell;
   }
   
   if(USE_ACCOUNTBALANCE == true && Symbol() == "XAUUSD") {
      Risk_Amount = AccountBalance() * (Risk / 100);
      Lots_Buy = Risk_Amount / ((close_periode1bar - sl_buy) * 100);
      Lots_Sell = Risk_Amount / ((sl_sell - close_periode1bar) * 100);

   }
   
   if(USE_ACCOUNTBALANCE == true && Symbol() == "XAGUSD") {
      Risk_Amount = AccountBalance() * (Risk / 100);
      Lots_Buy = Risk_Amount / ((close_periode1bar - sl_buy) * 5000);
      Lots_Sell = Risk_Amount / ((sl_sell - close_periode1bar) * 5000);

   }
   
   if(USE_ACCOUNTBALANCE == false) {
      Risk_Amount = MONEY * (Risk / 100);
      Lots_Buy = Risk_Amount / diff_buy;
      Lots_Sell = Risk_Amount / diff_sell;
   }
   
   if(USE_ACCOUNTBALANCE == false && Symbol() == "XAUUSD") {
      Risk_Amount = MONEY * (Risk / 100);
      Lots_Buy = Risk_Amount / ((close_periode1bar - sl_buy) * 100);
      Lots_Sell = Risk_Amount / ((sl_sell - close_periode1bar) * 100);
   }
   
   if(USE_ACCOUNTBALANCE == false && Symbol() == "XAGUSD") {
      Risk_Amount = MONEY * (Risk / 100);
      Lots_Buy = Risk_Amount / ((close_periode1bar - sl_buy) * 5000);
      Lots_Sell = Risk_Amount / ((sl_sell - close_periode1bar) * 5000);
   }
   
   // END NORMAL SETUP OPEN ORDER \\
   
   // START CHECK PREPARE ORDER \\
   {
   // CHECK  PREPARE BUY \\
   if(close_periode1bar < last_psar2 ) {
      signal = "prepare_buy";
   }
   // CHECK PREPARE SELL \\
   else if (close_periode1bar > last_psar2 ) {
      signal = "prepare_sell";
   }
 }
     
  //CHECK BUY SELL \\
   {
   //CHECK BUY \\
   if(signal == "prepare_sell" && close_periode1bar > last_psar && close_periode1bar > ema ) {
      signal_order = "buy";
   }
   //CHECK SELL \\
   else if (signal == "prepare_buy" && close_periode1bar < last_psar && close_periode1bar < ema) {
      signal_order = "sell";
   }
 }
   
   // START NORMAL ORDER \\
   
   //BUY ORDER\\
   if(signal_order == "buy" && OrdersTotal() == 0) {
      if(D1_order != iTime(Symbol(),0,0)) {
         ticket1 = OrderSend(_Symbol,OP_BUY,Lots_Buy,Ask,3,sl_buy,Ask + tp_buy,NULL,0,0,clrGreen);
         }
   }
   //SELL ORDER\\
   if(signal_order == "sell" && OrdersTotal() == 0) {
      if(D1_order != iTime(Symbol(),0,0)) {
         ticket2 = OrderSend(_Symbol,OP_SELL,Lots_Sell,Bid,3,sl_sell,Bid - tp_sell,NULL,0,0,clrOrange);
         }
   }
   // END OF ORDER NORMAL \\
   
   // START IF TRALING STOP USE \\
   
   // BUY CONDITION \\
   if(D1 != iTime(Symbol(),0,0)) {
      if(TralingStop == true && last_psar2 < close_periode1bar) {
         Use_TralingStop_Buy();
      }
      if(TralingStop == true && last_psar2 > close_periode1bar) {
         Use_TralingStop_Sell();
      }
      D1 = iTime(Symbol(),0,0);
   }
   // END IF TRALING STOP USE \\
     
  Comment("Signal : ",signal_order,"\n",
         "Risk : ",Risk_Amount,"\n",
         "TP : ",TP,"\n");
              
   D1_order = iTime(Symbol(),0,0);  
}

void Use_TralingStop_Buy() {
   for(int i = OrdersTotal() - 1; i >= 0;i--) {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)) {
         if(OrderSymbol() == Symbol()) {
            if(OrderType() == OP_BUY) {
               if(OrderStopLoss() < last_psar2) {
                  OrderModify(OrderTicket(),OrderOpenPrice(),last_psar2,OrderTakeProfit(),0,CLR_NONE);
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
               if(OrderStopLoss() > last_psar2) {
                  OrderModify(OrderTicket(),OrderOpenPrice(),last_psar2,OrderTakeProfit(),0,CLR_NONE);
               }
            }
         }
      }
   }
}
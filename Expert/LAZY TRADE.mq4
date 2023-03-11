//+------------------------------------------------------------------+
//|                                                   LAZY TRADE.mq4 |
//|                                                        BUNYAKORN |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "BUNYAKORN"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

   input int Period_EMA = 10;
   input double TP = 1;
   input double Risk = 1;
   input bool USE_ACCOUNTBALANCE = false;
   
   int Money = AccountBalance();
   double Cur_C,Cur_H,Pre_H,Cur_L,Pre_L;

void OnTick() {   
   double Lots_Buy,Lots_Sell;
   static bool Prepare_Buy = true;
   static bool Prepare_Sell = true;
   
   //-INDICATOR CALL-\\
   double EMA_H = iMA(NULL,0,Period_EMA,0,MODE_EMA,PRICE_HIGH,1);
   double EMA_L = iMA(NULL,0,Period_EMA,0,MODE_EMA,PRICE_LOW,1);
   double PSAR = iSAR(NULL,0,0.01,0.2,1);
   //-----------------\\
      
   //-CANDLE CALL-\\
   Cur_C = iClose(NULL,0,1);
   Cur_H = iHigh(NULL,0,1);
   Pre_H = iHigh(NULL,0,2);
   Cur_L = iLow(NULL,0,1);
   Pre_L = iLow(NULL,0,2);
   //--------------\\
   
   //-SL CAL-\\
   double Sl_Buy = EMA_L;
   double Sl_Sell = EMA_H;
   //---------\\
   
   //-TP CAL-\\
   double TP_Buy = (Cur_C - Sl_Buy) * TP;
   double TP_Sell = (Sl_Sell - Cur_C) * TP;
   //---------\\

   //-DIFF BETWEEN OPEN && SL-\\
   double Diff_Buy = (Cur_C - Sl_Buy) / _Point;
   double Diff_Sell = (Sl_Sell - Cur_C) / _Point;
   //--------------------------\\
   
   //-PREPARE-\\
   if(Cur_C < EMA_H && OrdersTotal() == 0) {
      Prepare_Buy = true;
   }
   if(Cur_C > EMA_L && OrdersTotal() == 0) {
      Prepare_Sell = true;
   }
   //----------\\
     
   //-LOT SIZE-\\
   if(USE_ACCOUNTBALANCE == true && Symbol() != "XAUUSD" && Symbol() != "XAGUSD") {
      double Risk_Amount = AccountBalance() * (Risk / 100);
      Lots_Buy = Risk_Amount / Diff_Buy;
      Lots_Sell = Risk_Amount / Diff_Sell;
   }
   if(USE_ACCOUNTBALANCE == false && Symbol() != "XAUUSD" && Symbol() != "XAGUSD") {
      double Risk_Amount = Money * (Risk / 100);
      Lots_Buy = Risk_Amount / Diff_Buy;
      Lots_Sell = Risk_Amount / Diff_Sell;
   }
   //----------\\
   
   //-LOT GOLD-\\
    if(USE_ACCOUNTBALANCE == true && Symbol() == "XAUUSD" && Symbol() != "XAGUSD") {
      double Risk_Amount = AccountBalance() * (Risk / 100);
      Lots_Buy = Risk_Amount / ((Cur_C - Sl_Buy) * 100);
      Lots_Sell = Risk_Amount / ((Sl_Sell - Cur_C) * 100);

   }
   if(USE_ACCOUNTBALANCE == false && Symbol() == "XAUUSD" && Symbol() != "XAGUSD") {
      double Risk_Amount = Money * (Risk / 100);
      Lots_Buy = Risk_Amount / ((Cur_C - Sl_Buy) * 100);
      Lots_Sell = Risk_Amount / ((Sl_Sell - Cur_C) * 100);
   } 
   //-----------\\
   
   //-LOT SLIVER-\\
    if(USE_ACCOUNTBALANCE == true && Symbol() != "XAUUSD" && Symbol() == "XAGUSD") {
      double Risk_Amount = AccountBalance() * (Risk / 100);
      Lots_Buy = Risk_Amount / ((Cur_C - Sl_Buy) * 5000);
      Lots_Sell = Risk_Amount / ((Sl_Sell - Cur_C) * 5000);

   }
   if(USE_ACCOUNTBALANCE == false && Symbol() != "XAUUSD" && Symbol() == "XAGUSD") {
      double Risk_Amount = Money * (Risk / 100);
      Lots_Buy = Risk_Amount / ((Cur_C - Sl_Buy) * 5000);
      Lots_Sell = Risk_Amount / ((Sl_Sell - Cur_C) * 5000);
      }
   //-------------\\
   
   //-ZONE  BUY CONDITION-\\
   if(Cur_C > EMA_H && Cur_C > PSAR && OrdersTotal() == 0) {
      double ticket1 = OrderSend(_Symbol,OP_BUY,Lots_Buy,Ask,3,Sl_Buy,Ask + TP_Buy,NULL,0,0,clrGreen);
      Prepare_Buy = false;
   }
   //----------------------\\
   
    //-ZONE  SELL CONDITION-\\
   if(Cur_C < EMA_L && Cur_C < PSAR && OrdersTotal() == 0) {
      double ticket2 = OrderSend(_Symbol,OP_SELL,Lots_Sell,Bid,3,Sl_Sell,Bid - TP_Sell,NULL,0,0,clrOrange);
      Prepare_Sell = false;
   }
   //----------------------\\
   
   //-EXIT POINT-\\
   if(OrderType() == OP_BUY) {
      if(Cur_H < Pre_H && Cur_L < Pre_L) {
         Exit_Buy();
      }
   }
   if(OrderType() == OP_SELL) {
      if(Cur_H > Pre_H && Cur_L > Pre_L) {
         Exit_Sell();
      }
   }
   //-------------\\ 
   
   Comment("PREPARE BUY := ",Prepare_Buy,"\n",
           "PREPARE SELL := ",Prepare_Sell);
}

  
void Exit_Buy() {
   for(int i = OrdersTotal() - 1;i >= 0;i--) {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)) {
         if(OrderSymbol() == Symbol()) {
            OrderModify(OrderTicket(),OrderOpenPrice(),Cur_L,OrderTakeProfit(),0,clrNONE);
         }
      }
   }
 }

 void Exit_Sell() {
   for(int i = OrdersTotal() - 1;i >= 0;i--) {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)) {
         if(OrderSymbol() == Symbol()) {
            OrderModify(OrderTicket(),OrderOpenPrice(),Cur_H,OrderTakeProfit(),0,clrNONE);
         }
      }
   } 
   }
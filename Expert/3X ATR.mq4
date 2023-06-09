//+------------------------------------------------------------------+
//|                                                       3X ATR.mq4 |
//|                                                        BUNYAKORN |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "BUNYAKORN"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

input int Period_ATR = 14;
input int Period_EMA = 260;
input double TP = 1;
input double Risk = 1;
input bool USE_ACCOUNTBALANCE = false;

int Money = AccountBalance();

void OnTick() 
{
   //indy Call//
   double ATR = iATR(NULL,0,Period_ATR,1);
   double EMA = iMA(NULL,0,Period_EMA,0,MODE_EMA,PRICE_CLOSE,1);
   
   //Candle Call *เอาค่ามาจากแท่งจบที่แล้ว(1) เพราะถ้าใช้ค่า(0) มันจะใช้ค่าแท่งปัจจุบันซึ่งยังไม่จบแท่งเลย ถ้าใช้มันจะมีปัญหา//
   double Cur_H = iHigh(NULL,0,1);
   double Cur_L = iLow(NULL,0,1);
   double Cur_C = iClose(NULL,0,1);
   double Cur_O = iOpen(NULL,0,1);
   
   double Lots_Buy,Lots_Sell;
   
   double Ticket1,Ticket2,Ticket1_Safe,Ticket2_Safe;
   
   //Setting Condition to open order//
   double diff_Candle = Cur_H - Cur_L;
   double X3_ATR = 3 * ATR;
   
   //เพื่อกันปัญหาเวลาเปิดออเดอร์แล้วมันเปิดหลายครั้ง *ถ้ามันเปิดหลายครั้งอาจจะต้องมาเช็คจุดนี้//
   bool Signal = false;
   bool open_Once = true;
   
   //SL\\
   double SL = Cur_O;
   
   //TP\\
   double TP_Buy = Ask + ((Ask - SL) * TP);
   double TP_Sell = Bid - ((SL - Bid) * TP);
   
   //TP SAFE//
   double TP_Buysafe = Ask + ((Ask - SL) * 1);
   double TP_Sellsafe = Bid - ((SL - Bid) * 1);
   
   //DIFF\\
   double Diff_Buy = (Ask - SL) / _Point;
   double Diff_Sell = (SL - Bid) / _Point;
      
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
      Lots_Buy = Risk_Amount / ((Cur_C - SL) * 100);
      Lots_Sell = Risk_Amount / ((SL - Cur_C) * 100);

   }
   if(USE_ACCOUNTBALANCE == false && Symbol() == "XAUUSD" && Symbol() != "XAGUSD") {
      double Risk_Amount = Money * (Risk / 100);
      Lots_Buy = Risk_Amount / ((Cur_C - SL) * 100);
      Lots_Sell = Risk_Amount / ((SL - Cur_C) * 100);
   } 
   //-----------\\
   
   //-LOT SLIVER-\\
    if(USE_ACCOUNTBALANCE == true && Symbol() != "XAUUSD" && Symbol() == "XAGUSD") {
      double Risk_Amount = AccountBalance() * (Risk / 100);
      Lots_Buy = Risk_Amount / ((Cur_C - SL) * 5000);
      Lots_Sell = Risk_Amount / ((SL - Cur_C) * 5000);

   }
   if(USE_ACCOUNTBALANCE == false && Symbol() != "XAUUSD" && Symbol() == "XAGUSD") {
      double Risk_Amount = Money * (Risk / 100);
      Lots_Buy = Risk_Amount / ((Cur_C - SL) * 5000);
      Lots_Sell = Risk_Amount / ((SL - Cur_C) * 5000);
      }
   //-------------\\

   
   if(diff_Candle > X3_ATR) {
      Signal = true;
   }
   
   if(diff_Candle < X3_ATR) {
      Signal = false;
      open_Once = true;
   }
   
   //BUY//
   if(Signal == true && Cur_C > EMA && open_Once == true) {
      Ticket1 = OrderSend(NULL,OP_BUY,Lots_Buy,Ask,3,SL,TP_Buy,NULL,0,0,clrGreen);
      Ticket1_Safe = OrderSend(NULL,OP_BUY,Lots_Buy,Ask,3,SL,TP_Buysafe,NULL,1,0,clrGreen);
      open_Once == false;
   }
   //SELL//
   if(Signal == true && Cur_C < EMA && open_Once == true) {
      Ticket2 = OrderSend(NULL,OP_SELL,Lots_Sell,Bid,3,SL,TP_Sell,NULL,0,0,clrOrange);
      Ticket2_Safe = OrderSend(NULL,OP_SELL,Lots_Sell,Bid,3,SL,TP_Sellsafe,NULL,1,0,clrOrange);
      open_Once == false;
   }
      
   if(OrderSelect(1,SELECT_BY_TICKET,MODE_TRADES) == false) {
      Safe_Buy();
      Safe_Sell();
   }
         
   Comment("OPEN ONCE := ",open_Once,"\n",
           "SIGNAL := ",Signal,"\n",
           "OrderSelect Safe Check",OrderSelect(1,SELECT_BY_TICKET,MODE_TRADES));
}

void Safe_Buy() {
   for(int i = OrdersTotal() -1;i >= 0;i--) {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)) {
         if(OrderSymbol() == Symbol()) {
            if(OrderType() == OP_BUY) {
               OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice(),OrderTakeProfit(),0,clrNONE);
            }
         }
      }
   }
}

void Safe_Sell() {
   for(int i = OrdersTotal() -1;i >= 0;i--) {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)) {
         if(OrderSymbol() == Symbol()) {
            if(OrderType() == OP_SELL) {
               OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice(),OrderTakeProfit(),0,clrNONE);
            }
         }
      }
   }
}
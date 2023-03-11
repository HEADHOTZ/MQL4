input double Risk = 1;
input double TP = 1;
input bool TralingStop = false;
input int MONEY = 10000;

datetime date;
double upperFractal,lowerFractal,oldupperFractal,oldlowerFractal;
int ticket1,ticket2;

void OnTick()
{
   double lotBuy,lotSell,riskAmount; 
   
   upperFractal=iFractals(_Symbol,_Period,MODE_UPPER,3);
   lowerFractal=iFractals(_Symbol,_Period,MODE_LOWER,3);
   
   riskAmount = MONEY * (Risk / 100);
   
   if(upperFractal!=0 && oldlowerFractal!=0)
   {
      double diffBuy = (upperFractal - oldlowerFractal) / _Point;
      double tpBuy = (upperFractal - oldlowerFractal) * TP;
      if(Symbol() == "XAUUSD") lotBuy = riskAmount / ((upperFractal - oldlowerFractal) * 100); 
      else if(Symbol() == "XAGUSD") lotBuy = riskAmount / ((upperFractal - oldlowerFractal) * 5000); 
      else lotBuy = riskAmount / diffBuy;
      
   }
   if(lowerFractal!=0 && oldupperFractal!=0)
   {
      double diffSell = (oldupperFractal - lowerFractal) / _Point;
      double tpSell = (oldupperFractal - lowerFractal) * TP;
      if(Symbol() == "XAUUSD") lotSell = riskAmount / ((oldupperFractal - lowerFractal) * 100);
      else if(Symbol() == "XAGUSD") lotSell = riskAmount / ((oldupperFractal - lowerFractal) * 5000);
      else lotSell = riskAmount / diffSell;
   }
      
   if(oldupperFractal!=upperFractal && upperFractal!=0)
   {
      deletePendingBuyStop();
   }
   
   if(oldlowerFractal!=lowerFractal && lowerFractal!=0)
   {
      deletePendingSellStop();
   }   
   
   if(upperFractal!=0) { 
      oldupperFractal = upperFractal;
      if(date != iTime(Symbol(),0,0) && oldlowerFractal!=0) {
         if(TralingStop == true) Use_TralingStop_Buy();
         ticket1 = OrderSend(_Symbol,OP_BUYSTOP,lotBuy,upperFractal,3,oldlowerFractal,upperFractal+tpBuy,NULL,0,0,clrGreen);
         date = iTime(Symbol(),0,0);
      }
   }
   
   if(lowerFractal!=0) {
   oldlowerFractal = lowerFractal;
   if(date != iTime(Symbol(),0,0) && oldupperFractal!=0) {
      if(TralingStop == true) Use_TralingStop_Sell();
      ticket2 = OrderSend(_Symbol,OP_SELLSTOP,lotSell,lowerFractal,3,oldupperFractal,lowerFractal-tpSell,NULL,0,0,clrRed);
      date = iTime(Symbol(),0,0);
   }
   }
   
   Comment("Upper : ",upperFractal,"\n",
           "Lower : ",lowerFractal,"\n",
           "OldUpper : ",oldupperFractal,"\n",
           "OldLower : ",oldlowerFractal,"\n",
           "TP Buy : ",tpBuy,"\n",
           "TP Sell : ",tpSell
          );
};

void deletePendingBuyStop() {
   for(int i = OrdersTotal() - 1; i >= 0;i--) {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)) {
         if(OrderSymbol() == Symbol()) {
            if(OrderType() == OP_BUYSTOP) {
               OrderDelete(ticket1);
            }
         }
      }
   }
}

void deletePendingSellStop() {
   for(int i = OrdersTotal() - 1; i >= 0;i--) {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)) {
         if(OrderSymbol() == Symbol()) {
            if(OrderType() == OP_SELLSTOP) {
               OrderDelete(ticket2);
            }
         }
      }
   }
}

void Use_TralingStop_Buy() {
   for(int i = OrdersTotal() - 1; i >= 0;i--) {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)) {
         if(OrderSymbol() == Symbol()) {
            if(OrderType() == OP_BUY) {
               if(OrderStopLoss() < oldlowerFractal) {
                  OrderModify(OrderTicket(),OrderOpenPrice(),oldlowerFractal,OrderTakeProfit(),0,CLR_NONE);
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
               if(OrderStopLoss() > oldupperFractal) {
                  OrderModify(OrderTicket(),OrderOpenPrice(),oldupperFractal,OrderTakeProfit(),0,CLR_NONE);
               }
            }
         }
      }
   }
}
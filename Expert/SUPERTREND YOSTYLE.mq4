//+------------------------------------------------------------------+
//|                                           SUPERTREND YOSTYLE.mq4 |
//|                                                        BUNYAKORN |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "BUNYAKORN"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

extern int Multi = 1;

double preUpper_Band,Lower_Band,preLower_Band,Upper_Band;

void OnTick() {
   string Trend_Signal = "";
   
   double cur_H = iHigh(Symbol(),0,1);
   double cur_L = iLow(Symbol(),0,1);
   double cur_C = iClose(Symbol(),0,1);
   
   double pre_H = iHigh(Symbol(),0,2);
   double pre_L = iLow(Symbol(),0,2);
   double pre_C = iClose(Symbol(),0,2);
   
   double cur_ATR = iATR(Symbol(),0,10,1);
   double pre_ATR = iATR(Symbol(),0,10,2);
      
   double cur_Upper = ((cur_H + cur_L)/2) + (Multi * cur_ATR);
   double cur_Lower = ((cur_H + cur_L)/2) - (Multi * cur_ATR);
   
   double pre_Upper = ((pre_H + pre_L)/2) + (Multi * pre_ATR);
   double pre_Lower = ((pre_H + pre_L)/2) - (Multi * pre_ATR);
   
   // UPPER \\
   if(cur_Upper < preUpper_Band || pre_C > preUpper_Band) {
      Upper_Band = cur_Upper;
   }
   else {
      Upper_Band = preUpper_Band;
   }
   
   // LOWER \\
   if(cur_Lower > preLower_Band || pre_C < preLower_Band) {
      Lower_Band = cur_Lower;
   }
   else {
      Lower_Band = preLower_Band;
   }
   
   // SUPER TREND ZONE \\
   if(pre_Supertrend = preUpper_Band && cur_C < cur_Upper) {
      Supertrend = Upper_Band;
   }
   else if(
}


   
   
   
   
   /*// Supertend Upper //SELL\\ \\
   if(cur_Upper < pre_Upper && cur_Lower < pre_Lower) {
      if(cur_C < pre_Supertend) {
         Trend_Signal = "TREND DOWN";
         Supertend = cur_Upper;
         pre_Supertend = Supertend;
      }
   }
   
   // Supertend Lower //BUY\\ \\
   if(cur_Upper > pre_Upper && cur_Lower > pre_Lower) {
      if(cur_C > pre_Supertend) {
         Trend_Signal = "TREND UP";
         Supertend = cur_Lower;
         pre_Supertend = Supertend;
      }
   }
   else {
      Supertend = pre_Supertend;
   }
   
   Comment("CUR_UPPER : ",cur_Upper,"\n",
           "PRE_UPPER : ",pre_Upper,"\n",
           "CUR_LOWER : ",cur_Lower,"\n",
           "PRE_LOWER : ",pre_Lower,"\n",
           "   CUR_C  : ",cur_C,"\n",
           "   TREND  : ",Trend_Signal,"\n",
           "SUPERTREND : ",Supertend,"\n",
           "PRE_SUPPERTEND : ",pre_Supertend,"\n");
}

/*double Upper_Line,Lower_Line,
       preUpper_Line,preLower_Line,
       pre2Upper_Line,pre2Lower_Line,
       Final_Upper,Final_Lower,
       preFinal_Upper,preFinal_Lower,
       SUPERTREND;

void OnTick() {
   double Multi = 1;
   double ATR = iATR(Symbol(),0,10,1);
   double Pre_ATR = iATR(Symbol(),0,10,2);
   double Pre2_ATR = iATR(Symbol(),0,10,3);
   
   double Cur_C = iClose(Symbol(),0,1);
   
   double Cur_H = iHigh(Symbol(),0,1);
   double Cur_L = iLow(Symbol(),0,1);
   
   double Pre_H = iHigh(Symbol(),0,2);
   double Pre_L = iLow(Symbol(),0,2);
   double Pre2_H = iHigh(Symbol(),0,3);
   double Pre2_L = iLow(Symbol(),0,3);
   
   Upper_Line = ((Cur_H + Cur_L)/2) + (Multi * ATR);
   Lower_Line = ((Cur_H + Cur_L)/2) - (Multi * ATR);
   
   preUpper_Line = ((Pre_H + Pre_L)/2) + (Multi * Pre_ATR);
   preLower_Line = ((Pre_H + Pre_L)/2) - (Multi * Pre_ATR);
   
   pre2Upper_Line = ((Pre2_H + Pre2_L)/2) + (Multi * Pre2_ATR);
   pre2Lower_Line = ((Pre2_H + Pre2_L)/2) - (Multi * Pre2_ATR);

   
   // PRE FINAL UPPER \\
   if(preUpper_Line < preFinal_Upper) {
      preFinal_Upper = preUpper_Line;
   }
   else if(preUpper_Line > preFinal_Upper) {
      preFinal_Upper = pre2Upper_Line;
   }
   
   // PRE FINAL LOWER \\
   if(preLower_Line > preFinal_Lower) {
      preFinal_Lower = preLower_Line;
   }
   else if(preUpper_Line < preFinal_Lower) {
      preFinal_Lower = pre2Upper_Line;
   }
   
   // FINAL UPPER [Sell Condition] \\
   if(Upper_Line < preFinal_Upper) {
      Final_Upper = Upper_Line;
   }
   else if (Upper_Line > preFinal_Upper) {
      Final_Upper = preUpper_Line;
   }
   
   // FINAL LOWER [Buy Condition] \\
   if(Lower_Line > preFinal_Lower) {
      Final_Lower = Lower_Line;
   }
   else if(Lower_Line < preFinal_Lower) {
      Final_Lower = preLower_Line;
   }
   
   // SUPERTREND VALUE \\
   
   // BUY CONDITION \\
   if(Lower_Line > preLower_Line && Upper_Line > preUpper_Line) {
      SUPERTREND = Final_Lower;
   }
   else if(Upper_Line < preUpper_Line && Lower_Line < preLower_Line) {
      SUPERTREND = Final_Upper;
   }
   /*if(Cur_C >= Final_Lower) {
      SUPERTREND = Final_Lower;
   }
   else if(Cur_C <= Final_Upper) {
      SUPERTREND = Final_Upper;
   }
 
   Comment("Cur_Upper : ",Upper_Line,"\n",
           "Pre_Upper : ",preUpper_Line,"\n",
           "Cur_Lower : ",Lower_Line,"\n",
           "Pre_Lower : ",preLower_Line,"\n",
           "preFinal_UP : ",preFinal_Upper,"\n",
           "Final_UP : ",Final_Upper,"\n",
           "preFinal_LOW : ",preFinal_Lower,"\n",
           "Final_LOW : ",Final_Lower,"\n",
           "Supertrend : ",SUPERTREND,"\n",
           "CUR C/H/L : ",Cur_C,"/",Cur_H,"/",Cur_L,"\n",
           "ATR : ",ATR,"\n",
           "Pre_ATR : ",Pre_ATR);
}
*/
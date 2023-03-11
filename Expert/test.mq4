#include <Trade\Trade.mqh>

input double StopLossMultiplier = 1.0;
input double RiskPerTrade = 1.0; // risk 1% of the account balance per trade
input ENUM_MA_METHOD MovingAverageMethod = MODE_SMA;
input int MovingAveragePeriod = 14;
input double MovingAverageShift = 0.0;
input int ParabolicSARStep = 0;
input double ParabolicSARMaximum = 0.02;

int buyOrderOpened = false;
int sellOrderOpened = false;

double MovingAverage,ParabolicSAR;

int OnInit()
{
   // Set up the moving average indicator
   MovingAverage = iMA(NULL, 0, MovingAveragePeriod, MovingAverageShift, MovingAverageMethod, PRICE_CLOSE, 0);

   // Set up the Parabolic SAR indicator
   ParabolicSAR = iSAR(NULL, 0, ParabolicSARStep, ParabolicSARMaximum, 0);

   return(INIT_SUCCEEDED);
}

void OnTick()
{
   double stopLoss;
   double takeProfit;
   double atr;
   double risk;
   double tradeVolume;

   // Calculate the average true range
   atr = iATR(NULL, 0, 14, 0);

   // Calculate the risk for the trade (1% of the account balance)
   risk = AccountBalance() * RiskPerTrade / 100.0;

   // Calculate the trade volume based on the risk
   tradeVolume = risk / (atr * StopLossMultiplier);

   // Calculate the stop loss and take profit levels for the buy order
   stopLoss = Low[0] - atr * StopLossMultiplier;
   takeProfit = (stopLoss - Close[0]) * 2;

   // Check if the close price is above both the moving average and Parabolic SAR
   if (Close[0] > MovingAverage && Close[0] > ParabolicSAR && !buyOrderOpened)
   {
      // Place a buy order with a stop loss and take profit
      OrderSend(Symbol(), OP_BUY, tradeVolume, Ask, 3, stopLoss, takeProfit, "My Order", 16384, 0, Green);
      buyOrderOpened = true;
   }

   // Calculate the stop loss and take profit levels for the sell order
   stopLoss = High[0] + atr * StopLossMultiplier;
   takeProfit = (Close[0] - stopLoss) * 2;

   // Check if the close price is below both the moving average and Parabolic SAR
   if (Close[0] < MovingAverage && Close[0] < ParabolicSAR && !sellOrderOpened)
   {
      // Place a sell order with a stop loss and take profit
      OrderSend(Symbol(), OP_SELL, tradeVolume, Bid, 3, stopLoss, takeProfit, "My Order", 16384, 0, Red);
      sellOrderOpened = true;
   }
}

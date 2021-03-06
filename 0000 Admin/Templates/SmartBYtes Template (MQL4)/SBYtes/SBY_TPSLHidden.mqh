//+------------------------------------------------------------------+
//|                                               SBY_TPSLHidden.mqh |
//|                                  Copyright 2016-2017, SmartBYtes |
//|                     Hidden TP/SL Library for SmartBYtes Template |
//+------------------------------------------------------------------+

// This is the hidden TP/SL module for the SmartBYtes template. Suitable
// for 1 SL/TP level only. Deprecated due to inflexibility for multiple
// SL/TP levels. Left as a template and for simple strategies that only
// use 1 SL/TP level/pipsize.

#property copyright "Copyright 2016-2017, SmartBYtes"
#property version   "1.02"
#property link      "https://github.com/AmadeusSG/ForexTradeGroup"
#property strict
#include <SBYtes/SBY_Main.mqh>

/* 

v1.00: 
- Adapted from the Falcon template by Lucas Liew 
  (https://github.com/Lucas170/The-Falcon), 
  for hidden TP/SL settings

v1.01:
- Added new comments to describe what each template-
  defined function does
- Seperated volatility to SBY_VolTPSL.mqh

v1.02:
- Added link

TODO:
- Able to use functions to create multiple TP/SL levels

*/

//+------------------------------------------------------------------+
//| Setup                                                            |
//+------------------------------------------------------------------+

extern string  TPSLHidHeader="----------Hidden TP & SL Settings-----------"; //.

extern bool    UseHiddenStopLoss=False;   // Hidden SL?
extern double  HardSLVariable_Hidden=0;   // Stop Loss Pips

extern bool    UseHiddenTakeProfit=False; // Hidden TP?
extern double  HardTPVariable_Hidden=0;   // Take Profit Pips

//----------Service Variables-----------//

double HiddenSLList[][2]; // First dimension is for position ticket numbers, second is for the SL Levels
double HiddenTPList[][2]; // First dimension is for position ticket numbers, second is for the TP Levels

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//|                     FUNCTIONS LIBRARY                                   
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

/*

Content:
   1) SetStopLossHidden
   2) TriggerStopLossHidden
   3) SetTakeProfitHidden
   4) TriggerTakeProfitHidden

*/

//+------------------------------------------------------------------+
//| Set Hidden Stop Loss                                             |
//+------------------------------------------------------------------+
// Type: Fixed Template 
// Do not edit unless you know what you're doing

// This function calculates hidden stop loss amount and tags it to the appropriate order using an array

void SetStopLossHidden(int OrderNum, bool customswitch=false, double customSLpips=0){ 

   if(UseHiddenStopLoss){
      double StopL;
   
      StopL=HardSLVariable_Hidden; // Stop Loss = Fixed Pips Stop Loss
      if(customswitch) StopL=customSLpips; // Stop Loss in Pips (custom)
   
      for(int x=0; x<ArrayRange(HiddenSLList,0); x++) { 
         // Number of elements in column 1
         if(HiddenSLList[x,0]==0){ 
            // Checks if the element is empty
            HiddenSLList[x,0] = OrderNum;
            HiddenSLList[x,1] = StopL;
            if(OnJournaling) Print("EA Journaling: Order "+(string)HiddenSLList[x,0]+" assigned with a hidden SL of "+
                                   (string)NormalizeDouble(HiddenSLList[x,1],2)+" pips.");
            break;
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Trigger Hidden Stop Loss                                         |
//+------------------------------------------------------------------+
// Type: Fixed Template 
// Do not edit unless you know what you're doing

/* This function does two 2 things:
1) Clears appropriate elements of your HiddenSLList if positions has been closed
2) Closes positions based on its hidden stop loss levels
*/

void TriggerStopLossHidden(){

   int ordersPos=OrdersTotal();
   int orderTicketNumber;
   double orderSL;
   int doesOrderExist;

   // 1) Check the HiddenSLList, match with current list of positions. Make sure the all the positions exists. 
   // If it doesn't, it means there are positions that have been closed

   for(int x=0; x<ArrayRange(HiddenSLList,0); x++){ 
      // Looping through all order number in list
      doesOrderExist=False;
      orderTicketNumber=(int)HiddenSLList[x,0];

      if(orderTicketNumber!=0){ 
         
         // Order exists
         for(int y=ordersPos-1; y>=0; y--){ 
            // Looping through all current open positions
            if(OrderSelect(y,SELECT_BY_POS,MODE_TRADES)==true && OrderSymbol()==Symbol() && 
               OrderMagicNumber()==MagicNumber){
               if(orderTicketNumber==OrderTicket()){ 
                  // Checks order number in list against order number of current positions
                  doesOrderExist=True;
                  break;
               }
            }
         }

         if(doesOrderExist==False){ 
            // Deletes elements if the order number does not match any current positions
            HiddenSLList[x, 0] = 0;
            HiddenSLList[x, 1] = 0;
         }
      }
   }

   // 2) Check each position against its hidden SL and close the position if hidden SL is hit

   for(int z=0; z<ArrayRange(HiddenSLList,0); z++){ 
      
      // Loops through elements in the list
      orderTicketNumber=(int)HiddenSLList[z,0]; // Records order numner
      orderSL=HiddenSLList[z,1]; // Records SL

      if(OrderSelect(orderTicketNumber,SELECT_BY_TICKET)==true && OrderSymbol()==Symbol() && 
         OrderMagicNumber()==MagicNumber){
         bool Closing=false;
         if(OrderType()==OP_BUY && OrderOpenPrice() -(orderSL*P*Point)>=Bid){ 
            
            // Checks SL condition for closing long orders
            if(OnJournaling)Print("EA Journaling: Trying to close position "+(string)OrderTicket()+" ...");
            HandleTradingEnvironment();
            Closing=OrderClose(OrderTicket(),OrderLots(),Bid,(int)(Slippage*P),Blue);
            if(OnJournaling && !Closing) Print("EA Journaling: Unexpected Error has happened. Error Description: "+
                                               GetErrorDescription(GetLastError()));
            if(OnJournaling &&  Closing) Print("EA Journaling: Position successfully closed.");
         }
         if(OrderType()==OP_SELL && OrderOpenPrice()+(orderSL*P*Point)<=Ask){ 

            // Checks SL condition for closing short orders
            if(OnJournaling)Print("EA Journaling: Trying to close position "+(string)OrderTicket()+" ...");
            HandleTradingEnvironment();
            Closing=OrderClose(OrderTicket(),OrderLots(),Ask,(int)(Slippage*P),Red);
            if(OnJournaling && !Closing) Print("EA Journaling: Unexpected Error has happened. Error Description: "+
                                               GetErrorDescription(GetLastError()));
            if(OnJournaling &&  Closing) Print("EA Journaling: Position successfully closed.");
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Set Hidden Take Profit                                           |
//+------------------------------------------------------------------+
// Type: Fixed Template 
// Do not edit unless you know what you're doing

// This function calculates hidden take profit amount and tags it to the appropriate order using an array

void SetTakeProfitHidden(int OrderNum, bool customswitch=false, double customTPpips=0){

   if(UseHiddenTakeProfit){
      double TakeP;
   
      TakeP=HardTPVariable_Hidden; // Take Profit = Fixed Pips Take Profit
      if(customswitch) TakeP=customTPpips; // Take Profit in Pips (custom)
   
      for(int x=0; x<ArrayRange(HiddenTPList,0); x++){ 
         // Number of elements in column 1
         if(HiddenTPList[x,0]==0){ 
            // Checks if the element is empty
            HiddenTPList[x,0] = OrderNum;
            HiddenTPList[x,1] = TakeP;
            if(OnJournaling) Print("EA Journaling: Order "+(string)HiddenTPList[x,0]+" assigned with a hidden TP of "+
                                   (string)NormalizeDouble(HiddenTPList[x,1],2)+" pips.");
            break;
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Trigger Hidden Take Profit                                       |
//+------------------------------------------------------------------+
// Type: Fixed Template 
// Do not edit unless you know what you're doing

/* This function does two 2 things:
1) Clears appropriate elements of your HiddenTPList if positions has been closed
2) Closes positions based on its hidden take profit levels
*/

void TriggerTakeProfitHidden(){

   int ordersPos=OrdersTotal();
   int orderTicketNumber;
   double orderTP;
   int doesOrderExist;

   // 1) Check the HiddenTPList, match with current list of positions. Make sure the all the positions exists. 
   // If it doesn't, it means there are positions that have been closed

   for(int x=0; x<ArrayRange(HiddenTPList,0); x++){ 

      // Looping through all order number in list
      doesOrderExist=False;
      orderTicketNumber=(int)HiddenTPList[x,0];

      if(orderTicketNumber!=0){ 
         // Order exists
         for(int y=ordersPos-1; y>=0; y--){ 
            // Looping through all current open positions
            if(OrderSelect(y,SELECT_BY_POS,MODE_TRADES)==true && OrderSymbol()==Symbol() && 
               OrderMagicNumber()==MagicNumber){
               if(orderTicketNumber==OrderTicket()) {
                  // Checks order number in list against order number of current positions
                  doesOrderExist=True;
                  break;
               }
            }
         }

         if(doesOrderExist==False){
            // Deletes elements if the order number does not match any current positions
            HiddenTPList[x, 0] = 0;
            HiddenTPList[x, 1] = 0;
         }
      }
   }

   // 2) Check each position against its hidden TP and close the position if hidden TP is hit

   for(int z=0; z<ArrayRange(HiddenTPList,0); z++){

      // Loops through elements in the list
      orderTicketNumber=(int)HiddenTPList[z,0]; // Records order numner
      orderTP=HiddenTPList[z,1]; // Records TP

      if(OrderSelect(orderTicketNumber,SELECT_BY_TICKET)==true && OrderSymbol()==Symbol() && 
         OrderMagicNumber()==MagicNumber){
         
         bool Closing=false;
         if(OrderType()==OP_BUY && OrderOpenPrice()+(orderTP*P*Point)<=Bid){

            // Checks TP condition for closing long orders
            if(OnJournaling)Print("EA Journaling: Trying to close position "+(string)OrderTicket()+" ...");
            HandleTradingEnvironment();
            Closing=OrderClose(OrderTicket(),OrderLots(),Bid,(int)(Slippage*P),Blue);
            if(OnJournaling && !Closing) Print("EA Journaling: Unexpected Error has happened. Error Description: "+
                                               GetErrorDescription(GetLastError()));
            if(OnJournaling &&  Closing) Print("EA Journaling: Position successfully closed.");
         }
         if(OrderType()==OP_SELL && OrderOpenPrice() -(orderTP*P*Point)>=Ask) {
         
            // Checks TP condition for closing short orders 
            if(OnJournaling)Print("EA Journaling: Trying to close position "+(string)OrderTicket()+" ...");
            HandleTradingEnvironment();
            Closing=OrderClose(OrderTicket(),OrderLots(),Ask,(int)(Slippage*P),Red);
            if(OnJournaling && !Closing) Print("EA Journaling: Unexpected Error has happened. Error Description: "+
                                              GetErrorDescription(GetLastError()));
            if(OnJournaling &&  Closing) Print("EA Journaling: Position successfully closed.");

         }
      }
   }
}

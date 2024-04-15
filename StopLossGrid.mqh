#include "Framework.mqh"

//
// Inputs
//

input int InputLevelPoints = 0; // Trade gap in points
input bool InpExitOnStopLoss = true; // Exit on stop loss


//  Now some general trading info
input double InpOrderSize = 0.00; // Order size
input string InpTradeComment = "Stop Loss Grid"; // Trade comment
input int InpMagic = 22222; // Magic

#include "Expert.mqh"
CExpert *Expert;

int OnInit() {

   Expert = new CExpert(InputLevelPoints, InpOrderSize, InpTradeComment, InpMagic);
   Expert.mExitOnStopLoss = InpExitOnStopLoss; // A bit of a hack

   return (Expert.InitResult());
}

void OnDeinit(const int reason) {
   delete Expert;
}

void OnTick(){
   Expert.OnTick();
   return;   
}
//+------------------------------------------------------------------+

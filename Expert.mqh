#include "Framework.mqh"

class CExpert : public CExpertBase {

private:
protected:
   // Init values
   double mLevelSize;

   // Working values
   bool   mClosing;
   bool   mExiting;
   double mBuyPrice;
   double mSellPrice;
   double mExitPrice;
   double mLevelCount;

   void   Loop();

   void   ResetCounters();
   void   OpenGrid();
   void   CloseGrid();
   void   ExitGrid();
   double OpenPosition( ENUM_ORDER_TYPE type );
   bool   ClosePosition( ENUM_POSITION_TYPE type );
   void   NewLevel( ENUM_ORDER_TYPE orderType, double &levelPrice, double &oppositePrice );

   // For the demo, or if you want it
   void   DisplayLevels();
   void   DisplayLevel( string name, double value, string text );

public:
   CExpert( int    levelPoints, //
            double orderSize, string tradeComment, long magic );
   ~CExpert();
   
   bool mExitOnStopLoss;
};

// As written this does not cope with restarting because all information is
//  inside variables that are lost on restart. To make this restartable
//  use global variables

CExpert::CExpert( int levelPoints, double orderSize, string tradeComment, long magic )
   : CExpertBase( orderSize, tradeComment, magic ) {

   mLevelSize = PointsToDouble( levelPoints );
   mExitOnStopLoss = true;

   ResetCounters();

   mInitResult = INIT_SUCCEEDED;
}

CExpert::~CExpert() {
}

void CExpert::Loop() {
   
   // New for safe exit
   if ( mExiting ) {
      ExitGrid();
      return;
   }

   //	This is here to make sure a close is a close
   if ( mClosing ) {
      CloseGrid();
      return;
   }

   // If there is nothing currently open then get started
   if ( mBuyPrice == 0 && mSellPrice == 0 ) {
      OpenGrid();
      return;
   }

   // I use SymbolInfoDouble ans pass in symbol instead of
   //  using inbuilt functions with defaults
   double bid = SymbolInfoDouble( mSymbol, SYMBOL_BID ); // Close price for buy
   double ask = SymbolInfoDouble( mSymbol, SYMBOL_ASK ); // close price for sell

   // If price has retreated to exit then close out
   if ( mExitPrice > 0 ) {
      if ( ( mBuyPrice > 0 && ask <= mExitPrice ) || ( mSellPrice > 0 && bid >= mExitPrice ) ) {
         CloseGrid();
         return;
      }
   }

   // If price has reached the next buy/sell price then shift up/down
   if ( ( mBuyPrice > 0 && bid >= mBuyPrice ) ) {
      NewLevel( ORDER_TYPE_SELL, mBuyPrice, mSellPrice );
      return;
   }

   if ( mSellPrice > 0 && ask <= mSellPrice ) {
      NewLevel( ORDER_TYPE_BUY, mSellPrice, mBuyPrice );
      return;
   }

   return;
}

void CExpert::NewLevel( ENUM_ORDER_TYPE orderType,double &levelPrice,double &oppositePrice ) {
   mLevelCount++;
   oppositePrice = 0;
   double mult = ( orderType == ORDER_TYPE_BUY ) ? -1 : 1;
   
   if ( mLevelCount >= 4 ) {
      CloseGrid();
      if ( mExitOnStopLoss ) {
         ExitGrid();
         return;
      }
   }
   else {
      mExitPrice = OpenPosition(orderType);
      if ( mExitPrice == 0 ) {
         CloseGrid();
      }
      else {
         levelPrice += ( mLevelSize * mult );
         mExitPrice -= ( mLevelSize * mult );         
      }
      DisplayLevels();
   }
}

void CExpert::ResetCounters() {

   mClosing    = false;
   mExiting    = false;
   mBuyPrice   = 0; // Price to open next buy
   mSellPrice  = 0; // Price to open next sell
   mExitPrice  = 0; // Pullback price to close grid
   mLevelCount = 0; // How many levels deep

   DisplayLevels();
}

void CExpert::OpenGrid() {

   ResetCounters();
   
   mBuyPrice = SymbolInfoDouble(mSymbol, SYMBOL_ASK);
   mSellPrice = SymbolInfoDouble(mSymbol, SYMBOL_BID);
   mBuyPrice += mLevelSize;
   mSellPrice -= mLevelSize;

   DisplayLevels();
}

void CExpert::CloseGrid() {

   mClosing = !( ClosePosition( POSITION_TYPE_BUY ) && ClosePosition( POSITION_TYPE_SELL ) );

   if ( !mClosing ) {
      ResetCounters();
   }
}

void CExpert::ExitGrid(void) {
   
   if ( !mExiting ) {
      Print("Hit SL, stopping expert");
   }
   
   mExiting = true;
   CloseGrid();
   if ( mClosing ) {
      return;
   }
   
   ExpertRemove();
}

double CExpert::OpenPosition( ENUM_ORDER_TYPE type ) {

   double price = ( type == ORDER_TYPE_BUY ) ? SymbolInfoDouble( mSymbol, SYMBOL_ASK )
                                             : SymbolInfoDouble( mSymbol, SYMBOL_BID );
   if ( Trade.PositionOpen( mSymbol, type, mOrderSize, price, 0, 0, mTradeComment ) ) {
      return ( Trade.ResultPrice() );
   }
   return ( 0 );
}

bool CExpert::ClosePosition( ENUM_POSITION_TYPE type ) {

   return ( Trade.PositionCloseByType( mSymbol, type ) );
}

void CExpert::DisplayLevels() {

   DisplayLevel( "BuyAt", mBuyPrice, "Buy At" );
   DisplayLevel( "SellAt", mSellPrice, "Sell At" );
   DisplayLevel( "ExitAt", mExitPrice, "Exit At" );
}

void CExpert::DisplayLevel( string name, double value, string text ) {

   string textName = name + "_text";
   ObjectDelete( 0, name );
   ObjectDelete( 0, textName );

   if ( value == 0 ) return;

   datetime time0 = iTime( mSymbol, mTimeframe, 0 );
   datetime time1 = iTime( mSymbol, mTimeframe, 1 );

   ObjectCreate( 0, name, OBJ_TREND, 0, time1, value, time0, value );
   ObjectSetInteger( 0, name, OBJPROP_HIDDEN, false );
   ObjectSetInteger( 0, name, OBJPROP_RAY_RIGHT, true );
   ObjectSetInteger( 0, name, OBJPROP_COLOR, clrYellow );

   ObjectCreate( 0, textName, OBJ_TEXT, 0, time0, value );
   ObjectSetInteger( 0, textName, OBJPROP_HIDDEN, false );
   ObjectSetString( 0, textName, OBJPROP_TEXT, StringFormat( text + " %f", value ) );
   ObjectSetInteger( 0, textName, OBJPROP_COLOR, clrYellow );

   return;
}
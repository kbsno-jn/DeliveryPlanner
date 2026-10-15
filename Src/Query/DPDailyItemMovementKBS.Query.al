namespace Knowit.DeliveryPlanner;

using Microsoft.Inventory.Ledger;

query 78900 "DP Daily Item Movement KBS"
{
    Caption = 'DeliveryPlanner-varebevegelse per dag';
    QueryType = Normal;
    OrderBy = ascending(Posting_Date);

    elements
    {
        dataitem(ItemLedgerEntry; "Item Ledger Entry")
        {
            filter(Item_No; "Item No.") { }
            filter(Variant_Code; "Variant Code") { }
            filter(Location_Code; "Location Code") { }
            column(Posting_Date; "Posting Date") { }
            column(Entry_Type; "Entry Type") { }
            column(Quantity; Quantity) { Method = Sum; }
        }
    }
}
